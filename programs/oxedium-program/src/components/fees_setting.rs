use crate::states::Vault;

pub fn fees_setting(
    vault_in: &Vault,
    vault_out: &Vault,
    proto_fee_bps: u64
) -> (u64, u64) {

    let delta_in: i64 = vault_in.current_liquidity as i64 - vault_in.initial_liquidity as i64;
    let delta_out: i64 = vault_out.current_liquidity as i64 - vault_out.initial_liquidity as i64;

    if delta_in <= delta_out {
        let protocol_fee_bps = (vault_out.base_fee * proto_fee_bps) / 100;
        let swap_fee_bps = vault_out.base_fee - protocol_fee_bps;
        return (swap_fee_bps, protocol_fee_bps);
    }

    let deviation_bps = if vault_out.current_liquidity > vault_out.initial_liquidity {
        ((vault_out.current_liquidity - vault_out.initial_liquidity) * 10_000) / vault_out.initial_liquidity
    } else {
        ((vault_out.initial_liquidity - vault_out.current_liquidity) * 10_000) / vault_out.initial_liquidity
    };
    let deviation_bps = deviation_bps.min(10_000);

    let total_fee_bps = vault_out.base_fee + ((100_000 - vault_out.base_fee) * deviation_bps) / 10_000;

    let protocol_fee_bps = (total_fee_bps * proto_fee_bps) / 100;

    let swap_fee_bps = total_fee_bps - protocol_fee_bps;

    (swap_fee_bps, protocol_fee_bps)
}
