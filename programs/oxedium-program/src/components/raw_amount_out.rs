use crate::utils::TyrbineError;

/// Calculates the output amount for a token swap based on input amount, token decimals, and token prices.
///
/// # Arguments
/// * `amount_in` - The amount of input tokens being swapped
/// * `decimals_in` - Number of decimal places for the input token
/// * `decimals_out` - Number of decimal places for the output token
/// * `price_in` - Price of the input token (in base units)
/// * `price_out` - Price of the output token (in base units)
///
/// # Returns
/// * `Result<u64, TyrbineError>` - The calculated output amount in tokens, or an error if overflow occurs
pub fn raw_amount_out(
    amount_in: u64,
    decimals_in: u8,
    decimals_out: u8,
    price_in: u64,
    price_out: u64
) -> Result<u64, TyrbineError> {

    // Compute the difference in decimal places between output and input tokens
    let decimals_diff = decimals_out as i32 - decimals_in as i32;

    // Calculate the scaling factor to adjust for decimal difference
    // scale = 10^abs(decimals_diff)
    let scale = 10u128
        .checked_pow(decimals_diff.abs() as u32)
        .ok_or(TyrbineError::OverflowInPow)?;

    // Convert amount_in to u128 to safely perform arithmetic without overflow
    let amount_in_u128 = amount_in as u128;

    // Adjust amount_in according to the decimals difference
    // - Multiply if output token has more decimals
    // - Divide if output token has fewer decimals
    let adjusted_amount_in = if decimals_diff > 0 {
        amount_in_u128
            .checked_mul(scale)
            .ok_or(TyrbineError::OverflowInMul)?
    } else {
        amount_in_u128
            .checked_div(scale)
            .ok_or(TyrbineError::OverflowInDiv)?
    };

    // Apply token prices to compute the output amount
    // Formula: amount_out = adjusted_amount_in * price_in / price_out
    let result = adjusted_amount_in
        .checked_mul(price_in as u128)
        .ok_or(TyrbineError::OverflowInMul)?
        .checked_div(price_out as u128)
        .ok_or(TyrbineError::OverflowInDiv)?;

    // Convert result back to u64, returning an error if it overflows u64
    u64::try_from(result).map_err(|_| TyrbineError::OverflowInCast)
}
