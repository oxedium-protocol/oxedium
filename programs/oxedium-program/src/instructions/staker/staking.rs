use anchor_lang::prelude::*;
use anchor_spl::{associated_token::AssociatedToken, token::{self, Mint, MintTo, Token, TokenAccount}};
use crate::{components::{calculate_staker_yield, check_stoptap}, events::StakingEvent, states::{Staker, Treasury, Vault}, utils::*};

/// Stake a given amount of vault tokens and mint LP tokens to the staker
///
/// # Arguments
/// * `ctx` - context containing all accounts for staking
/// * `amount` - amount of vault tokens to stake
#[inline(never)]
pub fn staking(ctx: Context<StakingInstructionAccounts>, amount: u64) -> Result<()> {
    let vault: &mut Account<'_, Vault> = &mut ctx.accounts.vault_pda;
    let staker: &mut Account<'_, Staker> = &mut ctx.accounts.staker_pda;
    let signer_lp_ata: Account<'_, TokenAccount> = ctx.accounts.signer_lp_ata.clone();

    // Check if the vault is active and stop-tap is not enabled
    check_stoptap(vault, &ctx.accounts.treasury_pda)?;

    // Get the cumulative yield per LP token from the vault
    let cumulative_yield: u128 = vault.cumulative_yield_per_lp;
    // Get the staker's current LP token balance
    let staker_lp: u64 = signer_lp_ata.amount;
    // Get the last recorded cumulative yield for the staker
    let last_cumulative_yield: u128 = staker.last_cumulative_yield;

    // Transfer the staked vault tokens from signer to treasury
    let cpi_accounts = token::Transfer {
        from: ctx.accounts.signer_ata.to_account_info(),
        to: ctx.accounts.treasury_ata.to_account_info(),
        authority: ctx.accounts.signer.to_account_info(),
    };

    token::transfer(CpiContext::new(ctx.accounts.token_program.to_account_info(), cpi_accounts), amount)?;

    // Prepare PDA seeds for signing the LP mint CPI
    let seeds = &[OXEDIUM_SEED.as_bytes(), TREASURY_SEED.as_bytes(), &[ctx.bumps.treasury_pda]];
    let signer_seeds = &[&seeds[..]];

    // Mint LP tokens to the staker corresponding to the staked amount
    let cpi_accounts: MintTo<'_> = MintTo {
        mint: ctx.accounts.lp_mint.to_account_info(),
        to: signer_lp_ata.to_account_info(),
        authority: ctx.accounts.treasury_pda.to_account_info(),
    };

    let cpi_ctx = CpiContext::new_with_signer(
        ctx.accounts.token_program.to_account_info(),
        cpi_accounts,
        signer_seeds,
    );
    token::mint_to(cpi_ctx, amount)?;

    // Set staker PDA owner and vault
    staker.owner = ctx.accounts.signer.key();
    staker.vault = ctx.accounts.vault_mint.key();

    // Calculate pending yield for staker and update
    staker.pending_claim += calculate_staker_yield(cumulative_yield, staker_lp, last_cumulative_yield);
    staker.last_cumulative_yield = cumulative_yield;

    // Update vault liquidity accounting
    vault.initial_liquidity += amount;
    vault.current_liquidity += amount;

    emit!(StakingEvent {
        user: ctx.accounts.signer.key(),
        mint: vault.token_mint.key(),
        amount: amount
    });

    Ok(())
}

/// Accounts context for the staking instruction
#[derive(Accounts)]
pub struct StakingInstructionAccounts<'info> {
    #[account(mut)]
    pub signer: Signer<'info>, // the user staking tokens

    #[account(mut)]
    pub vault_mint: Account<'info, Mint>, // vault token mint

    #[account(
        mut,
        seeds = [MINT_SEED.as_bytes(), vault_pda.key().as_ref()], 
        bump,
        mint::authority = treasury_pda.key(),
        mint::freeze_authority = treasury_pda.key()
    )]
    pub lp_mint: Account<'info, Mint>, // LP token mint controlled by treasury

    #[account(mut, token::authority = signer, token::mint = vault_mint)]
    pub signer_ata: Account<'info, TokenAccount>, // user token account for vault token

    #[account(
        init_if_needed,
        payer = signer,
        associated_token::mint = lp_mint,
        associated_token::authority = signer,
    )]
    pub signer_lp_ata: Account<'info, TokenAccount>, // LP token account for staker

    #[account(mut, seeds = [VAULT_SEED.as_bytes(), &vault_mint.to_account_info().key.to_bytes()], bump)]
    pub vault_pda: Account<'info, Vault>, // vault PDA storing liquidity and yield info

    #[account(
        init_if_needed,
        payer = signer,
        seeds = [STAKER_SEED.as_bytes(), vault_pda.key().as_ref(), signer.key().as_ref()],
        bump,
        space = 8 + 32 + 32 + 16 + 8,
    )]
    pub staker_pda: Account<'info, Staker>, // staker PDA storing pending rewards and last yield

    #[account(mut, seeds = [OXEDIUM_SEED.as_bytes(), TREASURY_SEED.as_bytes()], bump)]
    pub treasury_pda: Account<'info, Treasury>, // treasury PDA controlling LP mint

    #[account(
        init_if_needed,
        payer = signer,
        associated_token::mint = vault_mint,
        associated_token::authority = treasury_pda,
    )]
    pub treasury_ata: Account<'info, TokenAccount>, // treasury token account holding staked vault tokens

    pub associated_token_program: Program<'info, AssociatedToken>,
    pub token_program: Program<'info, Token>,
    pub system_program: Program<'info, System>,
}
