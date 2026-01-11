#![allow(unexpected_cfgs)]

use anchor_lang::prelude::*;

use instructions::admin::*;
use instructions::staker::*;
use instructions::trader::*;

pub mod states;
pub mod instructions;
pub mod components;
pub mod utils;
pub mod events;


declare_id!("oxe1SKL52HMLBDT2JQvdxscA1LbVc4EEwwSdNZcnDVH");

#[program]
pub mod oxedium_program {
    use super::*;

    pub fn init_treasury(ctx: Context<InitTreasuryInstructionAccounts>, proto_fee: u64) -> Result<()> {
        instructions::admin::init_treasury(ctx, proto_fee)
    }

    pub fn update_treasury(ctx: Context<UpdateTreasuryInstructionAccounts>, stoptap: bool, proto_fee: u64) -> Result<()> {
        instructions::admin::update_treasury(ctx, stoptap, proto_fee)
    }

    pub fn init_vault(ctx: Context<InitVaultInstructionAccounts>, is_active: bool, base_fee: u64, max_age_price: u64, max_liquidity: u64) -> Result<()> {
        instructions::admin::init_vault(ctx, is_active, base_fee, max_age_price, max_liquidity)
    }

    pub fn update_vault(ctx: Context<UpdateVaultInstructionAccounts>, is_active: bool, base_fee: u64, max_age_price: u64, max_liquidity: u64) -> Result<()> {
        instructions::admin::update_vault(ctx, is_active, base_fee, max_age_price, max_liquidity)
    }

    pub fn collect(ctx: Context<CollectInstructionAccounts>) -> Result<()> {
        instructions::admin::collect(ctx)
    }

    // Staker instructions
    pub fn staking(ctx: Context<StakingInstructionAccounts>, amount: u64) -> Result<()> {
        instructions::staker::staking(ctx, amount)
    }

    pub fn unstaking(ctx: Context<UnstakingInstructionAccounts>, amount: u64) -> Result<()> {
        instructions::staker::unstaking(ctx, amount)
    }

    pub fn claim(ctx: Context<ClaimInstructionAccounts>) -> Result<()> {
        instructions::staker::claim(ctx)
    }

    // Trader instruction
    pub fn swap(ctx: Context<SwapInstructionAccounts>, amount_in: u64, partner_fee: u64) -> Result<()> {
        instructions::trader::swap(ctx, amount_in, partner_fee)
    }
}
