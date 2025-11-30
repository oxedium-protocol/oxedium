use crate::utils::TyrbineError;

pub fn calculate_fee_amount(
    amount_out: u64,
    fee: u64,
    protocol_fee: u64,
    partner_fee: u64
) -> Result<(u64, u64, u64, u64), TyrbineError> {

    let total_fee = amount_out
        .checked_mul(fee).ok_or(TyrbineError::Overflow)?
        .checked_div(10_000).ok_or(TyrbineError::DivideByZero)?;

    let protocol_fee_amount = amount_out
        .checked_mul(protocol_fee).ok_or(TyrbineError::Overflow)?
        .checked_div(10_000).ok_or(TyrbineError::DivideByZero)?;

    let partner_fee_amount = amount_out
        .checked_mul(partner_fee).ok_or(TyrbineError::Overflow)?
        .checked_div(10_000).ok_or(TyrbineError::DivideByZero)?;

    let lp_fee = total_fee
        .checked_sub(protocol_fee_amount).ok_or(TyrbineError::Overflow)?
        .checked_sub(partner_fee_amount).ok_or(TyrbineError::Overflow)?;

    let amount_after_fee = amount_out.checked_sub(total_fee).ok_or(TyrbineError::Overflow)?;

    Ok((amount_after_fee, lp_fee, protocol_fee_amount, partner_fee_amount))
}
