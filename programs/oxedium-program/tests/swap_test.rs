#[cfg(test)]
mod swap {
    use anchor_lang::prelude::Pubkey;
    use oxedium_program::{components::compute_swap_math, states::{Treasury, Vault}};

    #[test]
    fn test_swap_math_output() {
        let amount_in = 1000000000; // 1 token (9 decimals)

        let price_in = 13524400000;   // $134.00
        let price_out = 100000000;   // $0.9998

        let decimals_in = 9;
        let decimals_out = 6;

        let pubkey = Pubkey::default();
        let vault_in = &Vault{create_at_ts: 1111, base_fee: 1, initial_liquidity: 1000000000000, current_liquidity: 1000000000000, is_active: true, token_mint: pubkey, pyth_price_account: pubkey, max_age_price: 300, lp_mint: pubkey, cumulative_yield_per_lp: 0, protocol_yield: 0};
        let vault_out = &Vault{create_at_ts: 1111, base_fee: 1, initial_liquidity: 150000000000, current_liquidity: 150000000000, is_active: true, token_mint: pubkey, pyth_price_account: pubkey, max_age_price: 300, lp_mint: pubkey, cumulative_yield_per_lp: 0, protocol_yield: 0};
        let treasury = &Treasury{stoptap: false, admin: pubkey, fee_bps: 1, deviation: 10};

        let result = compute_swap_math(
            amount_in,
            price_in,
            price_out,
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
