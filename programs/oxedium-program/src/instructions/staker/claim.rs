use anchor_lang::prelude::*;
use anchor_spl::token::{self, Mint, Token, TokenAccount, Transfer};

use crate::{components::{calculate_staker_yield, check_stoptap}, events::ClaimEvent, states::{Staker, Treasury, Vault}, utils::{MINT_SEED, OXEDIUM_SEED, STAKER_SEED, TREASURY_SEED, VAULT_SEED}};

/// Claim accumulated yield for a staker from a vault
///
/// # Arguments
/// * `ctx` - context containing all accounts required for claiming
pub fn claim(ctx: Context<ClaimInstructionAccounts>) -> Result<()> {
    let vault: &mut Account<'_, Vault> = &mut ctx.accounts.vault_pda;
    let staker: &mut Account<'_, Staker> = &mut ctx.accounts.staker_pda;

    // Check if vault is active and stop-tap is not enabled
    check_stoptap(vault, &ctx.accounts.treasury_pda)?;

    // Get cumulative yield per LP token from the vault
    let cumulative_yield_per_lp: u128 = vault.cumulative_yield_per_lp;
    // Get the staker's LP token balance
    let staker_lp: u64 = ctx.accounts.signer_lp_ata.amount;
    // Get the last cumulative yield recorded for the staker
    let staker_last_cumulative_yield: u128 = staker.last_cumulative_yield;
    // Get the pending claim for the staker
    let staker_pending_claim: u64 = staker.pending_claim;

    // Calculate total yield: new yield + pending claim
    let staker_yield: u64 = calculate_staker_yield(cumulative_yield_per_lp, staker_lp, staker_last_cumulative_yield);
    let amount: u64 = staker_yield + staker_pending_claim;

    // PDA seeds for signing transfer from treasury
    let seeds = &[OXEDIUM_SEED.as_bytes(), TREASURY_SEED.as_bytes(), &[ctx.bumps.treasury_pda]];
    let signer_seeds = &[&seeds[..]];

    // Define CPI transfer from treasury to staker
    let cpi_accounts = Transfer {
        from: ctx.accounts.treasury_ata.to_account_info(),
        to: ctx.accounts.signer_ata.to_account_info(), 
        authority: ctx.accounts.treasury_pda.to_account_info()
    };

    // Execute the transfer using PDA signer
    token::transfer(
        CpiContext::new_with_signer(
            ctx.accounts.token_program.to_account_info(), 
            cpi_accounts, 
            signer_seeds), 
        amount)?;

    // Update staker PDA state
    staker.last_cumulative_yield = cumulative_yield_per_lp;
    staker.pending_claim = 0;
    vault.current_liquidity -= amount;
    
    emit!(ClaimEvent {
        user: ctx.accounts.signer.key(),
        mint: vault.token_mint.key(),
        amount: amount
    });

    Ok(())
}

/// Accounts context for the claim instruction
#[derive(Accounts)]
pub struct ClaimInstructionAccounts<'info> {
    #[account(mut)]
    pub signer: Signer<'info>, // staker claiming rewards

    /// Vault token mint
    /// CHECK: no constraints
    pub vault_mint: Account<'info, Mint>,

    /// LP token mint controlled by treasury
    #[account(
        mut,
        seeds = [MINT_SEED.as_bytes(), vault_pda.key().as_ref()], 
        bump,
        mint::authority = treasury_pda.key(),
        mint::freeze_authority = treasury_pda.key()
    )]
    pub lp_mint: Account<'info, Mint>,

    /// Staker's LP token account
    #[account(
        mut,
        associated_token::mint = lp_mint,
        associated_token::authority = signer,
    )]
    pub signer_lp_ata: Account<'info, TokenAccount>,

    /// Staker's vault token account to receive claimed yield
    #[account(mut, token::authority = signer, token::mint = vault_mint)]
    pub signer_ata: Account<'info, TokenAccount>,

    /// Staker PDA storing last yield and pending claim
    #[account(mut, seeds = [STAKER_SEED.as_bytes(), vault_pda.key().as_ref(), signer.key().as_ref()], bump)]
    pub staker_pda: Account<'info, Staker>,

    /// Vault PDA storing cumulative yield and liquidity
    #[account(mut, seeds = [VAULT_SEED.as_bytes(), vault_mint.key().as_ref()], bump)]
    pub vault_pda: Account<'info, Vault>,

    /// Treasury PDA used to sign yield transfer
    #[account(mut, seeds = [OXEDIUM_SEED.as_bytes(), TREASURY_SEED.as_bytes()], bump)]
    pub treasury_pda: Account<'info, Treasury>,

    /// Treasury token account holding protocol/staker funds
    #[account(
        mut,
        associated_token::mint = vault_mint,
        associated_token::authority = treasury_pda,
    )]
    pub treasury_ata: Account<'info, TokenAccount>,

    pub token_program: Program<'info, Token>,
    pub system_program: Program<'info, System>,
}
