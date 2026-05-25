import 'dart:async'; // مكتبة المؤقتات والعمليات غير المتزامنة
import 'dart:math'; // مكتبة العمليات الرياضية
import 'package:flutter/material.dart'; // مكتبة فلاتر الأساسية للواجهات
import 'package:flutter_riverpod/flutter_riverpod.dart'; // مكتبة إدارة الحالة
// مكتبة فتح الروابط
import '../../providers/app_riverpod.dart'; // مزود الحالة الرئيسي للتطبيق
import '../../models/app_models.dart'; // نماذج البيانات (Medication, User, etc.)
import 'package:lottie/lottie.dart';
// ويدجت رفيق الذكاء الاصطناعي
// حوار طلب الصلاحيات المخصص

class HomeScreen extends ConsumerStatefulWidget {
  // شاشة المسن الرئيسية
  const HomeScreen({super.key}); // مشيد الفئة

  @override
  ConsumerState<HomeScreen> createState() =>
      _HomeScreenState(); // إنشاء حالة الشاشة
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with TickerProviderStateMixin {
  // حالة الشاشة مع دعم الأنيميشن المتعدد
  late AnimationController _bgController; // متحكم أنيميشن الخلفية المتحركة
  late AnimationController _pillController; // متحكم أنيميشن طفو حبة الدواء
  late AnimationController _ringController; // متحكم أنيميشن نبض الحلقة
  late AnimationController _starController; // متحكم أنيميشن قفز النجوم
  late AnimationController _glowController; // متحكم أنيميشن توهج الأزرار

  bool _showSuccessAnimation = false;
  String _successMessage = '';
  int remainingSeconds = 22 * 60; // الوقت المتبقي للدواء (22 دقيقة افتراضياً)
  Timer? _timer; // مؤقت للعد التنازلي

  @override
  void initState() {
    // دالة التهيئة الأولية عند تشغيل الشاشة
    super.initState();

    // إعداد أنيميشن تدرج الخلفية (حركة بطيئة وهادئة)
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    // إعداد أنيميشن طفو حبة الدواء (حركة ترددية)
    _pillController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat(reverse: true);

    // إعداد أنيميشن نبض الحلقة حول الزر
    _ringController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    // إعداد أنيميشن قفز النجوم عند كسب النقاط
    _starController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    // إعداد أنيميشن توهج الأزرار للتنبيه
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat(reverse: true);

    // بدء مؤقت العد التنازلي كل ثانية
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (remainingSeconds > 0) {
        setState(() => remainingSeconds--); // تحديث الواجهة عند نقصان الثواني
      }
    });
  }

  @override
  void dispose() {
    // تنظيف الموارد وإغلاق المؤقتات عند إغلاق الشاشة
    _bgController.dispose();
    _pillController.dispose();
    _ringController.dispose();
    _starController.dispose();
    _glowController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  String formatTime(int seconds) {
    // دالة لتحويل الثواني إلى صيغة نصية عربية
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return m > 0 ? '$m دقيقة' : '$s ثانية';
  }

  @override
  Widget build(BuildContext context) {
    // دالة بناء واجهة الشاشة الرئيسية
    final provider = ref.watch(appRiverpod); // مراقبة حالة التطبيق
    return Stack(
      children: [
        _buildAnimatedBackground(),
        SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 100), // مساحة إضافية في الأسفل
          child: Column(
            children: [
              // قسم الترحيب العلوي (Hero)
              _buildHero(provider),
              if (provider.currentMood.isEmpty)
                _buildMoodTracker(
                    provider), // إظهار متعقب المزاج إذا لم يحدد بعد

              // قسم البطاقات الرئيسية
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  children: [
                    _buildMedicineCard(provider), // بطاقة الدواء
                    const SizedBox(height: 12),
                    _buildFamilyCard(
                        provider, context), // بطاقة التواصل مع العائلة
                    const SizedBox(height: 12),
                    _buildPointsCard(provider), // بطاقة إجمالي النقاط
                    const SizedBox(height: 12),
                    _buildVolunteerRatingCard(
                        provider, context), // بطاقة تقييم المتطوع
                    const SizedBox(height: 12),
                    _buildServiceRatingCard(
                        provider, context), // بطاقة تقييم الخدمات
                    const SizedBox(height: 12),
                    _buildComplaintCard(
                        provider, context), // بطاقة طلب المساعدة
                  ],
                ),
              ),
            ],
          ),
        ),
        if (_showSuccessAnimation) _buildCentralSuccessAnimation(),
      ],
    );
  }

  Widget _buildCentralSuccessAnimation() {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 700),
      curve: Curves.elasticOut,
      child: Lottie.asset(
        'assets/animations/Done.json',
        repeat: false,
        fit: BoxFit.contain,
        onLoaded: (composition) {
          Future.delayed(composition.duration, () {
            if (mounted) {
              setState(() => _showSuccessAnimation = false);
            }
          });
        },
      ),
      builder: (context, value, child) {
        return Container(
          color: Colors.black.withValues(alpha: 0.5 * value),
          child: Center(
            child: Transform.scale(
              scale: value,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 320,
                    height: 320,
                    child: child,
                  ),
                  const SizedBox(height: 30),
                  Text(
                    _successMessage,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          color: Colors.black26,
                          offset: Offset(0, 4),
                          blurRadius: 10,
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHero(AppRiverpod provider) {
    // بناء قسم الترحيب العلوي (الـ Hero)
    return AnimatedBuilder(
      animation: _bgController,
      builder: (context, child) {
        return Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              // تدرج أرجواني عميق
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF1a0533),
                Color(0xFF3730a3),
                Color(0xFF0f3460),
                Color(0xFF6C63FF),
              ],
            ),
          ),
          child: Stack(
            children: [
              // كرات ملونة متحركة في الخلفية (Blobs) للحيوية
              _buildBlob(180, const Color(0xFF6C63FF), -50, -50, 7),
              _buildBlob(130, const Color(0xFFf472b6), -35, 30, 9),
              _buildBlob(90, const Color(0xFF0ea5e9), 80, -10, 6),

              SafeArea(
                bottom: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // نص الترحيب الصباحي باسم المستخدم
                    Padding(
                      padding:
                          const EdgeInsets.only(right: 28, top: 15, bottom: 8),
                      child: FittedBox(
                        alignment: Alignment.centerRight,
                        fit: BoxFit.scaleDown,
                        child: Text(
                            'صباح الخير يا ${provider.currentUser.name} ',
                            textAlign: TextAlign.start,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                height: 1.2)),
                      ),
                    ),

                    // شرائح إحصائية سريعة (أدوية، نقاط، نشاطات)
                    Padding(
                      padding: const EdgeInsets.only(
                          left: 16, right: 16, top: 8, bottom: 24),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildChip('${provider.todayMedications.length}',
                              'أدوية', 1), // عدد الأدوية اليوم
                          const SizedBox(width: 8),
                          _buildChip('${provider.currentUser.points}', 'نقاطي',
                              2), // إجمالي النقاط
                          const SizedBox(width: 8),
                          _buildChip(
                              '${provider.currentUser.completedActivities}',
                              'نشاطات',
                              3), // عدد النشاطات المكتملة
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMoodTracker(AppRiverpod provider) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
            color: const Color(0xFF6C63FF).withValues(alpha: 0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
              color: const Color(0xFF6C63FF).withValues(alpha: 0.15),
              blurRadius: 10,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          const Text('طمنا عليك، كيف حالك اليوم؟ ✨',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1e293b))),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _moodItem(provider, 'happy', '😊', 'سعيد'),
              _moodItem(provider, 'calm', '😌', 'هادئ'),
              _moodItem(provider, 'tired', '😴', 'متعب'),
              _moodItem(provider, 'active', '☀️', 'بخير'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _moodItem(
      AppRiverpod provider, String mood, String emoji, String label) {
    return GestureDetector(
      onTap: () => provider.setMood(mood),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFFf8fafc),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFede9fe)),
            ),
            child: Center(
                child: Text(emoji, style: const TextStyle(fontSize: 30))),
          ),
          const SizedBox(height: 8),
          Text(label,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF64748b))),
        ],
      ),
    );
  }

  Widget _buildBlob(
      double size, Color color, double right, double top, double duration) {
    return AnimatedBuilder(
      animation: _bgController,
      builder: (context, child) {
        final t = _bgController.value * 2 * pi;
        final x = sin(t * (duration / 7)) * 8;
        final y = cos(t * (duration / 7)) * 10;

        return Positioned(
          left: right + x,
          top: top + y,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.4),
            ),
            child: BackdropFilter(
              filter:
                  const ColorFilter.mode(Colors.transparent, BlendMode.srcOver),
              child: Container(color: Colors.transparent),
            ),
          ),
        );
      },
    );
  }

  Widget _buildChip(String value, String label, int index) {
    Color chipColor;
    Color borderColor;

    switch (index) {
      case 1: // أدوية
        chipColor =
            const Color(0xFF6C63FF).withValues(alpha: 0.15); // بنفسجي أساسي
        borderColor = const Color(0xFF6C63FF).withValues(alpha: 0.3);
        break;
      case 2: // نقاطي
        chipColor =
            const Color(0xFF8B5CF6).withValues(alpha: 0.15); // بنفسجي فاتح
        borderColor = const Color(0xFF8B5CF6).withValues(alpha: 0.3);
        break;
      case 3: // نشاطات
        chipColor = const Color(0xFF3B82F6).withValues(alpha: 0.15); // أزرق
        borderColor = const Color(0xFF3B82F6).withValues(alpha: 0.3);
        break;
      default:
        chipColor = Colors.white.withValues(alpha: 0.14);
        borderColor = Colors.white.withValues(alpha: 0.12);
    }

    return Expanded(
      child: TweenAnimationBuilder(
        tween: Tween<double>(begin: 0.6, end: 1),
        duration: const Duration(milliseconds: 450),
        curve: Curves.elasticOut,
        builder: (context, scale, child) {
          return Transform.scale(
            scale: scale,
            child: child!,
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 4),
          decoration: BoxDecoration(
            color: chipColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: borderColor.withValues(alpha: 0.2),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(value,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(label,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMedicineCard(AppRiverpod provider) {
    final nextMed = provider.nextMedication;
    final remainingSeconds = provider.remainingSecondsToNextMed;

    return AnimatedBuilder(
      animation: Listenable.merge([_bgController, _glowController]),
      builder: (context, child) {
        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF6366F1),
                Color(0xFF8B5CF6),
                Color(0xFFA855F7),
              ],
            ),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6366F1).withValues(alpha: 0.35),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Text('الجرعة القادمة ',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold)),
                        Lottie.asset(
                          'assets/animations/pickups.json',
                          width: 45,
                          height: 45,
                          fit: BoxFit.contain,
                          repeat: true,
                          animate: true,
                        ),
                      ],
                    ),
                    const SizedBox.shrink(),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            nextMed != null
                                ? nextMed.name
                                : 'كل الأدوية تم أخذها',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                height: 1.1),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            nextMed != null ? nextMed.dosage : '',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            nextMed != null ? 'بعد الغداء' : 'ممتاز!',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () {
                        if (nextMed != null) {
                          provider.elderlyConfirmMedication(nextMed.id);

                          // Show central animation
                          setState(() {
                            _successMessage = 'تم أخذ الدواء بنجاح';
                            _showSuccessAnimation = true;
                          });

                          // Automatically hides based on onLoaded in _buildCentralSuccessAnimation
                        }
                      },
                      child: _buildHandIcon(),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('⏱️', style: TextStyle(fontSize: 18)),
                          const SizedBox(width: 8),
                          Text(
                            formatTime(remainingSeconds),
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                if (nextMed != null)
                  _buildTakeMedButton(provider, nextMed, context),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHandIcon() {
    return SizedBox(
      width: 76,
      height: 76,
      child: Stack(
        children: [
          Center(
            child: AnimatedBuilder(
              animation: _ringController,
              builder: (context, child) {
                return Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white
                          .withValues(alpha: 0.4 * (1 - _ringController.value)),
                      width: 5 * _ringController.value,
                    ),
                  ),
                );
              },
            ),
          ),
          Center(
            child: Container(
              width: 60,
              height: 60,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10,
                      offset: Offset(0, 4))
                ],
              ),
              child: const Center(
                child:
                    Icon(Icons.touch_app, color: Color(0xFF6366F1), size: 32),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTakeMedButton(
      AppRiverpod provider, Medication nextMed, BuildContext context) {
    return GestureDetector(
      onTap: () {
        provider.elderlyConfirmMedication(nextMed.id);

        // Show central animation
        setState(() {
          _successMessage = 'تم أخذ الدواء بنجاح';
          _showSuccessAnimation = true;
        });

        // Automatically hides based on onLoaded in _buildCentralSuccessAnimation
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
              color: const Color(0xFF6366F1).withValues(alpha: 0.3),
              width: 1.5),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6366F1).withValues(alpha: 0.25),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('أخذت الدواء ✓',
                style: TextStyle(
                    color: Color(0xFF6366F1),
                    fontSize: 22,
                    fontWeight: FontWeight.bold)),
            const SizedBox(width: 10),
            Icon(Icons.check_circle_outline_rounded,
                color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                size: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildFamilyCard(AppRiverpod provider, BuildContext context) {
    bool hc = provider.isHighContrast;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: hc ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
            color: hc
                ? const Color(0xFF6C63FF).withValues(alpha: 0.4)
                : const Color(0xFF6C63FF).withValues(alpha: 0.3),
            width: 1.5),
        boxShadow: [
          BoxShadow(
              color:
                  const Color(0xFF6C63FF).withValues(alpha: hc ? 0.25 : 0.15),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Icon(Icons.phone_enabled_rounded,
                    color: Color(0xFF6C63FF), size: 28),
                SizedBox(width: 8),
                Text('تواصل مع أحبائك 💜',
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF6C63FF))),
              ],
            ),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.95,
              ),
              itemCount: provider.familyMembers.length,
              itemBuilder: (context, index) {
                final member = provider.familyMembers[index];
                final List<Color> avatarColors = [
                  const Color(0xFFdb2777),
                  const Color(0xFF10b981),
                  const Color(0xFF6366F1),
                ];
                return _buildPerson(
                  member,
                  avatarColors[index % avatarColors.length],
                  provider,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showCallActionSheet(
      BuildContext context, FamilyMember member, AppRiverpod provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 24),
            Text('كيف تود التواصل مع ${member.name}؟',
                style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Cairo')),
            const SizedBox(height: 30),
            Row(
              children: [
                Expanded(
                  child: _buildCallTypeButton(
                    label: 'اتصال هاتف',
                    icon: Icons.phone_forwarded_rounded,
                    color: const Color(0xFF10B981),
                    onTap: () {
                      Navigator.pop(context);
                      provider.callPhoneNumber(member.phoneNumber);
                      provider.addPoints(2);
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildCallTypeButton(
                    label: 'مكالمة زووم',
                    icon: Icons.videocam_rounded,
                    color: const Color(0xFF6366F1),
                    onTap: () {
                      Navigator.pop(context);
                      if (member.isAvailable) {
                        provider.launchZoom(member.zoomLink);
                        provider.addPoints(5);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(
                                  '${member.name} غير متاح حالياً للزووم.',
                                  style: const TextStyle(
                                      fontSize: 18, fontFamily: 'Cairo'))),
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildCallTypeButton(
      {required String label,
      required IconData icon,
      required Color color,
      required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
          boxShadow: [
            BoxShadow(
                color: color.withValues(alpha: 0.15),
                blurRadius: 10,
                offset: const Offset(0, 4))
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 48),
            const SizedBox(height: 12),
            Text(label,
                style: TextStyle(
                    color: color,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Cairo')),
          ],
        ),
      ),
    );
  }

  Widget _buildPerson(FamilyMember member, Color color, AppRiverpod provider) {
    bool hc = provider.isHighContrast;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showCallActionSheet(context, member, provider),
        borderRadius: BorderRadius.circular(22),
        child: Container(
          decoration: BoxDecoration(
            color: hc ? const Color(0xFF252525) : const Color(0xFFf5f3ff),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
                color: hc ? const Color(0xFF444444) : const Color(0xFFede9fe),
                width: 1.5),
            boxShadow: [
              BoxShadow(
                  color:
                      const Color(0xFF6C63FF).withValues(alpha: hc ? 0.2 : 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4))
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: member.isAvailable
                        ? const Color(0xFF4ade80)
                        : const Color(0xFFd1d5db),
                  ),
                ),
              ),
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 66,
                      height: 66,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: color.withValues(alpha: 0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: Center(
                        child: Text(
                          member.initials,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      member.name,
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1f2937)),
                    ),
                    Text(
                      member.relation,
                      style: const TextStyle(
                          fontSize: 15,
                          color: Color(0xFF6b7280),
                          fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPointsCard(AppRiverpod provider) {
    int points = provider.currentUser.points;
    double progress = (points / 600.0).clamp(0.0, 1.0);
    int percentage = (progress * 100).toInt();
    bool hc = provider.isHighContrast;
    return Container(
      decoration: BoxDecoration(
        color: hc ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
              color: const Color(0xFF6C63FF).withValues(alpha: hc ? 0.2 : 0.08),
              blurRadius: 20,
              offset: const Offset(0, 4))
        ],
        border: Border.all(
            color: hc ? const Color(0xFF333333) : const Color(0xFFede9fe),
            width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  // جعل قسم النصوص مرناً بالكامل
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FittedBox(
                        // يضمن أن رقم النقاط الكبير لن يسبب Overflow
                        fit: BoxFit.scaleDown,
                        child: Text(
                          '⭐ $points',
                          style: const TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF6C63FF)),
                        ),
                      ),
                      const SizedBox(height: 4),
                      FittedBox(
                        // يضمن أن الجملة التوضيحية لن تخرج عن حدود الكارت
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'من ٦٠٠ نقطة هذا الشهر',
                          style: TextStyle(
                              fontSize: 16,
                              color: hc ? Colors.white70 : Colors.grey[600],
                              fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                AnimatedBuilder(
                  animation: _starController,
                  builder: (context, child) {
                    final t = _starController.value * 2 * pi;
                    final y = -5 * sin(t * 2);
                    final rot = -8 * sin(t * 2) + 4 * sin(t * 4);
                    return Transform.translate(
                      offset: Offset(0, y),
                      child: Transform.rotate(
                        angle: rot * pi / 180,
                        child: const Text('🏆', style: TextStyle(fontSize: 36)),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Container(
                height: 12,
                decoration: BoxDecoration(
                    color:
                        hc ? const Color(0xFF333333) : const Color(0xFFede9fe),
                    borderRadius: BorderRadius.circular(10)),
                child: FractionallySizedBox(
                  alignment: Alignment.centerRight,
                  widthFactor: progress,
                  child: AnimatedBuilder(
                    animation: _bgController,
                    builder: (context, child) {
                      return Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment(_bgController.value * 4 - 2, 0),
                            end: const Alignment(1, 0),
                            colors: const [
                              Color(0xFFa78bfa),
                              Color(0xFFe9d5ff),
                              Color(0xFFa78bfa)
                            ],
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text('٪$percentage — استمر يا بطل! 💪',
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF7c3aed))),
          ],
        ),
      ),
    );
  }

  Widget _buildComplaintCard(AppRiverpod provider, BuildContext context) {
    bool hc = provider.isHighContrast;
    return GestureDetector(
      onTap: () => _showElderlyComplaintSheet(provider, context),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: hc ? const Color(0xFF1E1E1E) : const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(26),
          boxShadow: [
            BoxShadow(
                color:
                    const Color(0xFFEF4444).withValues(alpha: hc ? 0.2 : 0.08),
                blurRadius: 20,
                offset: const Offset(0, 4))
          ],
          border: Border.all(
              color: hc ? const Color(0xFF450a0a) : const Color(0xFFFECACA),
              width: 1.5),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: const BoxDecoration(
                  color: Color(0xFFFCA5A5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.room_service_rounded,
                    color: Color(0xFFB91C1C), size: 32),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('طلب مساعدة / شكوى',
                        style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF991B1B))),
                    Text('هل تحتاج لشيء؟ نحن هنا لخدمتك.',
                        style:
                            TextStyle(fontSize: 16, color: Color(0xFFB91C1C))),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showElderlyComplaintSheet(AppRiverpod provider, BuildContext context) {
    String selectedType = 'جودة الطعام';
    final TextEditingController descController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 20,
                right: 20,
                top: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                      width: 50,
                      height: 5,
                      decoration: BoxDecoration(
                          color: const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(4))),
                ),
                const SizedBox(height: 24),
                const Text('أخبرنا بما يزعجك',
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A))),
                const SizedBox(height: 24),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    'جودة الطعام',
                    'صيانة الغرفة',
                    'مساعدة في التنظيف',
                    'أحتاج ممرض',
                    'أخرى'
                  ].map((type) {
                    final isSelected = selectedType == type;
                    return GestureDetector(
                      onTap: () => setModalState(() => selectedType = type),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF6C63FF)
                              : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(type,
                            style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : const Color(0xFF475569),
                                fontSize: 18,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal)),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: descController,
                  maxLines: 2,
                  style: const TextStyle(fontSize: 18),
                  decoration: InputDecoration(
                    hintText: 'اكتب تفاصيل إضافية إن أردت...',
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: () {
                      provider.submitComplaint(
                          descController.text.isNotEmpty
                              ? descController.text
                              : 'طلب من المسن بخصوص $selectedType',
                          selectedType,
                          'مسن');
                      Navigator.pop(context);

                      // Show central animation
                      setState(() {
                        _successMessage =
                            'تم استلام طلبك وسيتوجه فريقنا لخدمتك فوراً';
                        _showSuccessAnimation = true;
                      });

                      // Automatically hides based on onLoaded in _buildCentralSuccessAnimation
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6C63FF),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                    ),
                    child: const Text('إرسال الطلب',
                        style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildVolunteerRatingCard(AppRiverpod provider, BuildContext context) {
    bool hc = provider.isHighContrast;
    return GestureDetector(
      onTap: () => _showVolunteerRatingSheet(provider, context),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: hc ? const Color(0xFF1E1E1E) : const Color(0xFFF0FDF4),
          borderRadius: BorderRadius.circular(26),
          boxShadow: [
            BoxShadow(
                color:
                    const Color(0xFF22C55E).withValues(alpha: hc ? 0.2 : 0.08),
                blurRadius: 20,
                offset: const Offset(0, 4))
          ],
          border: Border.all(
              color: hc ? const Color(0xFF052e16) : const Color(0xFFBBF7D0),
              width: 1.5),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: const BoxDecoration(
                  color: Color(0xFF86EFAC),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.volunteer_activism_rounded,
                    color: Color(0xFF15803D), size: 32),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('كيف كانت جلستك التطوعية؟',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF166534))),
                    Text('أخبرنا برأيك في المتطوع الذي زارك مؤخراً.',
                        style:
                            TextStyle(fontSize: 14, color: Color(0xFF15803D))),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showVolunteerRatingSheet(AppRiverpod provider, BuildContext context) {
    int selectedRating = 0; // 3 = happy, 2 = normal, 1 = sad
    final commentController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 20,
                right: 20,
                top: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Center(
                  child: Container(
                      width: 50,
                      height: 5,
                      decoration: BoxDecoration(
                          color: const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(4))),
                ),
                const SizedBox(height: 24),
                const Text('تقييم زيارة التطوع 🌟',
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A))),
                const SizedBox(height: 12),
                const Text('كيف كان وقتك مع المتطوع أحمد؟',
                    style: TextStyle(fontSize: 18, color: Color(0xFF475569))),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildRatingEmoji('☹️', 'غير سعيد', 1, selectedRating, () {
                      setModalState(() => selectedRating = 1);
                    }),
                    _buildRatingEmoji('😐', 'عادي', 2, selectedRating, () {
                      setModalState(() => selectedRating = 2);
                    }),
                    _buildRatingEmoji('😊', 'سعيد', 3, selectedRating, () {
                      setModalState(() => selectedRating = 3);
                    }),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: commentController,
                  maxLines: 2,
                  style: const TextStyle(fontSize: 16),
                  decoration: InputDecoration(
                    hintText: 'اكتب رأيك هنا (اختياري)...',
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: selectedRating == 0
                        ? null
                        : () {
                            provider.rateVolunteerSession(
                                'v_123', selectedRating,
                                comment: commentController.text);
                            Navigator.pop(context);

                            // Show central animation
                            setState(() {
                              _successMessage =
                                  'شكراً لتقييمك! نحن سعداء بخدمتك';
                              _showSuccessAnimation = true;
                            });

                            // Automatically hides based on onLoaded in _buildCentralSuccessAnimation
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF22C55E),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                      disabledBackgroundColor: const Color(0xFFE2E8F0),
                    ),
                    child: const Text('إرسال التقييم',
                        style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildRatingEmoji(String emoji, String label, int value,
      int selectedValue, VoidCallback onTap) {
    bool isSelected = value == selectedValue;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFFDCFCE7)
                  : const Color(0xFFF1F5F9),
              shape: BoxShape.circle,
              border: Border.all(
                  color:
                      isSelected ? const Color(0xFF22C55E) : Colors.transparent,
                  width: 3),
            ),
            child:
                Text(emoji, style: TextStyle(fontSize: isSelected ? 48 : 36)),
          ),
          const SizedBox(height: 12),
          Text(label,
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected
                      ? const Color(0xFF166534)
                      : const Color(0xFF64748B))),
        ],
      ),
    );
  }

  Widget _buildServiceRatingCard(AppRiverpod provider, BuildContext context) {
    bool hc = provider.isHighContrast;
    return GestureDetector(
      onTap: () => _showServiceRatingSheet(provider, context),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: hc ? const Color(0xFF1E1E1E) : const Color(0xFFEFF6FF),
          borderRadius: BorderRadius.circular(26),
          boxShadow: [
            BoxShadow(
                color:
                    const Color(0xFF3B82F6).withValues(alpha: hc ? 0.2 : 0.08),
                blurRadius: 20,
                offset: const Offset(0, 4))
          ],
          border: Border.all(
              color: hc ? const Color(0xFF1E3A8A) : const Color(0xFFBFDBFE),
              width: 1.5),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: const BoxDecoration(
                  color: Color(0xFF93C5FD),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.star_rounded,
                    color: Color(0xFF1D4ED8), size: 32),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('تقييم جودة الخدمة',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E40AF))),
                    Text('رأيك يهمنا في الدار والممرض والأخصائي.',
                        style:
                            TextStyle(fontSize: 14, color: Color(0xFF1D4ED8))),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showServiceRatingSheet(AppRiverpod provider, BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                  width: 50,
                  height: 5,
                  decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(4))),
            ),
            const SizedBox(height: 24),
            const Text('ماذا تريد أن تقيم اليوم؟ ⭐',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A))),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                    child: _elderlyReviewButton('الأخصائي', () {
                  Navigator.pop(context);
                  _showElderlyReviewDialog('specialist');
                })),
                const SizedBox(width: 8),
                Expanded(
                    child: _elderlyReviewButton('الممرض', () {
                  Navigator.pop(context);
                  _showElderlyReviewDialog('nurse');
                })),
                const SizedBox(width: 8),
                Expanded(
                    child: _elderlyReviewButton('الدار', () {
                  Navigator.pop(context);
                  _showElderlyReviewDialog('home');
                })),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _elderlyReviewButton(String label, VoidCallback onTap) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF3B82F6),
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 0,
      ),
      child: Text(label,
          style: const TextStyle(
              color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
    );
  }

  void _showElderlyReviewDialog(String toRole) {
    int selectedRating = 0;
    final commentController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(
              'تقييم ${toRole == 'specialist' ? 'الأخصائي' : toRole == 'nurse' ? 'الممرض' : 'الدار'}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontFamily: 'Cairo')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildRatingEmoji('☹️', 'غير سعيد', 1, selectedRating, () {
                      setState(() => selectedRating = 1);
                    }),
                    _buildRatingEmoji('😐', 'عادي', 2, selectedRating, () {
                      setState(() => selectedRating = 2);
                    }),
                    _buildRatingEmoji('😊', 'سعيد', 3, selectedRating, () {
                      setState(() => selectedRating = 3);
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: commentController,
                maxLines: 2,
                style: const TextStyle(fontSize: 16),
                decoration: InputDecoration(
                  hintText: 'اكتب رأيك هنا (اختياري)...',
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('إلغاء')),
            ElevatedButton(
              onPressed: selectedRating == 0
                  ? null
                  : () {
                      final provider = ref.read(appRiverpod);
                      provider.addReview(Review(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        fromRole: 'elderly',
                        fromName: provider.currentUser.name,
                        toRole: toRole,
                        rating: selectedRating.toDouble(),
                        comment: commentController.text,
                        date: DateTime.now().toString(),
                      ));
                      Navigator.pop(context);

                      // Show central animation
                      setState(() {
                        _successMessage = 'شكراً لتقييمك! نحن سعداء بخدمتك';
                        _showSuccessAnimation = true;
                      });

                      // Automatically hides based on onLoaded in _buildCentralSuccessAnimation
                    },
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF22C55E)),
              child: const Text('إرسال', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedBackground() {
    return AnimatedBuilder(
      animation: _bgController,
      builder: (context, child) {
        return Stack(
          children: [
            // Waves at the top
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 150,
              child: CustomPaint(
                painter: TopWavePainter(_bgController.value),
              ),
            ),

            // Waves in the middle
            Positioned(
              top: 300,
              left: 0,
              right: 0,
              height: 100,
              child: CustomPaint(
                painter: LineWavePainter(_bgController.value),
              ),
            ),

            Positioned(
              top: 600,
              left: 0,
              right: 0,
              height: 100,
              child: CustomPaint(
                painter: LineWavePainter(_bgController.value + 0.5),
              ),
            ),

            // Waves at the bottom
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: 200,
              child: CustomPaint(
                painter: WavePainter(_bgController.value),
              ),
            ),

            // Musical Notes
            FloatingNote(
                animationValue: _bgController.value,
                top: 200,
                left: 50,
                emoji: '🎵'),
            FloatingNote(
                animationValue: _bgController.value,
                top: 400,
                left: 300,
                emoji: '🎶'),
            FloatingNote(
                animationValue: _bgController.value,
                top: 600,
                left: 100,
                emoji: '🎼'),
            FloatingNote(
                animationValue: _bgController.value,
                top: 150,
                left: 250,
                emoji: '🎵'),
            FloatingNote(
                animationValue: _bgController.value,
                top: 700,
                left: 200,
                emoji: '🎶'),
            FloatingNote(
                animationValue: _bgController.value,
                top: 300,
                left: 150,
                emoji: '🎼'),
            FloatingNote(
                animationValue: _bgController.value,
                top: 500,
                left: 20,
                emoji: '🎵'),
            FloatingNote(
                animationValue: _bgController.value,
                top: 800,
                left: 250,
                emoji: '🎶'),
            FloatingNote(
                animationValue: _bgController.value,
                top: 100,
                left: 180,
                emoji: '🎵'),
            FloatingNote(
                animationValue: _bgController.value,
                top: 650,
                left: 280,
                emoji: '🎼'),
            FloatingNote(
                animationValue: _bgController.value,
                top: 250,
                left: 280,
                emoji: '🎶'),
            FloatingNote(
                animationValue: _bgController.value,
                top: 450,
                left: 120,
                emoji: '🎵'),
            FloatingNote(
                animationValue: _bgController.value,
                top: 550,
                left: 220,
                emoji: '🎼'),
            FloatingNote(
                animationValue: _bgController.value,
                top: 350,
                left: 50,
                emoji: '🎵'),
            FloatingNote(
                animationValue: _bgController.value,
                top: 750,
                left: 150,
                emoji: '🎶'),
            FloatingNote(
                animationValue: _bgController.value,
                top: 50,
                left: 100,
                emoji: '🎵'),
            FloatingNote(
                animationValue: _bgController.value,
                top: 70,
                left: 320,
                emoji: '🎶'),
            FloatingNote(
                animationValue: _bgController.value,
                top: 120,
                left: 40,
                emoji: '🎼'),
            FloatingNote(
                animationValue: _bgController.value,
                top: 180,
                left: 130,
                emoji: '🎵'),
          ],
        );
      },
    );
  }
}

class WavePainter extends CustomPainter {
  final double animationValue;
  WavePainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF6C63FF).withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, size.height * 0.45);

    for (double i = 0; i <= size.width; i++) {
      path.lineTo(
        i,
        size.height * 0.45 +
            sin((i / size.width * 2 * pi) + (animationValue * 2 * pi)) * 25,
      );
    }

    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);

    // Draw another wave
    final paint2 = Paint()
      ..color = const Color(0xFFF472B6).withValues(alpha: 0.1)
      ..style = PaintingStyle.fill;

    final path2 = Path();
    path2.moveTo(0, size.height * 0.55);

    for (double i = 0; i <= size.width; i++) {
      path2.lineTo(
        i,
        size.height * 0.55 +
            cos((i / size.width * 2 * pi) + (animationValue * 2 * pi)) * 20,
      );
    }

    path2.lineTo(size.width, size.height);
    path2.lineTo(0, size.height);
    path2.close();

    canvas.drawPath(path2, paint2);

    // Draw a third wave
    final paint3 = Paint()
      ..color = const Color(0xFF0EA5E9).withValues(alpha: 0.1)
      ..style = PaintingStyle.fill;

    final path3 = Path();
    path3.moveTo(0, size.height * 0.65);

    for (double i = 0; i <= size.width; i++) {
      path3.lineTo(
        i,
        size.height * 0.65 +
            sin((i / size.width * 3 * pi) + (animationValue * 2 * pi)) * 12,
      );
    }

    path3.lineTo(size.width, size.height);
    path3.lineTo(0, size.height);
    path3.close();

    canvas.drawPath(path3, paint3);

    path2.lineTo(size.width, size.height);
    path2.lineTo(0, size.height);
    path2.close();

    canvas.drawPath(path2, paint2);
  }

  @override
  bool shouldRepaint(covariant WavePainter oldDelegate) => true;
}

