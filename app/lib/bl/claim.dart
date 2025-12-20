import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:solana/solana.dart';
import 'package:oxedium_website/adapter/adapter.dart';
import 'package:oxedium_website/bl/get_staker.dart';
import 'package:oxedium_website/models/tx_status.dart';
import 'package:oxedium_website/models/stats.dart';
import 'package:oxedium_website/service/config.dart';
import 'package:oxedium_website/service/helius_api.dart';
import 'package:oxedium_website/service/oxedium_program.dart';

Future<void> claim(
  BuildContext context,
  WidgetRef ref, {
  required Adapter adapter,
  required String mint,
  required ValueNotifier<TxStatus> status,
  required List<Vault> vaultsData,
}) async {
  status.value = TxStatus(status: 'Awaiting approve');

  final message =
      await OxediumProgram.claim(signer: adapter.pubkey!, mint: mint);

  final hash = await solanaClient.rpcClient.getLatestBlockhash();

  final compiledMessage = message.compileV0(
      recentBlockhash: hash.value.blockhash,
      feePayer: Ed25519HDPublicKey.fromBase58(adapter.pubkey!));

  List<int> tx = List.generate(65, (i) => i == 0 ? 1 : 0);
  tx.addAll(compiledMessage.toByteArray());
  try {
    final signature =
        await adapter.signAndSendTransaction(Uint8List.fromList(tx));
    status.value = TxStatus(
        status: 'Sending transaction',
        signature:
            'https://orb.helius.dev/tx/$signature?cluster=${SolanaConfig.cluster}&tab=summary');
    await HeliusApi.waitingSignatureStatus(
        signature: signature, expectedStatus: Commitment.processed);
    status.value = TxStatus(
        status: 'Success',
        signature:
            'https://orb.helius.dev/tx/$signature?cluster=${SolanaConfig.cluster}&tab=summary');

    final currentStakes = ref.read(stakerNotifierProvider);
    if (currentStakes.value == null || currentStakes.value!.isEmpty) {
      await ref
          .read(stakerNotifierProvider.notifier)
          .loadStaker(vaultsData: vaultsData, owner: adapter.pubkey!);
    } else {
      await ref
          .read(stakerNotifierProvider.notifier)
          .loadStakerBackground(vaultsData: vaultsData, owner: adapter.pubkey!);
    }
  } catch (_) {
    status.value = TxStatus(status: 'Rejected');
  }
}
