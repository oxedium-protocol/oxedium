#[cfg(test)]
mod components {

    use anchor_lang::prelude::Pubkey;
    use oxedium_program::{components::{calculate_fee_amount, calculate_staker_yield, conf_fee_bps, fees_setting, raw_amount_out}, states::Vault, utils::SCALE};
    use pyth_solana_receiver_sdk::price_update::PriceFeedMessage;
    

#[test]
fn calculating_fee_amount() {
    let amount_out: u64 = 1000000;
    let fee = 50 * 100;
    let protocol_fee = 10;
    // Call the fee function: returns (amount after all fees, LP fee, partner fee, protocol fee)
    let (after_fee, lp_fee, protocol_fee) = calculate_fee_amount(amount_out, fee, protocol_fee).unwrap();

    // Print results for clarity
    println!("Input: {}", amount_out);
    println!("After fee: {}", after_fee);
    println!("LP fee ({}%): {}", (100 / fee) as f64, lp_fee);
    println!("Protocol fee: {}", protocol_fee);

    // Check that the sum after distributing all fees equals the original amount
    let total: u64 = after_fee + lp_fee + protocol_fee;
    assert_eq!(total, amount_out as u64, "The total after distributing fees does not equal the original amount");
}

#[test]
fn calculating_yield_per_lp() {
    let lp_fee: u128 = 39960; 
    let total_lp: u64 = 2000000000000;

    let cumulative_yield_per_lp = (lp_fee as u128 * SCALE) / total_lp as u128;

    println!("Cum Yield Per Lp: {}", cumulative_yield_per_lp);
}

#[test]
fn calculating_yield() {
    let staker_lp_balance = 1000000000;
    let cumulative_yield_per_lp = (29219519732 as u128 * SCALE) / staker_lp_balance as u128;

    let last_cumulative_yield: u128 = 0;

    let yield_amount = calculate_staker_yield(cumulative_yield_per_lp, staker_lp_balance, last_cumulative_yield);

    println!("Yield: {}", yield_amount);
}


#[test]
fn testing_raw_amount_out() {
    let amount_in: u64 = 1000000000;
    let price_a: PriceFeedMessage = PriceFeedMessage { feed_id: [8; 32], price: 10200000000, conf: 15, exponent: 8, publish_time: 1, prev_publish_time: 1, ema_price: 1, ema_conf: 1 };
    let price_b: PriceFeedMessage = PriceFeedMessage { feed_id: [8; 32], price: 100000000, conf: 15, exponent: 8, publish_time: 1, prev_publish_time: 1, ema_price: 1, ema_conf: 1 };
    let token_a_decimals: u8 = 9;
    let token_b_decimals: u8 = 6;

    let amount = raw_amount_out(amount_in, token_a_decimals, token_b_decimals, price_a, price_b);

    println!("Amount out: {:?}", amount);
    //assert_eq!(amount_out, 24604301);
}

#[test]
fn testing_fees_setting() {
    let pubkey = Pubkey::default();
    let vault_in = Vault {base_fee: 1, initial_liquidity: 1000000000000, current_liquidity: 900000000000, token_mint: pubkey, pyth_price_account: pubkey, max_age_price: 300, lp_mint: pubkey, cumulative_yield_per_lp: 0, protocol_yield: 0};
    let vault_out = Vault {base_fee: 1, initial_liquidity: 150000000000, current_liquidity: 100000000000, token_mint: pubkey, pyth_price_account: pubkey, max_age_price: 300, lp_mint: pubkey, cumulative_yield_per_lp: 0, protocol_yield: 0};

    let fee = fees_setting(&vault_in, &vault_out);

    println!("Swap fee: {:?}", fee);
    //assert_eq!(amount_out, 24604301);
}

// ─────────────────────────────────────────────
// conf_fee_bps unit tests
// ─────────────────────────────────────────────

#[test]
fn conf_fee_zero_conf_returns_zero() {
    // Both oracles report conf=0 → no extra fee
    let fee = conf_fee_bps(10_000_000_000, 0, 100_000_000, 0);
    assert_eq!(fee, 0, "zero conf should produce zero fee");
}

#[test]
fn conf_fee_typical_sol_usdc() {
    // SOL:  price = 10_000_000_000 @ exp-8 → $100.00
    //       conf  =     15_000_000 @ exp-8 → $0.15  → 15 bps
    // USDC: price =    100_000_000 @ exp-8 → $1.00
    //       conf  =         10_000 @ exp-8 → $0.0001 → 1 bps
    // Expected total = 16 bps
    let fee = conf_fee_bps(10_000_000_000, 15_000_000, 100_000_000, 10_000);
    assert_eq!(fee, 16, "typical SOL/USDC conf should give 16 bps");
}

#[test]
fn conf_fee_high_volatility() {
    // SOL conf at 5% of price → 500 bps each oracle → 1000 bps total
    let price: i64 = 10_000_000_000;
    let conf: u64 = 500_000_000; // 5% of price
    let fee = conf_fee_bps(price, conf, price, conf);
    assert_eq!(fee, 1000, "5% conf on each oracle should give 1000 bps");
}

#[test]
fn conf_fee_caps_at_10000_bps() {
    // conf >= price on both oracles → capped at 10_000 bps
    let fee = conf_fee_bps(1000, 1000, 1000, 1000);
    assert_eq!(fee, 10_000, "fee must not exceed 10_000 bps");
}

#[test]
fn conf_fee_price_zero_does_not_panic() {
    // price = 0 must return 0, not panic
    let fee = conf_fee_bps(0, 999_999, 0, 999_999);
    assert_eq!(fee, 0, "zero price must return zero, not panic");
}

#[test]
fn conf_fee_only_input_oracle_uncertain() {
    // Only oracle_in has significant conf, oracle_out is stable
    // SOL conf=$1 on $100 price → 100 bps; USDC conf=0 → 0 bps; total=100
    let fee = conf_fee_bps(10_000_000_000, 1_000_000_000, 100_000_000, 0);
    assert_eq!(fee, 1000, "only input oracle conf contributes 1000 bps");
}

#[test]
fn conf_fee_asymmetric_oracles() {
    // Verify fee_in and fee_out are summed independently
    // in:  conf/price = 50/10_000 = 50 bps
    // out: conf/price = 20/10_000 = 20 bps
    // total = 70 bps
    let fee = conf_fee_bps(10_000, 50, 10_000, 20);
    assert_eq!(fee, 70, "sum of independent conf fees should be 70 bps");
}

}