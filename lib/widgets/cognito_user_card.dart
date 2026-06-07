import 'package:flutter/material.dart';
import '../services/auth_service.dart';

// بطاقة تعرض بيانات Cognito الحقيقية للمستخدم الحالي
// تثبت أن الـ Auth مربوط بـ السيرفر فعلاً (مش mock).
class CognitoUserCard extends StatelessWidget {
  const CognitoUserCard({super.key});

  @override
  Widget build(BuildContext context) {
    final user = AuthService.instance.currentUser;
    if (user == null) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: const Row(
          children: [
            Icon(Icons.cloud_off_rounded, size: 18, color: Color(0xFF94A3B8)),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'لا توجد جلسة Cognito نشطة',
                style: TextStyle(
                  fontSize: 11,
                  color: Color(0xFF64748B),
                  fontFamily: 'Cairo',
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFFF7ED),
            Color(0xFFFEF3C7),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFFF9900).withValues(alpha: 0.35),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF9900), Color(0xFFFFB14E)],
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'السيرفر',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'Cairo',
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Row(
                children: [
                  Icon(Icons.verified_user_rounded,
                      size: 14, color: Color(0xFF10B981)),
                  SizedBox(width: 4),
                  Text(
                    'متحقق',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Cairo',
                      color: Color(0xFF065F46),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          _row(Icons.email_outlined, 'البريد', user.email),
          _row(Icons.badge_outlined, 'الدور',
              user.roles.isEmpty ? 'لا يوجد' : user.roles.join(', ')),
          _row(Icons.business_outlined, 'المنشأة', user.facilityId),
          _row(
            Icons.fingerprint_rounded,
            'User ID',
            user.userId.length > 18
                ? '${user.userId.substring(0, 18)}...'
                : user.userId,
          ),
        ],
      ),
    );
  }

  Widget _row(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(icon, size: 14, color: const Color(0xFFB45309)),
          const SizedBox(width: 6),
          SizedBox(
            width: 60,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF92400E),
                fontFamily: 'Cairo',
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF1E293B),
                fontFamily: 'Cairo',
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
