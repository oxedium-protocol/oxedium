use anchor_lang::prelude::*;

#[event]
pub struct UnstakingEvent {
    pub user: Pubkey,
    pub mint: Pubkey,
    pub amount: u64,
    pub extra_fee_bps: u64
}