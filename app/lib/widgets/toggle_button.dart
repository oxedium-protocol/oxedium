import 'package:flutter/material.dart';
import 'package:oxedium_website/widgets/custom_inkwell.dart';

class ToggleButton extends StatefulWidget {
  final bool isActive;
  final String text;
  final VoidCallback onTap;
  final Color activeColor;
  final double height;
  final double width;
  final FontWeight fontWeight;

  const ToggleButton({
    super.key,
    required this.isActive,
    required this.text,
    required this.onTap,
    required this.activeColor,
    this.height = 35.0,
    this.width = 50.0,
    this.fontWeight = FontWeight.bold
  });

  @override
  State<ToggleButton> createState() => _ToggleButtonState();
}

class _ToggleButtonState extends State<ToggleButton> {
  bool isHover = false;

  @override
  Widget build(BuildContext context) {
    return CustomInkWell(
      onTap: widget.onTap,
      onHover: (value) {
        setState(() {
          isHover = value;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        height: widget.height,
        width: widget.width,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: widget.isActive
              ? widget.activeColor.withOpacity(0.15)
              : isHover ? Colors.grey.withOpacity(0.1) : Colors.grey.withOpacity(0.05),
          borderRadius: BorderRadius.circular(10.0),
        ),
        child: Text(
          widget.text,
          style: TextStyle(
            color: widget.isActive ? widget.activeColor : Colors.grey.shade700,
            fontWeight: widget.fontWeight,
          ),
        ),
      ),
    );
  }
}
