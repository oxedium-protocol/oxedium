import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oxedium_website/adapter/wallet_notifier.dart';
import 'package:oxedium_website/bl/get_stats.dart';
import 'package:oxedium_website/bl/get_user_balance.dart';
import 'package:oxedium_website/bl/get_route.dart';
import 'package:oxedium_website/bl/swap.dart';
import 'package:oxedium_website/dialogs/choose_swap_token_dialog.dart';
import 'package:oxedium_website/dialogs/wallet_dialog.dart';
import 'package:oxedium_website/metadata/vaults.dart';
import 'package:oxedium_website/models/stats.dart';
import 'package:oxedium_website/models/tx_status.dart';
import 'package:oxedium_website/models/user_balance.dart';
import 'package:oxedium_website/presentation/bars/top_web_bar.dart';
import 'package:oxedium_website/utils/extensions.dart';
import 'package:oxedium_website/widgets/custom_inkwell.dart';
import 'package:oxedium_website/widgets/mini_button.dart';
import 'package:oxedium_website/widgets/stars_progress_indicator.dart';

class SwapWebScreen extends ConsumerStatefulWidget {
  const SwapWebScreen({super.key});
  static const routeName = '/swap';

  @override
  ConsumerState<SwapWebScreen> createState() => _SwapWebScreenState();
}

class _SwapWebScreenState extends ConsumerState<SwapWebScreen> {
  final transactionStatus = ValueNotifier<TxStatus>(TxStatus(status: ''));
  late final TopWebBar topWebBar;

  Vault inputToken = vaultsData.values.elementAt(0);
  Vault outputToken = vaultsData.values.elementAt(1);
  bool isPriceLoading = false;

  final TextEditingController _inputTokenAmountController =
      TextEditingController();
  final TextEditingController _outputTokenAmountController =
      TextEditingController();

  final ValueNotifier<bool> isQuoteLoading = ValueNotifier(false);
  Timer? _debounce;

  double _bestPriceOxedium = 0.0;
  double _bestPriceJupiter = 0.0;
  double _bestPrice = 0.0;

  @override
  void initState() {
    topWebBar = TopWebBar(transactionStatus: transactionStatus);
    super.initState();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _inputTokenAmountController.dispose();
    _outputTokenAmountController.dispose();
    isQuoteLoading.dispose();
    super.dispose();
  }

