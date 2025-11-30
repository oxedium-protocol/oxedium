import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oxedium_website/metadata/vaults.dart';
import 'package:oxedium_website/models/user_balance.dart';
import 'package:oxedium_website/service/custom_api.dart';

final userBalanceNotifierProvider =
    AsyncNotifierProviderFamily<UserBalanceNotifier, List<UserBalance>, String>(
  () => UserBalanceNotifier(),
);

class UserBalanceNotifier
    extends FamilyAsyncNotifier<List<UserBalance>, String> {
  @override
  Future<List<UserBalance>> build(String address) async {
    if (address.isEmpty) {
      return [];
    }
    return await getUserBalance(address);
  }

  Future<void> loadBalances(String address) async {
    state = const AsyncValue.loading();
    try {
      final balances = await getUserBalance(address);
      state = AsyncValue.data(balances);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

Future<List<UserBalance>> getUserBalance(String address) async {
  final mints = vaultsData.values.map((v) => v.mint).toList();
  final balances = await CustomApi.getBalance(address: address, mints: mints);
  return balances;
}
