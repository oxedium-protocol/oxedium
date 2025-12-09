@JS('walletModule')
library wallet_module;

import 'dart:js_interop';

import 'package:js/js.dart';

@JS('isInstalled')
external bool isInstalled(wallet);

@JS('connect')
external JSPromise connect(wallet);

@JS('address')
external String address();

@JS('disconnect')
external void disconnect(wallet);

@JS('sendTransaction')
external JSPromise<JSString> sendTransaction(wallet, tx);
