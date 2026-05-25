import 'dart:math';
import 'package:flutter/material.dart';

// --- تأثير الأشكال المضيئة المتحركة (الدلع) ---

class MovingOrb {
  Offset position;
  double radius;
  Color color;
  double angle;
  double speed;

  MovingOrb({
    required this.position,
    required this.radius,
    required this.color,
    required this.angle,
    required this.speed,
  });
}

class VolunteerMovingOrbsBackground extends StatefulWidget {
  const VolunteerMovingOrbsBackground({super.key});

  @override
  State<VolunteerMovingOrbsBackground> createState() =>
      _VolunteerMovingOrbsBackgroundState();
}

class _VolunteerMovingOrbsBackgroundState
    extends State<VolunteerMovingOrbsBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<MovingOrb> _orbs;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 20))
          ..repeat();

    _orbs = [
      MovingOrb(
        position: const Offset(0.2, 0.3),
        radius: 150,
        color: const Color(0xFFa7f3d0).withValues(alpha: 0.3),
        angle: 0.0,
        speed: 0.02,
      ),
      MovingOrb(
        position: const Offset(0.8, 0.7),
        radius: 200,
        color: const Color(0xFFfef08a).withValues(alpha: 0.3),
        angle: pi,
        speed: 0.015,
      ),
      MovingOrb(
        position: const Offset(0.5, 0.5),
        radius: 120,
        color: const Color(0xFFd1fae5).withValues(alpha: 0.4),
        angle: pi / 2,
        speed: 0.025,
      ),
    ];
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            painter:
                OrbsPainter(orbs: _orbs, animationValue: _controller.value),
          );
        },
      ),
    );
  }
}

class OrbsPainter extends CustomPainter {
  final List<MovingOrb> orbs;
  final double animationValue;

  OrbsPainter({required this.orbs, required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (var i = 0; i < orbs.length; i++) {
      final orb = orbs[i];

      double currentAngle =
          orb.angle + (animationValue * 2 * pi * orb.speed * 10);
      double dx = orb.position.dx * size.width + cos(currentAngle) * 50;
      double dy = orb.position.dy * size.height + sin(currentAngle) * 50;

      final currentPos = Offset(dx, dy);

      paint.color = orb.color;
      paint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 60);

      canvas.drawCircle(currentPos, orb.radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant OrbsPainter oldDelegate) => true;
}

// --- تأثير الجزيئات المتطايرة ---

class DustParticle {
  Offset position;
  double speed;
  double radius;
  Color color;

  DustParticle({
    required this.position,
    required this.speed,
    required this.radius,
    required this.color,
  });
}

class VolunteerParticleBackground extends StatefulWidget {
  final int count;
  const VolunteerParticleBackground({super.key, this.count = 500});

  @override
  State<VolunteerParticleBackground> createState() =>
      _VolunteerParticleBackgroundState();
}

class _VolunteerParticleBackgroundState
    extends State<VolunteerParticleBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<DustParticle> _dust;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 15))
          ..repeat();

    final random = Random();
    final colors = [
      const Color(0xFF4ade80).withValues(alpha: 0.4),
      const Color(0xFFfacc15).withValues(alpha: 0.4),
    ];

    _dust = List.generate(widget.count, (index) {
      return DustParticle(
        position: Offset(random.nextDouble(), random.nextDouble()),
        speed: random.nextDouble() * 0.03 + 0.01,
        radius: random.nextDouble() * 2.0 + 0.5,
        color: colors[random.nextInt(colors.length)],
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            painter:
                DustPainter(dust: _dust, animationValue: _controller.value),
          );
        },
      ),
    );
  }
}

class DustPainter extends CustomPainter {
  final List<DustParticle> dust;
  final double animationValue;

  DustPainter({required this.dust, required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (var i = 0; i < dust.length; i++) {
      final p = dust[i];

      double dy = (p.position.dy * size.height) -
          (animationValue * p.speed * size.height);
      if (dy < 0) dy += size.height;

      double dx =
          p.position.dx * size.width + sin(animationValue * 2 * pi + i) * 5;

      final currentPos = Offset(dx, dy);

      double opacity = (sin(animationValue * 2 * pi * 2 + i) + 1) / 2;
      paint.color = p.color.withValues(alpha: p.color.a * opacity);

      canvas.drawCircle(currentPos, p.radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant DustPainter oldDelegate) => true;
}

// --- ويدجت الخلفية المشتركة ---

class VolunteerAnimatedBackground extends StatelessWidget {
  final Widget child;
  final int particleCount;

  const VolunteerAnimatedBackground({
    super.key,
    required this.child,
    this.particleCount = 500,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const VolunteerMovingOrbsBackground(),
        VolunteerParticleBackground(count: particleCount),
        child,
      ],
    );
  }
}
