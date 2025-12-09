use anchor_lang::prelude::*;

#[account]
pub struct Treasury {
    pub stoptap: bool,
    pub admin: Pubkey,
    pub proto_fee_bps: u64
}