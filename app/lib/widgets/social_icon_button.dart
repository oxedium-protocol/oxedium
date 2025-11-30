import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:js' as js;

import 'package:oxedium_website/widgets/custom_inkwell.dart';

class SocialIconButton extends StatefulWidget {
  final String assetPath;
  final String url;
  final double height;

  const SocialIconButton({
    super.key,
    required this.assetPath,
    required this.url,
    required this.height,
  });

  @override
  SocialIconButtonState createState() => SocialIconButtonState();
}

class SocialIconButtonState extends State<SocialIconButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return CustomInkWell(
      onTap: () => js.context.callMethod('open', [widget.url]),
      onHover: (value) {
        _isHovered = value;
        setState(() {});
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform: _isHovered
            ? (Matrix4.identity()..scale(1.1)..translate(0, -4))
            : Matrix4.identity(),
        child: SvgPicture.asset(
          widget.assetPath,
          height: widget.height,
        ),
      ),
    );
  }
}
