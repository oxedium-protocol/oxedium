import 'package:fixnum/fixnum.dart';
import 'package:solana/base58.dart';
import 'package:solana/dto.dart';

class StakerPda {
  final String owner;
  final String vault;
  final int lastCumulativeYield;
  final int pendingClaim;

  StakerPda({required this.owner, required this.vault, required this.lastCumulativeYield, required this.pendingClaim});

  factory StakerPda.fromProgramAccount(Account account) {
    var binaryAccountData = account.data as BinaryAccountData;
    var data = binaryAccountData.data;
    return StakerPda( 
      owner: base58encode(data.getRange(8, 40).toList()),
      vault: base58encode(data.getRange(40, 72).toList()),
      lastCumulativeYield: Int64.fromBytes(data.getRange(72, 88).toList()).toInt(), 
      pendingClaim: Int64.fromBytes(data.getRange(88, 96).toList()).toInt(),
    );
  }
}