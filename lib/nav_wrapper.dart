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

class _NavWrapperState extends ConsumerState<NavWrapper>
    with TickerProviderStateMixin {
  late AnimationController _orbController;
  late AnimationController _rippleController;

  @override
  void initState() {
    super.initState();
    _orbController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10), // Slow, smooth marble rotation
    )..repeat();

    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3), // Calm ripple effect
    )..repeat();
  }

  @override
  void dispose() {
    _orbController.dispose();
    _rippleController.dispose();
    super.dispose();
  }

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
      // استخدام الهيكل الموحد لونس
      title: 'ونس', // عنوان التطبيق
      overrideRole: 'مسن', // تحديد الدور كمسن لإظهار الألوان المناسبة
      bottomNavigationBar: BottomNavBar(
        // شريط التنقل السفلي
        currentIndex: provider.currentElderlyTabIndex, // الفهرس الحالي المختار
        onTap: (index) {
          // عند الضغط على تبويب جديد
          provider.setElderlyTabIndex(index); // تحديث الفهرس في الحالة
        },
      ),
      floatingActionButton:
          provider.isAICompanionEnabled ? _buildAIOrb(context, provider) : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
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
          if (provider.isVideoCallActive) // إذا كانت هناك مكالمة فيديو نشطة
            const VideoCallOverlay(),
          if (provider.isEmergencyActive) // إذا تم تفعيل حالة الطوارئ
            _buildSOSOverlay(provider),
          // الزر الجانبي القابل للسحب (SOS) - يظهر دائماً في مكان ثابت
          const DraggableSOS(),
        ],
      ),
    );
  }

  Widget _buildAIOrb(BuildContext context, AppRiverpod provider) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const AICompanionChat()),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 3 Realistic Concentric Ripples
          ...List.generate(3, (i) {
            return AnimatedBuilder(
              animation: _rippleController,
              builder: (context, child) {
                final progress = (_rippleController.value + (i * 0.33)) % 1.0;
                return Container(
                  width: 76 + (35 * progress),
                  height: 76 + (35 * progress),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF818CF8)
                          .withValues(alpha: 0.2 * (1 - progress)),
                      width: 1.2,
                    ),
                  ),
                );
              },
            );
          }),

          // The Marble Orb
          AnimatedBuilder(
            animation: _orbController,
            builder: (context, child) {
              return Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6366F1).withValues(alpha: 0.35),
                      blurRadius: 25,
                      spreadRadius: 3,
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Stack(
                    children: [
                      // Base Gradient
                      Container(
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              Color(0xFFC7D2FE),
                              Color(0xFF818CF8),
                              Color(0xFF6366F1),
                              Color(0xFF4F46E5),
                              Color(0xFF312E81),
                            ],
                            stops: [0.0, 0.2, 0.5, 0.8, 1.0],
                            radius: 1.1,
                          ),
                        ),
                      ),
                      // Rotating Swirls
                      RotationTransition(
                        turns: _orbController,
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: SweepGradient(
                              colors: [
                                Colors.transparent,
                                Colors.white.withValues(alpha: 0.25),
                                const Color(0xFFF472B6).withValues(alpha: 0.3),
                                Colors.transparent,
                                const Color(0xFF38BDF8).withValues(alpha: 0.3),
                                Colors.white.withValues(alpha: 0.2),
                                Colors.transparent,
                              ],
                              stops: const [
                                0.0,
                                0.15,
                                0.3,
                                0.5,
                                0.7,
                                0.85,
                                1.0
                              ],
                            ),
                          ),
                        ),
                      ),
                      // Inner Glow
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              Colors.white.withValues(alpha: 0.35),
                              Colors.transparent,
                            ],
                            center: const Alignment(-0.3, -0.3),
                            radius: 0.7,
                          ),
                        ),
                      ),
                      // Glassy Reflection
                      Positioned(
                        top: 8,
                        left: 12,
                        child: Container(
                          width: 35,
                          height: 18,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.35),
                          ),
                        ),
                      ),
                      // Icon
                      const Center(
                        child: Icon(
                          Icons.auto_awesome_rounded,
                          color: Colors.white,
                          size: 34,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
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
