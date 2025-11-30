import 'package:flutter/material.dart';
import 'package:oxedium_website/adapter/adapter.dart';
import 'package:oxedium_website/utils/extensions.dart';
import 'package:oxedium_website/widgets/custom_inkwell.dart';

class DisconnectWalletButton extends StatefulWidget {
  final Adapter wallet;
  final Function() onTap;

  const DisconnectWalletButton({
    super.key,
    required this.wallet,
    required this.onTap,
  });

  @override
  State<DisconnectWalletButton> createState() => _DisconnectWalletButtonState();
}

class _DisconnectWalletButtonState extends State<DisconnectWalletButton> {
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
        height: 32.0,
        width: 160.0,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        decoration: BoxDecoration(
          border: Border.all(
            color: isHover ? Colors.redAccent.withOpacity(0.3) : Colors.grey.withOpacity(0.2),
          ),
          borderRadius: BorderRadius.circular(5.0),
          color: Colors.transparent,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(5.0),
              child: Image.asset(
                widget.wallet.logoUrl,
                height: 21.0,
                width: 21.0,
              ),
            ),
            Text(
              widget.wallet.pubkey!.cutText(start: 2, end: 4),
              style: const TextStyle(fontSize: 15.0),
            ),
            TweenAnimationBuilder<Color?>(
              tween: ColorTween(
                begin: Colors.grey.shade700,
                end: isHover ? Colors.redAccent : Colors.grey.shade700,
              ),
              duration: const Duration(milliseconds: 250),
              builder: (context, color, child) {
                return Icon(
                  Icons.power_settings_new,
                  size: 18.0,
                  color: color,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
