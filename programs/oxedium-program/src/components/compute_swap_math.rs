use pyth_solana_receiver_sdk::price_update::PriceFeedMessage;

use crate::{
    components::{calculate_fee_amount, fees_setting, raw_amount_out},
    states::{Treasury, Vault},
    utils::OxediumError,
};

pub struct SwapMathResult {
    pub swap_fee_bps: u64,
    pub raw_amount_out: u64,
    pub net_amount_out: u64,
    pub lp_fee_amount: u64,
    pub protocol_fee_amount: u64,
}

pub fn compute_swap_math(
    amount_in: u64,
    oracle_in: PriceFeedMessage,
    oracle_out: PriceFeedMessage,
    decimals_in: u8,
    decimals_out: u8,
    vault_in: &Vault,
    vault_out: &Vault,
    treasury: &Treasury,
) -> Result<SwapMathResult, OxediumError> {
    let swap_fee_bps = fees_setting(&vault_in, &vault_out);

    let protocol_fee_bps = treasury.fee_bps;

    let raw_out = raw_amount_out(amount_in, decimals_in, decimals_out, oracle_in, oracle_out)?;

    let ten_percent_of_liquidity = vault_out.current_liquidity / treasury.deviation; // 10%
    let adjusted_swap_fee_bps = if raw_out > ten_percent_of_liquidity {
        swap_fee_bps * 10 // e.g., x10 fee
    } else {
        swap_fee_bps
    };

    if adjusted_swap_fee_bps + protocol_fee_bps > 10_000 {
        return Err(OxediumError::FeeExceeds.into());
    }

    let (after_fee, lp_fee, protocol_fee) =
        calculate_fee_amount(raw_out, adjusted_swap_fee_bps, protocol_fee_bps)?;

    if vault_out.current_liquidity < (after_fee + lp_fee + protocol_fee) {
        return Err(OxediumError::InsufficientLiquidity.into());
    }

    Ok(SwapMathResult {
        swap_fee_bps: adjusted_swap_fee_bps,
        raw_amount_out: raw_out,
        net_amount_out: after_fee,
        lp_fee_amount: lp_fee,
        protocol_fee_amount: protocol_fee,
    })
}
