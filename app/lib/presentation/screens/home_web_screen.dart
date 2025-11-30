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
import 'package:oxedium_website/models/tx_status.dart';
import 'package:oxedium_website/models/stats.dart';
import 'package:oxedium_website/models/user_balance.dart';
import 'package:oxedium_website/presentation/bars/top_web_bar.dart';
import 'package:oxedium_website/presentation/basement/basement_web_widget.dart';
import 'package:oxedium_website/utils/extensions.dart';
import 'package:oxedium_website/widgets/max_button.dart';
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
        return Stack(
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
                                border: Border.all(
                                    color: Colors.grey.shade600, width: 0.15),
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
                                    const Text(
                                      'Choose your staking tokens',
                                      style:
                                          TextStyle(color: Color(0xFF5F5B5B)),
                                    ),
                                    const SizedBox(height: 16.0),

                                    // ----------------- STAKE AMOUNT BLOCK -----------------
                                    Container(
                                      height: 100.0,
                                      padding: const EdgeInsets.all(8.0),
                                      decoration: BoxDecoration(
                                        color: const Color.fromARGB(
                                            255, 12, 12, 12),
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
                                              const Text('Stake amount',
                                                  style: TextStyle(
                                                      color:
                                                          Color(0xFF5F5B5B))),
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
                                                                  color: Colors
                                                                      .grey
                                                                      .shade800,
                                                                  size: 16.0),
                                                              const SizedBox(
                                                                  width: 8.0),
                                                              Text(
                                                                "${vaultBalance.formatBalance()} ${vault.symbol}",
                                                                style: TextStyle(
                                                                    fontSize:
                                                                        14.0,
                                                                    color: Colors
                                                                        .grey
                                                                        .shade800),
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
                                                              color: Color(
                                                                  0xFF252525))),
                                                      border: InputBorder.none,
                                                      isCollapsed: true,
                                                      contentPadding:
                                                          EdgeInsets.zero,
                                                    ),
                                                    style: const TextStyle(
                                                      color: Colors.white,
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
                                                    color:
                                                        const Color(0xFF030303),
                                                    border: Border.all(
                                                        color: const Color(
                                                            0xFF202020)),
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
                                                const Text(
                                                  'You’ll join this vault',
                                                  style: TextStyle(
                                                      color: Color(0xFF5F5B5B)),
                                                ),
                                                const SizedBox(height: 8.0),

                                                Container(
                                                  height: 50.0,
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 8.0),
                                                  decoration: BoxDecoration(
                                                      border: Border.all(
                                                          color: Colors.grey
                                                              .withOpacity(
                                                                  0.1)),
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
                                                    color:
                                                        const Color(0xFF090909),
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
                                                          const Text(
                                                            'Estimated yield',
                                                            style: TextStyle(
                                                                color: Color(
                                                                    0xFF5F5B5B)),
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
                                                                  "Roobert",
                                                            ),
                                                            child:
                                                                PopupMenuButton<
                                                                    String>(
                                                              color: Theme.of(context).scaffoldBackgroundColor,
                                                              elevation:
                                                                  0,
                                                              surfaceTintColor:
                                                                  Colors.black,

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
                                                                        .grey
                                                                        .shade900,
                                                                    width: 1.0),
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
                                                                                style: const TextStyle(color: Colors.white, fontSize: 16.0),
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
                                                                  color: Colors
                                                                      .grey
                                                                      .withOpacity(
                                                                          0.05),
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .circular(
                                                                              5.0),
                                                                  border: Border
                                                                      .all(
                                                                    color: Colors
                                                                        .grey
                                                                        .shade900,
                                                                    width: 1.0,
                                                                  ),
                                                                ),
                                                                child: Row(
                                                                  children: [
                                                                    Text(
                                                                      selectedPeriod,
                                                                      style: const TextStyle(
                                                                          color:
                                                                              Colors.grey),
                                                                    ),
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
                                                const Text(
                                                  'By providing liquidity, you’ll earn a portion of trading fees',
                                                  style: TextStyle(
                                                      color: Color(0xFF5F5B5B),
                                                      fontSize: 13.0),
                                                ),
                                                const SizedBox(height: 32.0),

                                                CustomInkWell(
                                                  onTap: () {
                                                    if (isConnected) {
                                                      staking(context, ref,
                                                          adapter: wallet!,
                                                          vault: vault,
                                                          vaultsData:
                                                              stat.vaults,
                                                          status:
                                                              transactionStatus,
                                                          amountText:
                                                              _stakeAmountController
                                                                  .text);
                                                      _stakeAmountController
                                                          .clear();
                                                    }
                                                  },
                                                  child: Container(
                                                    height: 42.0,
                                                    decoration: BoxDecoration(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              100.0),
                                                      color: isConnected
                                                          ? const Color(
                                                              0xFF7637EC)
                                                          : Colors
                                                              .grey.shade900,
                                                    ),
                                                    child: const Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .center,
                                                      children: [
                                                        Icon(Icons.add,
                                                            color: Colors.white,
                                                            size: 18.0),
                                                        SizedBox(width: 8.0),
                                                        Text('Stake'),
                                                      ],
                                                    ),
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
                                        border: Border.all(
                                            color: Colors.grey.shade700,
                                            width: 0.2),
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
                  const Align(
                    alignment: Alignment.bottomCenter,
                    child: BasementWebWidget(),
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
                child: const Divider(height: 0.5, color: Color(0xFF2B2B2B)),
              ),
            ),
          ],
        );
      },
      loading: () => Center(
        child: RotationTransition(
          turns: Tween(begin: 0.0, end: -1.0).animate(_controller),
          child: SvgPicture.string(
            _spinnerSvg,
            width: 40,
            height: 40,
          ),
        ),
      ),
      error: (err, _) => Center(child: Text('Error: $err')),
    ));
  }
}

