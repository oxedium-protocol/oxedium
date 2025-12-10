import 'package:flutter/material.dart';
import 'package:oxedium_website/widgets/custom_inkwell.dart';

class MiniButton extends StatefulWidget {
  final String text;
  final Function() onTap;
  final double? height;
  const MiniButton({super.key, this.height, required this.text, required this.onTap});

  @override
  State<MiniButton> createState() => _MiniButtonState();
}

class _MiniButtonState extends State<MiniButton> {

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
        height: widget.height ?? 24.0,
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        alignment: Alignment.center,
        decoration: BoxDecoration(
            border: Border.all(color: isHover ? Colors.deepPurpleAccent : Colors.grey.withOpacity(0.2)),
            borderRadius: BorderRadius.circular(5.0),
            color: Theme.of(context).hintColor.withOpacity(0.1)),
        child: Text(widget.text,
            style: TextStyle(fontSize: 14.0, color: isHover ? Colors.deepPurpleAccent : Theme.of(context).hintColor)),
      ),
    );
  }
}
