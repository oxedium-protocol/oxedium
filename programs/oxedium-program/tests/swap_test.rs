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

    // ─────────────────────────────────────────────
    // conf_fee integration tests
    // ─────────────────────────────────────────────

    fn make_vault(pubkey: Pubkey) -> Vault {
        Vault {
            base_fee: 30,
            initial_liquidity: 1_000_000_000_000,
            current_liquidity: 1_000_000_000_000,
            token_mint: pubkey,
            pyth_price_account: pubkey,
            max_age_price: 300,
            lp_mint: pubkey,
            cumulative_yield_per_lp: 0,
            protocol_yield: 0,
        }
    }

    fn make_treasury(pubkey: Pubkey) -> Treasury {
        Treasury { stoptap: false, admin: pubkey, fee_bps: 5, deviation: 10 }
    }

    #[test]
    fn high_conf_produces_higher_fee_than_low_conf() {
        // Identical swap except conf value — higher conf must yield a larger swap_fee_bps
        // and therefore a smaller net_amount_out (more fee taken).
        let pubkey = Pubkey::default();
        let vault_in  = make_vault(pubkey);
        let vault_out = make_vault(pubkey);
        let treasury  = make_treasury(pubkey);

        let amount_in  = 1_000_000_000_u64; // 1 SOL
        let decimals_in  = 9_u8;
        let decimals_out = 6_u8;

        // SOL price $100, USDC price $1 — tiny conf (baseline)
        let low_conf_in  = PriceFeedMessage { feed_id: [0; 32], price: 10_000_000_000, conf: 100, exponent: 8, publish_time: 1, prev_publish_time: 1, ema_price: 1, ema_conf: 1 };
        let low_conf_out = PriceFeedMessage { feed_id: [0; 32], price:    100_000_000, conf: 100, exponent: 8, publish_time: 1, prev_publish_time: 1, ema_price: 1, ema_conf: 1 };

        // Same prices, but conf is 1% of price (volatile market)
        let high_conf_in  = PriceFeedMessage { feed_id: [0; 32], price: 10_000_000_000, conf: 100_000_000, exponent: 8, publish_time: 1, prev_publish_time: 1, ema_price: 1, ema_conf: 1 };
        let high_conf_out = PriceFeedMessage { feed_id: [0; 32], price:    100_000_000, conf:   1_000_000, exponent: 8, publish_time: 1, prev_publish_time: 1, ema_price: 1, ema_conf: 1 };

        let result_low = compute_swap_math(amount_in, low_conf_in, low_conf_out, decimals_in, decimals_out, &vault_in, &vault_out, &treasury)
            .expect("low-conf swap should succeed");

        let result_high = compute_swap_math(amount_in, high_conf_in, high_conf_out, decimals_in, decimals_out, &vault_in, &vault_out, &treasury)
            .expect("high-conf swap should succeed");

        assert!(
            result_high.swap_fee_bps > result_low.swap_fee_bps,
            "high conf must produce a higher swap_fee_bps: {} vs {}",
            result_high.swap_fee_bps, result_low.swap_fee_bps
        );
        assert!(
            result_high.net_amount_out < result_low.net_amount_out,
            "high conf must reduce net output: {} vs {}",
            result_high.net_amount_out, result_low.net_amount_out
        );
    }

    #[test]
    fn invariant_holds_with_conf_fee() {
        // raw_out == net_out + lp_fee + protocol_fee must hold regardless of conf
        let pubkey = Pubkey::default();
        let vault_in  = make_vault(pubkey);
        let vault_out = make_vault(pubkey);
        let treasury  = make_treasury(pubkey);

        // Realistic SOL conf: $0.15 on $100 price = 15 bps
        let oracle_in  = PriceFeedMessage { feed_id: [0; 32], price: 10_000_000_000, conf: 15_000_000, exponent: 8, publish_time: 1, prev_publish_time: 1, ema_price: 1, ema_conf: 1 };
        let oracle_out = PriceFeedMessage { feed_id: [0; 32], price:    100_000_000, conf:     10_000, exponent: 8, publish_time: 1, prev_publish_time: 1, ema_price: 1, ema_conf: 1 };

        let result = compute_swap_math(1_000_000_000, oracle_in, oracle_out, 9, 6, &vault_in, &vault_out, &treasury)
            .expect("swap with realistic conf should succeed");

        assert_eq!(
            result.raw_amount_out,
            result.net_amount_out + result.lp_fee_amount + result.protocol_fee_amount,
            "accounting invariant: raw_out == net_out + lp_fee + protocol_fee"
        );
    }

    #[test]
    fn excessive_conf_returns_fee_exceeds_error() {
        // conf equal to price on both oracles → conf_fee alone = 20_000 bps → FeeExceeds
        let pubkey = Pubkey::default();
        let vault_in  = make_vault(pubkey);
        let vault_out = make_vault(pubkey);
        let treasury  = make_treasury(pubkey);

        let oracle_in  = PriceFeedMessage { feed_id: [0; 32], price: 10_000_000_000, conf: 10_000_000_000, exponent: 8, publish_time: 1, prev_publish_time: 1, ema_price: 1, ema_conf: 1 };
        let oracle_out = PriceFeedMessage { feed_id: [0; 32], price:    100_000_000, conf:    100_000_000, exponent: 8, publish_time: 1, prev_publish_time: 1, ema_price: 1, ema_conf: 1 };

        let result = compute_swap_math(1_000_000_000, oracle_in, oracle_out, 9, 6, &vault_in, &vault_out, &treasury);

        assert!(result.is_err(), "conf equal to price must trigger FeeExceeds error");
    }

    #[test]
    fn zero_conf_matches_baseline_without_conf_fee() {
        // With conf=0, the conf fee component adds nothing.
        // swap_fee_bps must equal only the liquidity-based fee (base_fee here = 30).
        let pubkey = Pubkey::default();
        let vault_in  = make_vault(pubkey);
        let vault_out = make_vault(pubkey);
        let treasury  = make_treasury(pubkey);

        let oracle_in  = PriceFeedMessage { feed_id: [0; 32], price: 10_000_000_000, conf: 0, exponent: 8, publish_time: 1, prev_publish_time: 1, ema_price: 1, ema_conf: 1 };
        let oracle_out = PriceFeedMessage { feed_id: [0; 32], price:    100_000_000, conf: 0, exponent: 8, publish_time: 1, prev_publish_time: 1, ema_price: 1, ema_conf: 1 };

        let result = compute_swap_math(1_000_000_000, oracle_in, oracle_out, 9, 6, &vault_in, &vault_out, &treasury)
            .expect("zero-conf swap should succeed");

        // With balanced vaults swap_fee_bps == base_fee (30), no conf addition
        assert_eq!(result.swap_fee_bps, 30, "zero conf must not inflate swap_fee_bps beyond base_fee");
    }
}
