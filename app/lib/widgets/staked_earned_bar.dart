import 'package:flutter/material.dart';

class StakedEarnedBar extends StatelessWidget {
  final double staked;
  final double earned;

  const StakedEarnedBar({
    super.key,
    required this.staked,
    required this.earned,
  });

  @override
  Widget build(BuildContext context) {
    const double barWidth = 352;
    const double barHeight = 40;

    final ratio = staked == 0 ? 0 : (earned / staked).clamp(0, 1);

    const double stickWidth = 4.0;
    const double stickSpacing = 4.0;
    const double stickFullWidth = stickWidth + stickSpacing;

    final int totalPossibleSticks = (barWidth / stickFullWidth).floor();
    int earnedSticks = (totalPossibleSticks * ratio).round();

    if (earnedSticks == 0 && earned > 0) {
      earnedSticks = 1;
    }

    List<Widget> sticks = List.generate(
      earnedSticks,
      (_) => Padding(
        padding: const EdgeInsets.only(right: stickSpacing),
        child: Container(
          height: 32,
          width: stickWidth,
          color: Colors.amber.withOpacity(0.4),
        ),
      ),
    );

    return SizedBox(
      height: 100.0,
      width: barWidth,
      child: Stack(
        alignment: Alignment.centerLeft,
        children: [

          Container(
            height: barHeight,
            width: barWidth,
            color: Colors.deepPurpleAccent.withOpacity(0.1),
          ),

          Positioned.fill(
            child: Align(
              alignment: Alignment.centerLeft,
              child: Row(children: sticks),
            ),
          ),
        ],
      ),
    );
  }
}
