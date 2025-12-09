use anchor_lang::prelude::*;
use anchor_spl::token::{self, Mint, Token, TokenAccount, Transfer};

use crate::{components::{calculate_staker_yield, check_stoptap}, states::{Staker, Treasury, Vault}, utils::{MINT_SEED, STAKER_SEED, TREASURY_SEED, OXEDIUM_SEED, VAULT_SEED}};


pub fn claim(ctx: Context<ClaimInstructionAccounts>) -> Result<()> {
    check_stoptap(&ctx.accounts.vault_pda, &ctx.accounts.treasury_pda)?;

    let cumulative_yield_per_lp = ctx.accounts.vault_pda.cumulative_yield_per_lp;
    let staker_lp = ctx.accounts.signer_lp_ata.amount;
    let staker_last_cumulative_yield = ctx.accounts.staker_pda.last_cumulative_yield;
    let staker_pending_claim = ctx.accounts.staker_pda.pending_claim;

    let staker_yield = calculate_staker_yield(cumulative_yield_per_lp, staker_lp, staker_last_cumulative_yield);
    let amount = staker_yield + staker_pending_claim;

    let seeds = &[OXEDIUM_SEED.as_bytes(), TREASURY_SEED.as_bytes(), &[ctx.bumps.treasury_pda]];
    let signer_seeds = &[&seeds[..]];

    let cpi_accounts = Transfer {
        from: ctx.accounts.treasury_ata.to_account_info(),
        to: ctx.accounts.signer_ata.to_account_info(), 
        authority: ctx.accounts.treasury_pda.to_account_info()
    };

    token::transfer(
        CpiContext::new_with_signer(
            ctx.accounts.token_program.to_account_info(), 
            cpi_accounts, 
            signer_seeds), 
        amount)?;

    ctx.accounts.staker_pda.last_cumulative_yield = cumulative_yield_per_lp;
    ctx.accounts.staker_pda.pending_claim = 0;
    
    msg!("Claim {{staker: {}, mint: {}, amount: {}}}", ctx.accounts.signer.key(), ctx.accounts.vault_pda.token_mint.key(), amount);

    Ok(())
}

#[derive(Accounts)]
pub struct ClaimInstructionAccounts<'info> {
    #[account(mut)]
    pub signer: Signer<'info>,

    /// CHECK:
    pub vault_mint: Account<'info, Mint>,

    #[account(
        mut,
        seeds = [MINT_SEED.as_bytes(), vault_pda.key().as_ref()], 
        bump,
        mint::authority = treasury_pda.key(),
        mint::freeze_authority = treasury_pda.key()
    )]
    pub lp_mint: Account<'info, Mint>,

    #[account(
        mut,
        associated_token::mint = lp_mint,
        associated_token::authority = signer,
    )]
    pub signer_lp_ata: Account<'info, TokenAccount>,

    #[account(mut, token::authority = signer, token::mint = vault_mint)]
    pub signer_ata: Account<'info, TokenAccount>,

    #[account(mut, seeds = [STAKER_SEED.as_bytes(), vault_pda.key().as_ref(), signer.key().as_ref()], bump)]
    pub staker_pda: Account<'info, Staker>,

    #[account(mut, seeds = [VAULT_SEED.as_bytes(), vault_mint.key().as_ref()], bump)]
    pub vault_pda: Account<'info, Vault>,

    #[account(mut, seeds = [OXEDIUM_SEED.as_bytes(), TREASURY_SEED.as_bytes()], bump)]
    pub treasury_pda: Account<'info, Treasury>,

    #[account(
        mut,
        associated_token::mint = vault_mint,
        associated_token::authority = treasury_pda,
    )]
    pub treasury_ata: Account<'info, TokenAccount>,

    pub token_program: Program<'info, Token>,
    pub system_program: Program<'info, System>,
}
