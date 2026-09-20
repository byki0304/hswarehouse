import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:hswarehouse/app/theme/app_theme.dart';

/// Bold Illustrator-style wordmark: geometric HS mark + HS Warehouse type.
class HsWarehouseLogo extends StatefulWidget {
  const HsWarehouseLogo({
    super.key,
    this.compact = false,
    this.showWordmark = true,
  });

  final bool compact;
  final bool showWordmark;

  @override
  State<HsWarehouseLogo> createState() => _HsWarehouseLogoState();
}

class _HsWarehouseLogoState extends State<HsWarehouseLogo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4200),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final markSize = widget.compact ? 40.0 : 72.0;

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        final t = _ctrl.value;
        final sheen = 0.55 + 0.45 * math.sin(t * math.pi * 2);

        if (widget.compact) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _HsMark(size: markSize, sheen: sheen),
              if (widget.showWordmark) ...[
                const SizedBox(width: 10),
                Flexible(child: _Wordmark(compact: true)),
              ],
            ],
          );
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _HsMark(size: markSize, sheen: sheen),
            if (widget.showWordmark) ...[
              const SizedBox(height: 14),
              const _Wordmark(compact: false),
            ],
          ],
        );
      },
    );
  }
}

class _Wordmark extends StatelessWidget {
  const _Wordmark({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final hsStyle = GoogleFonts.spaceGrotesk(
      fontSize: compact ? 18 : 26,
      fontWeight: FontWeight.w800,
      letterSpacing: compact ? 0.4 : 1.2,
      height: 1,
      color: AppTheme.textPrimary,
    );
    final warehouseStyle = GoogleFonts.spaceGrotesk(
      fontSize: compact ? 11 : 13,
      fontWeight: FontWeight.w700,
      letterSpacing: compact ? 2.4 : 4.2,
      height: 1.2,
      color: AppTheme.neon,
    );

    return Column(
      crossAxisAlignment:
          compact ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Offset "poster" type — Illustrator layered stroke feel
        Stack(
          alignment: compact ? Alignment.centerLeft : Alignment.center,
          children: [
            Transform.translate(
              offset: const Offset(1.5, 1.5),
              child: Text(
                'HS',
                style: hsStyle.copyWith(
                  color: AppTheme.neonAlt.withValues(alpha: 0.35),
                ),
              ),
            ),
            Text('HS', style: hsStyle),
          ],
        ),
        const SizedBox(height: 2),
        Text('WAREHOUSE', style: warehouseStyle),
      ],
    );
  }
}

class _HsMark extends StatelessWidget {
  const _HsMark({required this.size, required this.sheen});

  final double size;
  final double sheen;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _HsMarkPainter(sheen: sheen),
      ),
    );
  }
}

class _HsMarkPainter extends CustomPainter {
  _HsMarkPainter({required this.sheen});

  final double sheen;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final inset = w * 0.08;
    final r = RRect.fromRectAndRadius(
      Rect.fromLTWH(inset, inset, w - inset * 2, w - inset * 2),
      Radius.circular(w * 0.18),
    );

    // Offset plate (Illustrator duplicate / offset path)
    final offsetPlate = r.shift(Offset(w * 0.04, w * 0.05));
    canvas.drawRRect(
      offsetPlate,
      Paint()
        ..color = AppTheme.neonAlt.withValues(alpha: 0.22)
        ..style = PaintingStyle.fill,
    );

    // Main plate
    final fill = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color.lerp(AppTheme.surfaceElevated, AppTheme.neon, 0.08 * sheen)!,
          AppTheme.sidebar,
        ],
      ).createShader(r.outerRect);
    canvas.drawRRect(r, fill);

    // Bold stroke
    canvas.drawRRect(
      r,
      Paint()
        ..color = AppTheme.neon.withValues(alpha: 0.55 + 0.35 * sheen)
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.045,
    );

    // Inner geometric frame
    final inner = r.deflate(w * 0.1);
    canvas.drawRRect(
      inner,
      Paint()
        ..color = AppTheme.neonAlt.withValues(alpha: 0.28)
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.018,
    );

    // HS letters as bold geometric paths
    final letterPaint = Paint()
      ..color = AppTheme.textPrimary
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.07
      ..strokeCap = StrokeCap.square
      ..strokeJoin = StrokeJoin.miter;

    final accent = Paint()
      ..color = AppTheme.neon.withValues(alpha: 0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.035
      ..strokeCap = StrokeCap.square;

    final cx = w * 0.5;
    final cy = w * 0.52;
    final letterH = w * 0.34;
    final letterW = w * 0.14;
    final gap = w * 0.06;

    // H
    final hx = cx - letterW - gap * 0.5;
    canvas.drawLine(
      Offset(hx, cy - letterH / 2),
      Offset(hx, cy + letterH / 2),
      letterPaint,
    );
    canvas.drawLine(
      Offset(hx + letterW, cy - letterH / 2),
      Offset(hx + letterW, cy + letterH / 2),
      letterPaint,
    );
    canvas.drawLine(
      Offset(hx, cy),
      Offset(hx + letterW, cy),
      accent,
    );

    // S (simplified block S)
    final sx = cx + gap * 0.5;
    final path = Path()
      ..moveTo(sx + letterW, cy - letterH / 2)
      ..lineTo(sx, cy - letterH / 2)
      ..lineTo(sx, cy)
      ..lineTo(sx + letterW, cy)
      ..lineTo(sx + letterW, cy + letterH / 2)
      ..lineTo(sx, cy + letterH / 2);
    canvas.drawPath(path, letterPaint);

    // Corner ticks
    final tick = Paint()
      ..color = AppTheme.neonAlt.withValues(alpha: 0.7)
      ..strokeWidth = w * 0.02
      ..strokeCap = StrokeCap.square;
    final tLen = w * 0.08;
    canvas.drawLine(Offset(inset + 2, inset + tLen), Offset(inset + 2, inset + 2), tick);
    canvas.drawLine(Offset(inset + 2, inset + 2), Offset(inset + tLen, inset + 2), tick);
    canvas.drawLine(
      Offset(w - inset - 2, w - inset - tLen),
      Offset(w - inset - 2, w - inset - 2),
      tick,
    );
    canvas.drawLine(
      Offset(w - inset - 2, w - inset - 2),
      Offset(w - inset - tLen, w - inset - 2),
      tick,
    );
  }

  @override
  bool shouldRepaint(covariant _HsMarkPainter oldDelegate) =>
      oldDelegate.sheen != sheen;
}
