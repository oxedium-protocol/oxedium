import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:oxedium_website/adapter/adapter.dart';
import 'package:oxedium_website/adapter/wallet_notifier.dart';
import 'package:oxedium_website/bl/get_staker.dart';
import 'package:oxedium_website/bl/get_stats.dart';
import 'package:oxedium_website/bl/get_user_balance.dart';
import 'package:oxedium_website/bl/staking.dart';
import 'package:oxedium_website/dialogs/choose_token_dialog.dart';
import 'package:oxedium_website/dialogs/wallet_dialog.dart';
import 'package:oxedium_website/models/tx_status.dart';
import 'package:oxedium_website/models/stats.dart';
import 'package:oxedium_website/models/user_balance.dart';
import 'package:oxedium_website/presentation/bars/top_web_bar.dart';
import 'package:oxedium_website/utils/extensions.dart';
import 'package:oxedium_website/widgets/mini_button.dart';
import 'package:oxedium_website/widgets/staking_button.dart';
import 'package:oxedium_website/widgets/stars_progress_indicator.dart';
import 'package:oxedium_website/widgets/custom_inkwell.dart';
import 'package:oxedium_website/widgets/stakes_list.dart';
import 'package:oxedium_website/widgets/stats_container_card.dart';

class HomeWebScreen extends ConsumerStatefulWidget {
  final String vaultMint;
  const HomeWebScreen({super.key, required this.vaultMint});

  @override
  ConsumerState<HomeWebScreen> createState() => _HomeWebScreenState();
}

