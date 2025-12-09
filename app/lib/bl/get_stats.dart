import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:solana/solana.dart';
import 'package:oxedium_website/metadata/vaults.dart';
import 'package:oxedium_website/models/stats.dart';
import 'package:oxedium_website/models/vault_pda.dart';
import 'package:oxedium_website/service/custom_api.dart';
import 'package:oxedium_website/service/tyrbine_program.dart';
import 'package:oxedium_website/utils/extensions.dart';

final statsProvider = FutureProvider<Stats?>((ref) async {
  return await getStats();
});

Future<Stats?> getStats() async {
  final programFuture = Ed25519HDPublicKey.findProgramAddress(
    seeds: [
      "oxedium-seed".codeUnits,
      "treasury-seed".codeUnits,
    ],
    programId: Ed25519HDPublicKey.fromBase58(TyrbineProgram.programId),
  );

  final vaultsFuture = CustomApi.getVaults();

  final results = await Future.wait([
    programFuture,
    vaultsFuture,
  ]);

  final treasuryAddress = results[0] as Ed25519HDPublicKey;
  final vaultsPda = results[1] as List<VaultPda>;

  final balanceFuture = CustomApi.getTreasuryBalance(
    treasuryAddress: treasuryAddress.toBase58(),
    mints: vaultsPda.map((vlt) => vlt.mint).toList(),
  );

  final usdTreasuryBalance = await balanceFuture;

  final currentTimestamp =
      (DateTime.now().toUtc().millisecondsSinceEpoch / 1000).toInt();

  for (var vault in vaultsPda) {
    vaultsData[vault.mint]?.tvl =
        vault.currentLiquidity / pow(10, vaultsData[vault.mint]!.decimals);

    const secondsInYear = 31536000;

    final cumulativeYieldUnscaled = vault.cumulativeYield / 1e11;
    final totalYieldAmount = cumulativeYieldUnscaled * vault.initialLiquidity;

    final totalYieldPercent = vault.initialLiquidity == 0
        ? 0
        : (totalYieldAmount / vault.initialLiquidity);

    final vaultLifetimeSeconds = currentTimestamp - vault.createAtTs;

    final yearsElapsedFactor =
        vaultLifetimeSeconds == 0 ? 0 : secondsInYear / vaultLifetimeSeconds;

    final apr = totalYieldPercent * yearsElapsedFactor;

    vaultsData[vault.mint]?.apr = apr.trimTo(2);
  }

  return Stats(
    treasuryAddress: treasuryAddress.toBase58(),
    usdTreasuryBalance: usdTreasuryBalance,
    vaults: vaultsData.values.toList(),
  );
}
