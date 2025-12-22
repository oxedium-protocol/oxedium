import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart';
import 'package:solana/dto.dart';
import 'package:solana/solana.dart';
import 'package:oxedium_website/models/user_balance.dart';
import 'package:oxedium_website/models/vault_pda.dart';
import 'package:oxedium_website/service/config.dart';
import 'package:oxedium_website/service/oxedium_program.dart';
import '../utils/extensions.dart';

class CustomApi {

    static Future<Map<String, dynamic>> _getSolBalance(String address) async {
    final solBalance = await solanaClient.rpcClient.getBalance(address, commitment: Commitment.processed);

    return {
      'mint': 'So11111111111111111111111111111111111111112',
      'symbol': 'SOL',
      'ata': address,
      'lamports': solBalance.value,
      'uiAmount': solBalance.value / pow(10, 9),
      'usdValue': 0,
      'decimals': 9,
      'standard': 'native',
      'price': null
    };
  }

  static Future<List<Map<String, dynamic>>> _getSplBalance(String address) async {
    final splTokens = await solanaClient.rpcClient.getTokenAccountsByOwner(address, TokenAccountsFilter.byProgramId(TokenProgramType.tokenProgram.programId), commitment: Commitment.processed, encoding: Encoding.jsonParsed);
    final list = splTokens.value.map((token) {
      final parsedData = token.account.data?.toJson()['parsed']['info'];
      final accountData = SplTokenAccountDataInfo.fromJson(parsedData);

      return {
        'mint': accountData.mint,
        'symbol': 'NULL',
        'ata': token.pubkey,
        'lamports': int.parse(accountData.tokenAmount.amount),
        'uiAmount': num.parse(accountData.tokenAmount.uiAmountString!),
        'usdValue': 0,
        'decimals': accountData.tokenAmount.decimals,
        'standard': 'spl-token',
        'price': null
      };
    }).toList();
    return list;
  }

  static Future<Map<String, dynamic>> _getTokensPrice(String mints) async {
    mints = mints.replaceAll(
      'Gh9ZwEmdLJ8DscKNTkTqPbNwLNNBjuSzaG9Vp2KGtKJr',
      'EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v',
    );

    final response = await get(Uri.parse("https://api.jup.ag/price/v3?ids=$mints"), headers: {
      'x-api-key': 'a7e8aee6-b556-47f7-abed-5d187fd6b8d6',
    });
    final Map<String, dynamic> jsonDecode = json.decode(response.body);
    return jsonDecode;
  }
  
  static Future<num> getTreasuryBalance({required String treasuryAddress, required List<String> mints}) async {
    final splBalace = await _getSplBalance(treasuryAddress);

    final tokensPrice = await _getTokensPrice(mints.join(','));

    num totalValueLocked = 0;

    for (var token in splBalace) {
      final price = num.parse(tokensPrice[token['mint'] == "Gh9ZwEmdLJ8DscKNTkTqPbNwLNNBjuSzaG9Vp2KGtKJr" ? "EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v" : token['mint']]?['usdPrice'].toString() ?? '0');
      token['usdValue'] = price * token['uiAmount'];
      totalValueLocked += token['usdValue'];
    }

    return totalValueLocked.trimTo(2);
  }

  static Future<List<VaultPda>> getVaults() async {
    final tyrbineVaults = await solanaClient.rpcClient.getProgramAccounts(OxediumProgram.programId, encoding: Encoding.jsonParsed, filters: [const ProgramDataFilter.dataSize(169)], commitment: Commitment.processed);
    final vaults = tyrbineVaults.map((vlt) => VaultPda.fromProgramAccount(vlt)).toList();
    return vaults;
  }

  static Future<List<UserBalance>> getBalance({
    required String address,
    required List<String> mints,
  }) async {
    final solBalance = _getSolBalance(address);
    final splBalance = _getSplBalance(address);

    final List result = await Future.wait([solBalance, splBalance]);

    List<Map<String, dynamic>> list = [];
    list.add(result[0]);
    list.addAll(result[1]);

    final balances = list.map((json) => UserBalance.fromJson(json)).toList();

    return balances.where((b) => mints.contains(b.mint)).toList();
  }

}