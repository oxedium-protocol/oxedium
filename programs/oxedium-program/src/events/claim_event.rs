use anchor_lang::prelude::*;

#[event]
pub struct ClaimEvent {
    pub user: Pubkey,
    pub mint: Pubkey,
    pub amount: u64
}