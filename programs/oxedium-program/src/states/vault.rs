use anchor_lang::prelude::*;

#[account]
pub struct Vault {
    pub create_at_ts: i64,
    pub is_active: bool,
    pub base_fee: u64,
    pub token_mint: Pubkey,

    pub pyth_price_account: Pubkey,
    pub max_age_price: u64,

    pub lp_mint: Pubkey,
    pub initial_liquidity: u64,
    pub current_liquidity: u64,
    
    pub cumulative_yield_per_lp: u128,
    pub protocol_yield: u64
}