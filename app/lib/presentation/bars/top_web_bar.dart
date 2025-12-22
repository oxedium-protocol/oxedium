import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:oxedium_website/adapter/adapter.dart';
import 'package:oxedium_website/adapter/wallet_notifier.dart';
import 'package:oxedium_website/adapter/wallets/wallets.dart';
import 'package:oxedium_website/dialogs/wallet_dialog.dart';
import 'package:oxedium_website/models/tx_status.dart';
import 'package:oxedium_website/presentation/screens/staking_web_screen.dart';
import 'package:oxedium_website/presentation/screens/swap_web_screen.dart';
import 'package:oxedium_website/utils/links.dart';
import 'package:oxedium_website/widgets/circle_button.dart';
import 'package:oxedium_website/widgets/connect_wallet_button.dart';
import 'package:oxedium_website/widgets/custom_inkwell.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:js' as js;

import 'package:oxedium_website/widgets/disconnect_wallet_button.dart';

class TopWebBar extends ConsumerStatefulWidget {
  final ValueNotifier<TxStatus>? transactionStatus;

  const TopWebBar({super.key, this.transactionStatus});

  @override
  ConsumerState<TopWebBar> createState() => _TopWebBarState();
}

class _TopWebBarState extends ConsumerState<TopWebBar>
    with TickerProviderStateMixin {
  OverlayEntry? _tooltipOverlay;
  Timer? _hideTimer;
  AnimationController? _progressController;

  void _hideTooltip() {
    _tooltipOverlay?.remove();
    _tooltipOverlay = null;
  }

  @override
  void initState() {
    super.initState();
  }

  void _startHideTimer(ValueNotifier<TxStatus> status, {required int seconds}) {
    _hideTimer?.cancel();
    _progressController = AnimationController(
      vsync: this,
      duration: Duration(seconds: seconds),
    );
    _progressController?.reset();
    _progressController?.forward();

    _hideTimer = Timer(Duration(seconds: seconds), () {
      status.value = TxStatus(status: '');
    });
  }

  Future autoConnect(WalletNotifier walletNotifier) async {
    final adapter = await Adapter.getLastAdapter(adapters);
    if (adapter != null) {
      await walletNotifier.connect(adapter);
    }
  }

  @override
  Widget build(BuildContext context) {
    final wallet = ref.watch(walletProvider);
    final walletNotifier = ref.read(walletProvider.notifier);
    final isConnected = wallet?.pubkey != null;

    final currentRoute = GoRouter.of(context).state.path;

    autoConnect(walletNotifier);

    return ValueListenableBuilder<TxStatus>(
      valueListenable: widget.transactionStatus ?? ValueNotifier(TxStatus(status: '')),
      builder: (context, value, _) {
        
        final showIndicator = value.status.isNotEmpty &&
            value.status != 'Awaiting approve' &&
            value.status != 'Awaiting approval' &&
            value.status != 'Sending transaction';

        
        if (showIndicator) {
          final seconds =
              value.status == 'Success' ? 7 : 3;
          _startHideTimer(widget.transactionStatus!, seconds: seconds);
        } else {
          _progressController?.reset();
          _hideTimer?.cancel();
        }

        return ClipRect(
          child: Column(
            children: [
              Container(
                height: 60.0,
                width: MediaQuery.of(context).size.width,
                decoration: const BoxDecoration(
                  color: Colors.transparent,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // TRANSACTION STATUS
                      if (value.status.isNotEmpty)
                        CustomInkWell(
                          onTap: () async => await js.context.callMethod('open', [value.signature!]),
                          child: Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              Container(
                                height: 30.0,
                                width: 400.0,
                                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                decoration: BoxDecoration(
                                  color: Colors.grey.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.max,
                                  children: [
                                    if (value.status == "Awaiting approve" || value.status == "Sending transaction")
                                    Padding(
                                      padding: const EdgeInsets.only(right: 16.0),
                                      child: SizedBox(
                                        height: 15.0,
                                        width: 15.0,
                                        child: CircularProgressIndicator(
                                          color: Colors.orangeAccent,
                                          strokeWidth: 1.0,
                                          backgroundColor: Colors.orangeAccent.withOpacity(0.05),
                                        ),
                                      ),
                                    ),
                                    if (value.status == "Success")
                                    const Padding(
                                      padding: EdgeInsets.only(right: 16.0),
                                      child: Icon(Icons.check_circle_rounded, color: Colors.greenAccent, size: 16.0),
                                    ),
                                    Text(
                                      value.status,
                                      style: TextStyle(
                                        color: value.status == 'Success'
                                            ? Colors.greenAccent
                                            : (value.status == 'Rejected' ||
                                                    value.status == 'Error'
                                                ? Colors.red
                                                : Colors.orangeAccent),
                                        fontSize: 14.0,
                                      ),
                                    ),
                                    const Spacer(),
                                    if (value.status == "Success")
                                    const Text("view", style: TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold, color: Colors.grey))
                                  ],
                                ),
                              ),
                                      
                              // PROGRESS INDICATOR (only when needed)
                              if (showIndicator)
                                Positioned(
                                  bottom: 0,
                                  left: 0,
                                  child: AnimatedBuilder(
                                    animation: _progressController!,
                                    builder: (context, _) {
                                      final progress =
                                          1 - _progressController!.value;
                                      return Container(
                                        height: 1,
                                        width: 400 * progress,
                                        decoration: BoxDecoration(
                                          color: value.status == 'Success'
                                              ? Colors.greenAccent
                                              : (value.status == 'Rejected' ||
                                                      value.status == 'Error'
                                                  ? Colors.red
                                                  : Colors.orangeAccent),
                                          borderRadius: const BorderRadius.only(
                                            bottomRight: Radius.circular(4),
                                            bottomLeft: Radius.circular(4),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                            ],
                          ),
                        ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // LOGO
                          Row(
                            children: [
                              const Text('Oxedium', style: TextStyle(fontSize: 18.0, fontFamily: "Audiowide")),
                              const SizedBox(width: 64.0),
                              CustomInkWell(
                                onTap: () => context.go('/swap'),
                                child: Text("Swap", style: TextStyle(color: currentRoute == SwapWebScreen.routeName ? Colors.white : Theme.of(context).hintColor))),
                              const SizedBox(width: 32.0),
                              CustomInkWell(
                                onTap: () => context.go('/'),
                                child: Text("Staking", style: TextStyle(color: currentRoute == StakingWebScreen.routeName ? Colors.white : Theme.of(context).hintColor))),
                            ],
                          ),
                                  
                          // SOCIALS MEDIA & WALLET
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              CircleButton(
                                assetUrl: "assets/icons/x_icon.svg",
                                padding: 10.0,
                                onTap: () => js.context.callMethod('open', [twitterLink]),
                              ),
                              const SizedBox(width: 4.0),
                              CircleButton(
                                assetUrl: "assets/icons/doc_icon.svg",
                                padding: 10.0,
                                onTap: () => js.context.callMethod('open', [litepaperLink]),
                              ),
                              const SizedBox(width: 4.0),
                              CircleButton(
                                assetUrl: "assets/icons/github_icon.svg",
                                padding: 8.0,
                                onTap: () => js.context.callMethod('open', [repGithubLink]),
                              ),
                              const SizedBox(width: 16.0),
                              isConnected
                              ? DisconnectWalletButton(wallet: wallet!, onTap: () => walletNotifier.disconnect())
                              : ConnectWalletButton(onTap: () => showWalletDialog(context, ref)),
                            ],
                          )
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _hideTooltip();
    _hideTimer?.cancel();
    _progressController?.dispose();
    super.dispose();
  }
}
