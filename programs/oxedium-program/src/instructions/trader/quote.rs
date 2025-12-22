use anchor_lang::prelude::*;
use anchor_spl::token::Mint;
use pyth_solana_receiver_sdk::price_update::PriceUpdateV2;

use crate::{
    components::{calculate_fee_amount, check_stoptap, fees_setting, raw_amount_out},
    events::RouteEvent,
    states::{Treasury, Vault},
    utils::{OXEDIUM_SEED, TREASURY_SEED, TyrbineError, VAULT_SEED},
};

/// Quote swap without executing transfers (no signer required)
pub fn quote(
    ctx: Context<QuoteInstructionAccounts>,
    amount_in: u64,
    partner_fee_bps: u64,
) -> Result<()> {
    // === 1. Check if vaults are active ===
    check_stoptap(&ctx.accounts.vault_pda_in, &ctx.accounts.treasury_pda)?;
    check_stoptap(&ctx.accounts.vault_pda_out, &ctx.accounts.treasury_pda)?;

    let vault_in: &Account<Vault> = &ctx.accounts.vault_pda_in;
    let vault_out: &Account<Vault> = &ctx.accounts.vault_pda_out;

    // === 2. Validate Pyth price accounts ===
    if ctx.accounts.pyth_price_account_in.key() != vault_in.pyth_price_account {
        return Err(TyrbineError::InvalidPythAccount.into());
    }
    if ctx.accounts.pyth_price_account_out.key() != vault_out.pyth_price_account {
        return Err(TyrbineError::InvalidPythAccount.into());
    }

    // === 3. Read prices ===
    let price_in: u64 = ctx.accounts.pyth_price_account_in.price_message.price as u64;
    let price_out: u64 = ctx.accounts.pyth_price_account_out.price_message.price as u64;

    // === 4. Check freshness ===
    let clock = Clock::get()?;
    let now = clock.unix_timestamp;

    if now - ctx.accounts.pyth_price_account_in.price_message.publish_time
        > vault_in.max_age_price as i64
    {
        return Err(TyrbineError::OracleDataTooOld.into());
    }

    if now - ctx.accounts.pyth_price_account_out.price_message.publish_time
        > vault_out.max_age_price as i64
    {
        return Err(TyrbineError::OracleDataTooOld.into());
    }

    // === 5. Raw output ===
    let raw_out = raw_amount_out(
        amount_in,
        ctx.accounts.mint_in.decimals,
        ctx.accounts.mint_out.decimals,
        price_in,
        price_out,
    )?;

    // === 6. Fees ===
    let swap_fee_bps = fees_setting(vault_in, vault_out);
    let protocol_fee_bps = ctx.accounts.treasury_pda.proto_fee_bps;

    let ten_percent_liquidity = vault_out.current_liquidity / 10;
    let adjusted_swap_fee_bps = if raw_out > ten_percent_liquidity {
        swap_fee_bps * 100
    } else {
        swap_fee_bps
    };

    if swap_fee_bps + protocol_fee_bps + partner_fee_bps > 10_000 {
        return Err(TyrbineError::FeeExceeds.into());
    }

    let (amount_out, lp_fee, protocol_fee, partner_fee) =
        calculate_fee_amount(
            raw_out,
            adjusted_swap_fee_bps,
            protocol_fee_bps,
            partner_fee_bps,
        )?;

    // === 7. Emit route event ===
    emit!(RouteEvent {
        user: Pubkey::default(), // quote — без пользователя
        fee_bps: swap_fee_bps + protocol_fee_bps + partner_fee_bps,
        token_in: vault_in.token_mint,
        token_out: vault_out.token_mint,
        amount_in,
        amount_out,
        price_in,
        price_out,
        decimals_in: ctx.accounts.mint_in.decimals,
        decimals_out: ctx.accounts.mint_out.decimals,
        lp_fee,
        protocol_fee,
        partner_fee,
        timestamp: now,
    });

    Ok(())
}

#[derive(Accounts)]
pub struct QuoteInstructionAccounts<'info> {
    pub mint_in: Account<'info, Mint>,
    pub mint_out: Account<'info, Mint>,

    pub pyth_price_account_in: Account<'info, PriceUpdateV2>,
    pub pyth_price_account_out: Account<'info, PriceUpdateV2>,

    #[account(seeds = [VAULT_SEED.as_bytes(), mint_in.key().as_ref()], bump)]
    pub vault_pda_in: Account<'info, Vault>,

    #[account(seeds = [VAULT_SEED.as_bytes(), mint_out.key().as_ref()], bump)]
    pub vault_pda_out: Account<'info, Vault>,

    #[account(seeds = [OXEDIUM_SEED.as_bytes(), TREASURY_SEED.as_bytes()], bump)]
    pub treasury_pda: Account<'info, Treasury>,
}
