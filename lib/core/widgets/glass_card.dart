import 'dart:ui';

import 'package:dominium/core/theme/dominium_theme.dart';
import 'package:flutter/material.dart';

class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.mood = ImperialMood.calmo,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final ImperialMood mood;

  @override
  Widget build(BuildContext context) {
    final nucleus = switch (mood) {
      ImperialMood.calmo => const Color(0x66381518),
      ImperialMood.alerta => const Color(0x66A04D10),
      ImperialMood.critico => const Color(0x66A01212),
      ImperialMood.vitoria => const Color(0x663B6A2C),
    };

    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.07),
                Colors.white.withOpacity(0.02),
              ],
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.white.withOpacity(0.18)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.65),
                blurRadius: 28,
                offset: const Offset(0, 16),
              ),
              BoxShadow(
                color: DominiumTheme.red.withOpacity(0.18),
                blurRadius: 16,
                offset: const Offset(-4, -2),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(-0.45, -0.75),
                      radius: 1.25,
                      colors: [nucleus, Colors.transparent],
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(painter: _NoisePainter(opacity: 0.025)),
                ),
              ),
              Padding(padding: padding, child: child),
            ],
          ),
        ),
      ),
    );
  }
}

class _NoisePainter extends CustomPainter {
  _NoisePainter({required this.opacity});
  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withOpacity(opacity);
    const gap = 12.0;
    for (double x = 0; x < size.width; x += gap) {
      for (double y = 0; y < size.height; y += gap) {
        if (((x + y) ~/ gap) % 2 == 0) {
          canvas.drawRect(Rect.fromLTWH(x, y, 1.2, 1.2), paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _NoisePainter oldDelegate) =>
      oldDelegate.opacity != opacity;
}

enum ImperialMood { calmo, alerta, critico, vitoria }
