import 'package:flutter/material.dart';
import 'package:oxedium_website/widgets/custom_inkwell.dart';

class ConnectWalletButton extends StatefulWidget {
  final Function() onTap;
  const ConnectWalletButton({super.key, required this.onTap});

  @override
  State<ConnectWalletButton> createState() => _ConnectWalletButtonState();
}

class _ConnectWalletButtonState extends State<ConnectWalletButton>
    with SingleTickerProviderStateMixin {
  bool isHover = false;

  late AnimationController _controller;
  late Animation<double> _positionAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<double> _jumpAnimation;

  final double buttonHeight = 35.0;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _positionAnimation = Tween<double>(
      begin: buttonHeight - 16,
      end: 0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _opacityAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.0).chain(CurveTween(curve: Curves.easeIn)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.0).chain(CurveTween(curve: Curves.easeOut)),
        weight: 60,
      ),
    ]).animate(_controller);

    // подпрыгивание в конце
    _jumpAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 80),
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -12.0).chain(CurveTween(curve: Curves.easeOut)), weight: 10),
      TweenSequenceItem(tween: Tween(begin: -12.0, end: 0.0).chain(CurveTween(curve: Curves.easeIn)), weight: 10),
    ]).animate(_controller);

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && isHover) {
        _controller.forward(from: 0);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _startAnimation() {
    if (!_controller.isAnimating) {
      _controller.forward(from: 0);
    }
  }

  void _stopAnimation() {
    _controller.stop();
  }

  @override
  Widget build(BuildContext context) {
    return CustomInkWell(
      onTap: () {
        _stopAnimation();
        widget.onTap();
      },
      onHover: (value) {
        setState(() => isHover = value);
        if (value) {
          _startAnimation();
        } else {
          _stopAnimation();
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        height: buttonHeight,
        width: 160.0,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: isHover ? const Color(0xFF7637EC) : Colors.white,
          borderRadius: BorderRadius.circular(500.0),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                if (!isHover) return const SizedBox();
                return Positioned(
                  left: 8,
                  top: _positionAnimation.value + _jumpAnimation.value,
                  child: Opacity(
                    opacity: _opacityAnimation.value,
                    child: const Icon(
                      Icons.power,
                      size: 21.0,
                      color: Colors.white,
                    ),
                  ),
                );
              },
            ),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 250),
              style: TextStyle(
                color: isHover ? Colors.white : Colors.black,
                fontFamily: 'Aeonik',
                fontSize: 17.0,
              ),
              child: const Text('Connect'),
            ),
          ],
        ),
      ),
    );
  }
}
