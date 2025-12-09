use anchor_lang::prelude::*;
use anchor_spl::{associated_token::AssociatedToken, token::{self, Mint, Token, TokenAccount}};
use pyth_solana_receiver_sdk::price_update::PriceUpdateV2;

use crate::{components::{calculate_fee_amount, check_stoptap, fees_setting, raw_amount_out}, events::SwapEvent, states::{Treasury, Vault}, utils::{SCALE, TREASURY_SEED, OXEDIUM_SEED, TyrbineError, VAULT_SEED}};

pub fn swap(
    ctx: Context<SwapInstructionAccounts>,
    amount_in: u64,
    partner_fee_bps: u64,
) -> Result<()> {

    check_stoptap(&ctx.accounts.vault_pda_in, &ctx.accounts.treasury_pda)?;
    check_stoptap(&ctx.accounts.vault_pda_out, &ctx.accounts.treasury_pda)?;

    let vault_in: &mut Account<'_, Vault> = &mut ctx.accounts.vault_pda_in;
    let vault_out: &mut Account<'_, Vault> = &mut ctx.accounts.vault_pda_out;

    if ctx.accounts.pyth_price_account_in.key() != vault_in.pyth_price_account {
        return Err(TyrbineError::InvalidPythAccount.into());
    }
    
    if ctx.accounts.pyth_price_account_out.key() != vault_out.pyth_price_account {
        return Err(TyrbineError::InvalidPythAccount.into());
    }

    let price_in: u64 = ctx.accounts.pyth_price_account_in.price_message.price as u64;
    let price_out: u64 = ctx.accounts.pyth_price_account_out.price_message.price as u64;
    
    let clock: Clock = Clock::get()?;
    let current_timestamp: i64 = clock.unix_timestamp;

    let max_age_vault_in: i64 = current_timestamp - ctx.accounts.pyth_price_account_in.price_message.publish_time;
    let max_age_vault_out: i64 = current_timestamp - ctx.accounts.pyth_price_account_out.price_message.publish_time;

    if  max_age_vault_in > vault_in.max_age_price as i64 {
        msg!("Vault In: Price feed stale by {} seconds", max_age_vault_in);
        return Err(TyrbineError::OracleDataTooOld.into());
    }

    if  max_age_vault_out > vault_out.max_age_price as i64 {
        msg!("Vault Out: Price feed stale by {} seconds", max_age_vault_out);
        return Err(TyrbineError::OracleDataTooOld.into());
    }

    let token_in_decimals: u8 = ctx.accounts.mint_in.decimals;
    let token_out_decimals: u8 = ctx.accounts.mint_out.decimals;

    let token_raw_amount_out: u64 = raw_amount_out(amount_in, token_in_decimals, token_out_decimals, price_in, price_out)?;

    let swap_fee_bps = fees_setting(&vault_in, &vault_out);
    let protocol_fee_bps = ctx.accounts.treasury_pda.proto_fee_bps;
    
    let (after_fee, lp_fee, protocol_fee, partner_fee) = calculate_fee_amount(token_raw_amount_out, swap_fee_bps, protocol_fee_bps, partner_fee_bps)?;
    
    if vault_out.current_liquidity < (after_fee + lp_fee + protocol_fee + partner_fee) {
        return Err(TyrbineError::InsufficientLiquidity.into());
    }

    vault_in.current_liquidity += amount_in;
    vault_out.current_liquidity -= after_fee;
    
    vault_out.cumulative_yield_per_lp += (lp_fee as u128 * SCALE) / vault_out.initial_liquidity as u128;
    vault_out.protocol_yield += protocol_fee;

    let cpi_accounts: token::Transfer<'_> = token::Transfer {
        from: ctx.accounts.signer_ata_in.to_account_info(),
        to: ctx.accounts.treasury_ata_in.to_account_info(),
        authority: ctx.accounts.signer.to_account_info(),
    };

    token::transfer(CpiContext::new(ctx.accounts.token_program.to_account_info(), cpi_accounts), amount_in)?;
    
    let seeds: &[&[u8]; 3] = &[OXEDIUM_SEED.as_bytes(), TREASURY_SEED.as_bytes(), &[ctx.bumps.treasury_pda]];
    let signer_seeds: &[&[&[u8]]; 1] = &[&seeds[..]];

    let cpi_accounts: token::Transfer<'_> = token::Transfer {
        from: ctx.accounts.treasury_ata_out.to_account_info(),
        to: ctx.accounts.signer_ata_out.to_account_info(), 
        authority: ctx.accounts.treasury_pda.to_account_info()
    };

    token::transfer(
        CpiContext::new_with_signer(
            ctx.accounts.token_program.to_account_info(), 
            cpi_accounts, 
            signer_seeds), 
        after_fee)?;
    
    if partner_fee > 0 {
        let partner_fee_account: &AccountInfo<'_> = ctx.accounts.partner_fee_ata.as_ref().ok_or(TyrbineError::MissingSPLAccount)?;

        let seeds: &[&[u8]; 3] = &[OXEDIUM_SEED.as_bytes(), TREASURY_SEED.as_bytes(), &[ctx.bumps.treasury_pda]];
        let signer_seeds: &[&[&[u8]]; 1] = &[&seeds[..]];
    
        let cpi_accounts: token::Transfer<'_> = token::Transfer {
            from: ctx.accounts.treasury_ata_out.to_account_info(),
            to: partner_fee_account.to_account_info(), 
            authority: ctx.accounts.treasury_pda.to_account_info()
        };
    
        token::transfer(
            CpiContext::new_with_signer(
                ctx.accounts.token_program.to_account_info(), 
                cpi_accounts, 
                signer_seeds), 
                partner_fee)?;
    }

    emit!(SwapEvent {
        user: ctx.accounts.signer.key(),
        fee_bps: swap_fee_bps + protocol_fee_bps,
        token_in: vault_in.token_mint,
        token_out: vault_out.token_mint,
        amount_in: amount_in,
        amount_out: after_fee,
        price_in: price_in,
        price_out: price_out,
        decimals_in: token_in_decimals,
        decimals_out: token_out_decimals,
        lp_fee: lp_fee,
        protocol_fee: protocol_fee,
        partner_fee: partner_fee,
        timestamp: current_timestamp,
    });

    Ok(())
}

