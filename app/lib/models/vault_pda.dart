import 'package:fixnum/fixnum.dart';
import 'package:solana/base58.dart';
import 'package:solana/dto.dart';

class VaultPda {
  final String address;
  final int createAtTs;
  final bool isActive;
  final int baseFee;
  final String mint;
  final String pythPriceFeedAccount;
  final int maxAgePrice;
  final String lpTokenMint;
  final int initialLiquidity;
  final int currentLiquidity;
  final int cumulativeYield;
  final int protocolYield;

  VaultPda({required this.address, required this.createAtTs, required this.isActive, required this.baseFee, required this.mint, required this.pythPriceFeedAccount, required this.maxAgePrice, required this.lpTokenMint, required this.initialLiquidity, required this.cumulativeYield, required this.currentLiquidity, required this.protocolYield});

  factory VaultPda.fromProgramAccount(ProgramAccount programAccount) {
    var binaryAccountData = programAccount.account.data as BinaryAccountData;
    var data = binaryAccountData.data;
    return VaultPda( 
      address: programAccount.pubkey,
      createAtTs: Int64.fromBytes(data.getRange(8, 16).toList()).toInt(),
      isActive: data.getRange(16, 17).toList()[0] == 1 ? true : false,
      baseFee: Int64.fromBytes(data.getRange(17, 25).toList()).toInt(),
      mint: base58encode(data.getRange(25, 57).toList()), 
      pythPriceFeedAccount: base58encode(data.getRange(57, 89).toList()), 
      maxAgePrice: Int64.fromBytes(data.getRange(89, 97).toList()).toInt(),
      lpTokenMint: base58encode(data.getRange(97, 129).toList()), 
      initialLiquidity: Int64.fromBytes(data.getRange(129, 137).toList()).toInt(), 
      currentLiquidity: Int64.fromBytes(data.getRange(137, 145).toList()).toInt(),
      cumulativeYield: Int64.fromBytes(data.getRange(145, 161).toList()).toInt(),
      protocolYield: Int64.fromBytes(data.getRange(161, 169).toList()).toInt()
    );
  }
}