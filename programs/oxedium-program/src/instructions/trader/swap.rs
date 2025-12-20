use anchor_lang::prelude::*;
use anchor_spl::{
    associated_token::AssociatedToken,
    token::{self, Mint, Token, TokenAccount},
};
use pyth_solana_receiver_sdk::price_update::PriceUpdateV2;

use crate::{
    components::{calculate_fee_amount, check_stoptap, fees_setting, raw_amount_out},
    events::{RouteEvent, SwapEvent},
    states::{Treasury, Vault},
    utils::{OXEDIUM_SEED, SCALE, TREASURY_SEED, TyrbineError, VAULT_SEED},
};

/// Swap tokens from one vault to another, optionally in quote-only mode
/// 
/// # Arguments
/// * `ctx` - context containing all accounts
/// * `amount_in` - amount of input tokens from user
/// * `partner_fee_bps` - optional partner fee in basis points
/// * `quote_only` - if true, only calculates output without executing transfers
pub fn swap(
    ctx: Context<SwapInstructionAccounts>,
    amount_in: u64,
    partner_fee_bps: u64,
    quote_only: bool,
) -> Result<()> {
    // === 1. Check if vaults are active ===
    check_stoptap(&ctx.accounts.vault_pda_in, &ctx.accounts.treasury_pda)?;
    check_stoptap(&ctx.accounts.vault_pda_out, &ctx.accounts.treasury_pda)?;

    let vault_in: &mut Account<'_, Vault> = &mut ctx.accounts.vault_pda_in;
    let vault_out: &mut Account<'_, Vault> = &mut ctx.accounts.vault_pda_out;

    // === 2. Validate Pyth price accounts ===
    if ctx.accounts.pyth_price_account_in.key() != vault_in.pyth_price_account {
        return Err(TyrbineError::InvalidPythAccount.into());
    }
    if ctx.accounts.pyth_price_account_out.key() != vault_out.pyth_price_account {
        return Err(TyrbineError::InvalidPythAccount.into());
    }

    // === 3. Read prices from Pyth ===
    let price_in: u64 = ctx.accounts.pyth_price_account_in.price_message.price as u64;
    let price_out: u64 = ctx.accounts.pyth_price_account_out.price_message.price as u64;

    // === 4. Check price feed freshness ===
    let clock: Clock = Clock::get()?;
    let current_timestamp: i64 = clock.unix_timestamp;

    let max_age_vault_in = current_timestamp - ctx.accounts.pyth_price_account_in.price_message.publish_time;
    let max_age_vault_out = current_timestamp - ctx.accounts.pyth_price_account_out.price_message.publish_time;

    if max_age_vault_in > vault_in.max_age_price as i64 {
        msg!("Vault In: Price feed stale by {} seconds", max_age_vault_in);
        return Err(TyrbineError::OracleDataTooOld.into());
    }
    if max_age_vault_out > vault_out.max_age_price as i64 {
        msg!("Vault Out: Price feed stale by {} seconds", max_age_vault_out);
        return Err(TyrbineError::OracleDataTooOld.into());
    }

    // === 5. Compute raw output amount ===
    let token_raw_amount_out: u64 = raw_amount_out(
        amount_in,
        ctx.accounts.mint_in.decimals,
        ctx.accounts.mint_out.decimals,
        price_in,
        price_out,
    )?;

    // === 6. Compute swap and protocol fees ===
    let swap_fee_bps = fees_setting(&vault_in, &vault_out);
    let protocol_fee_bps = ctx.accounts.treasury_pda.proto_fee_bps;

    // Apply high fee if swap > 10% of liquidity
    let ten_percent_of_liquidity = vault_out.current_liquidity / 10;
    let adjusted_swap_fee_bps = if token_raw_amount_out > ten_percent_of_liquidity {
        swap_fee_bps * 100
    } else {
        swap_fee_bps
    };

    if swap_fee_bps + protocol_fee_bps + partner_fee_bps > 10000 {
        return Err(TyrbineError::FeeExceeds.into());
    }

    let (after_fee, lp_fee, protocol_fee, partner_fee) =
        calculate_fee_amount(token_raw_amount_out, adjusted_swap_fee_bps, protocol_fee_bps, partner_fee_bps)?;

    // === 7. Quote-only mode: return output without executing transfer ===
    if quote_only {
        emit!(RouteEvent {
            user: ctx.accounts.signer.key(),
            fee_bps: swap_fee_bps + protocol_fee_bps,
            token_in: vault_in.token_mint,
            token_out: vault_out.token_mint,
            amount_in,
            amount_out: after_fee,
            price_in,
            price_out,
            decimals_in: ctx.accounts.mint_in.decimals,
            decimals_out: ctx.accounts.mint_out.decimals,
            lp_fee,
            protocol_fee,
            partner_fee,
            timestamp: current_timestamp,
        });

        return Ok(());
    }

    // === 8. Check liquidity ===
    if vault_out.current_liquidity < (after_fee + lp_fee + protocol_fee + partner_fee) {
        return Err(TyrbineError::InsufficientLiquidity.into());
    }

    // === 9. Update vaults and yields ===
    vault_in.current_liquidity += amount_in;
    vault_out.current_liquidity -= after_fee;
    vault_out.cumulative_yield_per_lp += (lp_fee as u128 * SCALE) / vault_out.initial_liquidity as u128;
    vault_out.protocol_yield += protocol_fee;

    // === 10. Transfer input tokens from user to treasury ===
    let cpi_accounts: token::Transfer<'_> = token::Transfer {
        from: ctx.accounts.signer_ata_in.to_account_info(),
        to: ctx.accounts.treasury_ata_in.to_account_info(),
        authority: ctx.accounts.signer.to_account_info(),
    };
    token::transfer(CpiContext::new(ctx.accounts.token_program.to_account_info(), cpi_accounts), amount_in)?;

    // === 11. Transfer output tokens from treasury to user ===
    let seeds: &[&[u8]; 3] = &[OXEDIUM_SEED.as_bytes(), TREASURY_SEED.as_bytes(), &[ctx.bumps.treasury_pda]];
    let signer_seeds: &[&[&[u8]]; 1] = &[&seeds[..]];

    let cpi_accounts_out: token::Transfer<'_> = token::Transfer {
        from: ctx.accounts.treasury_ata_out.to_account_info(),
        to: ctx.accounts.signer_ata_out.to_account_info(),
        authority: ctx.accounts.treasury_pda.to_account_info(),
    };
    token::transfer(
        CpiContext::new_with_signer(ctx.accounts.token_program.to_account_info(), cpi_accounts_out, signer_seeds),
        after_fee,
    )?;

    // === 12. Transfer partner fee (if applicable) ===
    if partner_fee > 0 {
        let partner_fee_account: &AccountInfo<'_> =
            ctx.accounts.partner_fee_ata.as_ref().ok_or(TyrbineError::MissingSPLAccount)?;
        let cpi_accounts_fee: token::Transfer<'_> = token::Transfer {
            from: ctx.accounts.treasury_ata_out.to_account_info(),
            to: partner_fee_account.to_account_info(),
            authority: ctx.accounts.treasury_pda.to_account_info(),
        };
        token::transfer(
            CpiContext::new_with_signer(ctx.accounts.token_program.to_account_info(), cpi_accounts_fee, signer_seeds),
            partner_fee,
        )?;
    }

    // === 13. Emit swap event for off-chain indexing ===
    emit!(SwapEvent {
        user: ctx.accounts.signer.key(),
        fee_bps: swap_fee_bps + protocol_fee_bps,
        token_in: vault_in.token_mint,
        token_out: vault_out.token_mint,
        amount_in,
        amount_out: after_fee,
        price_in,
        price_out,
        decimals_in: ctx.accounts.mint_in.decimals,
        decimals_out: ctx.accounts.mint_out.decimals,
        lp_fee,
        protocol_fee,
        partner_fee,
        timestamp: current_timestamp,
    });

    Ok(())
}

