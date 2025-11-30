import 'dart:typed_data';
import 'package:js/js_util.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:oxedium_website/adapter/wallet_module.dart' as wallet_module;
import 'package:url_launcher/url_launcher.dart';

class Adapter {
  final String name;
  final String logoUrl;
  final String website;
  String? _pubkey;

  Adapter({required this.name, required this.logoUrl, required this.website});

  String? get pubkey => _pubkey;

  static const _keyAutoConnect = 'wallet_autoconnect';

  Future<void> _saveAutoConnectFlag() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyAutoConnect, name.toLowerCase());
  }

  static Future<String?> loadAutoConnectWallet() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyAutoConnect);
  }

  Future<void> _clearAutoConnectFlag() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyAutoConnect);
  }

  static Future<Adapter?> getLastAdapter(List<Adapter> adapters) async {
    final saved = await Adapter.loadAutoConnectWallet();

    final adapter = adapters.firstWhere((a) => a.name.toLowerCase() == saved);

    return adapter;
  }

  Future<bool> connect() async {
    if (!wallet_module.isInstalled(name.toLowerCase())) {
      await launchUrl(Uri.parse(website));
      return false;
    }

    await promiseToFuture(wallet_module.connect(name.toLowerCase()));

    if (wallet_module.address().isEmpty) {
      return false;
    }

    _pubkey = wallet_module.address();

    await _saveAutoConnectFlag();

    return _pubkey != null;
  }

  Future<void> disconnect() async {
    wallet_module.disconnect(name.toLowerCase());
    _pubkey = null;
    await _clearAutoConnectFlag();
  }

  Future<String> signAndSendTransaction(Uint8List transaction) async {
    var signature = await promiseToFuture(
        wallet_module.sendTransaction(name.toLowerCase(), transaction));
    return signature;
  }
}
