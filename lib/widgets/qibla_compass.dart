import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_qiblah/flutter_qiblah.dart';

class QiblaCompass extends StatelessWidget {
  final QiblahDirection qiblahDirection;

  const QiblaCompass({super.key, required this.qiblahDirection});

  @override
  Widget build(BuildContext context) {
    final qiblaAngle = qiblahDirection.qiblah;
    final direction = qiblahDirection.direction;

    // Check if pointing towards Qibla (within 5 degrees)
    final isAligned = qiblaAngle.abs() < 5;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Qibla angle display
        _buildQiblaInfo(qiblaAngle, isAligned),
        const SizedBox(height: 20),

        // 3D Compass
        _build3DCompass(qiblaAngle, direction, isAligned),

        const SizedBox(height: 20),

        // Direction indicator
        _buildDirectionIndicator(qiblaAngle, isAligned),
      ],
    );
  }

  Widget _buildQiblaInfo(double qiblaAngle, bool isAligned) {
    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          decoration: BoxDecoration(
            color: isAligned
                ? const Color(0xFF4CAF50).withOpacity(0.3)
                : Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isAligned
                  ? const Color(0xFF4CAF50)
                  : Colors.white.withOpacity(0.2),
              width: 2,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isAligned ? Icons.check_circle : Icons.explore,
                color: isAligned ? const Color(0xFF4CAF50) : Colors.white70,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                isAligned
                    ? 'Facing Qibla ✓'
                    : 'Qibla: ${qiblaAngle.toStringAsFixed(1)}°',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isAligned ? const Color(0xFF4CAF50) : Colors.white,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _build3DCompass(double qiblaAngle, double direction, bool isAligned) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Outer glow effect
        Container(
          width: 320,
          height: 320,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: isAligned
                    ? const Color(0xFF4CAF50).withOpacity(0.4)
                    : const Color(0xFF4CAF50).withOpacity(0.1),
                blurRadius: 40,
                spreadRadius: 10,
              ),
            ],
          ),
        ),

        // Compass base (outer ring)
        Container(
          width: 300,
          height: 300,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF2E7D32).withOpacity(0.3),
                const Color(0xFF1B5E20).withOpacity(0.5),
                const Color(0xFF0D1B0F).withOpacity(0.8),
              ],
            ),
            border: Border.all(
              color: const Color(0xFF4CAF50).withOpacity(0.5),
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
        ),

        // Rotating compass dial
        AnimatedRotation(
          turns: -direction / 360,
          duration: const Duration(milliseconds: 300),
          child: SizedBox(
            width: 280,
            height: 280,
            child: CustomPaint(painter: CompassDialPainter()),
          ),
        ),

        // Middle ring with degree markers
        Container(
          width: 220,
          height: 220,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                const Color(0xFF1A3A1C),
                const Color(0xFF0D1B0F).withOpacity(0.9),
              ],
            ),
            border: Border.all(
              color: const Color(0xFF4CAF50).withOpacity(0.3),
              width: 2,
            ),
          ),
        ),

        // Qibla needle (points to Qibla)
        AnimatedRotation(
          turns: -qiblaAngle / 360,
          duration: const Duration(milliseconds: 300),
          child: SizedBox(
            width: 200,
            height: 200,
            child: CustomPaint(
              painter: QiblaNeedlePainter(isAligned: isAligned),
            ),
          ),
        ),

        // Center Kaaba icon
        Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [const Color(0xFF2E7D32), const Color(0xFF1B5E20)],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF4CAF50).withOpacity(0.5),
                blurRadius: 15,
                spreadRadius: 2,
              ),
            ],
          ),
          child: const Center(
            child: Text('🕋', style: TextStyle(fontSize: 36)),
          ),
        ),
      ],
    );
  }

  Widget _buildDirectionIndicator(double qiblaAngle, bool isAligned) {
    String directionText;
    IconData arrowIcon;

    if (isAligned) {
      directionText = "You're facing Qibla!";
      arrowIcon = Icons.check_circle;
    } else if (qiblaAngle > 0 && qiblaAngle <= 180) {
      directionText = "Turn Right ${qiblaAngle.toStringAsFixed(0)}°";
      arrowIcon = Icons.turn_right;
    } else if (qiblaAngle < 0 && qiblaAngle >= -180) {
      directionText = "Turn Left ${qiblaAngle.abs().toStringAsFixed(0)}°";
      arrowIcon = Icons.turn_left;
    } else if (qiblaAngle > 180) {
      directionText = "Turn Left ${(360 - qiblaAngle).toStringAsFixed(0)}°";
      arrowIcon = Icons.turn_left;
    } else {
      directionText = "Turn Right ${(360 + qiblaAngle).toStringAsFixed(0)}°";
      arrowIcon = Icons.turn_right;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: isAligned
            ? const Color(0xFF4CAF50).withOpacity(0.2)
            : Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            arrowIcon,
            color: isAligned ? const Color(0xFF4CAF50) : Colors.white70,
            size: 28,
          ),
          const SizedBox(width: 10),
          Text(
            directionText,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isAligned ? const Color(0xFF4CAF50) : Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

// Custom painter for compass dial with cardinal directions
class CompassDialPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Draw degree markers
    final markerPaint = Paint()
      ..color = Colors.white.withOpacity(0.5)
      ..strokeWidth = 1;

    final majorMarkerPaint = Paint()
      ..color = Colors.white.withOpacity(0.8)
      ..strokeWidth = 2;

    for (int i = 0; i < 360; i += 5) {
      final angle = (i - 90) * math.pi / 180;
      final isMajor = i % 30 == 0;
      final innerRadius = isMajor ? radius - 25 : radius - 15;

      final start = Offset(
        center.dx + innerRadius * math.cos(angle),
        center.dy + innerRadius * math.sin(angle),
      );
      final end = Offset(
        center.dx + (radius - 5) * math.cos(angle),
        center.dy + (radius - 5) * math.sin(angle),
      );

      canvas.drawLine(start, end, isMajor ? majorMarkerPaint : markerPaint);
    }

    // Draw cardinal directions
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    final cardinals = [
      {'label': 'N', 'angle': -90, 'color': const Color(0xFFFF5722)},
      {'label': 'E', 'angle': 0, 'color': Colors.white},
      {'label': 'S', 'angle': 90, 'color': Colors.white},
      {'label': 'W', 'angle': 180, 'color': Colors.white},
    ];

    for (final cardinal in cardinals) {
      final angle = (cardinal['angle'] as int) * math.pi / 180;
      final textRadius = radius - 45;

      textPainter.text = TextSpan(
        text: cardinal['label'] as String,
        style: TextStyle(
          color: cardinal['color'] as Color,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      );
      textPainter.layout();

      final offset = Offset(
        center.dx + textRadius * math.cos(angle) - textPainter.width / 2,
        center.dy + textRadius * math.sin(angle) - textPainter.height / 2,
      );
      textPainter.paint(canvas, offset);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Custom painter for Qibla direction needle
class QiblaNeedlePainter extends CustomPainter {
  final bool isAligned;

  QiblaNeedlePainter({required this.isAligned});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // Qibla needle (pointing up = towards Qibla when rotation is 0)
    final needlePath = Path();

    // Arrow head pointing up
    needlePath.moveTo(center.dx, 15); // Tip
    needlePath.lineTo(center.dx - 12, 50);
    needlePath.lineTo(center.dx - 4, 50);
    needlePath.lineTo(center.dx - 4, center.dy - 10);
    needlePath.lineTo(center.dx + 4, center.dy - 10);
    needlePath.lineTo(center.dx + 4, 50);
    needlePath.lineTo(center.dx + 12, 50);
    needlePath.close();

    final needlePaint = Paint()
      ..shader =
          LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isAligned
                ? [const Color(0xFF4CAF50), const Color(0xFF2E7D32)]
                : [const Color(0xFF81C784), const Color(0xFF4CAF50)],
          ).createShader(
            Rect.fromCenter(
              center: center,
              width: size.width,
              height: size.height,
            ),
          );

    // Draw shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);

    canvas.save();
    canvas.translate(3, 3);
    canvas.drawPath(needlePath, shadowPaint);
    canvas.restore();

    // Draw needle
    canvas.drawPath(needlePath, needlePaint);

    // Draw needle border
    final borderPaint = Paint()
      ..color = Colors.white.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawPath(needlePath, borderPaint);
  }

  @override
  bool shouldRepaint(covariant QiblaNeedlePainter oldDelegate) {
    return oldDelegate.isAligned != isAligned;
  }
}
