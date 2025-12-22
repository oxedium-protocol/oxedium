import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oxedium_website/bl/get_user_balance.dart';
import 'package:solana/solana.dart';
import 'package:oxedium_website/adapter/adapter.dart';
import 'package:oxedium_website/models/tx_status.dart';
import 'package:oxedium_website/models/stats.dart';
import 'package:oxedium_website/service/config.dart';
import 'package:oxedium_website/service/helius_api.dart';
import 'package:oxedium_website/service/oxedium_program.dart';

Future<void> swap(BuildContext context, WidgetRef ref, {required Adapter adapter, required Vault vaultA, required Vault vaultB, required ValueNotifier<TxStatus> status, required String amountText}) async {
  status.value = TxStatus(status: 'Awaiting approve');

  final amount = (num.parse(amountText) * pow(10, vaultA.decimals)).toInt();

  final message = await OxediumProgram.swap(signer: adapter.pubkey!, vaultA: vaultA, vaultB: vaultB, amount: amount);
  
  final hash = await solanaClient.rpcClient.getLatestBlockhash();

  final compiledMessage = message.compileV0(recentBlockhash: hash.value.blockhash, feePayer: Ed25519HDPublicKey.fromBase58(adapter.pubkey!));
  
  List<int> tx = List.generate(65, (i) => i == 0 ? 1 : 0);
  tx.addAll(compiledMessage.toByteArray());
  try {
    final signature = await adapter.signAndSendTransaction(Uint8List.fromList(tx));
    status.value = TxStatus(status: 'Sending transaction', signature: 'https://orb.helius.dev/tx/$signature?cluster=${SolanaConfig.cluster}&tab=summary');
    await HeliusApi.waitingSignatureStatus(signature: signature, expectedStatus: Commitment.processed);
    status.value = TxStatus(status: 'Success', signature: 'https://orb.helius.dev/tx/$signature?cluster=${SolanaConfig.cluster}&tab=summary');
    final userBalanceNotifier = ref.read(userBalanceNotifierProvider(adapter.pubkey!).notifier);
    await userBalanceNotifier.loadBalances(adapter.pubkey!);
  } catch (_) {
    status.value = TxStatus(status: 'Rejected');
  }
}