import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:oxedium_website/widgets/custom_inkwell.dart';

class StakingButton extends ConsumerStatefulWidget {
  final bool isConnected;
  final Function() onTap;
  const StakingButton({super.key, required this.isConnected, required this.onTap});

  @override
  ConsumerState<StakingButton> createState() => _StakingButtonState();
}

class _StakingButtonState extends ConsumerState<StakingButton> {
  @override
  Widget build(BuildContext context) {
    return CustomInkWell(
      onTap: widget.onTap,
      child: Container(
        height: 42.0,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(100.0),
          color: widget.isConnected
              ? Colors.white
              : Colors.grey.withOpacity(0.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            widget.isConnected ? SvgPicture.asset("assets/icons/staking_icon.svg",
                height: 18.0, width: 18.0) : const SizedBox(),
            const SizedBox(width: 8.0),
            widget.isConnected ? const Text('Stake',
                style: TextStyle(color: Colors.black, fontSize: 17.0)) : const Text('Connect wallet',
                style: TextStyle(color: Colors.white, fontSize: 17.0)),
          ],
        ),
      ),
    );
  }
}
