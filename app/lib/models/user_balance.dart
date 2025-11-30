class UserBalance {
  final String mint;
  final double amount;

  UserBalance({
    required this.mint,
    required this.amount,
  });

  factory UserBalance.fromJson(json) {
    return UserBalance(
      mint: json['mint'], 
      amount: json['uiAmount']
    );
  }
}
