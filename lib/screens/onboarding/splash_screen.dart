import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

class WanasSplashScreen extends StatefulWidget {
  const WanasSplashScreen({super.key});

  @override
  State<WanasSplashScreen> createState() => _WanasSplashScreenState();
}

class _WanasSplashScreenState extends State<WanasSplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _glowController;
  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _textOpacity;
  late Animation<double> _sloganOpacity;
  late Animation<double> _glowPulse;
  bool _useLogoAsset = false;

  Future<void> _checkLogoAsset() async {
    try {
      await rootBundle.load('assets/icons/wanas_logo.png');
      if (mounted) setState(() => _useLogoAsset = true);
    } catch (_) {
      if (mounted) setState(() => _useLogoAsset = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _checkLogoAsset();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _logoScale = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
      ),
    );
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );
    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: const Interval(0.3, 0.7, curve: Curves.easeIn),
      ),
    );
    _sloganOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: const Interval(0.5, 0.9, curve: Curves.easeIn),
      ),
    );
    _glowPulse = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFFAF7F2),
                  Color(0xFFF3EFE9),
                  Color(0xFFE9E4DC),
                ],
              ),
            ),
            child: Image.asset(
              'assets/icons/wanas_splash_bg.png',
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              errorBuilder: (context, error, stackTrace) {
                return AnimatedBuilder(
                  animation: _glowPulse,
                  builder: (context, child) {
                    return Stack(
                      children: [
                        Positioned(
                          top: -120 * _glowPulse.value,
                          right: -100 * _glowPulse.value,
                          child: _buildGlowRing(
                            width: 320 * _glowPulse.value,
                            height: 320 * _glowPulse.value,
                            glowColor: const Color(0xFFE8DFCD)
                                .withValues(alpha: 0.45),
                            borderColor: const Color(0xFFDFD4BE)
                                .withValues(alpha: 0.2),
                          ),
                        ),
                        Positioned(
                          bottom: -150 * _glowPulse.value,
                          left: -120 * _glowPulse.value,
                          child: _buildGlowRing(
                            width: 420 * _glowPulse.value,
                            height: 420 * _glowPulse.value,
                            glowColor: const Color(0xFFE5DBC5)
                                .withValues(alpha: 0.4),
                            borderColor: const Color(0xFFDBD0B4)
                                .withValues(alpha: 0.18),
                          ),
                        ),
                        Center(
                          child: Container(
                            width: 250 * _glowPulse.value,
                            height: 250 * _glowPulse.value,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  const Color(0xFFEFE9DC)
                                      .withValues(alpha: 0.55),
                                  const Color(0xFFFAF7F2)
                                      .withValues(alpha: 0.0),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            child: SizedBox(
              width: double.infinity,
              height: double.infinity,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedBuilder(
                        animation: _fadeController,
                        builder: (context, child) {
                          return Opacity(
                            opacity: _logoOpacity.value,
                            child: Transform.scale(
                              scale: _logoScale.value,
                              child: _useLogoAsset
                                  ? Image.asset(
                                      'assets/icons/wanas_logo.png',
                                      width: size.width * 0.72,
                                      fit: BoxFit.contain,
                                    )
                                  : _buildLogoWidget(),
                            ),
                          );
                        },
                      ),
                      if (!_useLogoAsset) ...[
                        const SizedBox(height: 32),
                        FadeTransition(
                          opacity: _textOpacity,
                          child: const Text(
                            'وَنَسْ',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 48,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF8F7C56),
                              letterSpacing: 1.0,
                              shadows: [
                                Shadow(
                                  color: Color(0x1F8F7C56),
                                  offset: Offset(0, 4),
                                  blurRadius: 12,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      FadeTransition(
                        opacity: _sloganOpacity,
                        child: const Text(
                          'وَنَسٌ… حَيْثُ يَطْمَئِنُّ القَلْب',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF8F7C56),
                            letterSpacing: 0.2,
                            shadows: [
                              Shadow(
                                color: Color(0x1A8F7C56),
                                offset: Offset(0, 2),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 32,
                        height: 32,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFFB09D76),
                          ),
                          backgroundColor:
                              const Color(0xFF8F7C56).withValues(alpha: 0.1),
                        ),
                      ),
                      const SizedBox(height: 48),
                      const Text(
                        'Wanas 2026',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF8F7C56),
                          letterSpacing: 2.0,
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlowRing({
    required double width,
    required double height,
    required Color glowColor,
    required Color borderColor,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: borderColor, width: 1.5),
        gradient: RadialGradient(
          colors: [
            glowColor,
            glowColor.withValues(alpha: 0.1),
            Colors.transparent,
          ],
          stops: const [0.0, 0.7, 1.0],
        ),
      ),
    );
  }

  Widget _buildLogoWidget() {
    return Container(
      width: 110,
      height: 110,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.4),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8F7C56).withValues(alpha: 0.06),
            blurRadius: 24,
            spreadRadius: 4,
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Image.asset(
        'assets/icons/wanas_logo.png',
        width: 85,
        height: 85,
        errorBuilder: (context, error, stackTrace) {
          return CustomPaint(
            size: const Size(80, 50),
            painter: WanasInfinityLogoPainter(),
          );
        },
      ),
    );
  }
}

class WanasInfinityLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);

    final paint = Paint()
      ..shader = const LinearGradient(
        colors: [
          Color(0xFF8F7C56),
          Color(0xFFC7B38C),
          Color(0xFFAD9970),
          Color(0xFF8F7C56),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.5
      ..strokeCap = StrokeCap.round;

    final path = Path();
    double w = size.width;
    double h = size.height;

    path.moveTo(w * 0.5, h * 0.5);
    path.cubicTo(w * 0.32, h * 0.15, w * 0.05, h * 0.15, w * 0.08, h * 0.5);
    path.cubicTo(w * 0.1, h * 0.85, w * 0.32, h * 0.85, w * 0.5, h * 0.5);
    path.cubicTo(w * 0.68, h * 0.15, w * 0.95, h * 0.15, w * 0.92, h * 0.5);
    path.cubicTo(w * 0.9, h * 0.85, w * 0.68, h * 0.85, w * 0.5, h * 0.5);

    canvas.drawPath(path, paint);

    final glowPaint = Paint()
      ..color = const Color(0xFFFAF4E7).withValues(alpha: 0.8)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(w * 0.5, h * 0.5), 3.0, glowPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
