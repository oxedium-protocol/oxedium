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
import 'package:oxedium_website/presentation/bars/top_mob_bar.dart';
import 'package:oxedium_website/service/config.dart';
import 'package:oxedium_website/utils/extensions.dart';
import 'package:oxedium_website/widgets/stars_progress_indicator.dart';
import 'package:oxedium_website/widgets/custom_inkwell.dart';
import 'package:oxedium_website/widgets/stakes_list.dart';
import 'package:oxedium_website/widgets/mini_button.dart';
import 'dart:js' as js;

class HomeMobScreen extends ConsumerStatefulWidget {
  final String vaultMint;
  const HomeMobScreen({super.key, required this.vaultMint});

  @override
  ConsumerState<HomeMobScreen> createState() => _HomeMobScreenState();
}

class _HomeMobScreenState extends ConsumerState<HomeMobScreen>
    with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _stakeAmountController = TextEditingController();
  late AnimationController _controller;
  final transactionStatus = ValueNotifier<TxStatus>(TxStatus(status: ''));
  final transactionSignature = ValueNotifier<String>('');

  bool _showVaultSection = false;
  num estimatedDailyAmount = 0;

  // period selector state (matches web logic)
  String selectedPeriod = "365D";
  final List<String> periods = ["24H", "7D", "30D", "365D"];

  @override
  void initState() {
    super.initState();
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
    if (value.isEmpty) {
      setState(() {
        estimatedDailyAmount = 0;
      });
      return;
    }

    num adjustedApr = apr;
    if (selectedPeriod == "24H") {
      adjustedApr = apr / 365;
    } else if (selectedPeriod == "7D") {
      adjustedApr = apr / 52;
    } else if (selectedPeriod == "30D") {
      adjustedApr = apr / 12;
    } else {
      adjustedApr = apr; // 365D
    }

    final valueNum = num.parse(value);
    final percent = adjustedApr / 100.0;

    setState(() {
      estimatedDailyAmount = (valueNum * percent).smartSignificantRound();
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
          final tvl = stat.usdTreasuryBalance;
          final parts = tvl.toStringAsFixed(2).split('.');
          final whole = int.parse(parts[0]).formatNumWithCommas();
          final decimals = parts[1];

          return LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                controller: _scrollController,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                  ),
                  child: IntrinsicHeight(
                    child: Stack(
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
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const TopMobBar(),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16.0),
                              child: Column(
                                children: [
                                  Container(
                                    width: 400.0,
                                    padding: const EdgeInsets.all(16.0),
                                    decoration: BoxDecoration(
                                        borderRadius:
                                            BorderRadius.circular(10.0),
                                        color: Theme.of(context).cardColor),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    const Text(
                                                        'Treasury balance',
                                                        style: TextStyle(
                                                            color: Color(
                                                                0xFF5F5B5B))),
                                                    const SizedBox(width: 8.0),
                                                    CustomInkWell(
                                                      onTap: () => js.context
                                                          .callMethod('open', [
                                                        'https://orb.helius.dev/address/${stat.treasuryAddress}?cluster=${SolanaConfig.cluster}&tab=summary'
                                                      ]),
                                                      child: Container(
                                                          height: 20.0,
                                                          width: 20.0,
                                                          alignment:
                                                              Alignment.center,
                                                          decoration: BoxDecoration(
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          5.0),
                                                              border: Border.all(
                                                                  color: Colors
                                                                      .grey
                                                                      .withOpacity(
                                                                          0.2))),
                                                          child: Image.asset(
                                                              "assets/icons/orb.png",
                                                              height: 10.0,
                                                              width: 10.0)),
                                                    ),
                                                  ],
                                                ),
                                                Row(
                                                  children: [
                                                    Text('\$$whole',
                                                        style: const TextStyle(
                                                            fontSize: 26.0)),
                                                    const SizedBox(width: 2.0),
                                                    Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                              top: 3.0),
                                                      child: Text('.$decimals',
                                                          style: TextStyle(
                                                              fontSize: 22.0,
                                                              color: Colors.grey
                                                                  .shade800)),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                            SvgPicture.asset(
                                                'assets/icons/treasury.svg',
                                                height: 60.0,
                                                width: 60.0)
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 8.0),
                                  SvgPicture.asset("assets/icons/stars.svg",
                                      height: 12.0),
                                  const SizedBox(height: 8.0),
                                  buildStakeBox(
                                      vault, stat, isConnected, wallet),
                                  const SizedBox(height: 8.0),
                                  if (isConnected)
                                    Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 16.0),
                                      child: stakerAsync.when(
                                        data: (stakes) {
                                          if (stakes.isEmpty) {
                                            return const SizedBox();
                                          }
                                          return Column(
                                            children: [
                                              SvgPicture.asset(
                                                  "assets/icons/stars.svg",
                                                  height: 12.0),
                                              const SizedBox(height: 8.0),
                                              Container(
                                                width: 400.0,
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          12.0),
                                                  color: Theme.of(context)
                                                      .cardColor,
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
                                                            color: Color(
                                                                0xFF5F5B5B)),
                                                      ),
                                                    ),
                                                    StakesList(
                                                        stakes: stakes,
                                                        vaultsData:
                                                            stat.vaults),
                                                    const SizedBox(height: 8.0),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          );
                                        },
                                        loading: () =>
                                            const StarsProgressIndicator(),
                                        error: (e, _) => Padding(
                                          padding:
                                              const EdgeInsets.only(top: 32.0),
                                          child: Text('Error: $e',
                                              style: const TextStyle(
                                                  color: Colors.red)),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(
          child: StarsProgressIndicator(),
        ),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget buildStakeBox(
      Vault vault, Stats stat, bool isConnected, Adapter? wallet) {
    return Container(
      width: 410.0,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10.0),
        color: Theme.of(context).cardColor,
      ),
      child: Padding(
        padding: const EdgeInsets.only(top: 16.0, right: 16.0, left: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Stake tokens', style: TextStyle(fontSize: 18.0)),
            const SizedBox(height: 8.0),
            Text(
              'Choose your staking tokens',
              style: TextStyle(color: Theme.of(context).hintColor),
            ),
            const SizedBox(height: 16.0),

            // ----------------- STAKE AMOUNT BLOCK -----------------
            Container(
              height: 120.0,
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor, // web-like background
                borderRadius: BorderRadius.circular(10.0),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  // Top row: label + token selector
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Stake amount',
                          style: TextStyle(color: Theme.of(context).hintColor)),
                      Consumer(builder: (context, ref, _) {
                        final walletLocal = ref.watch(walletProvider);
                        final isConnectedLocal = walletLocal?.pubkey != null;
                        if (!isConnectedLocal) return const SizedBox.shrink();

                        final userBalancesAsync = ref.watch(
                            userBalanceNotifierProvider(walletLocal!.pubkey!));

                        return userBalancesAsync.when(
                          data: (balances) {
                            final vaultBalance = balances
                                .firstWhere(
                                  (b) => b.mint == vault.mint,
                                  orElse: () =>
                                      UserBalance(mint: vault.mint, amount: 0),
                                )
                                .amount;

                            return Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Icon(Icons.account_balance_wallet_outlined,
                                    color: Colors.grey.shade800, size: 16.0),
                                const SizedBox(width: 8.0),
                                Text(
                                  "${vaultBalance.formatBalance()} ${vault.symbol}",
                                  style: TextStyle(
                                      fontSize: 14.0,
                                      color: Colors.grey.shade800),
                                ),
                                const SizedBox(width: 8.0),
                                MiniButton(
                                  text: "max",
                                  onTap: () {
                                    _stakeAmountController.text =
                                        vaultBalance.toString();
                                    calculatingYield(
                                        vaultBalance.toString(), vault.apr);
                                  },
                                ),
                              ],
                            );
                          },
                          loading: () => const SizedBox(),
                          error: (e, _) => Text('Error loading balance: $e'),
                        );
                      }),
                    ],
                  ),

                  // Amount input
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _stakeAmountController,
                          onChanged: (value) =>
                              calculatingYield(value, vault.apr),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'[0-9.]')),
                          ],
                          decoration: InputDecoration(
                            hint: Text('0.00',
                                style: TextStyle(
                                    fontSize: 26.0,
                                    color: Colors
                                        .grey.shade800)), // match web hint
                            border: InputBorder.none,
                          ),
                          style: const TextStyle(
                              fontSize: 26.0), // match web (no forced white)
                        ),
                      ),
                      CustomInkWell(
                        onTap: () => chooseTokenDialog(
                            context, ref, stat.vaults,
                            isMob: true),
                        child: Container(
                          height: 35.0,
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            border:
                                Border.all(color: Colors.grey.withOpacity(0.1)),
                            borderRadius: BorderRadius.circular(6.0),
                          ),
                          child: Row(
                            children: [
                              Image.network(vault.logoUrl,
                                  height: 21.0, width: 21.0),
                              const SizedBox(width: 8.0),
                              Text(vault.symbol),
                              const Icon(Icons.keyboard_arrow_down_rounded,
                                  color: Colors.grey, size: 21.0),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16.0),

            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, animation) =>
                  FadeTransition(opacity: animation, child: child),
              child: _showVaultSection
                  ? Column(
                      key: const ValueKey('vault_section'),
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('You’ll join this vault',
                            style:
                                TextStyle(color: Theme.of(context).hintColor)),
                        const SizedBox(height: 16.0),
                        Container(
                          height: 50.0,
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          decoration: BoxDecoration(
                              border: Border.all(
                                  color: Colors.grey.withOpacity(0.1)),
                              borderRadius: BorderRadius.circular(10.0)),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Image.network(vault.logoUrl,
                                      height: 21.0, width: 21.0),
                                  const SizedBox(width: 8.0),
                                  Text(vault.symbol),
                                ],
                              ),
                              Text(
                                '+${vault.apr}%',
                                style: const TextStyle(
                                    color: Colors.greenAccent, fontSize: 18.0),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16.0),
                        Container(
                          height: 80.0,
                          padding: const EdgeInsets.all(8.0),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .primaryColor, // match web estimated-yield bg
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Estimated yield',
                                      style: TextStyle(
                                          color: Theme.of(context).hintColor)),
                                  // interactive period selector
                                  buildPeriodSelector(vault),
                                ],
                              ),
                              const SizedBox(height: 4.0),
                              Text(
                                '$estimatedDailyAmount ${vault.symbol}',
                                style: const TextStyle(fontSize: 18.0),
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

                        /// Stake Button
                        CustomInkWell(
                          onTap: () => isConnected
                              ? staking(context, ref,
                                  adapter: wallet!,
                                  vault: vault,
                                  vaultsData: stat.vaults,
                                  status: transactionStatus,
                                  amountText: _stakeAmountController.text)
                              : showWalletDialog(context, ref),
                          child: Container(
                            height: 42.0,
                            alignment: Alignment.center,
                            width: MediaQuery.of(context).size.width,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(100.0),
                              color: isConnected
                                  ? const Color(0xFF7637EC)
                                  : Colors.grey
                                      .withOpacity(0.5), // match web disabled
                            ),
                            child: isConnected
                                ? const Text('Stake')
                                : const Text("Connect wallet"),
                          ),
                        ),
                        const SizedBox(height: 16.0),
                      ],
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildPeriodSelector(Vault vault) {
    return Theme(
      data: ThemeData(
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        hoverColor: Colors.grey.withOpacity(0.03),
        focusColor: Colors.transparent,
        fontFamily: "Aeonik",
      ),
      child: PopupMenuButton<String>(
        color: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        surfaceTintColor: Colors.black,
        shadowColor: Colors.transparent,
        padding: EdgeInsets.zero,
        tooltip: "",
        shape: RoundedRectangleBorder(
          side: BorderSide(color: Colors.grey.shade900, width: 1.0),
          borderRadius: BorderRadius.circular(6),
        ),
        onSelected: (value) {
          setState(() {
            selectedPeriod = value;
            calculatingYield(_stakeAmountController.text, vault.apr);
          });
        },
        itemBuilder: (context) => periods
            .map(
              (p) => PopupMenuItem<String>(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                value: p,
                child: Text(
                  p,
                  style: const TextStyle(color: Colors.white, fontSize: 16.0),
                ),
              ),
            )
            .toList(),
        child: Container(
          height: 30.0,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            border: Border.all(color: Colors.grey.withOpacity(0.1)),
            borderRadius: BorderRadius.circular(6.0),
          ),
          child: Row(
            children: [
              Text(selectedPeriod, style: const TextStyle(color: Colors.grey)),
              const Icon(Icons.keyboard_arrow_down_rounded,
                  color: Colors.grey, size: 21.0),
            ],
          ),
        ),
      ),
    );
  }
}
