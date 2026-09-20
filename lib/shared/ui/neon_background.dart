import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:hswarehouse/app/theme/app_theme.dart';

/// AI-atmosphere field for the main content area.
/// Soft mesh + precision grid — distinct from the dense sidebar.
class NeonBackground extends StatelessWidget {
  const NeonBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: AppTheme.background),
        const _MeshLayer(),
        const _GridLayer(),
        const _OrbitPulse(),
        child,
      ],
    );
  }
}

class _MeshLayer extends StatelessWidget {
  const _MeshLayer();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(-0.85, -0.95),
          radius: 1.35,
          colors: [
            AppTheme.neon.withValues(alpha: 0.14),
            AppTheme.background.withValues(alpha: 0),
          ],
        ),
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(1.05, -0.15),
            radius: 1.2,
            colors: [
              AppTheme.neonAlt.withValues(alpha: 0.12),
              AppTheme.background.withValues(alpha: 0),
            ],
          ),
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppTheme.mainPanel.withValues(alpha: 0.35),
                AppTheme.background.withValues(alpha: 0.92),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GridLayer extends StatelessWidget {
  const _GridLayer();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _AiGridPainter(),
      child: const SizedBox.expand(),
    );
  }
}

class _AiGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.neonAlt.withValues(alpha: 0.045)
      ..strokeWidth = 1;

    const step = 48.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // Horizon accent line
    final horizon = Paint()
      ..shader = LinearGradient(
        colors: [
          AppTheme.neon.withValues(alpha: 0),
          AppTheme.neon.withValues(alpha: 0.18),
          AppTheme.neonAlt.withValues(alpha: 0),
        ],
      ).createShader(Rect.fromLTWH(0, size.height * 0.22, size.width, 2));
    canvas.drawRect(
      Rect.fromLTWH(0, size.height * 0.22, size.width, 1.2),
      horizon,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _OrbitPulse extends StatefulWidget {
  const _OrbitPulse();

  @override
  State<_OrbitPulse> createState() => _OrbitPulseState();
}

class _OrbitPulseState extends State<_OrbitPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        final t = _ctrl.value * math.pi * 2;
        return IgnorePointer(
          child: Stack(
            children: [
              Positioned(
                right: 40 + 24 * math.cos(t),
                top: 80 + 18 * math.sin(t),
                child: _Orb(
                  size: 120,
                  color: AppTheme.neonAlt.withValues(alpha: 0.07),
                ),
              ),
              Positioned(
                left: 60 + 16 * math.sin(t * 0.8),
                bottom: 100 + 20 * math.cos(t * 0.8),
                child: _Orb(
                  size: 90,
                  color: AppTheme.neon.withValues(alpha: 0.06),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Orb extends StatelessWidget {
  const _Orb({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, color.withValues(alpha: 0)],
        ),
      ),
    );
  }
}

int responsiveGridCount(double width) {
  if (width >= 1400) return 6;
  if (width >= 1100) return 5;
  if (width >= 850) return 4;
  if (width >= 600) return 3;
  return 2;
}
