import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/jarvis_theme.dart';

class ArcReactor extends StatefulWidget {
  final bool isListening;
  final bool isThinking;
  final bool isOnline;
  final double size;

  const ArcReactor({
    super.key,
    this.isListening = false,
    this.isThinking = false,
    this.isOnline = false,
    this.size = 160,
  });

  @override
  State<ArcReactor> createState() => _ArcReactorState();
}

class _ArcReactorState extends State<ArcReactor>
    with TickerProviderStateMixin {
  late AnimationController _rotateCtrl;
  late AnimationController _pulseCtrl;
  late AnimationController _scanCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();

    _rotateCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _scanCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _pulseAnim = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _rotateCtrl.dispose();
    _pulseCtrl.dispose();
    _scanCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color glowColor = widget.isListening
        ? JarvisTheme.redAlert
        : widget.isThinking
            ? JarvisTheme.goldAccent
            : JarvisTheme.arcBlue;

    return AnimatedBuilder(
      animation: Listenable.merge([_rotateCtrl, _pulseCtrl, _scanCtrl]),
      builder: (context, _) {
        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer glow ring
              _buildGlowRing(widget.size, glowColor, 0.3),
              // Rotating hex ring
              Transform.rotate(
                angle: _rotateCtrl.value * 2 * pi,
                child: _buildHexRing(widget.size * 0.9, glowColor),
              ),
              // Counter-rotating inner ring
              Transform.rotate(
                angle: -_rotateCtrl.value * 2 * pi * 1.5,
                child: _buildDotRing(widget.size * 0.72, glowColor),
              ),
              // Pulse scale ring
              Transform.scale(
                scale: widget.isListening || widget.isThinking
                    ? _pulseAnim.value
                    : 1.0,
                child: _buildCoreRing(widget.size * 0.55, glowColor),
              ),
              // Center circle
              _buildCore(widget.size * 0.28, glowColor),
              // Scan line (only when active)
              if (widget.isListening || widget.isThinking)
                _buildScanLine(widget.size * 0.55, glowColor),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGlowRing(double size, Color color, double opacity) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(opacity),
            blurRadius: 40,
            spreadRadius: 10,
          ),
        ],
      ),
    );
  }

  Widget _buildHexRing(double size, Color color) {
    return CustomPaint(
      size: Size(size, size),
      painter: _HexRingPainter(color: color),
    );
  }

  Widget _buildDotRing(double size, Color color) {
    return CustomPaint(
      size: Size(size, size),
      painter: _DotRingPainter(color: color),
    );
  }

  Widget _buildCoreRing(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color.withOpacity(0.6), width: 1.5),
        boxShadow: [
          BoxShadow(color: color.withOpacity(0.3), blurRadius: 12, spreadRadius: 2),
        ],
      ),
    );
  }

  Widget _buildCore(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color.withOpacity(0.95),
            color.withOpacity(0.6),
            color.withOpacity(0.1),
          ],
        ),
        boxShadow: [
          BoxShadow(color: color, blurRadius: 20, spreadRadius: 3),
        ],
      ),
    );
  }

  Widget _buildScanLine(double size, Color color) {
    return Transform.rotate(
      angle: _scanCtrl.value * 2 * pi,
      child: CustomPaint(
        size: Size(size, size),
        painter: _ScanLinePainter(color: color, progress: _scanCtrl.value),
      ),
    );
  }
}

class _HexRingPainter extends CustomPainter {
  final Color color;
  _HexRingPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.7)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final center = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2;
    final count = 12;

    for (int i = 0; i < count; i++) {
      final angle = (i / count) * 2 * pi;
      final x = center.dx + r * cos(angle);
      final y = center.dy + r * sin(angle);
      // small tick marks
      final innerX = center.dx + (r - 8) * cos(angle);
      final innerY = center.dy + (r - 8) * sin(angle);
      canvas.drawLine(Offset(innerX, innerY), Offset(x, y), paint);
    }

    // Draw the arc circle
    canvas.drawCircle(center, r - 2, paint..color = color.withOpacity(0.4));
  }

  @override
  bool shouldRepaint(_) => true;
}

class _DotRingPainter extends CustomPainter {
  final Color color;
  _DotRingPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color.withOpacity(0.8);
    final center = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2 - 4;
    const count = 8;

    for (int i = 0; i < count; i++) {
      final angle = (i / count) * 2 * pi;
      final x = center.dx + r * cos(angle);
      final y = center.dy + r * sin(angle);
      canvas.drawCircle(Offset(x, y), 3, paint);
    }
  }

  @override
  bool shouldRepaint(_) => true;
}

class _ScanLinePainter extends CustomPainter {
  final Color color;
  final double progress;
  _ScanLinePainter({required this.color, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2;

    final paint = Paint()
      ..shader = RadialGradient(
        colors: [color.withOpacity(0.6), color.withOpacity(0.0)],
      ).createShader(Rect.fromCircle(center: center, radius: r))
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(center.dx, center.dy)
      ..arcTo(
        Rect.fromCircle(center: center, radius: r),
        -pi / 2,
        pi / 3,
        false,
      )
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_) => true;
}

/// Status indicator widget
class StatusIndicator extends StatelessWidget {
  final bool isOnline;
  const StatusIndicator({super.key, required this.isOnline});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isOnline ? JarvisTheme.arcBlue : JarvisTheme.textDim,
            boxShadow: isOnline
                ? [BoxShadow(color: JarvisTheme.arcBlue, blurRadius: 6, spreadRadius: 1)]
                : null,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          isOnline ? 'JARVIS ONLINE' : 'OFFLINE',
          style: TextStyle(
            fontSize: 11,
            letterSpacing: 2,
            color: isOnline ? JarvisTheme.arcBlue : JarvisTheme.textDim,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
