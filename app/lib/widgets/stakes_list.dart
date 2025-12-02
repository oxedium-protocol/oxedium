import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oxedium_website/adapter/wallet_notifier.dart';
import 'package:oxedium_website/dialogs/stake_dialog.dart';
import 'package:oxedium_website/models/staked.dart';
import 'package:oxedium_website/models/tx_status.dart';
import 'package:oxedium_website/models/stats.dart';
import 'package:oxedium_website/widgets/custom_inkwell.dart';

class StakesList extends ConsumerStatefulWidget {
  final List<Staked> stakes;
  final ValueNotifier<TxStatus>? transactionStatus;
  final List<Vault> vaultsData;

  const StakesList({super.key, required this.stakes, this.transactionStatus, required this.vaultsData});

  @override
  ConsumerState<StakesList> createState() => _StakesListState();
}

class _StakesListState extends ConsumerState<StakesList> {
  @override
  Widget build(BuildContext context) {
    final wallet = ref.watch(walletProvider);
    return Column(
      children: widget.stakes.map((stake) {
        return Card(
          shadowColor: Colors.transparent,
          color: Colors.transparent,
          elevation: 3,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.only(left: 14.0, right: 14.0, bottom: 8.0),
            child: Container(
              padding: const EdgeInsets.only(top: 8.0, right: 8.0, left: 8.0, bottom: 8.0),
              constraints: const BoxConstraints(
                maxWidth: 400,
              ),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10.0)
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 12.0),
                        child: Container(
                          padding: const EdgeInsets.all(8.0),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.grey.withOpacity(0.05)
                          ),
                          child: Image.network(
                                      stake.logoUrl,
                                      width: 22.0,
                                      height: 22.0,
                                      errorBuilder: (context, error, stackTrace) =>
                                          const Icon(Icons.error),
                                    ),
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                            'Staked',
                            style: TextStyle(color: Colors.grey.shade700, fontSize: 15.0),
                          ),
                              const SizedBox(width: 8.0),
                              Text(stake.uiAmount, style: const TextStyle(fontSize: 15.0)),
                              const SizedBox(width: 8.0),
                              Text(stake.symbol, style: const TextStyle(fontSize: 15.0)),
                            ],
                          ),
                          Row(
                            children: [
                              Text(
                            'Earned',
                            style: TextStyle(color: Colors.grey.shade700, fontSize: 15.0),
                          ),
                              const SizedBox(width: 8.0),
                              Text(stake.earned.toString(), style: const TextStyle(fontSize: 15.0)),
                              const SizedBox(width: 8.0),
                              Text(stake.symbol, style: const TextStyle(fontSize: 15.0)),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                  CustomInkWell(
                    onTap: () => showStakeDialog(context, ref, stake, widget.vaultsData, status: widget.transactionStatus!, wallet!),
                    child: Container(
                      height: 35.0,
                      width: 35.0,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.grey.withOpacity(0.05)
                      ),
                      child: Icon(Icons.more_vert, color: Colors.grey.shade800),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