class FloatingNote extends StatelessWidget {
  final double animationValue;
  final double top;
  final double left;
  final String emoji;

  const FloatingNote({
    super.key,
    required this.animationValue,
    required this.top,
    required this.left,
    required this.emoji,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top + sin(animationValue * 2 * pi) * 20,
      left: left + cos(animationValue * 2 * pi) * 20,
      child: Opacity(
        opacity: 0.25,
        child: Text(
          emoji,
          style: const TextStyle(fontSize: 28),
        ),
      ),
    );
  }
}

class TopWavePainter extends CustomPainter {
  final double animationValue;
  TopWavePainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF6C63FF).withValues(alpha: 0.1)
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, size.height * 0.5);

    for (double i = 0; i <= size.width; i++) {
      path.lineTo(
        i,
        size.height * 0.5 +
            sin((i / size.width * 2 * pi) + (animationValue * 2 * pi)) * 15,
      );
    }

    path.lineTo(size.width, 0);
    path.lineTo(0, 0);
    path.close();

    canvas.drawPath(path, paint);

    // Draw another wave
    final paint2 = Paint()
      ..color = const Color(0xFFF472B6).withValues(alpha: 0.08)
      ..style = PaintingStyle.fill;

    final path2 = Path();
    path2.moveTo(0, size.height * 0.4);

    for (double i = 0; i <= size.width; i++) {
      path2.lineTo(
        i,
        size.height * 0.4 +
            cos((i / size.width * 2 * pi) + (animationValue * 2 * pi)) * 12,
      );
    }

    path2.lineTo(size.width, 0);
    path2.lineTo(0, 0);
    path2.close();

    canvas.drawPath(path2, paint2);
  }

  @override
  bool shouldRepaint(covariant TopWavePainter oldDelegate) => true;
}

class LineWavePainter extends CustomPainter {
  final double animationValue;
  LineWavePainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF6C63FF).withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final path = Path();
    path.moveTo(0, size.height * 0.5);

    for (double i = 0; i <= size.width; i++) {
      path.lineTo(
        i,
        size.height * 0.5 +
            sin((i / size.width * 2 * pi) + (animationValue * 2 * pi)) * 20,
      );
    }

    canvas.drawPath(path, paint);

    final paint2 = Paint()
      ..color = const Color(0xFFF472B6).withValues(alpha: 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final path2 = Path();
    path2.moveTo(0, size.height * 0.6);

    for (double i = 0; i <= size.width; i++) {
      path2.lineTo(
        i,
        size.height * 0.6 +
            cos((i / size.width * 2 * pi) + (animationValue * 2 * pi)) * 15,
      );
    }

    canvas.drawPath(path2, paint2);
  }

  @override
  bool shouldRepaint(covariant LineWavePainter oldDelegate) => true;
}
