import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:solana/base58.dart';
import 'package:solana/dto.dart';
import 'package:solana/solana.dart';
import 'package:oxedium_website/models/staked.dart';
import 'package:oxedium_website/models/staker.dart';
import 'package:oxedium_website/models/stats.dart';
import 'package:oxedium_website/models/vault_pda.dart';
import 'package:oxedium_website/service/config.dart';
import 'package:oxedium_website/service/oxedium_program.dart';
import 'package:oxedium_website/utils/extensions.dart';

final stakerNotifierProvider =
    AsyncNotifierProvider<StakerNotifier, List<Staked>>(() => StakerNotifier());

class StakerNotifier extends AsyncNotifier<List<Staked>> {
  @override
  Future<List<Staked>> build() async {
    return [];
  }

  Future<void> loadStaker({
    required String owner,
    required List<Vault> vaultsData,
  }) async {
    state = const AsyncValue.loading();
    try {
      final staked = await getStaker(owner: owner, vaultsData: vaultsData);
      state = AsyncValue.data(staked);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> loadStakerBackground({
    required String owner,
    required List<Vault> vaultsData,
  }) async {
    try {
      final staked = await getStaker(owner: owner, vaultsData: vaultsData);
      state = AsyncValue.data(staked);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

Future<List<Staked>> getStaker(
    {required String owner, required List<Vault> vaultsData}) async {
  List<VaultPda> vaults = [];
  List<Staked> staked = [];

  final accounts = await solanaClient.rpcClient.getTokenAccountsByOwner(
      owner, const TokenAccountsFilter.byProgramId(TokenProgram.programId),
      encoding: Encoding.jsonParsed, commitment: Commitment.processed);
  var tyrbineVaults = await solanaClient.rpcClient.getProgramAccounts(
      OxediumProgram.programId,
      encoding: Encoding.jsonParsed,
      filters: [const ProgramDataFilter.dataSize(169)],
      commitment: Commitment.processed);

  for (var value in tyrbineVaults) {
    vaults.add(VaultPda.fromProgramAccount(value));
  }

  for (var vault in vaults) {
    final vaultInfo =
        vaultsData.where((element) => element.mint == vault.mint).first;

    for (var account in accounts.value) {
      final parsed = account.account.data as ParsedAccountData;
      final tokenAccount = parsed.parsed as TokenAccountData;

      if (tokenAccount.info.mint == vault.lpTokenMint) {
        final stakerPDA = await Ed25519HDPublicKey.findProgramAddress(seeds: [
          "staker-seed".codeUnits,
          base58decode(vault.address),
          base58decode(owner),
        ], programId: Ed25519HDPublicKey.fromBase58(OxediumProgram.programId));

        final getStakerAccount = await solanaClient.rpcClient.getAccountInfo(
            stakerPDA.toBase58(),
            encoding: Encoding.jsonParsed,
            commitment: Commitment.processed);
        final staker = StakerPda.fromProgramAccount(getStakerAccount.value!);

        const apr = 0.0;

        final uiAmountStr = tokenAccount.info.tokenAmount.uiAmountString;
        final decimals = tokenAccount.info.tokenAmount.decimals;
        final uiAmount = num.tryParse(uiAmountStr ?? '0') ?? 0;

        const int scale = 100000000000;
        num earned;

        final yieldPortion =
            (vault.cumulativeYield - staker.lastCumulativeYield) * uiAmount;
        earned =
            yieldPortion / scale + (staker.pendingClaim / pow(10, decimals));

        if (earned == 0 && uiAmount == 0) {
          continue;
        }

        final roundedEarned = earned.roundToSignificantFigures(decimals);

        staked.add(Staked(
            logoUrl: vaultInfo.logoUrl,
            symbol: vaultInfo.symbol,
            uiAmount: tokenAccount.info.tokenAmount.uiAmountString!,
            amount: int.parse(tokenAccount.info.tokenAmount.amount),
            apr: apr,
            earned:
                roundedEarned.trimTo(tokenAccount.info.tokenAmount.decimals),
            mint: vault.mint,
            decimals: tokenAccount.info.tokenAmount.decimals));
      }
    }
  }

  return staked;
}
