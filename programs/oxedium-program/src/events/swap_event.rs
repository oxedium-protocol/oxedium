use anchor_lang::prelude::*;

#[event]
pub struct SwapEvent {
    pub user: Pubkey,
    pub fee_bps: u64,
    pub token_in: Pubkey,
    pub token_out: Pubkey,
    pub amount_in: u64,
    pub amount_out: u64,
    pub price_in: u64,
    pub price_out: u64,
    pub lp_fee: u64,
    pub protocol_fee: u64
}