  Future<void> getSwapRoute(
      String amount, Vault inputToken, Vault outputToken) async {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    if (amount.isEmpty) {
      _outputTokenAmountController.clear();
      setState(() => isPriceLoading = false);
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 500), () async {
      isQuoteLoading.value = true;

      try {
        final oxediumRoute = await getRoute(
          vaultA: inputToken,
          vaultB: outputToken,
          amountText: amount,
        );

        final jupiterRoute = await getJupiterRoute(
          vaultA: inputToken,
          vaultB: outputToken,
          amountText: amount,
        );

        double oxediumPrice = 0.0;
        if (oxediumRoute != null) {
          oxediumPrice =
              oxediumRoute.amountOut / pow(10, oxediumRoute.decimalsOut);
          _outputTokenAmountController.text =
              oxediumPrice.toStringAsFixed(oxediumRoute.decimalsOut);
        } else {
          _outputTokenAmountController.clear();
        }

        double jupiterPrice = double.parse(jupiterRoute!);

        double bestPrice = max(oxediumPrice, jupiterPrice);

        setState(() {
          isPriceLoading = true;
          _bestPriceOxedium = oxediumPrice;
          _bestPriceJupiter = jupiterPrice;
          _bestPrice = bestPrice;
        });
      } catch (_) {
        _outputTokenAmountController.clear();
      } finally {
        isQuoteLoading.value = false;
      }
    });
  }

  Widget _buildPriceRow(String name, double price, {bool isBest = false}) {
    return Container(
      height: 45.0,
      padding: const EdgeInsets.only(left: 4.0, right: 8.0),
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10.0),
          border: Border.all(color: Theme.of(context).cardColor)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            children: [
              SizedBox(
                  width: 40.0,
                  child: Image.asset("assets/icons/${name.toLowerCase()}.png",
                      height: 21.0)),
              const SizedBox(width: 2.0),
              Text(name),
              if (isBest)
                Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: Container(
                    height: 20.0,
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                        border: Border.all(color: Colors.deepPurpleAccent),
                        borderRadius: BorderRadius.circular(5.0),
                        color: Theme.of(context).hintColor.withOpacity(0.1)),
                    child: const Text("best price",
                        style: TextStyle(
                            fontSize: 12.0, color: Colors.deepPurpleAccent)),
                  ),
                )
            ],
          ),
          Text(price.toStringAsFixed(2))
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final wallet = ref.watch(walletProvider);
    final isConnected = wallet?.pubkey != null;
    final vaultsAsync = ref.watch(statsProvider);

    return Scaffold(
      body: vaultsAsync.when(
        data: (stat) {
          return SizedBox(
            width: MediaQuery.of(context).size.width,
            child: Stack(
              alignment: Alignment.topCenter,
              children: [
                SizedBox(
                  width: double.infinity,
                  height: double.infinity,
                  child: Transform.scale(
                    scaleX: 2.5,
                    scaleY: 1.0,
                    alignment: Alignment.topRight,
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: RadialGradient(
                          center: Alignment.topRight,
                          radius: 0.5,
                          colors: [
                            Color.fromRGBO(42, 42, 56, 0.4),
                            Color.fromRGBO(42, 42, 56, 0.0),
                          ],
                          stops: [0.0, 0.8],
                        ),
                      ),
                    ),
                  ),
                ),
                SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: 75.0),
                      // --- Swap Cards ---
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Column(
                            children: [
                              // Sell Card
                              _buildTokenCard(
                                  context, _inputTokenAmountController, true),
                              const SizedBox(height: 8.0),
                              // Buy Card
                              _buildTokenCard(
                                  context, _outputTokenAmountController, false),
                            ],
                          ),
                          // Swap Button in middle
                          CustomInkWell(
                            onTap: () {
                              final token = outputToken;
                              outputToken = inputToken;
                              inputToken = token;
                              _inputTokenAmountController.clear();
                              _outputTokenAmountController.clear();
                              setState(() {});
                            },
                            child: Container(
                              height: 45.0,
                              width: 45.0,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Theme.of(context).cardColor,
                                  border: Border.all(
                                      color: Theme.of(context)
                                          .scaffoldBackgroundColor,
                                      width: 4.0)),
                              child: Icon(Icons.swap_vert_rounded,
                                  color: Theme.of(context).hintColor),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16.0),
                      // Swap / Connect button
                      ValueListenableBuilder<bool>(
                        valueListenable: isQuoteLoading,
                        builder: (context, loading, _) {
                          return SizedBox(
                            width: 400.0,
                            height: 42.0,
                            child: ElevatedButton(
                              onPressed: isConnected
                                  ? (loading
                                      ? null
                                      : () async {
                                          await swap(context, ref,
                                              adapter: wallet!,
                                              vaultA: inputToken,
                                              vaultB: outputToken,
                                              status: transactionStatus,
                                              amountText:
                                                  _inputTokenAmountController
                                                      .text);
                                        })
                                  : () => showWalletDialog(context, ref),
                              style: ElevatedButton.styleFrom(
                                shadowColor: Colors.transparent,
                                overlayColor: Colors.transparent,
                                backgroundColor: isConnected
                                    ? Colors.white
                                    : Colors.grey.shade300,
                                disabledBackgroundColor: Colors.grey.shade400,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(50.0),
                                ),
                              ),
                              child: loading
                                  ? const SizedBox(
                                      width: 22.0,
                                      height: 22.0,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.black,
                                      ),
                                    )
                                  : Text(
                                      isConnected ? "Swap" : "Connect wallet",
                                      style: const TextStyle(
                                          fontSize: 17.0, color: Colors.black),
                                    ),
                            ),
                          );
                        },
                      ),
                      // Best Price Block
                      if (isPriceLoading)
                        Padding(
                          padding: const EdgeInsets.only(top: 16.0),
                          child: Container(
                            width: 400.0,
                            padding: const EdgeInsets.all(8.0),
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10.0),
                                border: Border.all(
                                    color: Theme.of(context).cardColor)),
                            child: Column(
                              children: [
                                if (_bestPrice == _bestPriceOxedium) ...[
                                  _buildPriceRow("Oxedium", _bestPriceOxedium,
                                      isBest: true),
                                  const SizedBox(height: 8.0),
                                  _buildPriceRow("Jupiter", _bestPriceJupiter,
                                      isBest: false),
                                ] else ...[
                                  _buildPriceRow("Jupiter", _bestPriceJupiter,
                                      isBest: true),
                                  const SizedBox(height: 8.0),
                                  _buildPriceRow("Oxedium", _bestPriceOxedium,
                                      isBest: false),
                                ]
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Positioned(top: 0, left: 0, right: 0, child: topWebBar),
              ],
            ),
          );
        },
        loading: () => const Center(child: StarsProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildTokenCard(
      BuildContext context, TextEditingController controller, bool isInput) {
    final vault = isInput ? inputToken : outputToken;
    final title = isInput ? 'Sell' : 'Buy';

    return Container(
      height: 120.0,
      width: 400.0,
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: Container(
        height: 100.0,
        padding: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor,
          borderRadius: BorderRadius.circular(10.0),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title,
                    style: TextStyle(color: Theme.of(context).hintColor)),
                isInput
                    ? Consumer(
                        builder: (context, ref, _) {
                          final wallet = ref.watch(walletProvider);
                          if (wallet?.pubkey == null) {
                            return const SizedBox.shrink();
                          }

                          final userBalancesAsync = ref.watch(
                              userBalanceNotifierProvider(wallet!.pubkey!));

                          return userBalancesAsync.when(
                            data: (balances) {
                              final vaultBalance = balances
                                  .firstWhere((b) => b.mint == vault.mint,
                                      orElse: () => UserBalance(
                                          mint: vault.mint, amount: 0))
                                  .amount;

                              return Row(
                                children: [
                                  Icon(Icons.account_balance_wallet_outlined,
                                      color: Theme.of(context).hintColor,
                                      size: 16.0),
                                  const SizedBox(width: 8.0),
                                  Text(
                                      "${vaultBalance.formatBalance()} ${vault.symbol}",
                                      style: TextStyle(
                                          fontSize: 14.0,
                                          color: Theme.of(context).hintColor)),
                                  const SizedBox(width: 8.0),
                                  MiniButton(
                                    text: "max",
                                    onTap: () async {
                                      final vb = vault.mint ==
                                              'So11111111111111111111111111111111111111112'
                                          ? (vaultBalance - 0.006)
                                              .toStringAsFixed(vault.decimals)
                                          : vaultBalance
                                              .toStringAsFixed(vault.decimals);
                                      controller.text = vb;
                                      await getSwapRoute(
                                          vb, inputToken, outputToken);
                                    },
                                  ),
                                ],
                              );
                            },
                            loading: () => const SizedBox(),
                            error: (e, _) => Text('Error loading balance: $e'),
                          );
                        },
                      )
                    : const SizedBox.shrink(),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 4.0),
                    child: TextField(
                      controller: controller,
                      onChanged: (value) async {
                        if (isInput) {
                          await getSwapRoute(value, inputToken, outputToken);
                        }
                      },
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))
                      ],
                      decoration: InputDecoration(
                          hintText: '0.00',
                          border: InputBorder.none,
                          hintStyle: TextStyle(color: Colors.grey.shade800)),
                      style: const TextStyle(fontSize: 26, color: Colors.white),
                      enabled: isInput,
                    ),
                  ),
                ),
                CustomInkWell(
                  onTap: () async {
                    final selectedVault = await chooseSwapTokenDialog(
                        context, ref, vaultsData.values.toList());
                    if (selectedVault != null) {
                      if (isInput) {
                        inputToken = selectedVault;
                      } else {
                        outputToken = selectedVault;
                      }
                      _inputTokenAmountController.clear();
                      _outputTokenAmountController.clear();
                      setState(() {});
                    }
                  },
                  child: Container(
                    height: 35.0,
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      border: Border.all(color: Colors.grey.withOpacity(0.1)),
                      borderRadius: BorderRadius.circular(6.0),
                    ),
                    child: Row(
                      children: [
                        Image.network(vault.logoUrl, height: 21.0, width: 21.0),
                        const SizedBox(width: 8.0),
                        Text(vault.symbol),
                        const Icon(Icons.keyboard_arrow_down_rounded,
                            color: Colors.grey, size: 21.0),
                      ],
                    ),
                  ),
                )
              ],
            ),
          ],
        ),
      ),
    );
  }
}
