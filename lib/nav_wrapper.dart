import 'dart:ui'; // مكتبة الواجهات المتقدمة
import 'widgets/draggable_sos.dart'; // استيراد زر الطوارئ الجانبي الجديد
import 'package:flutter/material.dart'; // مكتبة فلاتر الأساسية
import 'package:flutter_riverpod/flutter_riverpod.dart'; // مكتبة إدارة الحالة
import 'providers/app_riverpod.dart'; // استيراد مزود الحالة الرئيسي
import 'screens/elderly/home_screen.dart'; // شاشة المسن الرئيسية
import 'screens/elderly/medication_screen.dart'; // شاشة الأدوية
import 'screens/elderly/calls_screen.dart'; // شاشة المكالمات
import 'screens/elderly/memories_screen.dart'; // شاشة الذكريات
import 'screens/elderly/activities_screen.dart'; // شاشة الأنشطة
import 'screens/elderly/widgets/video_call_overlay.dart'; // واجهة مكالمة الفيديو
import 'widgets/bottom_nav_bar.dart'; // شريط التنقل السفلي المخصص
import 'widgets/taptaba_scaffold.dart'; // الهيكل الموحد للتطبيق
import 'widgets/ai_companion_chat.dart'; // ويدجت المساعد الذكي

class NavWrapper extends ConsumerStatefulWidget {
  // غلاف التنقل لدور المسن
  const NavWrapper({super.key}); // مشيد الفئة

  @override
  ConsumerState<NavWrapper> createState() => _NavWrapperState(); // إنشاء الحالة
}

class _NavWrapperState extends ConsumerState<NavWrapper> {

  @override
  Widget build(BuildContext context) {
    // دالة بناء الواجهة
    final provider = ref.watch(appRiverpod); // مراقبة تغيرات حالة التطبيق

    // قائمة الشاشات المتاحة للمسن
    final List<Widget> screens = [
      const HomeScreen(), // شاشة البداية
      const MedicationScreen(), // شاشة تنبيهات الأدوية
      const CallsScreen(), // شاشة الاتصال بالأسرة
      const MemoriesScreen(), // شاشة ألبوم الصور
      const ActivitiesScreen(), // شاشة الأنشطة
    ];

    return TaptabaScaffold(
      title: 'ونس',
      overrideRole: 'مسن',
      bottomNavigationBar: BottomNavBar(
        currentIndex: provider.currentElderlyTabIndex,
        onTap: (index) => provider.setElderlyTabIndex(index),
        onAiTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AICompanionChat()),
        ),
      ),
      body: Stack(
        children: [
          IndexedStack(
            index: provider.currentElderlyTabIndex >= screens.length
                ? 0
                : provider.currentElderlyTabIndex,
            children: screens.asMap().entries.map((entry) {
              final isActive = entry.key ==
                  (provider.currentElderlyTabIndex >= screens.length
                      ? 0
                      : provider.currentElderlyTabIndex);
              return TickerMode(
                enabled: isActive,
                child: entry.value,
              );
            }).toList(),
          ),
          if (provider.isVideoCallActive) const VideoCallOverlay(),
          if (provider.isEmergencyActive) _buildSOSOverlay(provider),
          const DraggableSOS(),
        ],
      ),
    );
  }

  Widget _buildSOSOverlay(AppRiverpod provider) {
    // دالة بناء واجهة الاستغاثة الكاملة
    return BackdropFilter(
      // فلتر لتغطية الشاشة بالكامل
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), // ضبابية خفيفة للخلفية
      child: Container(
        // وعاء أحمر شفاف
        color:
            const Color(0xFFef4444).withValues(alpha: 0.85), // لون أحمر طوارئ
        width: double.infinity, // كامل العرض
        height: double.infinity, // كامل الارتفاع
        child: Column(
          // ترتيب عناصر الاستغاثة
          mainAxisAlignment: MainAxisAlignment.center, // توسيط رأسي
          children: [
            const Icon(Icons.emergency_share_rounded,
                color: Colors.white, size: 100), // أيقونة استغاثة كبيرة
            const SizedBox(height: 24), // مسافة فارغة
            const Text(
              // نص جاري الإرسال
              'جاري إرسال نداء استغاثة...',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8), // مسافة فارغة
            const Text(
              // نص توضيحي للمسن
              'سيصل النداء للأسرة والممرض فوراً',
              style: TextStyle(color: Colors.white70, fontSize: 18),
            ),
            const SizedBox(height: 60), // مسافة قبل زر الإلغاء
            ElevatedButton(
              // زر إلغاء النداء في حالة الخطأ
              onPressed: () => provider.cancelSOS(), // إلغاء الاستغاثة
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white, // خلفية بيضاء للزر
                padding: const EdgeInsets.symmetric(
                    horizontal: 40, vertical: 15), // حواف مريحة للضغط
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30)), // حواف دائرية
              ),
              child: const Text('إلغاء النداء ❌',
                  style: TextStyle(
                      color: Color(0xFFef4444),
                      fontSize: 20,
                      fontWeight: FontWeight.bold)), // نص الإلغاء
            ),
          ],
        ),
      ),
    );
  }
}
