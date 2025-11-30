use anchor_lang::prelude::*;

#[account]
pub struct Staker {
    pub owner: Pubkey,
    pub vault: Pubkey,
    pub last_cumulative_yield: u128,
    pub pending_claim: u64
}