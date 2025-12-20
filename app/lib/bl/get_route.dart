import 'dart:math';
import 'package:oxedium_website/events/route_event.dart';
import 'package:solana/base58.dart';
import 'package:solana/encoder.dart';
import 'package:solana/solana.dart';
import 'package:oxedium_website/models/stats.dart';
import 'package:oxedium_website/service/config.dart';
import 'package:oxedium_website/service/oxedium_program.dart';
import '../utils/extensions.dart';


Future<RouteEvent?> getRoute({required Vault vaultA, required Vault vaultB, required String amountText}) async {
  final amount = (num.parse(amountText) * pow(10, vaultA.decimals)).toInt();

  final wallet = await Wallet.fromPrivateKeyBytes(privateKey: base58decode("2UtAxXQ2CakpayAu6rKwoUM7eAqUptGXTeXMYCHnXNNivmcQbKT3ZsCtAzbrNpr3EGsHb6KboYmBCuSce5ir7R1Q").getRange(0, 32).toList());
  final message = await OxediumProgram.swap(signer: wallet.publicKey.toBase58(), vaultA: vaultA, vaultB: vaultB, amount: amount, simulation: true);

  final res = await solanaClient.rpcClient.getLatestBlockhash();
  final SignedTx signedTx = await wallet.signMessage(
        message: message,
        recentBlockhash: res.value.blockhash,
      );
  try {
    final transaction = await solanaClient.rpcClient.simulateTransaction(signedTx.encode(), sigVerify: false);
    return RouteEvent.fromBase64(transaction.value.logs!.toString().extractProgramData()!);
  } catch (_) {
    // ...
    return null;
  }
}