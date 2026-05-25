import 'package:flutter/material.dart';
import '../constants.dart';

class SplashHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final double height;
  final bool isSmall;

  const SplashHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.height = 140,
    this.isSmall = false,
  });

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: const RectClipper(),
      child: Container(
        height: height,
        decoration: const BoxDecoration(color: AppColors.bgDark),
        clipBehavior: Clip.hardEdge,
        child: Stack(
          children: [
            // Primary blob full right edge
            Positioned(
              right: -25,
              top: 5,
              child: _buildBlob(120, AppColors.primary),
            ),
            // Pink blob full left top
            Positioned(
              left: -30,
              top: 20,
              child: _buildBlob(100, AppColors.pinkBlob),
            ),
            // Blue blob full left bottom
            Positioned(
              left: -15,
              bottom: 5,
              child: _buildBlob(85, AppColors.blueBlob),
            ),
            SafeArea(
              bottom: false,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildLogo(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBlob(double size, Color color) {
    return Builder(
      builder: (context) {
        final screenWidth = MediaQuery.of(context).size.width;
        final scale = (screenWidth / 375).clamp(0.75, 1.3);
        final scaledSize = (size * scale).clamp(50.0, 160.0);
        final width = scaledSize * 1.8; // Horizontal for full width feel
        final height = scaledSize * 0.7;
        final radius = height / 2;
        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color:
                color.withAlpha(((color.a * 255 * 0.6).round() & 0xff).toInt()),
            borderRadius:
                BorderRadius.vertical(bottom: Radius.circular(radius)),
            // Soft blur effect
            boxShadow: [
              BoxShadow(
                color: color
                    .withAlpha(((color.a * 255 * 0.3).round() & 0xff).toInt()),
                blurRadius: scaledSize * 0.25,
                spreadRadius: scaledSize * 0.05,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLogo() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: 1),
          duration: const Duration(milliseconds: 600),
          builder: (context, value, child) => Opacity(
            opacity: value,
            child: Builder(
              builder: (context) {
                final screenWidth = MediaQuery.of(context).size.width;
                final baseFontSize = (screenWidth * 0.075).clamp(12.0, 20.0);
                final fontSize = isSmall ? baseFontSize * 0.85 : baseFontSize;
                return Text(
                  title,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: fontSize,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.01,
                  ),
                );
              },
            ),
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 2),
          Text(
            subtitle!,
            style: TextStyle(color: Colors.white.withAlpha(128), fontSize: 9),
          ),
        ],
      ],
    );
  }
}

class RectClipper extends CustomClipper<Path> {
  const RectClipper();

  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(0, 0);
    path.lineTo(size.width, 0);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
