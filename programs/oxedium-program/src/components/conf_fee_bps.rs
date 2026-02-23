/// Computes additional swap fee in basis points derived from Pyth confidence intervals.
///
/// Protects against oracle-latency arbitrage: when `conf` is large relative to `price`,
/// the oracle uncertainty window is wider, giving arbitrageurs a larger edge.
/// Charging `conf/price` as extra fee makes each such trade unprofitable for them.
///
/// Formula: `fee_in_bps + fee_out_bps`, where each term = `conf * 10_000 / price`.
///
/// # Example
/// SOL  (price=$100, conf=$0.15) → 15 bps
/// USDC (price=$1,   conf=$0.0001) → 1 bps
/// Total conf fee = 16 bps
pub fn conf_fee_bps(price_in: i64, conf_in: u64, price_out: i64, conf_out: u64) -> u64 {
    let fee_in = conf_to_bps(price_in, conf_in);
    let fee_out = conf_to_bps(price_out, conf_out);
    fee_in.saturating_add(fee_out).min(10_000)
}

fn conf_to_bps(price: i64, conf: u64) -> u64 {
    if price <= 0 || conf == 0 {
        return 0;
    }
    ((conf as u128 * 10_000) / price as u128).min(10_000) as u64
}
