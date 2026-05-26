import 'dart:ui';
import 'package:flutter/material.dart';
import '../models/app_models.dart';

class AIInsightsPanel extends StatelessWidget {
  final bool isEnabled;
  final AIInsight? insight;
  final VoidCallback? onToggle;

  const AIInsightsPanel({
    super.key,
    required this.isEnabled,
    this.insight,
    this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      child: isEnabled ? _buildEnabledState(context) : _buildDisabledState(context),
    );
  }

  Widget _buildEnabledState(BuildContext context) {
    if (insight == null) return const SizedBox.shrink();

    return Container(
      key: const ValueKey('enabled'),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF6366F1).withValues(alpha: 0.05),
                  Colors.white.withValues(alpha: 0.9),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: const Color(0xFF6366F1).withValues(alpha: 0.2),
                width: 1.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildBadge('يتطلب مراجعة بشرية ⚖️', const Color(0xFFF59E0B)),
                    const Row(
                      children: [
                        Text(
                          'رؤى الذكاء الاصطناعي',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF4338CA),
                            fontFamily: 'Cairo',
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.auto_awesome_rounded, color: Color(0xFF6366F1), size: 18),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  insight!.summary,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B),
                    height: 1.5,
                    fontFamily: 'Cairo',
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'التفسير والمنطق:',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF64748B),
                    fontFamily: 'Cairo',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  insight!.rationale,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF475569),
                    height: 1.4,
                    fontFamily: 'Cairo',
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(color: Color(0xFFE2E8F0)),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'تم التوليد: ${_formatDate(insight!.generationDate)}',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFF94A3B8),
                        fontFamily: 'Cairo',
                      ),
                    ),
                    Text(
                      'نسبة الثقة: ${(insight!.confidenceScore * 100).toInt()}%',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF10B981),
                        fontFamily: 'Cairo',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDisabledState(BuildContext context) {
    return Container(
      key: const ValueKey('disabled'),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAF9),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          const Icon(Icons.auto_awesome_motion_rounded, color: Color(0xFF94A3B8), size: 32),
          const SizedBox(height: 12),
          const Text(
            'رؤى الذكاء الاصطناعي غير مفعلة',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF64748B),
              fontFamily: 'Cairo',
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'قم بتفعيل الميزة من الإعدادات للحصول على ملخصات ذكية لحالة المقيمين',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              color: Color(0xFF94A3B8),
              fontFamily: 'Cairo',
            ),
          ),
          if (onToggle != null) ...[
            const SizedBox(height: 16),
            TextButton(
              onPressed: onToggle,
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text(
                'تفعيل الآن',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12, fontFamily: 'Cairo'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          fontFamily: 'Cairo',
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.hour}:${date.minute.toString().padLeft(2, '0')} - ${date.day}/${date.month}';
  }
}
