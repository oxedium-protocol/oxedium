use crate::utils::{SCALE, TyrbineError};

/// Calculates the raw output amount for a token swap using fixed-point math.
/// Supports dust swaps by avoiding early division and rounding only once at the end.
///
/// # Arguments
/// * `amount_in` - Input token amount in smallest units
/// * `decimals_in` - Decimals of the input token
/// * `decimals_out` - Decimals of the output token
/// * `price_in` - Price of the input token (e.g. Pyth price, scaled)
/// * `price_out` - Price of the output token (e.g. Pyth price, scaled)
///
/// # Returns
/// * `Result<u64, TyrbineError>` - Output token amount in smallest units
pub fn raw_amount_out(
    amount_in: u64,
    decimals_in: u8,
    decimals_out: u8,
    price_in: u64,
    price_out: u64,
) -> Result<u64, TyrbineError> {
    let amount_in = amount_in as u128;
    let price_in = price_in as u128;
    let price_out = price_out as u128;

    // 1. Convert input amount into fixed-point token representation
    //    amount_fp = amount_in / 10^decimals_in (in FP precision)
    let amount_fp = amount_in
        .checked_mul(SCALE)
        .ok_or(TyrbineError::OverflowInMul)?
        .checked_div(10u128.pow(decimals_in as u32))
        .ok_or(TyrbineError::OverflowInDiv)?;

    // 2. Convert input token amount into USD value (still fixed-point)
    //    Assumes price is scaled (e.g. 1e8 for Pyth)
    let usd_fp = amount_fp
        .checked_mul(price_in)
        .ok_or(TyrbineError::OverflowInMul)?
        .checked_div(1_000_000_00) // price scale (adjust if different)
        .ok_or(TyrbineError::OverflowInDiv)?;

    // 3. Convert USD value into output token amount (fixed-point)
    let out_fp = usd_fp
        .checked_mul(1_000_000_00) // price scale
        .ok_or(TyrbineError::OverflowInMul)?
        .checked_div(price_out)
        .ok_or(TyrbineError::OverflowInDiv)?;

    // 4. Convert fixed-point output into smallest output token units
    //    This is the ONLY place where rounding occurs
    let out = out_fp
        .checked_mul(10u128.pow(decimals_out as u32))
        .ok_or(TyrbineError::OverflowInMul)?
        .checked_div(SCALE)
        .ok_or(TyrbineError::OverflowInDiv)?;

    // Convert back to u64
    u64::try_from(out).map_err(|_| TyrbineError::OverflowInCast)
}
