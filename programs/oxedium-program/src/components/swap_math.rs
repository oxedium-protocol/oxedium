use crate::{components::{calculate_fee_amount, fees_setting, raw_amount_out}, states::{Treasury, Vault}, utils::TyrbineError};

pub struct SwapMathResult {
    pub swap_fee_bps: u64,
    pub raw_amount_out: u64,
    pub net_amount_out: u64,
    pub lp_fee_amount: u64,
    pub protocol_fee_amount: u64,
    pub partner_fee_amount: u64,
}

pub fn compute_swap_math(
    amount_in: u64,
    price_in: u64,
    price_out: u64,
    decimals_in: u8,
    decimals_out: u8,
    vault_in: &Vault,
    vault_out: &Vault,
    treasury: &Treasury,
    partner_fee_bps: u64,
) -> Result<SwapMathResult, TyrbineError> {
    let swap_fee_bps = fees_setting(&vault_in, &vault_out);
    let protocol_fee_bps = treasury.fee_bps;

    let raw_out = raw_amount_out(
        amount_in,
        decimals_in,
        decimals_out,
        price_in,
        price_out,
    )?;

    if swap_fee_bps + protocol_fee_bps + partner_fee_bps > 10_000 {
        return Err(TyrbineError::FeeExceeds.into());
    }

    let (after_fee, lp_fee, protocol_fee, partner_fee) =
        calculate_fee_amount(
            raw_out,
            swap_fee_bps,
            protocol_fee_bps,
            partner_fee_bps,
        )?;
    
    if vault_out.current_liquidity < (after_fee + lp_fee + protocol_fee + partner_fee) {
        return Err(TyrbineError::InsufficientLiquidity.into());
    }

    Ok(SwapMathResult {
        swap_fee_bps: swap_fee_bps,
        raw_amount_out: raw_out,
        net_amount_out: after_fee,
        lp_fee_amount: lp_fee,
        protocol_fee_amount: protocol_fee,
        partner_fee_amount: partner_fee,
    })
}