class _HomeWebScreenState extends ConsumerState<HomeWebScreen>
    with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _stakeAmountController = TextEditingController();
  late AnimationController _controller;

  bool _showVaultSection = false;
  num estimatedAmount = 0;
  final transactionStatus = ValueNotifier<TxStatus>(TxStatus(status: ''));
  late final TopWebBar topWebBar;

  final GlobalKey _topContentKey = GlobalKey();
  bool _showTopDivider = false;

  String selectedPeriod = "365D";
  final List<String> periods = ["24H", "7D", "30D", "365D"];

  void _updateDividerVisibility() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_topContentKey.currentContext!.mounted) return;

      final box =
          _topContentKey.currentContext!.findRenderObject() as RenderBox;
      final position = box.localToGlobal(Offset.zero);
      final shouldShow = position.dy < 0;

      if (_showTopDivider != shouldShow) {
        setState(() {
          _showTopDivider = shouldShow;
        });
      }
    });
  }

  @override
  void initState() {
    super.initState();
    topWebBar = TopWebBar(transactionStatus: transactionStatus);
    _stakeAmountController.addListener(_onStakeAmountChanged);
    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 2))
          ..repeat();
  }

  void _onStakeAmountChanged() {
    final text = _stakeAmountController.text;
    final amount = double.tryParse(text);
    final shouldShow = amount != null && amount > 0;

    if (_showVaultSection != shouldShow) {
      setState(() {
        _showVaultSection = shouldShow;
      });
    }
  }

  void calculatingYield(String value, num apr) {
    if (value.isEmpty) return;

    if (selectedPeriod == "24H") {
      apr = apr / 365;
    } else if (selectedPeriod == "7D") {
      apr = apr / 52;
    } else if (selectedPeriod == "30D") {
      apr = apr / 12;
    }

    final valueNum = num.parse(value);
    final percent = apr / 100.0;

    setState(() {
      estimatedAmount = (valueNum * percent).smartSignificantRound();
    });
  }

  @override
  void dispose() {
    _stakeAmountController.dispose();
    _scrollController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final wallet = ref.watch(walletProvider);
    final isConnected = wallet?.pubkey != null;
    final vaultsAsync = ref.watch(statsProvider);
    final stakerAsync = ref.watch(stakerNotifierProvider);

    ref.listen<Adapter?>(walletProvider, (previous, wallet) {
      final pubkey = wallet?.pubkey;
      final vaultsAsync = ref.read(statsProvider);

      if (pubkey != null && vaultsAsync.value != null) {
        ref.read(stakerNotifierProvider.notifier).loadStaker(
              owner: pubkey,
              vaultsData: vaultsAsync.value!.vaults,
            );
      }
    });

    return Scaffold(
        body: vaultsAsync.when(
      data: (stat) {
        Vault vault =
            stat!.vaults.where((v) => v.mint == widget.vaultMint).first;
        return SizedBox(
          width: MediaQuery.of(context).size.width,
          child: Stack(
            alignment: Alignment.center,
            children: [
              NotificationListener<ScrollNotification>(
                onNotification: (scrollNotification) {
                  _updateDividerVisibility();
                  return true;
                },
                child: Stack(
                  alignment: Alignment.topCenter,
                  children: [
                    SingleChildScrollView(
                      controller: _scrollController,
                      child: Column(
                        key: _topContentKey,
                        children: [
                          const SizedBox(height: 75.0),
                          Column(
                            children: [
                              StatsContainerCard(stat: stat),
                              const SizedBox(height: 16.0),
                              SvgPicture.asset("assets/icons/stars.svg",
                                  height: 12.0),
                              const SizedBox(height: 16.0),
                              Container(
                                width: 400.0,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10.0),
                                  color: Theme.of(context).cardColor,
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.only(
                                      top: 16.0, right: 16.0, left: 16.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Stake tokens',
                                          style: TextStyle(fontSize: 18.0)),
                                      const SizedBox(height: 8.0),
                                      Text(
                                        'Choose your staking tokens',
                                        style:
                                            TextStyle(color: Theme.of(context).hintColor),
                                      ),
                                      const SizedBox(height: 16.0),
          
                                      // ----------------- STAKE AMOUNT BLOCK -----------------
                                      Container(
                                        height: 100.0,
                                        padding: const EdgeInsets.all(8.0),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).primaryColor,
                                          borderRadius:
                                              BorderRadius.circular(10.0),
                                        ),
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceAround,
                                          children: [
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text('Stake amount',
                                                    style: TextStyle(
                                                        color: Theme.of(context).hintColor)),
                                                Consumer(
                                                  builder: (context, ref, _) {
                                                    final wallet =
                                                        ref.watch(walletProvider);
                                                    final isConnected =
                                                        wallet?.pubkey != null;
          
                                                    if (!isConnected) {
                                                      return const SizedBox
                                                          .shrink();
                                                    }
          
                                                    final userBalancesAsync =
                                                        ref.watch(
                                                            userBalanceNotifierProvider(
                                                                wallet!.pubkey!));
          
                                                    return userBalancesAsync.when(
                                                      data: (balances) {
                                                        final vaultBalance =
                                                            balances
                                                                .firstWhere(
                                                                  (b) =>
                                                                      b.mint ==
                                                                      vault.mint,
                                                                  orElse: () =>
                                                                      UserBalance(
                                                                          mint: vault
                                                                              .mint,
                                                                          amount:
                                                                              0),
                                                                )
                                                                .amount;
          
                                                        return Row(
                                                          children: [
                                                            Row(
                                                              children: [
                                                                Icon(
                                                                    Icons
                                                                        .account_balance_wallet_outlined,
                                                                    color: Theme.of(context).hintColor,
                                                                    size: 16.0),
                                                                const SizedBox(
                                                                    width: 8.0),
                                                                Text(
                                                                  "${vaultBalance.formatBalance()} ${vault.symbol}",
                                                                  style: TextStyle(
                                                                      fontSize:
                                                                          14.0,
                                                                      color: Theme.of(context).hintColor),
                                                                ),
                                                                const SizedBox(
                                                                    width: 8.0),
                                                                MiniButton(
                                                                  text: "max",
                                                                  onTap: () {
                                                                    final vb = vault.mint == 'So11111111111111111111111111111111111111112' ? (vaultBalance - 0.006).toString() : vaultBalance.toString();
                                                                    _stakeAmountController.text = vb;
                                                                    calculatingYield(vaultBalance.toString(), vault.apr);
                                                                  },
                                                                ),
                                                              ],
                                                            ),
                                                          ],
                                                        );
                                                      },
                                                      loading: () =>
                                                          const SizedBox(),
                                                      error: (e, _) => Text(
                                                          'Error loading balance: $e'),
                                                    );
                                                  },
                                                ),
                                              ],
                                            ),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.spaceBetween,
                                              children: [
                                                Expanded(
                                                  child: Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                            right: 4.0),
                                                    child: TextField(
                                                      controller:
                                                          _stakeAmountController,
                                                      onChanged: (value) =>
                                                          calculatingYield(
                                                              value, vault.apr),
                                                      keyboardType:
                                                          TextInputType.number,
                                                      inputFormatters: [
                                                        FilteringTextInputFormatter
                                                            .allow(RegExp(
                                                                r'[0-9.]')),
                                                      ],
                                                      decoration:
                                                          const InputDecoration(
                                                        hint: Text('0.00',
                                                            style: TextStyle(
                                                                fontSize: 26.0,
                                                                color: Colors.grey)),
                                                        border: InputBorder.none,
                                                        isCollapsed: true,
                                                        contentPadding:
                                                            EdgeInsets.zero,
                                                      ),
                                                      style: const TextStyle(
                                                        fontSize: 26.0,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                CustomInkWell(
                                                  onTap: () => chooseTokenDialog(
                                                      context, ref, stat.vaults),
                                                  child: Container(
                                                    height: 35.0,
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 8.0),
                                                    decoration: BoxDecoration(
                                                      color: Theme.of(context).cardColor,
                                                      border: Border.all(
                                                          color: Colors.grey.withOpacity(0.1)),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              6.0),
                                                    ),
                                                    child: Row(
                                                      children: [
                                                        Image.network(
                                                            vault.logoUrl,
                                                            height: 21.0,
                                                            width: 21.0),
                                                        const SizedBox(
                                                            width: 8.0),
                                                        Text(vault.symbol),
                                                        const Icon(
                                                          Icons
                                                              .keyboard_arrow_down_rounded,
                                                          color: Colors.grey,
                                                          size: 21.0,
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                )
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
          
                                      const SizedBox(height: 16.0),
          
                                      AnimatedSwitcher(
                                        duration:
                                            const Duration(milliseconds: 300),
                                        transitionBuilder: (child, animation) =>
                                            FadeTransition(
                                                opacity: animation, child: child),
                                        child: _showVaultSection
                                            ? Column(
                                                key: const ValueKey(
                                                    'vault_section'),
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    'You’ll join this vault',
                                                    style: TextStyle(
                                                        color: Theme.of(context).hintColor),
                                                  ),
                                                  const SizedBox(height: 8.0),
          
                                                  Container(
                                                    height: 50.0,
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 8.0),
                                                    decoration: BoxDecoration(
                                                        border: Border.all(
                                                            color: const Color(0xFF404056), width: 0.5),
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                                10.0)),
                                                    child: Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .spaceBetween,
                                                      children: [
                                                        Row(
                                                          children: [
                                                            Image.network(
                                                              vault.logoUrl,
                                                              height: 21.0,
                                                              width: 21.0,
                                                            ),
                                                            const SizedBox(
                                                                width: 8.0),
                                                            Text(vault.symbol),
                                                          ],
                                                        ),
                                                        Text(
                                                          '+${vault.apr}%',
                                                          style: const TextStyle(
                                                            color: Colors
                                                                .greenAccent,
                                                            fontSize: 18.0,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
          
                                                  const SizedBox(height: 16.0),
          
                                                  // ---------------- ESTIMATED YIELD BLOCK ----------------
          
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.all(8.0),
                                                    decoration: BoxDecoration(
                                                      color: Theme.of(context).primaryColor,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              10.0),
                                                    ),
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Row(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .spaceBetween,
                                                          children: [
                                                            Text(
                                                              'Estimated yield',
                                                              style: TextStyle(
                                                                  color: Theme.of(context).hintColor),
                                                            ),
                                                            Theme(
                                                              data: ThemeData(
                                                                splashColor: Colors
                                                                    .transparent,
                                                                highlightColor:
                                                                    Colors
                                                                        .transparent,
                                                                hoverColor: Colors
                                                                    .grey
                                                                    .withOpacity(
                                                                        0.03),
                                                                focusColor: Colors
                                                                    .transparent,
                                                                fontFamily:
                                                                    "Aeonik",
                                                              ),
                                                              child: PopupMenuButton<String>(
                                                                color: Theme.of(context).cardColor,
                                                                elevation:
                                                                    0,
                                                                surfaceTintColor:
                                                                    Colors.white,
                                                                shadowColor: Colors
                                                                    .transparent,
                                                                padding:
                                                                    EdgeInsets
                                                                        .zero,
                                                                tooltip: "",
                                                                shape:
                                                                    RoundedRectangleBorder(
                                                                  side: BorderSide(
                                                                      color: Colors
                                                                          .grey.withOpacity(0.1),
                                                                      width: 0.5),
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .circular(
                                                                              6),
                                                                ),
          
                                                                onSelected:
                                                                    (value) {
                                                                  setState(() {
                                                                    selectedPeriod = value;
                                                                    calculatingYield(_stakeAmountController.text, vault.apr);
                                                                  });
                                                                },
          
                                                                itemBuilder:
                                                                    (context) =>
                                                                        periods
                                                                            .map(
                                                                              (p) =>
                                                                                  PopupMenuItem<String>(
                                                                                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                                                                value: p,
                                                                                child: Text(
                                                                                  p,
                                                                                  style: const TextStyle(fontSize: 16.0, color: Colors.white),
                                                                                ),
                                                                              ),
                                                                            )
                                                                            .toList(),
          
                                                                child: Container(
                                                                  height: 30.0,
                                                                  alignment:
                                                                      Alignment
                                                                          .center,
                                                                  padding: const EdgeInsets
                                                                      .symmetric(
                                                                      horizontal:
                                                                          8.0),
                                                                  decoration:
                                                                      BoxDecoration(
                                                                    color: Theme.of(context).cardColor,
                                                                    borderRadius:
                                                                        BorderRadius
                                                                            .circular(
                                                                                5.0),
                                                                    border: Border
                                                                        .all(
                                                                      color: Colors
                                                                          .grey.withOpacity(0.1),
                                                                    ),
                                                                  ),
                                                                  child: Row(
                                                                    children: [
                                                                      Text(selectedPeriod),
                                                                      const Icon(
                                                                        Icons
                                                                            .keyboard_arrow_down_rounded,
                                                                        color: Colors
                                                                            .grey,
                                                                        size:
                                                                            21.0,
                                                                      ),
                                                                    ],
                                                                  ),
                                                                ),
                                                              ),
                                                            )
                                                          ],
                                                        ),
                                                        const SizedBox(
                                                            height: 4.0),
                                                        Text(
                                                          '$estimatedAmount ${vault.symbol}',
                                                          style: const TextStyle(
                                                              fontSize: 18.0),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
          
                                                  const SizedBox(height: 16.0),
                                                  Text(
                                                    'By providing liquidity, you’ll earn a portion of trading fees',
                                                    style: TextStyle(
                                                        color: Theme.of(context).hintColor,
                                                        fontSize: 13.0),
                                                  ),
                                                  const SizedBox(height: 32.0),
          
                                                  StakingButton(isConnected: isConnected, onTap: () {
                                                      if (isConnected) {
                                                        staking(context, ref,
                                                            adapter: wallet!,
                                                            vault: vault,
                                                            vaultsData: stat.vaults,
                                                            status: transactionStatus,
                                                            amountText: _stakeAmountController.text);
                                                        _stakeAmountController.clear();
                                                      } else {
                                                        showWalletDialog(context, ref);
                                                      }
                                                  }),
                                                  const SizedBox(height: 16.0),
                                                ],
                                              )
                                            : const SizedBox.shrink(),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (isConnected)
                            Padding(
                              padding: const EdgeInsets.only(
                                  left: 280.0,
                                  right: 280.0,
                                  top: 16.0,
                                  bottom: 64.0),
                              child: stakerAsync.when(
                                data: (stakes) {
                                  if (stakes.isEmpty) return const SizedBox();
          
                                  return Column(
                                    children: [
                                      SvgPicture.asset("assets/icons/stars.svg",
                                          height: 12.0),
                                      const SizedBox(height: 16.0),
                                      Container(
                                        width: 400.0,
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(12.0),
                                          color: Theme.of(context).cardColor
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Padding(
                                              padding: EdgeInsets.only(
                                                  top: 16.0,
                                                  left: 16.0,
                                                  bottom: 8.0),
                                              child: Text(
                                                'Your stakes',
                                                style: TextStyle(
                                                    color: Color(0xFF5F5B5B)),
                                              ),
                                            ),
                                            StakesList(
                                                stakes: stakes,
                                                transactionStatus:
                                                    transactionStatus,
                                                vaultsData: stat.vaults),
                                            const SizedBox(height: 8.0),
                                          ],
                                        ),
                                      ),
                                    ],
                                  );
                                },
                                loading: () => const StarsProgressIndicator(),
                                error: (e, _) => Padding(
                                  padding: const EdgeInsets.only(top: 32.0),
                                  child: Text('Error: $e',
                                      style: const TextStyle(color: Colors.red)),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(top: 0, left: 0, right: 0, child: topWebBar),
              Positioned(
                top: 60.0,
                left: 0,
                right: 0,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: !_showTopDivider ? 0.0 : 0.5,
                  child: Divider(height: 0.05, color: Colors.grey.shade400),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const Center(
        child: StarsProgressIndicator(),
      ),
      error: (err, _) => Center(child: Text('Error: $err')),
    ));
  }
}
