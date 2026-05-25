import 'package:flutter/material.dart';
import '../constants.dart';

class PasswordStrength extends StatelessWidget {
  final int strength; // 0-4
  final String text;

  const PasswordStrength({
    super.key,
    required this.strength,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Row(
          children: List.generate(4, (index) {
            final isFilled = index < strength;
            final isYellow = strength <= 2 && isFilled;
            return Expanded(
              child: Container(
                height: 3,
                margin: const EdgeInsets.symmetric(horizontal: 1.5),
                decoration: BoxDecoration(
                  color: isFilled
                      ? (isYellow
                          ? AppColors.strengthYellow
                          : AppColors.primary)
                      : AppColors.bgInput,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 3),
        Text(
          text,
          style: const TextStyle(fontSize: 8, color: AppColors.strengthYellow),
        ),
      ],
    );
  }
}
