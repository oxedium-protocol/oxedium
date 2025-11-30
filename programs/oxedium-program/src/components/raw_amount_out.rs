use crate::utils::TyrbineError;

pub fn raw_amount_out(
    amount_in: u64,
    decimals_in: u8,
    decimals_out: u8,
    price_in: u64,
    price_out: u64
) -> Result<u64, TyrbineError> {

    let decimals_diff = decimals_out as i32 - decimals_in as i32;

    let scale = 10u128
        .checked_pow(decimals_diff.abs() as u32)
        .ok_or(TyrbineError::OverflowInPow)?;

    let amount_in_u128 = amount_in as u128;

    let adjusted_amount_in = if decimals_diff > 0 {
        amount_in_u128
            .checked_mul(scale)
            .ok_or(TyrbineError::OverflowInMul)?
    } else {
        amount_in_u128
            .checked_div(scale)
            .ok_or(TyrbineError::OverflowInDiv)?
    };

    let result = adjusted_amount_in
        .checked_mul(price_in as u128)
        .ok_or(TyrbineError::OverflowInMul)?
        .checked_div(price_out as u128)
        .ok_or(TyrbineError::OverflowInDiv)?;

    // конвертируем обратно в u64
    u64::try_from(result).map_err(|_| TyrbineError::OverflowInCast)
}
