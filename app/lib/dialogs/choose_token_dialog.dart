import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oxedium_website/models/stats.dart';
import 'package:oxedium_website/presentation/screens/home_mob_screen.dart';
import 'package:oxedium_website/presentation/screens/home_web_screen.dart';
import 'package:oxedium_website/widgets/custom_inkwell.dart';
import 'package:oxedium_website/widgets/mini_button.dart';

void chooseTokenDialog(BuildContext context, WidgetRef ref, List<Vault> vaults, {bool? isMob}) {
  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            child: Container(
              height: 450.0,
              width: 384.0,
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(10.0),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Text("Choose token"),
                        MiniButton(text: "Esc", onTap: () => Navigator.of(context).pop())
                      ],
                    ),
                  ),
                  Expanded(
                      child: ListView.builder(
                      itemCount: vaults.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                          child: CustomInkWell(
                            onTap: () => Navigator.push(
                                context,
                                PageRouteBuilder(
                                  pageBuilder: (context, animation, secondaryAnimation) {
                                    if (isMob != null && isMob) {
                                      return HomeMobScreen(vaultMint: vaults[index].mint);
                                    }
                                    return HomeWebScreen(vaultMint: vaults[index].mint);
                                  },
                                  transitionDuration: Duration.zero,
                                  reverseTransitionDuration: Duration.zero,
                                ),
                              ),
                            child: Container(
                              height: 70.0,
                              width: MediaQuery.of(context).size.width,
                              padding: const EdgeInsets.all(8.0),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(5.0),
                                border: Border.all(color: Colors.grey.withOpacity(0.5))
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Image.network(vaults[index].logoUrl, height: 21.0, width: 21.0),
                                          const SizedBox(width: 8.0),
                                          Text(vaults[index].symbol),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          Text('TVL: ${vaults[index].tvl} ${vaults[index].symbol}', style: const TextStyle(color: Colors.grey, fontSize: 12.0))
                                        ],
                                      ),
                                    ],
                                  ),
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text('${vaults[index].apr}%', style: TextStyle(color: Colors.greenAccent.shade700)),
                                      const Text('APR', style: TextStyle(color: Colors.grey, fontSize: 12.0))
                                    ],
                                  )
                                ],
                              ),
                            ),
                          ),
                        );
                    }),
                  )
                ],
              ),
            ),
          );
        },
      );
    },
  );
}
