use crate::utils::SCALE;

/// Calculates the staker's yield based on cumulative yield per LP token.
///
/// # Arguments
/// * `current_cumulative_yield` - The current cumulative yield per LP token (scaled by `SCALE`)
/// * `staker_balance` - The amount of LP tokens the staker holds
/// * `last_recorded_yield` - The cumulative yield per LP token at the last update for this staker
///
/// # Returns
/// * `u64` - The amount of yield earned by the staker since the last update
pub fn calculate_staker_yield(
    current_cumulative_yield: u128,
    staker_balance: u64,
    last_recorded_yield: u128,
) -> u64 {
    // Calculate the yield difference per LP token since the last update
    let delta_yield_per_lp = match current_cumulative_yield.checked_sub(last_recorded_yield) {
        Some(val) => val,
        None => return 0, // If underflow occurs, return 0 yield
    };

    // Multiply the yield per LP token by the staker's LP balance to get total yield
    let total_yield = delta_yield_per_lp
        .checked_mul(staker_balance as u128)
        .unwrap_or(0); // On overflow, default to 0

    // Scale down the yield to normal units by dividing by SCALE
    let final_yield = match total_yield.checked_div(SCALE) {
        Some(val) => val,
        None => return 0, // If division by zero or underflow occurs, return 0
    };

    // Return the staker's yield as u64
    final_yield as u64
}
