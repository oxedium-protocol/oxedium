import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oxedium_website/adapter/adapter.dart';

final adapters = [
    // Adapter(
    //     name: "Jupiter",
    //     logoUrl: "assets/logos/jupiter.png",
    //     website: "https://jup.ag/download"),
    Adapter(
        name: "Phantom",
        logoUrl: "assets/logos/phantom.png",
        website: "https://phantom.app/download"),
    Adapter(
        name: "Backpack",
        logoUrl: "assets/logos/backpack.png",
        website: "https://backpack.app/download"),
    Adapter(
        name: "Solflare",
        logoUrl: "assets/logos/solflare.png",
        website: "https://solflare.com"),
];

final walletAdaptersProvider = Provider<List<Adapter>>((ref) {
  return adapters;
});
