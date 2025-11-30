import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:solana/solana.dart';
import 'package:oxedium_website/service/config.dart';

class HeliusApi {

  static const Map<Commitment, int> _statusPriority = {
    Commitment.processed: 1,
    Commitment.confirmed: 2,
    Commitment.finalized: 3,
  };

  static Future<void> waitingSignatureStatus({
    required String signature,
    required Commitment expectedStatus,
    int? duration,
  }) async {
    duration ??= 30;
    final int maxTimeMillis = duration * 1000;
    int elapsedTime = 0;
    const int interval = 1000;

    while (elapsedTime < maxTimeMillis) {
      final response = await http.post(
        Uri.parse(SolanaConfig.rpc),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          "jsonrpc": "2.0",
          "id": "1",
          "method": "getSignatureStatuses",
          "params": [
            [signature],
            {"searchTransactionHistory": true}
          ]
        }),
      );

      if (response.statusCode != 200) {
        throw Exception("[Helius API] - Error during transaction status request");
      }

      final result = json.decode(response.body)['result']['value'][0];
      final String? statusStr = result?['confirmationStatus'];

      if (statusStr != null) {
        final Commitment? currentStatus = _stringToCommitment(statusStr);

        if (currentStatus != null) {
          if (_statusPriority[currentStatus]! >= _statusPriority[expectedStatus]!) {
            return;
          }
        }
      }

      await Future.delayed(const Duration(milliseconds: interval));
      elapsedTime += interval;
    }

    throw Exception(
        "[Helius API] - Transaction did not reach expected status in time");
  }

  static Commitment? _stringToCommitment(String status) {
    switch (status) {
      case 'processed':
        return Commitment.processed;
      case 'confirmed':
        return Commitment.confirmed;
      case 'finalized':
        return Commitment.finalized;
      default:
        return null;
    }
  }
}