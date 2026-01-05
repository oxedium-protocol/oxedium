use crate::states::Vault;

/// Calculates the swap fee (in basis points) based on the liquidity imbalance
/// between the input and output vaults.
///
/// Fee logic:
/// - If the swap does NOT worsen the imbalance (delta_in <= delta_out),
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
    // Change in liquidity relative to the initial state
    let delta_in: i64 =
        vault_in.current_liquidity as i64 - vault_in.initial_liquidity as i64;
    let delta_out: i64 =
        vault_out.current_liquidity as i64 - vault_out.initial_liquidity as i64;

    // If the swap does not increase imbalance,
    // apply only the base fee
    if delta_in <= delta_out {
        return vault_out.base_fee;
    }

    // Absolute deviation of output vault liquidity from its initial value,
    // expressed in basis points (0..10_000)
    let deviation_bps: u64 = if vault_out.current_liquidity > vault_out.initial_liquidity {
        ((vault_out.current_liquidity - vault_out.initial_liquidity) * 10_000)
            / vault_out.initial_liquidity
    } else {
        ((vault_out.initial_liquidity - vault_out.current_liquidity) * 10_000)
            / vault_out.initial_liquidity
    };

    // Cap deviation at 100% to avoid excessive or undefined fee growth
    let deviation_bps = deviation_bps.min(10_000);

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
    let total_fee_bps =
        vault_out.base_fee
            + (MAX_FEE_BPS - vault_out.base_fee)
                * curved_deviation_bps
                / 10_000;

    total_fee_bps
}
