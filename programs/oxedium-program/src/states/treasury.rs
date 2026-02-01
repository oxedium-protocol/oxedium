use anchor_lang::prelude::*;

#[account]
pub struct Treasury {
    pub stoptap: bool,
    pub admin: Pubkey,
    pub fee_bps: u64,
    pub deviation: u64
}