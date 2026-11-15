import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// Renders the custom **CadenceFlow** brand icon (`assets/icons/cadenceflow_icon.png`)
/// featuring the 2x2 Eisenhower Matrix (3 Teal quadrants + 1 glowing Warm Amber
/// priority quadrant with upward cadence flow & checkmark), with a crisp
/// vector `CustomPaint` fallback so unit/widget tests and high-DPI AppBars
/// always render with zero flicker.
class CadenceFlowBrandIcon extends StatelessWidget {
  const CadenceFlowBrandIcon({
    super.key,
    this.size = 34,
    this.borderRadius = 10,
    this.showGlow = false,
  });

  final double size;
  final double borderRadius;
  final bool showGlow;

  static const String assetPath = 'assets/icons/cadenceflow_icon.png';

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: CadenceFlowTheme.surfaceSlateDark,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: showGlow
            ? [
                BoxShadow(
                  color:
                      CadenceFlowTheme.primaryTealDark.withValues(alpha: 0.30),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ]
            : null,
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.asset(
        assetPath,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return CustomPaint(
            size: Size.square(size),
            painter: _CadenceFlowMatrixLogoPainter(),
          );
        },
      ),
    );
  }
}

class _CadenceFlowMatrixLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = const Color(0xFF0C1618);
    canvas.drawRect(Offset.zero & size, bgPaint);

    final pad = size.width * 0.16;
    final gap = size.width * 0.06;
    final cell = (size.width - (pad * 2) - gap) / 2;
    final radius = Radius.circular(cell * 0.28);

    final tealPaint = Paint()..color = const Color(0xFF14B8A6);
    final amberPaint = Paint()..color = const Color(0xFFF59E0B);

    // Top-left (Teal)
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(pad, pad, cell, cell), radius),
      tealPaint,
    );
    // Top-right (Amber Priority Q1)
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(pad + cell + gap, pad, cell, cell),
        radius,
      ),
      amberPaint,
    );
    // Bottom-left (Teal)
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(pad, pad + cell + gap, cell, cell),
        radius,
      ),
      tealPaint,
    );
    // Bottom-right (Teal)
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(pad + cell + gap, pad + cell + gap, cell, cell),
        radius,
      ),
      tealPaint,
    );

    // Checkmark inside top-right Amber quadrant
    final checkPaint = Paint()
      ..color = const Color(0xFF0C1618)
      ..strokeWidth = size.width * 0.065
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final q1Left = pad + cell + gap;
    final q1Top = pad;
    final path = Path()
      ..moveTo(q1Left + cell * 0.25, q1Top + cell * 0.54)
      ..lineTo(q1Left + cell * 0.45, q1Top + cell * 0.74)
      ..lineTo(q1Left + cell * 0.78, q1Top + cell * 0.30);
    canvas.drawPath(path, checkPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
