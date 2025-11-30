import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:oxedium_website/widgets/custom_inkwell.dart';

class CustomBackButton extends StatefulWidget {
  const CustomBackButton({super.key});

  @override
  State<CustomBackButton> createState() => _CustomBackButtonState();
}

class _CustomBackButtonState extends State<CustomBackButton> {
  bool isHover = false;

  @override
  Widget build(BuildContext context) {
    return CustomInkWell(
      onTap: () => context.go('/'),
      onHover: (value) {
        isHover = value;
        setState(() {});
      },
      borderRadius: 100.0,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        height: 35.0,
        width: 35.0,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isHover ? Colors.deepPurpleAccent : Colors.grey.withOpacity(0.1),
        ),
        child: const Icon(Icons.arrow_back, color: Colors.white),
      ),
    );
  }
}
