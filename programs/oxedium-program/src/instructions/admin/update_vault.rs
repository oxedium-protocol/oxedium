use crate::{components::check_admin, states::{Treasury, Vault}, utils::{OXEDIUM_SEED, TREASURY_SEED, VAULT_SEED}};
use anchor_lang::prelude::*;
use anchor_spl::token::Mint;
use pyth_solana_receiver_sdk::price_update::PriceUpdateV2;

/// Update vault parameters: activity status, base fee, and price feed settings
///
/// # Arguments
/// * `ctx` - context containing all accounts required for this instruction
/// * `base_fee` - base fee for swaps involving this vault
/// * `max_age_price` - maximum allowed age for the Pyth price feed (in seconds)
pub fn update_vault(
    ctx: Context<UpdateVaultInstructionAccounts>,
    base_fee: u64,
    max_age_price: u64,
) -> Result<()> {
    let treasury: Account<'_, Treasury> = ctx.accounts.treasury_pda.clone();
    let vault: &mut Account<'_, Vault> = &mut ctx.accounts.vault_pda;

    // Ensure the caller is an admin using the Treasury account
    check_admin(&treasury, &ctx.accounts.signer)?;

    // Update vault fields
    vault.base_fee = base_fee;                       // set the base fee for the vault
    vault.pyth_price_account = ctx.accounts.pyth_price_account.key(); // update Pyth price feed
    vault.max_age_price = max_age_price;             // max allowed age of price feed

    // Log the update for transparency
    msg!("UpdateVault {{mint: {}, base_fee: {}, max_age_price: {}}}", 
        vault.token_mint.key(), 
        vault.base_fee,
        vault.max_age_price
    );

    Ok(())
}

/// Accounts context for the `update_vault` instruction
#[derive(Accounts)]
pub struct UpdateVaultInstructionAccounts<'info> {
    /// The signer of the transaction (must be the admin)
    #[account(mut)]
    pub signer: Signer<'info>,

    /// The vault token mint
    /// CHECK: no additional constraints, assumed valid
    pub vault_mint: Account<'info, Mint>,

    /// The Pyth price feed account for the vault token
    pub pyth_price_account: Account<'info, PriceUpdateV2>,

    /// The Vault PDA account
    ///
    /// Seeds:
    /// - `VAULT_SEED`
    /// - vault_mint key
    /// `bump` is automatically derived
    #[account(mut, seeds = [VAULT_SEED.as_bytes(), vault_mint.key().as_ref()], bump)]
    pub vault_pda: Account<'info, Vault>,

    /// The Treasury PDA account used for admin checks
    ///
    /// Seeds:
    /// - `OXEDIUM_SEED`
    /// - `TREASURY_SEED`
    /// `bump` is automatically derived
    #[account(mut, seeds = [OXEDIUM_SEED.as_bytes(), TREASURY_SEED.as_bytes()], bump)]
    pub treasury_pda: Account<'info, Treasury>,
    
    /// System program required for account management
    pub system_program: Program<'info, System>,
}
