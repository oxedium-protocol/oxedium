use anchor_lang::prelude::*;
use anchor_spl::{associated_token::AssociatedToken, token::{self, Mint, MintTo, Token, TokenAccount}};
use crate::{components::{calculate_yield, check_stoptap}, states::{Staker, Treasury, Vault}, utils::*};

#[inline(never)]
pub fn staking(ctx: Context<StakingInstructionAccounts>, amount: u64) -> Result<()> {

    check_stoptap(&ctx.accounts.vault_pda, &ctx.accounts.treasury_pda)?;

    let cumulative_yield = ctx.accounts.vault_pda.cumulative_yield_per_lp;
    let staker_lp = ctx.accounts.signer_lp_ata.amount;
    let last_cumulative_yield = ctx.accounts.staker_pda.last_cumulative_yield;

    ctx.accounts.staker_pda.owner = ctx.accounts.signer.key();
    ctx.accounts.staker_pda.vault = ctx.accounts.vault_mint.key();

    ctx.accounts.staker_pda.pending_claim += calculate_yield(cumulative_yield, staker_lp, last_cumulative_yield);
    ctx.accounts.staker_pda.last_cumulative_yield = cumulative_yield;

    let cpi_accounts = token::Transfer {
        from: ctx.accounts.signer_ata.to_account_info(),
        to: ctx.accounts.treasury_ata.to_account_info(),
        authority: ctx.accounts.signer.to_account_info(),
    };

    token::transfer(CpiContext::new(ctx.accounts.token_program.to_account_info(), cpi_accounts), amount)?;

    let seeds = &[OXEDIUM_SEED.as_bytes(), TREASURY_SEED.as_bytes(), &[ctx.bumps.treasury_pda]];
    let signer_seeds = &[&seeds[..]];

    let cpi_accounts: MintTo<'_> = MintTo {
        mint: ctx.accounts.lp_mint.to_account_info(),
        to: ctx.accounts.signer_lp_ata.to_account_info(),
        authority: ctx.accounts.treasury_pda.to_account_info(),
    };

    let cpi_ctx = CpiContext::new_with_signer(
        ctx.accounts.token_program.to_account_info(),
        cpi_accounts,
        signer_seeds,
    );
    token::mint_to(cpi_ctx, amount)?;

    ctx.accounts.vault_pda.initial_liquidity += amount;
    ctx.accounts.vault_pda.current_liquidity += amount;

    msg!("Staking {{staker: {}, mint: {}, amount: {}}}", ctx.accounts.signer.key(), ctx.accounts.vault_pda.token_mint.key(), amount);

    Ok(())
}

#[derive(Accounts)]
pub struct StakingInstructionAccounts<'info> {
    #[account(mut)]
    pub signer: Signer<'info>,

    #[account(mut)]
    pub vault_mint: Account<'info, Mint>,

    #[account(
        mut,
        seeds = [MINT_SEED.as_bytes(), vault_pda.key().as_ref()], 
        bump,
        mint::authority = treasury_pda.key(),
        mint::freeze_authority = treasury_pda.key()
    )]
    pub lp_mint: Account<'info, Mint>,

    #[account(mut, token::authority = signer, token::mint = vault_mint)]
    pub signer_ata: Account<'info, TokenAccount>,

    #[account(
        init_if_needed,
        payer = signer,
        associated_token::mint = lp_mint,
        associated_token::authority = signer,
    )]
    pub signer_lp_ata: Account<'info, TokenAccount>,

    #[account(mut, seeds = [VAULT_SEED.as_bytes(), &vault_mint.to_account_info().key.to_bytes()], bump)]
    pub vault_pda: Account<'info, Vault>,

    #[account(
        init_if_needed,
        payer = signer,
        seeds = [STAKER_SEED.as_bytes(), vault_pda.key().as_ref(), signer.key().as_ref()],
        bump,
        space = 8 + 32 + 32 + 16 + 8,
    )]
    pub staker_pda: Account<'info, Staker>,

    #[account(mut, seeds = [OXEDIUM_SEED.as_bytes(), TREASURY_SEED.as_bytes()], bump)]
    pub treasury_pda: Account<'info, Treasury>,

    #[account(
        init_if_needed,
        payer = signer,
        associated_token::mint = vault_mint,
        associated_token::authority = treasury_pda,
    )]
    pub treasury_ata: Account<'info, TokenAccount>,

    pub associated_token_program: Program<'info, AssociatedToken>,
    pub token_program: Program<'info, Token>,
    pub system_program: Program<'info, System>,
}
