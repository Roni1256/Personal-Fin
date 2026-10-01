import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class FinOrb extends StatefulWidget {
  final double size;
  final bool isThinking;

  const FinOrb({
    super.key,
    this.size = 48,
    this.isThinking = false,
  });

  @override
  State<FinOrb> createState() => _FinOrbState();
}

class _FinOrbState extends State<FinOrb> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: widget.isThinking ? 1000 : 2500),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.92, end: 1.08).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(FinOrb oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isThinking != widget.isThinking) {
      _controller.duration = Duration(milliseconds: widget.isThinking ? 1000 : 2500);
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const RadialGradient(
                colors: [
                  AppColors.lavenderGlow,
                  AppColors.gradientMid,
                  AppColors.violet700,
                ],
                center: Alignment(-0.2, -0.3),
                radius: 0.9,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.violet600.withValues(alpha: widget.isThinking ? 0.6 : 0.35),
                  blurRadius: widget.size * (widget.isThinking ? 0.6 : 0.4),
                  spreadRadius: widget.isThinking ? 4 : 2,
                ),
              ],
            ),
            child: Center(
              child: Icon(
                Icons.auto_awesome_rounded,
                size: widget.size * 0.45,
                color: Colors.white,
              ),
            ),
          ),
        );
      },
    );
  }
}
