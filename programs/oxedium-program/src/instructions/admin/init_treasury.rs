use crate::{states::Treasury, utils::{TREASURY_SEED, OXEDIUM_SEED, OxediumError}};
use anchor_lang::prelude::*;
use std::str::FromStr;

/// Initialize the Treasury account (PDA)
///
/// # Arguments
/// * `ctx` - context containing all accounts required for this instruction
/// * `protocol_fee_bps` - protocol fee in basis points (bps), taken from the total swap fee
pub fn init_treasury(
    ctx: Context<InitTreasuryInstructionAccounts>,
    protocol_fee_bps: u64
) -> Result<()> {
    // Define the admin public key (hardcoded)
    // For production, it is safer to store this in a config PDA
    let admin_key = Pubkey::from_str("3gXnk9LTHHtFzKK5pkKzp58okeo9V72MjGSyzFUCvKk2")
        .map_err(|_| OxediumError::InvalidAdmin)?; // ensure the key is valid

    // Check if the signer is the admin
    if ctx.accounts.signer.key() != admin_key {
        return Err(OxediumError::InvalidAdmin.into());
    }

    // Get a mutable reference to the treasury PDA
    let treasury: &mut Account<'_, Treasury> = &mut ctx.accounts.treasury_pda;

    // Set the treasury fields
    treasury.admin = ctx.accounts.signer.key();  // admin public key
    treasury.stoptap = false;                     // stop-tap flag, default false
    treasury.fee_bps = protocol_fee_bps;     // protocol fee in basis points

    Ok(())
}

/// Accounts context for the `init_treasury` instruction
#[derive(Accounts)]
pub struct InitTreasuryInstructionAccounts<'info> {
    /// The signer of the transaction
    #[account(mut)]
    pub signer: Signer<'info>,

    /// The Treasury PDA account
    ///
    /// This account will be created and initialized when this instruction is called.
    /// Seeds:
    /// - `OXEDIUM_SEED` (for uniqueness)
    /// - `TREASURY_SEED` (for uniqueness)
    /// `bump` is automatically calculated by Anchor
    /// `space` is the total account size (8 + 1 + 32 + 8 = 41 bytes):
    /// - 8 bytes: Anchor account discriminator
    /// - 1 byte: bool `stoptap`
    /// - 32 bytes: `admin` Pubkey
    /// - 8 bytes: `proto_fee_bps` u64 — protocol fee in basis points, taken from the total swap fee
    #[account(
        init,
        payer = signer,
        seeds = [OXEDIUM_SEED.as_bytes(), TREASURY_SEED.as_bytes()],
        bump,
        space = 8 + 1 + 32 + 8,
    )]
    pub treasury_pda: Account<'info, Treasury>,

    /// System program (required to create accounts/PDA)
    pub system_program: Program<'info, System>,
}
