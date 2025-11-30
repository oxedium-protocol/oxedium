import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oxedium_website/adapter/adapter.dart';

class WalletNotifier extends StateNotifier<Adapter?> {
  WalletNotifier() : super(null);

  Future<bool> connect(Adapter adapter) async {

    final connected = await adapter.connect();
    if (connected) {
      state = adapter;
    }
    return connected;
  }

  Future<void> disconnect() async {
    if (state != null) {
      await state!.disconnect();
      state = null;
    }
  }
}

final walletProvider = StateNotifierProvider<WalletNotifier, Adapter?>(
  (ref) => WalletNotifier(),
);
