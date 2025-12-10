import 'package:flutter/material.dart';
import 'package:oxedium_website/models/stats.dart';
import 'package:oxedium_website/service/config.dart';
import 'package:oxedium_website/utils/extensions.dart';
import 'package:oxedium_website/widgets/custom_inkwell.dart';
import 'dart:js' as js;

class StatsContainerCard extends StatefulWidget {
  final Stats stat;

  const StatsContainerCard({super.key, required this.stat});

  @override
  StatsContainerCardState createState() => StatsContainerCardState();
}

class StatsContainerCardState extends State<StatsContainerCard> {

  @override
  Widget build(BuildContext context) {
    final tvl = widget.stat.usdTreasuryBalance;
    final parts = tvl.toStringAsFixed(2).split('.');  
    final whole = int.parse(parts[0]).formatNumWithCommas();  
    final decimals = parts[1];
    return CustomInkWell(
      onTap: () => js.context.callMethod('open', ['https://orb.helius.dev/address/${widget.stat.treasuryAddress}?cluster=${SolanaConfig.cluster}&tab=summary']),
      child: Container(
        width: 400.0,
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10.0),
          color: Theme.of(context).cardColor
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Image.asset("assets/icons/orb.png", height: 13.0, width: 13.0),
                        const SizedBox(width: 8.0),
                        Text('Treasury balance', style: TextStyle(color: Theme.of(context).hintColor)),
                      ],
                    ),
                    const SizedBox(height: 4.0),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text('\$$whole',
                            style: const TextStyle(fontSize: 26.0)),
                          const SizedBox(width: 2.0),
                          Text('.$decimals',
                            style: const TextStyle(fontSize: 22.0, color: Colors.grey)),
                      ],
                    ),
                  ],
                ),
                //...
              ],
            ),
          ],
        ),
      ),
    );
  }
}
