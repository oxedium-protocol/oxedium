@JS('walletModule')
library wallet_module;

import 'package:js/js.dart';

@JS('isInstalled')
external bool isInstalled(wallet);

@JS('connect')
external Future<void> connect(wallet);

@JS('address')
external String address();

@JS('disconnect')
external void disconnect(wallet);

@JS('sendTransaction')
external Future<dynamic> sendTransaction(wallet, tx);
