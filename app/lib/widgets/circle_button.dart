import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:oxedium_website/widgets/custom_inkwell.dart';

class CircleButton extends StatefulWidget {
  final String assetUrl;
  final Function() onTap;
  final double padding;
  const CircleButton({super.key, required this.assetUrl, required this.onTap, required this.padding});

  @override
  State<CircleButton> createState() => _CircleButtonState();
}

class _CircleButtonState extends State<CircleButton> {
  @override
  Widget build(BuildContext context) {
    return CustomInkWell(
      onTap: widget.onTap,
      child: Container(
        height: 35.0,
        width: 35.0,
        alignment: Alignment.center,
        padding: EdgeInsets.all(widget.padding),
        decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.black),
        child: SvgPicture.asset(widget.assetUrl),
      ),
    );
  }
}
