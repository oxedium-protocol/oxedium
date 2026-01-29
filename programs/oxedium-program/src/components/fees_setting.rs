use crate::states::Vault;

/// Calculates the swap fee (in basis points) based on the liquidity imbalance
/// between the input and output vaults.
///
/// Fee logic:
/// - If the swap does NOT worsen the relative imbalance
///   (delta_in_bps <= delta_out_bps),
///   the base fee is applied.
/// - If the swap increases pressure on the output vault,
///   the fee grows non-linearly (quadratic curve) with liquidity deviation.
///
/// # Arguments
/// * `vault_in`  - The source vault for the swap
/// * `vault_out` - The destination vault for the swap
///
/// # Returns
/// * `u64` - The calculated total fee in basis points (bps)
pub fn fees_setting(
    vault_in: &Vault,
    vault_out: &Vault,
) -> u64 {
    // Relative liquidity deltas in basis points (can be negative)
    let delta_in_bps: i128 =
        (vault_in.current_liquidity as i128 - vault_in.initial_liquidity as i128)
            * 10_000
            / vault_in.initial_liquidity as i128;
    println!("Delta in bps: {}", delta_in_bps);
    let delta_out_bps: i128 =
        (vault_out.current_liquidity as i128 - vault_out.initial_liquidity as i128)
            * 10_000
            / vault_out.initial_liquidity as i128;
    println!("Delta out bps: {}", delta_out_bps);
    // If the swap does not worsen relative imbalance,
    // apply only the base fee
    if delta_in_bps <= delta_out_bps {
        return vault_out.base_fee;
    }

    // Absolute deviation of output vault liquidity from its initial value (0..10_000 bps)
    let deviation_bps: u64 = delta_out_bps
        .unsigned_abs()
        .min(10_000) as u64;

    // Apply a quadratic (x²) curve to the deviation:
    // - small deviations increase the fee slowly
    // - large deviations increase the fee aggressively
    //
    // Result is still scaled to 0..10_000
    let curved_deviation_bps =
        deviation_bps * deviation_bps / 10_000;

    // Maximum possible fee is capped at 10_000 bps (100%)
    const MAX_FEE_BPS: u64 = 10_000;

    // Final fee calculation:
    // base_fee + curved proportional increase up to MAX_FEE_BPS
    vault_out.base_fee
        + (MAX_FEE_BPS - vault_out.base_fee)
            * curved_deviation_bps
            / 10_000
}
