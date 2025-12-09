import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class StarsProgressIndicator extends StatefulWidget {
  const StarsProgressIndicator({super.key});

  @override
  State<StarsProgressIndicator> createState() => _StarsProgressIndicatorState();
}

class _StarsProgressIndicatorState extends State<StarsProgressIndicator>
    with TickerProviderStateMixin {
  late AnimationController _centerController;
  late Animation<double> _centerRotation;

  late AnimationController _leftController;
  late Animation<double> _leftRotation;

  late AnimationController _rightController;
  late Animation<double> _rightRotation;

  @override
  void initState() {
    super.initState();

    _centerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _centerRotation = Tween<double>(begin: 0, end: 90 / 360)
        .animate(CurvedAnimation(parent: _centerController, curve: Curves.easeInOut));

    _animateCenterStar();

    _leftController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _leftRotation = Tween<double>(begin: 0, end: 90 / 360)
        .animate(CurvedAnimation(parent: _leftController, curve: Curves.easeInOut));

    _rightController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _rightRotation = Tween<double>(begin: 0, end: 90 / 360)
        .animate(CurvedAnimation(parent: _rightController, curve: Curves.easeInOut));

    _animateSideStars();
  }

  void _animateCenterStar() async {
    while (mounted) {
      await _centerController.forward();
      await Future.delayed(const Duration(milliseconds: 1000));
      _centerController.reset();
    }
  }

  void _animateSideStars() async {
    await Future.delayed(const Duration(milliseconds: 500)); // старт через 1 секунду
    while (mounted) {
      await Future.wait([
        _leftController.forward(),
        _rightController.forward(),
      ]);
      await Future.delayed(const Duration(milliseconds: 1000));
      _leftController.reset();
      _rightController.reset();
    }
  }

  @override
  void dispose() {
    // _centerController.dispose();
    // _leftController.dispose();
    // _rightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        RotationTransition(
          turns: _leftRotation,
          child: SvgPicture.asset('assets/icons/star.svg', height: 8.0, width: 8.0),
        ),
        const SizedBox(width: 17.0),
        RotationTransition(
          turns: _centerRotation,
          child: SvgPicture.asset('assets/icons/star.svg', height: 10.0, width: 10.0),
        ),
        const SizedBox(width: 17.0),
        RotationTransition(
          turns: _rightRotation,
          child: SvgPicture.asset('assets/icons/star.svg', height: 8.0, width: 8.0),
        ),
      ],
    );
  }
}
