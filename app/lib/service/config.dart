import 'package:oxedium_website/main.dart';
import 'package:solana/solana.dart';

class SolanaConfig {
  // mainnet, devnet
  static String cluster = "mainnet-beta";
  static String rpc = "https://mainnet.helius-rpc.com/?api-key=$HELIUS_API";
  static String wss = "wss://mainnet.helius-rpc.com/?api-key=$HELIUS_API";
  //static String rpc = "https://devnet.helius-rpc.com/?api-key=$HELIUS_API";
  //static String wss = "wss://devnet.helius-rpc.com/?api-key=$HELIUS_API";
}

final SolanaClient solanaClient = SolanaClient(
    rpcUrl: Uri.parse(SolanaConfig.rpc),
    websocketUrl: Uri.parse(SolanaConfig.wss));
