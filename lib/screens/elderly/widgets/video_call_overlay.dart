import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/app_riverpod.dart';

class VideoCallOverlay extends ConsumerStatefulWidget {
  const VideoCallOverlay({super.key});

  @override
  ConsumerState<VideoCallOverlay> createState() => _VideoCallOverlayState();
}

class _VideoCallOverlayState extends ConsumerState<VideoCallOverlay>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _slideController;

  @override
  void initState() {
    super.initState();
    _pulseController =
        AnimationController(vsync: this, duration: const Duration(seconds: 2))
          ..repeat(reverse: true);
    _slideController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600))
      ..forward();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = ref.watch(appRiverpod);

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
      child: Container(
        color: Colors.black.withValues(alpha: 0.7),
        child: Column(
          children: [
            const Spacer(),
            // Caller Info Area
            FadeTransition(
              opacity: _slideController,
              child: SlideTransition(
                position:
                    Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero)
                        .animate(
                  CurvedAnimation(
                      parent: _slideController, curve: Curves.easeOutBack),
                ),
                child: Column(
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        // Animated pulse rings
                        ...List.generate(
                            2,
                            (index) => AnimatedBuilder(
                                  animation: _pulseController,
                                  builder: (context, child) {
                                    return Container(
                                      width: 150 +
                                          (index * 40 * _pulseController.value),
                                      height: 150 +
                                          (index * 40 * _pulseController.value),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                            color: Colors.white.withValues(
                                                alpha: 0.3 *
                                                    (1 -
                                                        _pulseController
                                                            .value)),
                                            width: 2),
                                      ),
                                    );
                                  },
                                )),
                        // Large Avatar
                        Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                                colors: [Color(0xFF6C63FF), Color(0xFFc084fc)]),
                            boxShadow: [
                              BoxShadow(
                                  color: const Color(0xFF6C63FF)
                                      .withValues(alpha: 0.5),
                                  blurRadius: 30,
                                  spreadRadius: 5),
                            ],
                          ),
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  provider.activeCallerInitials,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 42,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          provider.activeCallerName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'مكالمة فيديو جارية...',
                      style: TextStyle(color: Colors.white70, fontSize: 18),
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),
            // Controls Area
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _circleButton(Icons.mic_off_rounded,
                        Colors.white.withValues(alpha: 0.2), Colors.white),
                    const SizedBox(width: 20),
                    _circleButton(
                        Icons.call_end_rounded, Colors.redAccent, Colors.white,
                        size: 85, iconSize: 42, onTap: () {
                      provider.endVideoCall();
                    }),
                    const SizedBox(width: 20),
                    _circleButton(Icons.videocam_off_rounded,
                        Colors.white.withValues(alpha: 0.2), Colors.white),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _circleButton(IconData icon, Color bg, Color iconColor,
      {double size = 65, double iconSize = 32, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
        child: Icon(icon, color: iconColor, size: iconSize),
      ),
    );
  }
}
