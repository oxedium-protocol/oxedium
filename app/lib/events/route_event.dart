import 'dart:convert';
import 'package:fixnum/fixnum.dart';
import 'package:solana/solana.dart';

class RouteEvent {
  final Ed25519HDPublicKey user;
  final int feeBps;
  final Ed25519HDPublicKey tokenIn;
  final Ed25519HDPublicKey tokenOut;
  final int amountIn;
  final int amountOut;
  final int priceIn;
  final int priceOut;
  final int decimalsIn;
  final int decimalsOut;
  final int lpFee;
  final int protocolFee;
  final int partnerFee;
  final int timestamp;

  RouteEvent({
    required this.user,
    required this.feeBps,
    required this.tokenIn,
    required this.tokenOut,
    required this.amountIn,
    required this.amountOut,
    required this.priceIn,
    required this.priceOut,
    required this.decimalsIn,
    required this.decimalsOut,
    required this.lpFee,
    required this.protocolFee,
    required this.partnerFee,
    required this.timestamp,
  });

  factory RouteEvent.fromBase64(String base64Data) {
    final bytes = base64.decode(base64Data);

    final data = bytes.sublist(8);

    int offset = 0;

    Ed25519HDPublicKey readPubkey() {
      final result = Ed25519HDPublicKey(data.sublist(offset, offset + 32));
      offset += 32;
      return result;
    }

    int readU64() {
      final slice = data.sublist(offset, offset + 8);
      offset += 8;
      return Int64.fromBytes(slice).toInt();
    }

    int readI64() {
      final slice = data.sublist(offset, offset + 8);
      offset += 8;
      return Int64.fromBytes(slice).toInt();
    }

    int readU8() {
      final slice = data.sublist(offset, offset + 1);
      offset += 1;
      return slice[0];
    }

    return RouteEvent(
      user: readPubkey(),
      feeBps: readU64(),
      tokenIn: readPubkey(),
      tokenOut: readPubkey(),
      amountIn: readU64(),
      amountOut: readU64(),
      priceIn: readU64(),
      priceOut: readU64(),
      decimalsIn: readU8(),
      decimalsOut: readU8(),
      lpFee: readU64(),
      protocolFee: readU64(),
      partnerFee: readU64(),
      timestamp: readI64(),
    );
  }

  toJson() => {
  'user': user,
  'feeBps': feeBps,
  'amountIn': amountIn,
  'amountOut': amountOut,
  'priceIn': priceIn,
  'priceOut': priceOut,
  'lpFee': lpFee,
  'protocolFee': protocolFee,
  'partnerFee': partnerFee,
  'timestamp': timestamp
};

}