/// Accounts required for the swap instruction
#[derive(Accounts)]
pub struct SwapInstructionAccounts<'info> {
    #[account(mut)]
    pub signer: Signer<'info>, // user performing the swap

    pub mint_in: Account<'info, Mint>,  // input token mint
    pub mint_out: Account<'info, Mint>, // output token mint

    pub pyth_price_account_in: Account<'info, PriceUpdateV2>,  // Pyth price feed for input token
    pub pyth_price_account_out: Account<'info, PriceUpdateV2>, // Pyth price feed for output token

    #[account(mut, token::authority = signer, token::mint = mint_in)]
    pub signer_ata_in: Account<'info, TokenAccount>, // user's input token account

    #[account(
        init_if_needed,
        payer = signer,
        associated_token::mint = mint_out,
        associated_token::authority = signer,
    )]
    pub signer_ata_out: Account<'info, TokenAccount>, // user's output token account

    #[account(mut, seeds = [VAULT_SEED.as_bytes(), mint_in.key().as_ref()], bump)]
    pub vault_pda_in: Account<'info, Vault>, // input vault

    #[account(mut, seeds = [VAULT_SEED.as_bytes(), mint_out.key().as_ref()], bump)]
    pub vault_pda_out: Account<'info, Vault>, // output vault

    #[account(mut, seeds = [OXEDIUM_SEED.as_bytes(), TREASURY_SEED.as_bytes()], bump)]
    pub treasury_pda: Account<'info, Treasury>, // treasury PDA

    #[account(mut, token::authority = treasury_pda, token::mint = mint_in)]
    pub treasury_ata_in: Account<'info, TokenAccount>, // treasury input token account

    #[account(mut, token::authority = treasury_pda, token::mint = mint_out)]
    pub treasury_ata_out: Account<'info, TokenAccount>, // treasury output token account

    pub partner_fee_ata: Option<AccountInfo<'info>>, // optional partner fee account

    pub associated_token_program: Program<'info, AssociatedToken>,
    pub token_program: Program<'info, Token>,
    pub system_program: Program<'info, System>,
}
