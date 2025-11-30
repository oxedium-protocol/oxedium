import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oxedium_website/bl/get_stats.dart';
import 'package:oxedium_website/models/stats.dart';

void main() {

  test('get stat', () async {
    final Stats? stats = await getStats();
    debugPrint(stats?.usdTreasuryBalance.toString());
});
  
// test('get staker', () async {
//     final List<Staked> staked = await getStaker(owner: 'Cy89hxcHCuZhyR8Hjc5AZVcsiNXtFXynf4wDHSi7QsTC', vaultsData: vaultsData);
//     for (var stake in staked) {
//       print("${stake.symbol}: ${stake.earned.trimTo(stake.decimals)}");
//     }
// });

}