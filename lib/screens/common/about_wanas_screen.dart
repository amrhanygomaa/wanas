import 'package:flutter/material.dart';

class AboutWanasScreen extends StatelessWidget {
  const AboutWanasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1a0533),
        foregroundColor: Colors.white,
        title: const Text('عن ونس',
            style: TextStyle(
                fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        shape: const RoundedRectangleBorder(
            borderRadius:
                BorderRadius.vertical(bottom: Radius.circular(20))),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 16),
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6C63FF).withValues(alpha: 0.25),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/icons/wanas_logo.png',
                  width: 110,
                  height: 110,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 110,
                    height: 110,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF6C63FF), Color(0xFF3730a3)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Text('ونس',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Cairo')),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            const Text('تطبيق ونس للرعاية الذكية',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1e293b),
                    fontFamily: 'Cairo')),
            const SizedBox(height: 6),
            const Text('الإصدار 1.0.0',
                style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF94a3b8),
                    fontFamily: 'Cairo')),
            const SizedBox(height: 32),
            const _SectionCard(
              icon: Icons.favorite_rounded,
              iconColor: Color(0xFFef4444),
              title: 'رسالتنا',
              body:
                  'توفير رعاية ذكية ومتكاملة لكبار السن من خلال التكنولوجيا والذكاء الاصطناعي، وتعزيز التواصل بينهم وبين عائلاتهم ومقدمي الرعاية.',
            ),
            const SizedBox(height: 16),
            const _SectionCard(
              icon: Icons.lightbulb_rounded,
              iconColor: Color(0xFFf59e0b),
              title: 'رؤيتنا',
              body:
                  'عالم يشعر فيه كل مقيم بالأمان والاهتمام والتواصل مع عائلته، حيث تُستخدم التقنية لإثراء حياة كبار السن لا لتعقيدها.',
            ),
            const SizedBox(height: 16),
            const _SectionCard(
              icon: Icons.auto_awesome_rounded,
              iconColor: Color(0xFF6C63FF),
              title: 'مميزات التطبيق',
              body: '• رفيق الذكاء الاصطناعي — يتحدث ويستمع ويتذكر\n'
                  '• متابعة الأدوية والمواعيد الصحية\n'
                  '• ألعاب ذهنية لتنشيط الذاكرة\n'
                  '• تواصل مباشر مع الأسرة\n'
                  '• تقارير يومية لمقدمي الرعاية\n'
                  '• جدولة الزيارات والفعاليات',
            ),
            const SizedBox(height: 16),
            const _SectionCard(
              icon: Icons.support_agent_rounded,
              iconColor: Color(0xFF059669),
              title: 'تواصل معنا',
              body:
                  'البريد الإلكتروني: support@wanas.sa\nالهاتف: 920‑000‑0000\nالموقع: www.wanas.sa',
            ),
            const SizedBox(height: 32),
            const Text('© 2024 ونس — جميع الحقوق محفوظة',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF94a3b8),
                    fontFamily: 'Cairo')),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String body;

  const _SectionCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 12),
              Text(title,
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1e293b),
                      fontFamily: 'Cairo')),
            ],
          ),
          const SizedBox(height: 12),
          Text(body,
              style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF475569),
                  height: 1.7,
                  fontFamily: 'Cairo')),
        ],
      ),
    );
  }
}
