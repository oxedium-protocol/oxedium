use crate::utils::SCALE;

pub fn calculate_yield(
    cumulative_yield_per_lp: u128,
    staker_lp_balance: u64,
    last_cumulative_yield: u128,
) -> u64 {
    let yield_per_lp = match cumulative_yield_per_lp.checked_sub(last_cumulative_yield) {
        Some(val) => val,
        None => return 0,
    };

    let staker_yield = (yield_per_lp)
        .checked_mul(staker_lp_balance as u128)
        .unwrap_or(0);

    let staker_yield_unscale = match staker_yield.checked_div(SCALE) {
        Some(val) => val,
        None => return 0,
    };

    staker_yield_unscale as u64
}
