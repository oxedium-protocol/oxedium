import 'package:fixnum/fixnum.dart';

class ProviderPda {
  final int lpBalance;
  final int userLastCumulativeYield;
  final int pendingYield;

  ProviderPda({required this.lpBalance, required this.userLastCumulativeYield, required this.pendingYield});

  factory ProviderPda.fromAccountData(List<int> data) {
    return ProviderPda( 
      lpBalance: Int64.fromBytes(data.getRange(40, 48).toList()).toInt(),
      userLastCumulativeYield: Int64.fromBytes(data.getRange(48, 56).toList()).toInt(),
      pendingYield: Int64.fromBytes(data.getRange(56, 64).toList()).toInt()
    );
  }
}