import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oxedium_website/adapter/wallet_notifier.dart';
import 'package:oxedium_website/adapter/wallets/wallets.dart';
import 'package:oxedium_website/widgets/custom_inkwell.dart';

void showWalletDialog(BuildContext context, WidgetRef ref) {
  Navigator.maybePop(context);
  final wallets = ref.read(walletAdaptersProvider);
  final walletNotifier = ref.read(walletProvider.notifier);

  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (BuildContext context) {
      String? hoveredWalletName;

      return StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            child: Container(
              height: 330.0,
              width: 290.0,
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                border: Border.all(
                  color: Colors.grey.withOpacity(0.2),
                  width: 1.0,
                ),
                borderRadius: BorderRadius.circular(20.0),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Text("Connect wallet"),
                  ),
                  Container(
                    height: 1.0,
                    width: MediaQuery.of(context).size.width,
                    color: Colors.grey.withOpacity(0.2),
                  ),
                  Wrap(
                    runSpacing: -8.0,
                    children: wallets.map((wallet) {
                      final isHovered = hoveredWalletName == wallet.name;
                      return MouseRegion(
                        onEnter: (_) => setState(() => hoveredWalletName = wallet.name),
                        onExit: (_) => setState(() => hoveredWalletName = null),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.all(8.0),
                            decoration: BoxDecoration(
                              color: isHovered
                                  ? Colors.grey.withOpacity(0.05)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(15.0),
                            ),
                            child: CustomInkWell(
                              onTap: () {
                                Navigator.of(context).pop();
                                walletNotifier.connect(wallet);
                              },
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(10.0),
                                    child: Image.asset(wallet.logoUrl,
                                        height: 40.0, width: 40.0),
                                  ),
                                  const SizedBox(width: 16.0),
                                  Text(wallet.name),
                                  wallet.name == "Phantom"
                                      ? const Row(
                                          children: [
                                            SizedBox(width: 16.0),
                                            Text(
                                              "⋅ recommend",
                                              style: TextStyle(
                                                fontFamily: "",
                                                color: Colors.greenAccent,
                                                fontSize: 12.0,
                                              ),
                                            )
                                          ],
                                        )
                                      : const SizedBox(),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 8.0, horizontal: 16.0),
                      alignment: Alignment.bottomCenter,
                      child: CustomInkWell(
                        onTap: () {},
                        child: Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                  text:
                                      "By connecting the wallet, you confirm that you agree to the ",
                                  style: TextStyle(
                                      fontSize: 12.0,
                                      color: Colors.grey.withOpacity(0.5))),
                              const TextSpan(
                                  text: "terms of use.",
                                  style: TextStyle(
                                      fontSize: 12.0, color: Color(0xFF6A5D7B)))
                            ],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
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

