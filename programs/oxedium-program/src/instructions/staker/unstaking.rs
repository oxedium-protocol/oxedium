use anchor_lang::prelude::*;
use anchor_spl::{associated_token::AssociatedToken, token::{self, burn, Burn, Mint, Token, TokenAccount, Transfer}};
use crate::{components::{calculate_fee_amount, calculate_staker_yield, check_stoptap}, states::{Staker, Treasury, Vault}, utils::*};

#[inline(never)]
pub fn unstaking(ctx: Context<UnstakingInstructionAccounts>, amount: u64) -> Result<()> {

    check_stoptap(&ctx.accounts.vault_pda, &ctx.accounts.treasury_pda)?;

    let vault = &mut ctx.accounts.vault_pda;

    let cumulative_yield: u128 = vault.cumulative_yield_per_lp;
    let staker_lp: u64 = ctx.accounts.signer_lp_ata.amount;
    let last_cumulative_yield: u128 = ctx.accounts.staker_pda.last_cumulative_yield;

    // Update pending yield for the staker
    ctx.accounts.staker_pda.pending_claim += calculate_staker_yield(cumulative_yield, staker_lp, last_cumulative_yield);
    ctx.accounts.staker_pda.last_cumulative_yield = cumulative_yield;

    // --- Dynamic Fee Logic ---
    let mut unstake_amount = amount;
    let liquidity_ratio = (vault.current_liquidity as u128 * 100) / vault.initial_liquidity as u128; // in %
    let mut extra_fee_bps: u64 = 0;

    // Apply extra fee if current liquidity < 50%
    if liquidity_ratio < 50 {
        extra_fee_bps = 200; // 2% extra fee if liquidity too low
    }

    if extra_fee_bps > 0 {
        unstake_amount -= calculate_fee_amount(unstake_amount, extra_fee_bps, 0, 0)?.0;
    }

    // Burn LP tokens
    let cpi_accounts = Burn {
        mint: ctx.accounts.lp_mint.to_account_info(),
        from: ctx.accounts.signer_lp_ata.to_account_info(),
        authority: ctx.accounts.signer.to_account_info(),
    };
    let cpi_ctx = CpiContext::new(
        ctx.accounts.token_program.to_account_info(),
        cpi_accounts,
    );
    burn(cpi_ctx, amount)?;

    // Transfer unstake amount from treasury to staker
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
        unstake_amount)?;

    // Update vault liquidity
    vault.initial_liquidity -= amount;
    vault.current_liquidity -= unstake_amount;

    msg!("Unstaking {{staker: {}, mint: {}, amount: {}, extra_fee_bps: {}}}", ctx.accounts.signer.key(), vault.token_mint.key(), unstake_amount, extra_fee_bps);

    Ok(())
}

#[derive(Accounts)]
pub struct UnstakingInstructionAccounts<'info> {
    #[account(mut)]
    pub signer: Signer<'info>,

    #[account(mut)]
    pub token_mint: Account<'info, Mint>,

    #[account(
        mut,
        seeds = [MINT_SEED.as_bytes(), vault_pda.key().as_ref()], 
        bump,
        mint::authority = treasury_pda.key(),
        mint::freeze_authority = treasury_pda.key()
    )]
    pub lp_mint: Account<'info, Mint>,

    #[account(mut, token::authority = signer, token::mint = token_mint)]
    pub signer_ata: Account<'info, TokenAccount>,

    #[account(mut, token::authority = signer, token::mint = lp_mint)]
    pub signer_lp_ata: Account<'info, TokenAccount>,

    #[account(mut, seeds = [VAULT_SEED.as_bytes(), &token_mint.to_account_info().key.to_bytes()], bump)]
    pub vault_pda: Account<'info, Vault>,

    #[account(mut, seeds = [STAKER_SEED.as_bytes(), vault_pda.key().as_ref(), signer.key().as_ref()], bump)]
    pub staker_pda: Account<'info, Staker>,

    #[account(mut, seeds = [OXEDIUM_SEED.as_bytes(), TREASURY_SEED.as_bytes()], bump)]
    pub treasury_pda: Account<'info, Treasury>,

    #[account(mut, token::authority = treasury_pda, token::mint = token_mint)]
    pub treasury_ata: Account<'info, TokenAccount>,

    pub associated_token_program: Program<'info, AssociatedToken>,
    pub token_program: Program<'info, Token>,
    pub system_program: Program<'info, System>,
}
