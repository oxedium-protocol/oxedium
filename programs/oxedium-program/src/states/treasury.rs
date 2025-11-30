use anchor_lang::prelude::*;

#[account]
pub struct Treasury {
    pub stoptap: bool,
    pub admin: Pubkey,
    pub proto_fee: u64
}