const String _spinnerSvg = '''
<svg viewBox="0 0 60 60" fill="none" xmlns="http://www.w3.org/2000/svg">
  <ellipse cx="9.57977" cy="9.57977" rx="9.57977" ry="9.57977" transform="matrix(-1 0 0 1 39.4062 20.1172)" fill="#9971FF"/>
  <path d="M44.9062 6.94614C40.4079 3.94362 37.1622 2.78023 29.3391 2.15625C23.7121 8.67877 22.7903 13.0174 24.5492 21.7948L30.5366 20.3578C32.1045 13.1891 35.8391 10.5335 44.9062 6.94614Z" fill="#9971FF"/>
  <path d="M56.6623 23.9277C55.5281 18.6396 54.0109 15.5434 48.8347 9.64452C40.2537 10.4016 36.5692 12.8711 31.7145 20.3922L37.0102 23.5338C43.1301 19.4847 47.6592 20.1824 56.6623 23.9277Z" fill="#9971FF"/>
  <path d="M52.8122 44.6976C55.7499 40.1567 56.8666 36.8946 57.3783 29.0634C50.7757 23.5305 46.4243 22.671 37.6731 24.5557L39.1958 30.5218C46.3862 31.9868 49.0951 35.6828 52.8122 44.6976Z" fill="#9971FF"/>
  <path d="M23.8962 3.31372C18.6161 4.48466 15.5306 6.02345 9.66792 11.2406C10.4848 19.8161 12.9799 23.4833 20.5347 28.2855L23.6392 22.9681C19.5476 16.8765 20.2137 12.3427 23.8962 3.31372Z" fill="#9971FF"/>
  <path d="M7.04732 15.0333C4.10176 19.5692 2.97941 22.8293 2.45413 30.6596C9.04709 36.204 13.397 37.071 22.1515 35.2015L20.6392 29.2327C13.4513 27.7553 10.7488 24.0545 7.04732 15.0333Z" fill="#9971FF"/>
  <path d="M3.3088 35.646C4.48725 40.9244 6.03042 44.0077 11.2559 49.863C19.8303 49.0339 23.4939 46.5336 28.2854 38.972L22.9635 35.875C16.8778 39.9752 12.343 39.3156 3.3088 35.646Z" fill="#9971FF"/>
  <path d="M15.6089 53.3937C20.2716 56.1341 23.5785 57.11 31.4245 57.2856C36.6693 50.4519 37.3415 46.0676 35.0835 37.4052L29.1881 39.1823C28.0327 46.4289 24.4561 49.2937 15.6089 53.3937Z" fill="#9971FF"/>
  <path d="M35.6494 56.6795C40.9318 55.5189 44.0203 53.9862 49.8932 48.7805C49.0932 40.2034 46.6052 36.5314 39.0599 31.7143L35.9449 37.0257C40.0246 43.1253 39.3496 47.6578 35.6494 56.6795Z" fill="#9971FF"/>
</svg>
''';
