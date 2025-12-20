import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oxedium_website/widgets/custom_inkwell.dart';

class CustomButton extends ConsumerStatefulWidget {
  final bool isConnected;
  final Function() onTap;
  final String title;
  final double? width;
  const CustomButton({super.key, required this.isConnected, required this.onTap, required this.title, this.width});

  @override
  ConsumerState<CustomButton> createState() => _StakingButtonState();
}

class _StakingButtonState extends ConsumerState<CustomButton> {
  @override
  Widget build(BuildContext context) {
    return CustomInkWell(
      onTap: widget.onTap,
      child: Container(
        height: 42.0,
        width: widget.width,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(100.0),
          color: widget.isConnected
              ? Colors.white
              : Colors.grey.withOpacity(0.5),
        ),
        child: widget.isConnected ? Text(widget.title,
                style: const TextStyle(color: Colors.black, fontSize: 17.0)) : const Text('Connect wallet',
                style: TextStyle(color: Colors.white, fontSize: 17.0)),
      ),
    );
  }
}
