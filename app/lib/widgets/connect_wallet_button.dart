import 'package:flutter/material.dart';
import 'package:oxedium_website/widgets/custom_inkwell.dart';

class ConnectWalletButton extends StatefulWidget {
  final Function() onTap;
  const ConnectWalletButton({super.key, required this.onTap});

  @override
  State<ConnectWalletButton> createState() => _ConnectWalletButtonState();
}

class _ConnectWalletButtonState extends State<ConnectWalletButton> {

  bool isHover = false;

  @override
  Widget build(BuildContext context) {
    return CustomInkWell(
      onTap: widget.onTap,
      onHover: (value) {
        isHover = value;
        setState(() {});
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        height: 35.0,
        width: 150.0,
        decoration: BoxDecoration(
            color: isHover ? const Color(0xFF9971FF) : const Color(0xFF7637EC),
            borderRadius: BorderRadius.circular(500.0)),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text('Connect', style: TextStyle(color: Colors.white)),
            Icon(Icons.power, color: Colors.white, size: 21.0)
          ],
        ),
      ),
    );
  }
}