#[derive(Accounts)]
pub struct SwapInstructionAccounts<'info> {
    #[account(mut)]
    pub signer: Signer<'info>,

    /// CHECK:
    pub mint_in: Account<'info, Mint>,

    /// CHECK:
    pub mint_out: Account<'info, Mint>,

    /// CHECK: pyth_price_account_in
    pub pyth_price_account_in: Account<'info, PriceUpdateV2>,

    /// CHECK: pyth_price_account_out
    pub pyth_price_account_out: Account<'info, PriceUpdateV2>,

    #[account(mut, token::authority = signer, token::mint = mint_in)]
    pub signer_ata_in: Account<'info, TokenAccount>,

    #[account(
        init_if_needed,
        payer = signer,
        associated_token::mint = mint_out,
        associated_token::authority = signer,
    )]
    pub signer_ata_out: Account<'info, TokenAccount>,

    /// CHECK:
    #[account(mut, seeds = [VAULT_SEED.as_bytes(), mint_in.key().as_ref()], bump)]
    pub vault_pda_in: Account<'info, Vault>,

    /// CHECK:
    #[account(mut, seeds = [VAULT_SEED.as_bytes(), mint_out.key().as_ref()], bump)]
    pub vault_pda_out: Account<'info, Vault>,

    #[account(mut, seeds = [OXEDIUM_SEED.as_bytes(), TREASURY_SEED.as_bytes()], bump)]
    pub treasury_pda: Account<'info, Treasury>,

    #[account(mut, token::authority = treasury_pda, token::mint = mint_in)]
    pub treasury_ata_in: Account<'info, TokenAccount>,

    #[account(mut, token::authority = treasury_pda, token::mint = mint_out)]
    pub treasury_ata_out: Account<'info, TokenAccount>,

    #[account(mut)]
    pub partner_fee_ata: Option<AccountInfo<'info>>,

    pub associated_token_program: Program<'info, AssociatedToken>,
    pub token_program: Program<'info, Token>,
    pub system_program: Program<'info, System>,
}
