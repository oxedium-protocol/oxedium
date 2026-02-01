use crate::{components::check_admin, states::{Vault, Treasury}, utils::*};
use anchor_lang::prelude::*;
use anchor_spl::token::{Mint, Token};
use pyth_solana_receiver_sdk::price_update::PriceUpdateV2;

/// Initialize a new Vault (PDA) and associated LP token mint
///
/// # Arguments
/// * `ctx` - context containing all accounts required for this instruction
/// * `is_active` - whether the vault is active
/// * `base_fee` - base fee for swaps involving this vault
/// * `max_age_price` - maximum allowed age for the Pyth price feed in seconds
pub fn init_vault(
    ctx: Context<InitVaultInstructionAccounts>,
    is_active: bool,
    base_fee: u64,
    max_age_price: u64,
) -> Result<()> {
    // Ensure the caller is an admin using the Treasury account
    check_admin(&ctx.accounts.treasury_pda, &ctx.accounts.signer)?;

    // Get the current UNIX timestamp
    let clock = Clock::get()?;
    let current_timestamp = clock.unix_timestamp;

    // Initialize the Vault PDA
    let vault: &mut Account<'_, Vault> = &mut ctx.accounts.vault_pda;
    
    vault.create_at_ts = current_timestamp;                  // timestamp of vault creation
    vault.is_active = is_active;                             // whether the vault is active
    vault.base_fee = base_fee;                               // base fee for swaps
    vault.token_mint = ctx.accounts.vault_mint.key();        // token associated with the vault
    vault.pyth_price_account = ctx.accounts.pyth_price_account.key(); // Pyth price feed account
    vault.max_age_price = max_age_price;                     // max age for Pyth price feed in seconds
    vault.lp_mint = ctx.accounts.lp_mint.key();              // LP token mint for liquidity providers
    vault.initial_liquidity = 0;                             // initial liquidity in the vault
    vault.current_liquidity = 0;                             // current liquidity in the vault
    vault.cumulative_yield_per_lp = 0;                       // cumulative yield per LP token
    vault.protocol_yield = 0;                                // yield earned by the protocol

    Ok(())
}

/// Accounts context for the `init_vault` instruction
#[derive(Accounts)]
pub struct InitVaultInstructionAccounts<'info> {
    /// The signer of the transaction (must be admin)
    #[account(mut)]
    pub signer: Signer<'info>,

    /// The token mint for the vault asset
    /// CHECK: no constraints on this account (assumed valid)
    pub vault_mint: Account<'info, Mint>,

    /// The Pyth price feed account
    pub pyth_price_account: Account<'info, PriceUpdateV2>,

    /// The LP token mint for liquidity providers
    ///
    /// This mint is created when initializing the vault.
    /// The Treasury PDA is set as both the mint authority and freeze authority.
    #[account(
        init,
        payer = signer,
        seeds = [MINT_SEED.as_bytes(), vault_pda.key().as_ref()], 
        bump,
        mint::decimals = vault_mint.decimals,
        mint::authority = treasury_pda.key(),
        mint::freeze_authority = treasury_pda.key()
    )]
    pub lp_mint: Account<'info, Mint>,

    /// The Vault PDA account
    ///
    /// This account stores all vault data and is initialized here.
    /// Seeds:
    /// - `VAULT_SEED`
    /// - `vault_mint` key
    /// Space:
    /// - 8 bytes: Anchor discriminator
    /// - 8 bytes: create_at_ts (timestamp)
    /// - 1 byte: is_active (bool)
    /// - 32 bytes: token_mint
    /// - 32 bytes: pyth_price_account
    /// - 8 bytes: max_age_price
    /// - 32 bytes: lp_mint
    /// - 8 bytes: initial_liquidity
    /// - 8 bytes: current_liquidity
    /// - 8 bytes: max_liquidity
    /// - 16 bytes: cumulative_yield_per_lp
    /// - 8 bytes: protocol_yield
    #[account(
        init,
        payer = signer,
        seeds = [VAULT_SEED.as_bytes(), vault_mint.key().as_ref()],
        bump,
        space = 8 + 8 + 1 + 8 + 32 + 32 + 8 + 32 + 8 + 8 + 8 + 16 + 8,
    )]
    pub vault_pda: Account<'info, Vault>,

    /// The Treasury PDA account
    ///
    /// Must be mutable and is used for admin checks and LP mint authority
    #[account(mut, seeds = [OXEDIUM_SEED.as_bytes(), TREASURY_SEED.as_bytes()], bump)]
    pub treasury_pda: Account<'info, Treasury>,

    /// Token program required to manage mint accounts
    pub token_program: Program<'info, Token>,

    /// System program required to create accounts
    pub system_program: Program<'info, System>,
}
