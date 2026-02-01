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


declare_id!("oxe2YhrQZ8yjbaHfp6mQXfSJd124qK2sRpdH9ePZXh1");

#[program]
pub mod oxedium_program {
    use super::*;

    pub fn init_treasury(ctx: Context<InitTreasuryInstructionAccounts>, proto_fee: u64) -> Result<()> {
        instructions::admin::init_treasury(ctx, proto_fee)
    }

    pub fn update_treasury(ctx: Context<UpdateTreasuryInstructionAccounts>, stoptap: bool, proto_fee: u64, deviation: u64) -> Result<()> {
        instructions::admin::update_treasury(ctx, stoptap, proto_fee, deviation)
    }

    pub fn init_vault(ctx: Context<InitVaultInstructionAccounts>, base_fee: u64, max_age_price: u64) -> Result<()> {
        instructions::admin::init_vault(ctx, base_fee, max_age_price)
    }

    pub fn update_vault(ctx: Context<UpdateVaultInstructionAccounts>, base_fee: u64, max_age_price: u64) -> Result<()> {
        instructions::admin::update_vault(ctx, base_fee, max_age_price)
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
    pub fn swap(ctx: Context<SwapInstructionAccounts>, amount_in: u64, minimum_out: u64) -> Result<()> {
        instructions::trader::swap(ctx, amount_in, minimum_out)
    }
}
