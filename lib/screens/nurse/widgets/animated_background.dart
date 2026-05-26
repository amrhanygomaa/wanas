import 'dart:math';
import 'package:flutter/material.dart';

class AnimatedBackground extends StatefulWidget {
  final Widget child;
  const AnimatedBackground({super.key, required this.child});

  @override
  State<AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return CustomPaint(
              painter: BackgroundPainter(_controller.value),
              child: Container(),
            );
          },
        ),
        const SodaBubblesBackground(), // إضافة فقاعات المياه الغازية (+)
        widget.child,
      ],
    );
  }
}

class BackgroundPainter extends CustomPainter {
  final double progress;
  BackgroundPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint1 = Paint()
      ..color = const Color(0xFFBAE6FD).withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;

    // Draw some circles that move based on progress!
    final center1 = Offset(size.width * 0.2, size.height * (0.2 + 0.1 * sin(progress * 2 * pi)));
    canvas.drawCircle(center1, 150, paint1);

    final paint2 = Paint()
      ..color = const Color(0xFFD1FAE5).withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;
    final center2 = Offset(size.width * 0.8, size.height * (0.8 - 0.1 * cos(progress * 2 * pi)));
    canvas.drawCircle(center2, 200, paint2);

    final paint3 = Paint()
      ..color = const Color(0xFFFEF08A).withValues(alpha: 0.1)
      ..style = PaintingStyle.fill;
    final center3 = Offset(size.width * 0.5, size.height * (0.5 + 0.05 * sin(progress * 4 * pi)));
    canvas.drawCircle(center3, 100, paint3);
  }

  @override
  bool shouldRepaint(covariant BackgroundPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class SodaBubblesBackground extends StatefulWidget {
  const SodaBubblesBackground({super.key});

  @override
  State<SodaBubblesBackground> createState() => _SodaBubblesBackgroundState();
}

class _SodaBubblesBackgroundState extends State<SodaBubblesBackground> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this, 
      duration: const Duration(seconds: 15)
    )..repeat();
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
          final size = MediaQuery.of(context).size;
          return Stack(
            children: List.generate(30, (index) { // كثرها (30 particles)
              final speed = 0.5 + (index * 0.15); // سرعات متفاوتة
              final progress = (_controller.value * speed + (index * 0.05)) % 1.0;
              
              // توزيع أفقي عشوائي بناءً على الـ index
              final left = (index * 17.0) % size.width;
              
              return Positioned(
                left: left,
                bottom: progress * size.height, // تتصاعد من الأسفل للأعلى بكامل طول الشاشة
                child: Opacity(
                  opacity: (1.0 - progress) * 0.7, // جعلها باينة أكثر
                  child: RotationTransition(
                    turns: AlwaysStoppedAnimation(progress * 2), // دوران مستمر
                    child: Icon(
                      Icons.add_rounded,
                      size: 12.0 + (index * 6) % 30, // تكبير الحجم قليلاً
                      color: const Color(0xFF0EA5E9).withValues(alpha: 0.6), // توضيح اللون أكثر
                    ),
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}
