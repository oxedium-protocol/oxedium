use pyth_solana_receiver_sdk::price_update::PriceFeedMessage;
use crate::utils::{SCALE, OxediumError};

pub fn raw_amount_out(
    amount_in: u64,
    decimals_in: u8,
    decimals_out: u8,
    price_message_in: PriceFeedMessage,
    price_message_out: PriceFeedMessage,
) -> Result<u64, OxediumError> {
    let amount_in = amount_in as u128;

    // ---------- 1. Adverse prices ----------
    // input token -> lower bound
    let price_in = (price_message_in.price as i128)
        .checked_sub(price_message_in.conf as i128)
        .ok_or(OxediumError::OverflowInSub)? as u128;

    // output token -> upper bound
    let price_out = (price_message_out.price as i128)
        .checked_add(price_message_out.conf as i128)
        .ok_or(OxediumError::OverflowInAdd)? as u128;

    let exp_in = price_message_in.exponent.abs() as u32;
    let exp_out = price_message_out.exponent.abs() as u32;

    // ---------- 2. amount_in → fixed point ----------
    let amount_fp = amount_in
        .checked_mul(SCALE)
        .ok_or(OxediumError::OverflowInMul)?
        .checked_div(10u128.pow(decimals_in as u32))
        .ok_or(OxediumError::OverflowInDiv)?;

    // ---------- 3. token_in → USD ----------
    let usd_fp = amount_fp
        .checked_mul(price_in)
        .ok_or(OxediumError::OverflowInMul)?
        .checked_div(10u128.pow(exp_in))
        .ok_or(OxediumError::OverflowInDiv)?;

    // ---------- 4. USD → token_out ----------
    let out_fp = usd_fp
        .checked_mul(10u128.pow(exp_out))
        .ok_or(OxediumError::OverflowInMul)?
        .checked_div(price_out)
        .ok_or(OxediumError::OverflowInDiv)?;

    // ---------- 5. fixed point → smallest units ----------
    let out = out_fp
        .checked_mul(10u128.pow(decimals_out as u32))
        .ok_or(OxediumError::OverflowInMul)?
        .checked_div(SCALE)
        .ok_or(OxediumError::OverflowInDiv)?;

    u64::try_from(out).map_err(|_| OxediumError::OverflowInCast)
}
