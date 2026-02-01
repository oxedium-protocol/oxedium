use anchor_lang::prelude::*;
use anchor_spl::{
    associated_token::AssociatedToken,
    token::{self, Mint, Token, TokenAccount},
};
use pyth_solana_receiver_sdk::price_update::PriceUpdateV2;

use crate::{
    components::{
        check_stoptap, compute_swap_math,
    },
    events::SwapEvent,
    states::{Treasury, Vault},
    utils::{OxediumError, OXEDIUM_SEED, SCALE, TREASURY_SEED, VAULT_SEED},
};

/// Swap tokens from one vault to another, optionally in quote-only mode
///
/// # Arguments
/// * `ctx` - context containing all accounts
/// * `amount_in` - amount of input tokens from user
/// * `minimum_out` - minimum amount output
pub fn swap(
    ctx: Context<SwapInstructionAccounts>,
    amount_in: u64,
    minimum_out: u64,
) -> Result<()> {
    let treasury: Account<'_, Treasury> = ctx.accounts.treasury_pda.clone();
    let vault_in: &mut Account<'_, Vault> = &mut ctx.accounts.vault_pda_in;
    let vault_out: &mut Account<'_, Vault> = &mut ctx.accounts.vault_pda_out;

    check_stoptap(&treasury)?;

    // === 2. Validate Pyth price accounts ===
    if ctx.accounts.pyth_price_account_in.key() != vault_in.pyth_price_account {
        return Err(OxediumError::InvalidPythAccount.into());
    }
    if ctx.accounts.pyth_price_account_out.key() != vault_out.pyth_price_account {
        return Err(OxediumError::InvalidPythAccount.into());
    }

    // === 3. Read prices from Pyth ===
    let oracle_in: Account<'_, PriceUpdateV2>  = ctx.accounts.pyth_price_account_in.clone();
    let oracle_out: Account<'_, PriceUpdateV2>  = ctx.accounts.pyth_price_account_out.clone();

    // === 4. Check price feed freshness ===
    let clock: Clock = Clock::get()?;
    let current_timestamp: i64 = clock.unix_timestamp;

    let max_age_vault_in = current_timestamp
        - ctx
            .accounts
            .pyth_price_account_in
            .price_message
            .publish_time;
    let max_age_vault_out = current_timestamp
        - ctx
            .accounts
            .pyth_price_account_out
            .price_message
            .publish_time;

    if max_age_vault_in > vault_in.max_age_price as i64 {
        msg!("Vault In: Price feed stale by {} seconds", max_age_vault_in);
        return Err(OxediumError::OracleDataTooOld.into());
    }
    if max_age_vault_out > vault_out.max_age_price as i64 {
        msg!(
            "Vault Out: Price feed stale by {} seconds",
            max_age_vault_out
        );
        return Err(OxediumError::OracleDataTooOld.into());
    }

    // === 5. Compute swap math ===
    let result = compute_swap_math(
        amount_in,
        oracle_in.price_message,
        oracle_out.price_message,
        ctx.accounts.mint_in.decimals,
        ctx.accounts.mint_out.decimals,
        vault_in,
        vault_out,
        &treasury,
    )?;

    if result.net_amount_out < minimum_out {
        return Err(OxediumError::HighSlippage.into());
    }

    // === 6. Update vaults and yields ===
    vault_in.current_liquidity += amount_in;
    vault_out.current_liquidity -= result.raw_amount_out;
    vault_out.cumulative_yield_per_lp += (result.lp_fee_amount as u128 * SCALE) / vault_out.initial_liquidity as u128;
    vault_out.protocol_yield += result.protocol_fee_amount;

    // === 7. Transfer input tokens from user to treasury ===
    let cpi_accounts: token::Transfer<'_> = token::Transfer {
        from: ctx.accounts.signer_ata_in.to_account_info(),
        to: ctx.accounts.treasury_ata_in.to_account_info(),
        authority: ctx.accounts.signer.to_account_info(),
    };
    token::transfer(
        CpiContext::new(ctx.accounts.token_program.to_account_info(), cpi_accounts),
        amount_in,
    )?;

    // === 8. Transfer output tokens from treasury to user ===
    let seeds: &[&[u8]; 3] = &[
        OXEDIUM_SEED.as_bytes(),
        TREASURY_SEED.as_bytes(),
        &[ctx.bumps.treasury_pda],
    ];
    let signer_seeds: &[&[&[u8]]; 1] = &[&seeds[..]];

    let cpi_accounts_out: token::Transfer<'_> = token::Transfer {
        from: ctx.accounts.treasury_ata_out.to_account_info(),
        to: ctx.accounts.signer_ata_out.to_account_info(),
        authority: ctx.accounts.treasury_pda.to_account_info(),
    };
    token::transfer(
        CpiContext::new_with_signer(
            ctx.accounts.token_program.to_account_info(),
            cpi_accounts_out,
            signer_seeds,
        ),
        result.net_amount_out,
    )?;

    // === 9. Emit swap event for off-chain indexing ===
    emit!(SwapEvent {
        user: ctx.accounts.signer.key(),
        fee_bps: result.swap_fee_bps + treasury.fee_bps,
        token_in: vault_in.token_mint,
        token_out: vault_out.token_mint,
        amount_in: amount_in,
        amount_out: result.net_amount_out,
        price_in: oracle_in.price_message.price,
        price_out: oracle_out.price_message.price,
        lp_fee: result.lp_fee_amount,
        protocol_fee: result.protocol_fee_amount
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

    pub pyth_price_account_in: Account<'info, PriceUpdateV2>, // Pyth price feed for input token
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

    pub associated_token_program: Program<'info, AssociatedToken>,
    pub token_program: Program<'info, Token>,
    pub system_program: Program<'info, System>,
}
