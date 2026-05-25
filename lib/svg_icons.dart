import 'package:flutter/material.dart';
import 'dart:math';

class AppIcons {
  static Widget lock({double size = 28, Color color = Colors.white}) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: LockPainter(color: color)),
    );
  }

  static Widget user({
    double size = 14,
    Color color = const Color(0xFF3C3489),
  }) {
    return CustomPaint(
      size: Size(size, size),
      painter: UserPainter(color: color),
    );
  }

  static Widget nurse({
    double size = 14,
    Color color = const Color(0xFF3C3489),
  }) {
    return CustomPaint(
      size: Size(size, size),
      painter: NursePainter(color: color),
    );
  }

  static Widget family({
    double size = 14,
    Color color = const Color(0xFF3C3489),
  }) {
    return CustomPaint(
      size: Size(size, size),
      painter: FamilyPainter(color: color),
    );
  }

  static Widget volunteer({
    double size = 14,
    Color color = const Color(0xFF3C3489),
  }) {
    return CustomPaint(
      size: Size(size, size),
      painter: StarPainter(color: color),
    );
  }

  static Widget eye({double size = 12, Color color = const Color(0xFFAFA9EC)}) {
    return CustomPaint(
      size: Size(size, size),
      painter: EyePainter(color: color),
    );
  }

  static Widget check({double size = 9, Color color = Colors.white}) {
    return CustomPaint(
      size: Size(size, size),
      painter: CheckPainter(color: color),
    );
  }

  static Widget arrow({double size = 14, Color color = Colors.white}) {
    return CustomPaint(
      size: Size(size, size),
      painter: ArrowPainter(color: color),
    );
  }

  static Widget google({double size = 14}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Center(
        child: Text(
          'G',
          style: TextStyle(
            color: const Color(0xFF4285F4),
            fontSize: size * 0.6,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class LockPainter extends CustomPainter {
  final Color color;
  LockPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.9)
      ..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..color = const Color(0xFF6C63FF)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    final whitePaint = Paint()
      ..color = color.withValues(alpha: 0.9)
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * 0.14,
          size.height * 0.36,
          size.width * 0.72,
          size.height * 0.5,
        ),
        const Radius.circular(4),
      ),
      paint,
    );

    canvas.drawLine(
      Offset(size.width * 0.14, size.height * 0.5),
      Offset(size.width * 0.86, size.height * 0.5),
      strokePaint,
    );
    canvas.drawArc(
      Rect.fromLTWH(
        size.width * 0.36,
        size.height * 0.25,
        size.width * 0.28,
        size.height * 0.28,
      ),
      3.14,
      3.14,
      false,
      whitePaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.64),
      size.width * 0.07,
      Paint()..color = const Color(0xFF6C63FF),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class UserPainter extends CustomPainter {
  final Color color;
  UserPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.36),
      size.width * 0.21,
      paint,
    );
    final path = Path();
    path.moveTo(size.width * 0.14, size.height * 0.93);
    path.quadraticBezierTo(
      size.width * 0.14,
      size.height * 0.64,
      size.width * 0.5,
      size.height * 0.64,
    );
    path.quadraticBezierTo(
      size.width * 0.86,
      size.height * 0.64,
      size.width * 0.86,
      size.height * 0.93,
    );
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class NursePainter extends CustomPainter {
  final Color color;
  NursePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.29),
      size.width * 0.18,
      paint,
    );
    final path = Path();
    path.moveTo(size.width * 0.07, size.height * 0.93);
    path.quadraticBezierTo(
      size.width * 0.07,
      size.height * 0.71,
      size.width * 0.5,
      size.height * 0.71,
    );
    path.quadraticBezierTo(
      size.width * 0.93,
      size.height * 0.71,
      size.width * 0.93,
      size.height * 0.93,
    );
    canvas.drawPath(path, paint);
    canvas.drawLine(
      Offset(size.width * 0.71, size.height * 0.57),
      Offset(size.width * 0.93, size.height * 0.79),
      Paint()
        ..color = color
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class FamilyPainter extends CustomPainter {
  final Color color;
  FamilyPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.1
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(
      Offset(size.width * 0.36, size.height * 0.32),
      size.width * 0.14,
      paint,
    );
    final path1 = Path();
    path1.moveTo(size.width * 0.07, size.height * 0.93);
    path1.quadraticBezierTo(
      size.width * 0.07,
      size.height * 0.79,
      size.width * 0.36,
      size.height * 0.79,
    );
    path1.quadraticBezierTo(
      size.width * 0.64,
      size.height * 0.79,
      size.width * 0.64,
      size.height * 0.93,
    );
    canvas.drawPath(path1, paint);
    canvas.drawCircle(
      Offset(size.width * 0.64, size.height * 0.32),
      size.width * 0.14,
      paint,
    );
    final path2 = Path();
    path2.moveTo(size.width * 0.5, size.height * 0.93);
    path2.quadraticBezierTo(
      size.width * 0.5,
      size.height * 0.79,
      size.width * 0.64,
      size.height * 0.79,
    );
    path2.quadraticBezierTo(
      size.width * 0.93,
      size.height * 0.79,
      size.width * 0.93,
      size.height * 0.93,
    );
    canvas.drawPath(path2, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class StarPainter extends CustomPainter {
  final Color color;
  StarPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.1
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round;
    final path = Path();
    final center = Offset(size.width * 0.5, size.height * 0.5);
    final outerRadius = size.width * 0.43;
    final innerRadius = size.width * 0.21;

    for (int i = 0; i < 10; i++) {
      final radius = i.isEven ? outerRadius : innerRadius;
      final angle = (i * 3.14159 / 5) - (3.14159 / 2);
      final x = center.dx + radius * cos(angle);
      final y = center.dy + radius * sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class EyePainter extends CustomPainter {
  final Color color;
  EyePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    final path = Path();
    path.moveTo(size.width * 0.08, size.height * 0.5);
    path.quadraticBezierTo(
      size.width * 0.33,
      size.height * 0.17,
      size.width * 0.5,
      size.height * 0.17,
    );
    path.quadraticBezierTo(
      size.width * 0.67,
      size.height * 0.17,
      size.width * 0.92,
      size.height * 0.5,
    );
    path.quadraticBezierTo(
      size.width * 0.67,
      size.height * 0.83,
      size.width * 0.5,
      size.height * 0.83,
    );
    path.quadraticBezierTo(
      size.width * 0.33,
      size.height * 0.83,
      size.width * 0.08,
      size.height * 0.5,
    );
    canvas.drawPath(path, paint);
    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.5),
      size.width * 0.13,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class CheckPainter extends CustomPainter {
  final Color color;
  CheckPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final path = Path();
    path.moveTo(size.width * 0.11, size.height * 0.5);
    path.lineTo(size.width * 0.39, size.height * 0.86);
    path.lineTo(size.width * 0.89, size.height * 0.14);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class ArrowPainter extends CustomPainter {
  final Color color;
  ArrowPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawLine(
      Offset(size.width * 0.21, size.height * 0.5),
      Offset(size.width * 0.79, size.height * 0.5),
      paint,
    );
    final path = Path();
    path.moveTo(size.width * 0.57, size.height * 0.29);
    path.lineTo(size.width * 0.79, size.height * 0.5);
    path.lineTo(size.width * 0.57, size.height * 0.71);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
