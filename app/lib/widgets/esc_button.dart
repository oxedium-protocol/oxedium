import 'package:flutter/material.dart';
import 'package:oxedium_website/widgets/custom_inkwell.dart';

class EscButton extends StatefulWidget {
  final Function() onTap;
  const EscButton({super.key, required this.onTap});

  @override
  State<EscButton> createState() => _EscButtonState();
}

class _EscButtonState extends State<EscButton> {

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
        height: 25.0,
        width: 55.0,
        alignment: Alignment.center,
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(5.0),
            color: isHover ? Colors.grey.withOpacity(0.2) : Colors.grey.withOpacity(0.1)),
        child: const Text('Esc',
            style: TextStyle(fontSize: 14.0, color: Colors.grey)),
      ),
    );
  }
}
