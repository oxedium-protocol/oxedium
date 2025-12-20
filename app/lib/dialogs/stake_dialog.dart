import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oxedium_website/adapter/adapter.dart';
import 'package:oxedium_website/bl/claim.dart';
import 'package:oxedium_website/bl/unstaking.dart';
import 'package:oxedium_website/models/staked.dart';
import 'package:oxedium_website/models/tx_status.dart';
import 'package:oxedium_website/models/stats.dart';
import 'package:oxedium_website/presentation/screens/staking_mob_screen.dart';
import 'package:oxedium_website/presentation/screens/staking_web_screen.dart';
import 'package:oxedium_website/widgets/custom_inkwell.dart';
import 'package:oxedium_website/widgets/mini_button.dart';
import 'package:oxedium_website/widgets/staked_earned_bar.dart';
import 'package:oxedium_website/widgets/toggle_button.dart';

void showStakeDialog(BuildContext context, WidgetRef ref, Staked stake,
    List<Vault> vaultsData, Adapter adapter,
    {required ValueNotifier<TxStatus> status, bool? isMob}) {
  Navigator.maybePop(context);

  showDialog(
    context: context,
    builder: (BuildContext context) {
      TextEditingController unstakeController = TextEditingController();
      bool showUnstakeField = false;

      return StatefulBuilder(
        builder: (context, setState) {
          return Center(
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: 384.0,
                height: showUnstakeField ? 380.0 : 252.0,
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(10.0),
                  border: Border.all(color: Colors.grey.withOpacity(0.2)),
                ),
                padding: const EdgeInsets.only(
                    top: 8.0, left: 16.0, right: 16.0, bottom: 16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8.0),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.grey.withOpacity(0.05),
                                border: Border.all(
                                    color: Colors.grey.withOpacity(0.05)),
                              ),
                              child: Image.network(
                                stake.logoUrl,
                                width: 22.0,
                                height: 22.0,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(Icons.error),
                              ),
                            ),
                            const SizedBox(width: 16.0),
                            Text(stake.symbol),
                          ],
                        ),
                        MiniButton(text: "Esc", onTap: () => Navigator.of(context).pop())
                      ],
                    ),

                    const SizedBox(height: 8.0),

                    /// Info
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              height: 10.0,
                              width: 10.0,
                              color: Colors.deepPurpleAccent.withOpacity(0.2),
                            ),
                            const SizedBox(width: 8.0),
                            Text('Staked',
                                style: TextStyle(
                                    color: Colors.grey.shade700,
                                    fontSize: 15.0)),
                            const SizedBox(width: 8.0),
                            Text(stake.uiAmount,
                                style: const TextStyle(fontSize: 15.0)),
                            const SizedBox(width: 8.0),
                            Text(stake.symbol,
                                style: const TextStyle(fontSize: 15.0)),
                          ],
                        ),
                        Row(
                          children: [
                            Container(
                              height: 10.0,
                              width: 10.0,
                              color: Colors.amber.withOpacity(0.4),
                            ),
                            const SizedBox(width: 8.0),
                            Text('Earned',
                                style: TextStyle(
                                    color: Colors.grey.shade700,
                                    fontSize: 15.0)),
                            const SizedBox(width: 8.0),
                            Text(stake.earned.toString(),
                                style: const TextStyle(fontSize: 15.0)),
                            const SizedBox(width: 8.0),
                            Text(stake.symbol,
                                style: const TextStyle(fontSize: 15.0)),
                          ],
                        ),
                      ],
                    ),

                    StakedEarnedBar(staked: double.parse(stake.uiAmount), earned: stake.earned),

                    /// Action buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        /// +
                        ToggleButton(
                          isActive: false,
                          activeColor: Colors.greenAccent,
                          onTap: () => Navigator.push(
                            context,
                            PageRouteBuilder(
                              pageBuilder:
                                  (context, animation, secondaryAnimation) {
                                if (isMob != null && isMob) {
                                  return StakingMobScreen(vaultMint: stake.mint);
                                }
                                return StakingWebScreen(vaultMint: stake.mint);
                              },
                              transitionDuration: Duration.zero,
                              reverseTransitionDuration: Duration.zero,
                            ),
                          ),
                          text: "+",
                        ),

                        const SizedBox(width: 16.0),

                        /// -
                        ToggleButton(
                          isActive: showUnstakeField,
                          activeColor: Colors.red,
                          onTap: () {
                            setState(() {
                              showUnstakeField = !showUnstakeField;
                            });
                          },
                          text: "-",
                        ),

                        const SizedBox(width: 16.0),

                        /// Claim
                        Expanded(
                          child: ToggleButton(
                            isActive: false,
                            activeColor: Colors.amber,
                            fontWeight: FontWeight.normal,
                            onTap: () {
                              if (showUnstakeField) {
                                setState(() {
                                  showUnstakeField = false;
                                });
                              }
                              claim(
                                context,
                                ref,
                                adapter: adapter,
                                status: status,
                                mint: stake.mint,
                                vaultsData: vaultsData,
                              );
                              Navigator.of(context).pop();
                            },
                            text: "Claim",
                          ),
                        ),
                      ],
                    ),

                    /// Unstake field & button
                    if (showUnstakeField) ...[
                      const SizedBox(height: 20.0),
                      TextField(
                        controller: unstakeController,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                        ],
                        decoration: InputDecoration(
                          hintText: 'Enter amount to unstake',
                          hintStyle: TextStyle(color: Colors.grey.shade800),
                          suffixIcon: Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: CustomInkWell(
                              onTap: () =>
                                  unstakeController.text = stake.uiAmount,
                              child: Container(
                                  height: 35.0,
                                  width: 50.0,
                                  alignment: Alignment.center,
                                  child: const Text('max',
                                      style: TextStyle(color: Colors.grey))),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.0),
                            borderSide: BorderSide(
                                color: Colors.grey.shade800, width: 1.0),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.0),
                            borderSide: BorderSide(
                                color: Colors.grey.shade600, width: 1.0),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12.0, vertical: 8.0),
                        ),
                      ),
                      const SizedBox(height: 12.0),
                      CustomInkWell(
                        onTap: () {
                          final amount = unstakeController.text.trim();
                          if (amount.isNotEmpty) {
                            unstaking(context, ref,
                                adapter: adapter,
                                stake: stake,
                                status: status,
                                vaultsData: vaultsData,
                                amountText: unstakeController.text);
                            Navigator.of(context).pop();
                          }
                        },
                        child: Container(
                          height: 40.0,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.redAccent,
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          child: const Text(
                            'Unstaking',
                            style: TextStyle(
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
}
