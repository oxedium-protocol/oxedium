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
        width: 140.0,
        alignment: Alignment.center,
        decoration: BoxDecoration(
            color: isHover ? const Color(0xFF7637EC) : Colors.white,
            borderRadius: BorderRadius.circular(500.0)),
        child: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 250),
          style: TextStyle(color: isHover ? Colors.white : Colors.black, fontFamily: 'Aeonik', fontSize: 17.0),
          child: const Text('Connect')),
      ),
    );
  }
}
