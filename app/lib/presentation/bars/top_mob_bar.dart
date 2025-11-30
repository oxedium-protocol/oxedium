import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:oxedium_website/adapter/wallet_notifier.dart';
import 'package:oxedium_website/dialogs/wallet_dialog.dart';
import 'package:oxedium_website/utils/extensions.dart';
import 'package:oxedium_website/widgets/connect_wallet_button.dart';
import 'package:oxedium_website/widgets/custom_inkwell.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TopMobBar extends ConsumerStatefulWidget {
  const TopMobBar({super.key});

  @override
  ConsumerState<TopMobBar> createState() => _TopMobBarState();
}

class _TopMobBarState extends ConsumerState<TopMobBar> {
  OverlayEntry? _tooltipOverlay;

  void _hideTooltip() {
    _tooltipOverlay?.remove();
    _tooltipOverlay = null;
  }

  @override
  Widget build(BuildContext context) {
    final wallet = ref.watch(walletProvider);
    final walletNotifier = ref.read(walletProvider.notifier);
    final isConnected = wallet?.pubkey != null;

    return Container(
      height: 60.0,
      width: MediaQuery.of(context).size.width,
      decoration:
          BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              children: [
                SvgPicture.asset('assets/logos/oxe_logo.svg',
                    height: 25.0, width: 25.0),
                const SizedBox(width: 16.0),
                const Text('Tyrbine', style: TextStyle(fontSize: 18.0)),
              ],
            ),
            isConnected
                ? CustomInkWell(
                    onTap: () => walletNotifier.disconnect(),
                    child: Container(
                      height: 30.0,
                      width: 120.0,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(5.0)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(wallet!.pubkey!.cutText(start: 2, end: 7),
                              style: const TextStyle(
                                  color: Colors.redAccent, fontSize: 15.0)),
                          const SizedBox(width: 8.0),
                          const Icon(Icons.power_settings_new,
                              size: 18.0, color: Colors.redAccent)
                        ],
                      ),
                    ),
                  )
                : ConnectWalletButton(onTap: () => showWalletDialog(context, ref))
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _hideTooltip();
    super.dispose();
  }
}
