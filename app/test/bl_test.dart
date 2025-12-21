import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oxedium_website/bl/get_route.dart';
import 'package:oxedium_website/bl/get_stats.dart';
import 'package:oxedium_website/metadata/vaults.dart';
import 'package:oxedium_website/models/stats.dart';

void main() {

  test('get stat', () async {
    final Stats? stats = await getStats();
    debugPrint(stats?.usdTreasuryBalance.toString());
});
  
test('get jupiter route', () async {
    final r = await getJupiterRoute(vaultA: vaultsData.values.first, vaultB: vaultsData.values.last, amountText: "1.1");
    print(r);
});

}