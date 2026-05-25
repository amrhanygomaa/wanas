import 'package:flutter/material.dart';
import '../constants.dart';
import '../svg_icons.dart';

class ShimmerButton extends StatefulWidget {
  final String text;
  final VoidCallback onTap;
  final bool showArrow;

  const ShimmerButton({
    super.key,
    required this.text,
    required this.onTap,
    this.showArrow = true,
  });

  @override
  State<ShimmerButton> createState() => _ShimmerButtonState();
}

class _ShimmerButtonState extends State<ShimmerButton>
    with TickerProviderStateMixin {
  late AnimationController _shimmerController;
  late AnimationController _glowController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _glowController,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(13),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(
                  alpha: 0.3 + (_glowController.value * 0.25),
                ),
                blurRadius: 20 + (_glowController.value * 8),
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(13),
            child: AnimatedBuilder(
              animation: _shimmerController,
              builder: (context, child) {
                return Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment(_shimmerController.value * 4 - 2, 0),
                      end: const Alignment(1, 0),
                      colors: const [
                        AppColors.primary,
                        AppColors.primaryLight,
                        AppColors.primary,
                      ],
                      stops: const [0.3, 0.5, 0.7],
                    ),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: widget.onTap,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              widget.text,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (widget.showArrow) ...[
                              const SizedBox(width: 6),
                              AppIcons.arrow(size: 14),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
