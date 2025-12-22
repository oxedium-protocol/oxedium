import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:oxedium_website/events/route_event.dart';
import 'package:oxedium_website/service/config.dart';
import 'package:oxedium_website/service/helius_api.dart';
import 'package:solana/base58.dart';
import 'package:solana/encoder.dart';
import 'package:solana/solana.dart';
import 'package:oxedium_website/models/stats.dart';
import 'package:oxedium_website/service/oxedium_program.dart';
import '../utils/extensions.dart';


Future<RouteEvent?> getRoute({required Vault vaultA, required Vault vaultB, required String amountText}) async {
  final amount = (num.parse(amountText) * pow(10, vaultA.decimals)).toInt();

  final wallet = await Wallet.fromPrivateKeyBytes(privateKey: base58decode(dotenv.env['PRIVATE_KEY']!).getRange(0, 32).toList());

  final message = await OxediumProgram.quote(vaultA: vaultA, vaultB: vaultB, amount: amount);
  final hash = await solanaClient.rpcClient.getLatestBlockhash();
  final SignedTx signedTx = await wallet.signMessage(
        message: message,
        recentBlockhash: hash.value.blockhash,
      );
  try {
    final transaction = await HeliusApi.simulateTransaction(base64Transaction: signedTx.encode());
    return RouteEvent.fromBase64(transaction.toString().extractProgramData()!);
  } catch (e) {
    debugPrint(e.toString());
    return null;
  }
}

Future<String?> getJupiterRoute({
  required Vault vaultA,
  required Vault vaultB,
  required String amountText,
}) async {
  final rpcUrl = dotenv.env['JUPITER_API'];
  try {
    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) return null;

    final amountInBaseUnits = (amount * pow(10, vaultA.decimals)).toInt();

    final uri = Uri.parse(
      'https://api.jup.ag/swap/v1/quote'
      '?inputMint=${vaultA.mint == "Gh9ZwEmdLJ8DscKNTkTqPbNwLNNBjuSzaG9Vp2KGtKJr" ? "EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v" : vaultA.mint}'
      '&outputMint=${vaultB.mint == "Gh9ZwEmdLJ8DscKNTkTqPbNwLNNBjuSzaG9Vp2KGtKJr" ? "EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v" : vaultB.mint}'
      '&amount=$amountInBaseUnits'
      '&slippageBps=50'
      '&restrictIntermediateTokens=true',
    );

    final response = await http.get(
      uri,
      headers: {
        'x-api-key': rpcUrl!,
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      return null;
    }

    final jsonDecode = json.decode(response.body);

    return (int.parse(jsonDecode['outAmount']) / pow(10, vaultB.decimals)).toStringAsFixed(vaultB.decimals);
  } catch (e) {
    return null;
  }
}