use anchor_lang::prelude::*;
use anchor_spl::token::{self, Mint, Token, TokenAccount, Transfer};

use crate::{components::check_admin, states::{Treasury, Vault}, utils::{TREASURY_SEED, OXEDIUM_SEED, VAULT_SEED}};

/// Collect the protocol yield from a vault to the admin's token account
///
/// # Arguments
/// * `ctx` - context containing all accounts required for this instruction
pub fn collect(ctx: Context<CollectInstructionAccounts>) -> Result<()> {
    // Ensure the caller is the treasury admin
    check_admin(&ctx.accounts.treasury_pda, &ctx.accounts.signer)?;

    let vault: &mut Account<'_, Vault> = &mut ctx.accounts.vault_pda;

    // Read the protocol yield accumulated in the vault
    let protocol_yield = vault.protocol_yield;

    // Prepare PDA seeds for signing the transfer from treasury ATA
    let seeds = &[OXEDIUM_SEED.as_bytes(), TREASURY_SEED.as_bytes(), &[ctx.bumps.treasury_pda]];
    let signer_seeds = &[&seeds[..]]; // wrapped as slice for CPI

    // Define the token transfer instruction
    let cpi_accounts = Transfer {
        from: ctx.accounts.treasury_ata.to_account_info(),   // treasury token account (source)
        to: ctx.accounts.signer_ata.to_account_info(),      // admin's token account (destination)
        authority: ctx.accounts.treasury_pda.to_account_info() // PDA authority
    };

    // Perform the transfer using CPI with PDA signer
    token::transfer(
        CpiContext::new_with_signer(
            ctx.accounts.token_program.to_account_info(),
            cpi_accounts,
            signer_seeds
        ),
        protocol_yield
    )?;

    // Reset the protocol yield in the vault after collection
    vault.protocol_yield -= protocol_yield;

    // Log the collection for transparency
    msg!("Collect {{mint: {}, amount: {}}}", vault.token_mint.key(), protocol_yield);

    Ok(())
}

/// Accounts context for the `collect` instruction
#[derive(Accounts)]
pub struct CollectInstructionAccounts<'info> {
    /// The signer of the transaction (must be admin)
    #[account(mut)]
    pub signer: Signer<'info>,

    /// The vault token mint
    /// CHECK: no constraints, assumed valid
    pub vault_mint: Account<'info, Mint>,

    /// The admin's token account for receiving protocol yield
    #[account(mut, token::authority = signer, token::mint = vault_mint)]
    pub signer_ata: Account<'info, TokenAccount>,

    /// The Vault PDA storing vault state
    #[account(mut, seeds = [VAULT_SEED.as_bytes(), vault_mint.key().as_ref()], bump)]
    pub vault_pda: Account<'info, Vault>,

    /// The Treasury PDA account controlling protocol funds
    #[account(mut, seeds = [OXEDIUM_SEED.as_bytes(), TREASURY_SEED.as_bytes()], bump)]
    pub treasury_pda: Account<'info, Treasury>,

    /// Treasury's token account holding the collected yield
    #[account(
        mut,
        associated_token::mint = vault_mint,
        associated_token::authority = treasury_pda,
    )]
    pub treasury_ata: Account<'info, TokenAccount>,

    /// Token program required to execute token transfers
    pub token_program: Program<'info, Token>,

    /// System program required for account management
    pub system_program: Program<'info, System>,
}
