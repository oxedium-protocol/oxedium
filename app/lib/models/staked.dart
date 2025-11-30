class Staked {
  final String logoUrl;
  final String symbol;
  final String uiAmount;
  final int amount;
  final double apr;
  final double earned;
  final String mint;
  final int decimals;

  Staked({
    required this.logoUrl,
    required this.symbol,
    required this.uiAmount,
    required this.amount,
    required this.apr,
    required this.earned,
    required this.mint,
    required this.decimals
  });
}