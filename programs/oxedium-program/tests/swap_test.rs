#[cfg(test)]
mod swap {
    use anchor_lang::prelude::Pubkey;
    use oxedium_program::{components::compute_swap_math, states::{Treasury, Vault}};
    use pyth_solana_receiver_sdk::price_update::PriceFeedMessage;

    #[test]
    fn test_swap_math_output() {
        let amount_in = 50000000000; // 1 token (9 decimals)

        let decimals_in = 9;
        let decimals_out = 6;

        let pubkey = Pubkey::default();
        let vault_in = &Vault{base_fee: 1, initial_liquidity: 1000000000000, current_liquidity: 1000000000000, token_mint: pubkey, pyth_price_account: pubkey, max_age_price: 300, lp_mint: pubkey, cumulative_yield_per_lp: 0, protocol_yield: 0};
        let vault_out = &Vault{base_fee: 1, initial_liquidity: 150000000000, current_liquidity: 150000000000, token_mint: pubkey, pyth_price_account: pubkey, max_age_price: 300, lp_mint: pubkey, cumulative_yield_per_lp: 0, protocol_yield: 0};
        let treasury = &Treasury{stoptap: false, admin: pubkey, fee_bps: 1, deviation: 10};

        let result = compute_swap_math(
            amount_in,
            PriceFeedMessage { feed_id: [8; 32], price: 10000000000, conf: 15, exponent: 8, publish_time: 1, prev_publish_time: 1, ema_price: 1, ema_conf: 1 },
            PriceFeedMessage { feed_id: [8; 32], price: 100000000, conf: 15, exponent: 8, publish_time: 1, prev_publish_time: 1, ema_price: 1, ema_conf: 1 },
            decimals_in,
            decimals_out,
            vault_in,
            vault_out,
            treasury,
        )
        .expect("swap math should succeed");

        println!("=== SWAP MATH RESULT ===");
        println!("Raw out:        {}", result.raw_amount_out);
        println!("After fee:     {}", result.net_amount_out);
        println!("LP fee:        {}", result.lp_fee_amount);
        println!("Protocol fee:  {}", result.protocol_fee_amount);

        let total_fee =
            result.lp_fee_amount + result.protocol_fee_amount;

        println!("Total fee:     {}", total_fee);

        //assert_eq!(result.after_fee, 0);
        assert_eq!(
            result.raw_amount_out,
            result.net_amount_out + result.lp_fee_amount + result.protocol_fee_amount
        );
    }
}
