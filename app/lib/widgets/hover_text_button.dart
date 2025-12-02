import 'package:flutter/material.dart';

class HoverTextButton extends StatefulWidget {
  final String text;
  final String? subText;
  final VoidCallback onTap;

  const HoverTextButton({super.key, required this.text, required this.onTap, this.subText});

  @override
  HoverTextButtonState createState() => HoverTextButtonState();
}

class HoverTextButtonState extends State<HoverTextButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: InkWell(
        onTap: widget.onTap,
        child: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 250),
          style: TextStyle(
            fontSize: 12.0,
            color: _isHovered ? Colors.black : Colors.grey.shade600,
            fontFamily: 'Aeonik'
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(widget.text),
              if (widget.subText != null)
              Padding(
                padding: const EdgeInsets.only(left: 4.0),
                child: Text(widget.subText!, style: const TextStyle(fontSize: 12.0)),
              ),
            ],
          ),
      )),
    );
  }
}
