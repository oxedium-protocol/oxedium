use crate::states::Vault;

/// Calculates the swap fee (in basis points) based on the liquidity of input and output vaults.
///
/// # Arguments
/// * `vault_in` - The source vault for the swap
/// * `vault_out` - The destination vault for the swap
///
/// # Returns
/// * `u64` - The calculated total fee in basis points (bps)
pub fn fees_setting(
    vault_in: &Vault,
    vault_out: &Vault
) -> u64 {
    // Calculate the change in liquidity for the input and output vaults
    let delta_in: i64 = vault_in.current_liquidity as i64 - vault_in.initial_liquidity as i64;
    let delta_out: i64 = vault_out.current_liquidity as i64 - vault_out.initial_liquidity as i64;

    // If input vault change is less than or equal to output vault change,
    // return the base fee of the output vault (no deviation adjustment needed)
    if delta_in <= delta_out {
        return vault_out.base_fee;
    }

    // Calculate the deviation of the output vault's liquidity from its initial liquidity
    // in basis points (bps). This represents how much the vault has deviated.
    let deviation_bps = if vault_out.current_liquidity > vault_out.initial_liquidity {
        ((vault_out.current_liquidity - vault_out.initial_liquidity) * 10_000) / vault_out.initial_liquidity
    } else {
        ((vault_out.initial_liquidity - vault_out.current_liquidity) * 10_000) / vault_out.initial_liquidity
    };

    // Cap the deviation at 10_000 bps (100%) to prevent excessive fee increase
    let deviation_bps = deviation_bps.min(10_000);

    // Calculate the total fee in bps:
    // - Start with the base fee of the output vault
    // - Add a proportional increase based on the deviation of the output vault's liquidity
    let total_fee_bps = vault_out.base_fee + ((100_000 - vault_out.base_fee) * deviation_bps) / 10_000;

    // Return the total fee in bps
    total_fee_bps
}

