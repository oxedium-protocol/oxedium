use anchor_lang::prelude::*;

#[event]
pub struct StakingEvent {
    pub user: Pubkey,
    pub mint: Pubkey,
    pub amount: u64
}