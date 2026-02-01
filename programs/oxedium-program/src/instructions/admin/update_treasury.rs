use crate::{components::check_admin, states::Treasury, utils::{TREASURY_SEED, OXEDIUM_SEED}};
use anchor_lang::prelude::*;

/// Update treasury settings: admin, stop-tap flag, and protocol fee
///
/// # Arguments
/// * `ctx` - context containing all accounts required for this instruction
/// * `stoptap` - boolean flag to pause or resume treasury operations
/// * `protocol_fee_bps` - protocol fee in basis points (bps), taken from total swap fees
#[inline(never)]
pub fn update_treasury(
    ctx: Context<UpdateTreasuryInstructionAccounts>,
    stoptap: bool,
    protocol_fee_bps: u64,
    deviation: u64
) -> Result<()> {
    let treasury: &mut Account<'_, Treasury> = &mut ctx.accounts.treasury_pda;

    // Ensure the signer is the treasury admin
    check_admin(treasury, &ctx.accounts.signer)?;
    
    // Update the treasury fields
    treasury.admin = ctx.accounts.new_admin.key(); // set new admin
    treasury.stoptap = stoptap;                    // enable/disable operations
    treasury.fee_bps = protocol_fee_bps;     // protocol fee in bps
    treasury.deviation = deviation;

    // Log the update for transparency
    msg!("UpdateTreasury {{admin: {}, stoptap: {}, protocol_fee: {}, deviation: {}}}", 
        treasury.admin.key(), 
        treasury.stoptap, 
        treasury.fee_bps,
        treasury.deviation
    );

    Ok(())
}

/// Accounts context for `update_treasury` instruction
#[derive(Accounts)]
pub struct UpdateTreasuryInstructionAccounts<'info> {
    /// The signer of the transaction (must be current admin)
    #[account(mut)]
    pub signer: Signer<'info>,

    /// The new admin public key to assign
    /// CHECK: No constraints, assumed valid by admin
    pub new_admin: AccountInfo<'info>,

    /// The Treasury PDA account
    ///
    /// Seeds:
    /// - `OXEDIUM_SEED`
    /// - `TREASURY_SEED`
    /// `bump` is automatically derived
    #[account(mut, seeds = [OXEDIUM_SEED.as_bytes(), TREASURY_SEED.as_bytes()], bump)]
    pub treasury_pda: Account<'info, Treasury>,

    /// System program (required for account management)
    pub system_program: Program<'info, System>,
}
