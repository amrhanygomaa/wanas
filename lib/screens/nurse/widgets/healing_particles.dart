import 'package:flutter/material.dart';

class HealingParticles extends StatefulWidget {
  const HealingParticles({super.key});

  @override
  State<HealingParticles> createState() => _HealingParticlesState();
}

class _HealingParticlesState extends State<HealingParticles>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 10))
          ..repeat();
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
          return Stack(
            children: List.generate(7, (index) {
              final speed = 1.0 + (index * 0.3);
              final progress =
                  (_controller.value * speed + (index * 0.18)) % 1.0;

              return Positioned(
                left: 20.0 + (index * 55.0) % 320, // توزيع أفقي عشوائي
                bottom: (progress * 220) - 30, // تتصاعد من الأسفل للأعلى
                child: Opacity(
                  opacity: (1.0 - progress) * 0.3, // تتلاشى وتختفي كلما صعدت
                  child: RotationTransition(
                    turns: AlwaysStoppedAnimation(
                        progress * 0.5), // دوران خفيف جداً
                    child: Icon(
                      Icons.add_rounded,
                      size: 24.0 + (index * 12) % 40, // أحجام متفاوتة
                      color: Colors.white,
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
