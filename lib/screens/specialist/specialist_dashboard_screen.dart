import 'dart:math'; // مكتبة العمليات الرياضية

import 'package:flutter/material.dart'; // مكتبة فلاتر للواجهات
import 'package:flutter_riverpod/flutter_riverpod.dart'; // مكتبة إدارة الحالة
import '../../providers/app_riverpod.dart'; // مزود الحالة الرئيسي
// الهيكل الموحد للتطبيق
import '../../widgets/taptaba_drawer.dart'; // القائمة الجانبية الموحدة
import '../../widgets/taptaba_bell.dart'; // أيقونة الإشعارات
import 'views/assessment_view.dart'; // واجهة التقييمات الاجتماعية
import 'views/complaints_view.dart'; // واجهة الشكاوى والاقتراحات
import 'views/kpi_view.dart'; // واجهة مؤشرات الأداء للأخصائي
import 'views/files_view.dart'; // واجهة الملفات والمستندات
import 'views/activities_view.dart'; // واجهة الأنشطة والرحلات
// مركز التنبيهات العام
import 'specialist_chats_list_screen.dart'; // شاشة قائمة المحادثات

class SocialSpecialistDashboardScreen extends ConsumerStatefulWidget {
  // شاشة لوحة تحكم الأخصائي الاجتماعي
  const SocialSpecialistDashboardScreen({super.key}); // مشيد الفئة

  @override
  ConsumerState<SocialSpecialistDashboardScreen> createState() =>
      _SocialSpecialistDashboardScreenState(); // إنشاء حالة المكون
}

class _SocialSpecialistDashboardScreenState
    extends ConsumerState<SocialSpecialistDashboardScreen>
    with TickerProviderStateMixin {
  // حالة الشاشة مع دعم الأنيميشن
  int _currentTabIndex = 0; // الفهرس الحالي للتبويبات
  late AnimationController _floatController; // متحكم حركة الطفو
  late AnimationController _shimmerController; // متحكم حركة اللمعان
  late AnimationController _popController; // متحكم حركة دخول العناصر
  late AnimationController _particleController; // متحكم حركة الجزيئات
  late List<Animation<double>> _fadeAnimations; // قائمة حركات التلاشي للعناصر
  late ScrollController _chipsScrollController; // متحكم شريط تمرير الشرائح
  late List<Particle> _particles; // قائمة الجزيئات للشبكة
  late List<BgParticle> _dust; // قائمة غبار النجوم للخلفية

  @override
  void initState() {
    // دالة التهيئة الأولية
    super.initState();
    _chipsScrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startChipsScrolling());

    _floatController = AnimationController(
        // إعداد حركة الطفو المستمرة
        vsync: this,
        duration: const Duration(milliseconds: 2000))
      ..repeat(reverse: true);
    _shimmerController = AnimationController(
        // إعداد حركة اللمعان للمؤشرات
        vsync: this,
        duration: const Duration(milliseconds: 1500))
      ..repeat();
    _popController = AnimationController(
        // إعداد حركة دخول العناصر
        vsync: this,
        duration: const Duration(milliseconds: 800))
      ..forward();

    _particleController = AnimationController(
        // إعداد حركة الجزيئات
        vsync: this,
        duration: const Duration(seconds: 20))
      ..repeat();

    // تهيئة الجزيئات بشكل عشوائي
    final random = Random();
    _particles = List.generate(40, (index) {
      return Particle(
        position: Offset(random.nextDouble(),
            random.nextDouble()), // نسب مئوية لتغطية الشاشة بالكامل
        velocity: Offset((random.nextDouble() - 0.5) * 0.1,
            (random.nextDouble() - 0.5) * 0.1), // سرعة أبطأ لتناسب النسب
        radius: random.nextDouble() * 2 + 1, // حجم عشوائي
      );
    });

    // تهيئة غبار النجوم للخلفية
    _dust = List.generate(150, (index) {
      return BgParticle(
        position: Offset(random.nextDouble(), random.nextDouble()),
        speed: random.nextDouble() * 0.05 + 0.02, // سرعة صعود بطيئة
        radius: random.nextDouble() * 1.5 + 0.5, // حجم صغير جداً
      );
    });

    _fadeAnimations = List.generate(
      // إنشاء تسلسل حركات ظهور للعناصر
      15,
      (index) => Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
          parent: _popController,
          curve: Interval(index * 0.05, min(index * 0.05 + 0.5, 1.0),
              curve: Curves.easeOut),
        ),
      ),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // تحديث دور المستخدم في الحالة بعد البناء
      if (mounted) {
        ref.read(appRiverpod).setAndSaveRole('أخصائي اجتماعي');
      }
    });
  }

  void _startChipsScrolling() async {
    while (mounted) {
      await Future.delayed(const Duration(seconds: 2));
      if (_chipsScrollController.hasClients) {
        final maxScroll = _chipsScrollController.position.maxScrollExtent;
        if (maxScroll > 0) {
          await _chipsScrollController.animateTo(
            maxScroll,
            duration: const Duration(seconds: 3),
            curve: Curves.linear,
          );
          await Future.delayed(const Duration(seconds: 2));
          if (_chipsScrollController.hasClients) {
            await _chipsScrollController.animateTo(
              0,
              duration: const Duration(milliseconds: 1000),
              curve: Curves.easeOut,
            );
          }
        }
      }
    }
  }

  @override
  void dispose() {
    // تنظيف متحكمات الأنيميشن عند إغلاق الشاشة
    _floatController.dispose();
    _shimmerController.dispose();
    _popController.dispose();
    _particleController.dispose();
    _chipsScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // بناء واجهة لوحة تحكم الأخصائي
    final provider = ref.watch(appRiverpod); // مراقبة حالة التطبيق

    void navigateToTab(int index) {
      // دالة للتنقل بين التبويبات برمجياً
      if (index >= 0 && index < 5) {
        setState(() => _currentTabIndex = index);
      }
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text('ونس',
            style: TextStyle(
                color: Color(0xFFea580c),
                fontWeight: FontWeight.w900,
                fontSize: 24)),
        iconTheme: const IconThemeData(color: Color(0xFFea580c)),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu_rounded),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline_rounded,
                color: Color(0xFFea580c)),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const SpecialistChatsListScreen()),
              );
            },
          ),
          const TaptabaBell(),
          const SizedBox(width: 8),
        ],
      ),
      drawer: const TaptabaDrawer(overrideRole: 'أخصائي'),
      body: Column(
        children: [
          _buildHero(provider, navigateToTab),
          Expanded(
            child: Container(
              // جسم الصفحة تحت شريط العنوان
              decoration: const BoxDecoration(
                color: Color(0xFFf8fafc), // لون خلفية هادئ
                borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30)), // حواف دائرية علوية
              ),
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: Stack(
                  children: [
                    // أنيميشن الخلفية (الفقاعات وغبار النجوم)
                    Positioned.fill(
                      child: AnimatedBuilder(
                        animation: _particleController,
                        builder: (context, child) {
                          return CustomPaint(
                            painter: BackgroundPainter(
                              dust: _dust,
                              animationValue: _particleController.value,
                            ),
                          );
                        },
                      ),
                    ),
                    Positioned.fill(
                      child: IndexedStack(
                        // عرض المحتوى بناءً على التبويب المختار
                        index: _currentTabIndex,
                        children: [
                          SpecialistAssessmentView(
                              // واجهة التقييمات
                              fadeAnimations: _fadeAnimations,
                              floatController: _floatController,
                              shimmerController: _shimmerController,
                              popController: _popController,
                              onNavigate: navigateToTab),
                          SpecialistComplaintsView(
                              // واجهة الشكاوى
                              fadeAnimations: _fadeAnimations,
                              floatController: _floatController,
                              shimmerController: _shimmerController,
                              popController: _popController,
                              onNavigate: navigateToTab),
                          SpecialistKPIView(
                              // واجهة الأرقام والإحصائيات
                              fadeAnimations: _fadeAnimations,
                              floatController: _floatController,
                              shimmerController: _shimmerController,
                              popController: _popController,
                              onNavigate: navigateToTab),
                          SpecialistFilesView(
                              // واجهة المستندات
                              fadeAnimations: _fadeAnimations,
                              floatController: _floatController,
                              shimmerController: _shimmerController,
                              popController: _popController,
                              onNavigate: navigateToTab),
                          SpecialistActivitiesView(
                              // واجهة الأنشطة والرحلات
                              fadeAnimations: _fadeAnimations,
                              floatController: _floatController,
                              shimmerController: _shimmerController,
                              popController: _popController,
                              onNavigate: navigateToTab),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(), // بناء شريط التنقل السفلي المخصص
    );
  }

  Widget _buildHero(AppRiverpod provider, void Function(int) navigateToTab) {
    // بناء منطقة الـ Hero في الأعلى
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          // تدرج برتقالي حيوي
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [Color(0xFFc2410c), Color(0xFFea580c), Color(0xFFf97316)],
        ),
      ),
      child: Stack(
        children: [
          // شبكة العلاقات الاجتماعية المتحركة في الخلفية
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _particleController,
              builder: (context, child) {
                return CustomPaint(
                  painter: SocialMeshPainter(
                    particles: _particles,
                    animationValue: _particleController.value,
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 20, 28, 20),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start, // محاذاة لليمين في الـ RTL
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('الأخصائي الاجتماعي',
                          style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 0.5)),
                      Text('أ. نور — رعاية المقيمين', // اسم الأخصائي
                          style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withValues(alpha: 0.9),
                              fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
                if (_currentTabIndex != 1) ...[
                  const SizedBox(height: 20),
                  SingleChildScrollView(
                    // شرائح إحصائية سريعة في الـ Hero
                    controller: _chipsScrollController,
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        _buildHeroChip(
                            'شكاوى مفتوحة ٢',
                            const Color(0xFF34d399),
                            () => navigateToTab(1)), // شريحة الشكاوى
                        const SizedBox(width: 12),
                        _buildHeroChip('تقييم مطلوب ٧', const Color(0xFFfbbf24),
                            () => navigateToTab(0)), // شريحة التقييمات المطلوبة
                        const SizedBox(width: 12),
                        _buildHeroChip(
                            'احتياج فوري ١٣',
                            const Color(0xFFf87171),
                            () => navigateToTab(0)), // شريحة الاحتياجات العاجلة
                      ],
                    ),
                  ),
                ],
                if (_currentTabIndex == 1) ...[
                  const SizedBox(height: 16),
                  _buildComplaintsKPI(provider),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComplaintsKPI(AppRiverpod provider) {
    final stats = [
      {'val': '١٥', 'lbl': 'الكل', 'col': Colors.white},
      {'val': '٨', 'lbl': 'مُغلقة', 'col': const Color(0xFF6ee7b7)},
      {'val': '٤', 'lbl': 'جاري', 'col': const Color(0xFFfde68a)},
      {'val': '٣', 'lbl': 'مفتوحة', 'col': const Color(0xFFfca5a5)},
    ];

    return Row(
      children: stats
          .map((s) => Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border:
                        Border.all(color: Colors.white.withValues(alpha: 0.2)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(s['val'] as String,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      Text(s['lbl'] as String,
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 11,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ))
          .toList(),
    );
  }

  Widget _buildHeroChip(String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Text(label,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold)),
            const SizedBox(width: 8),
            Container(
                width: 7,
                height: 7,
                decoration:
                    BoxDecoration(color: color, shape: BoxShape.circle)),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      height: 85,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, -5))
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(0, Icons.assignment_rounded, 'التقييمات'),
          _buildNavItem(1, Icons.report_problem_rounded, 'الشكاوى'),
          _buildNavItem(2, Icons.analytics_rounded, 'الأداء'),
          _buildNavItem(3, Icons.folder_shared_rounded, 'الملفات'),
          _buildNavItem(4, Icons.event_available_rounded, 'الأنشطة'),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    bool isActive = _currentTabIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentTabIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: isActive
            ? BoxDecoration(
                color: const Color(0xFFfff7ed),
                borderRadius: BorderRadius.circular(16))
            : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                color: isActive
                    ? const Color(0xFFea580c)
                    : const Color(0xFF475569), // تغميق لون الأيقونة غير المفعلة
                size: 24),
            const SizedBox(height: 4),
            Text(label,
                style: TextStyle(
                    color: isActive
                        ? const Color(0xFFea580c)
                        : const Color(0xFF475569), // تغميق لون النص غير المفعل
                    fontSize: 11, // تكبير الخط قليلاً
                    fontWeight: isActive
                        ? FontWeight.w900
                        : FontWeight.w600)), // جعل الخط أثقل في الحالتين
          ],
        ),
      ),
    );
  }
}

class Particle {
  Offset position;
  Offset velocity;
  double radius;

  Particle(
      {required this.position, required this.velocity, required this.radius});
}

class SocialMeshPainter extends CustomPainter {
  final List<Particle> particles;
  final double animationValue;

  SocialMeshPainter({required this.particles, required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;

    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.1)
      ..strokeWidth = 0.5;

    // تحديث مواقع النقاط ورسمها
    for (var i = 0; i < particles.length; i++) {
      final p = particles[i];

      // حركة تعتمد على الـ animationValue والـ velocity + حركة موجية (Floating)
      double dx = (p.position.dx * size.width) +
          (p.velocity.dx * animationValue * size.width) +
          sin(animationValue * 2 * pi * 3 + i) * 10;
      double dy = (p.position.dy * size.height) +
          (p.velocity.dy * animationValue * size.height) +
          cos(animationValue * 2 * pi * 3 + i) * 10;

      // التأكد من بقاء النقاط داخل الحدود (Bounce)
      dx = dx % size.width;
      dy = dy % size.height;

      final currentPos = Offset(dx, dy);

      // رسم النقطة
      canvas.drawCircle(currentPos, p.radius, paint);

      // رسم وهج صغير للنقطة
      canvas.drawCircle(
          currentPos,
          p.radius * 2,
          Paint()
            ..color = Colors.white.withValues(alpha: 0.1)
            ..style = PaintingStyle.fill);

      // رسم الخطوط بين النقاط القريبة (شبكة العلاقات)
      for (var j = i + 1; j < particles.length; j++) {
        final p2 = particles[j];
        double dx2 = (p2.position.dx * size.width) +
            (p2.velocity.dx * animationValue * size.width) +
            sin(animationValue * 2 * pi * 3 + j) * 10;
        double dy2 = (p2.position.dy * size.height) +
            (p2.velocity.dy * animationValue * size.height) +
            cos(animationValue * 2 * pi * 3 + j) * 10;
        dx2 = dx2 % size.width;
        dy2 = dy2 % size.height;
        final pos2 = Offset(dx2, dy2);

        final distance = (currentPos - pos2).distance;
        if (distance < 80) {
          // المسافة التي تظهر عندها الخطوط
          // شفافية الخط تعتمد على المسافة (أقرب = أوضح)
          linePaint.color =
              Colors.white.withValues(alpha: (1.0 - (distance / 80)) * 0.15);
          canvas.drawLine(currentPos, pos2, linePaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant SocialMeshPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}

class BgParticle {
  Offset position;
  double speed;
  double radius;
  BgParticle(
      {required this.position, required this.speed, required this.radius});
}

class BackgroundPainter extends CustomPainter {
  final List<BgParticle> dust;
  final double animationValue;

  BackgroundPainter({required this.dust, required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    // 1. رسم الفقاعات (Blobs)
    final blobPaint1 = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFea580c).withValues(
              alpha: 0.25), // برتقالي (زيادة الوضوح بناء على طلب المستخدم)
          const Color(0xFFea580c).withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromCircle(center: const Offset(0, 0), radius: 150));

    final blobPaint2 = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF3b82f6).withValues(
              alpha: 0.25), // أزرق (زيادة الوضوح بناء على طلب المستخدم)
          const Color(0xFF3b82f6).withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromCircle(center: const Offset(0, 0), radius: 200));

    // حركة الفقاعات باستخدام الـ animationValue
    double blob1X = size.width * 0.2 + sin(animationValue * 2 * pi) * 80;
    double blob1Y = size.height * 0.3 + cos(animationValue * 2 * pi) * 80;

    double blob2X = size.width * 0.8 + cos(animationValue * 2 * pi) * 100;
    double blob2Y = size.height * 0.7 + sin(animationValue * 2 * pi) * 100;

    canvas.save();
    canvas.translate(blob1X, blob1Y);
    canvas.drawCircle(const Offset(0, 0), 150, blobPaint1);
    canvas.restore();

    canvas.save();
    canvas.translate(blob2X, blob2Y);
    canvas.drawCircle(const Offset(0, 0), 200, blobPaint2);
    canvas.restore();

    // 2. رسم غبار النجوم (Dust)
    final dustPaint = Paint()
      ..color = Colors.orange.withValues(alpha: 0.5)
      ..style = PaintingStyle.fill;

    for (var i = 0; i < dust.length; i++) {
      final p = dust[i];

      // حركة للأعلى
      double dy = (p.position.dy * size.height) -
          (animationValue * p.speed * size.height);
      if (dy < 0) dy += size.height; // إعادة التدوير للأعلى

      double dx = p.position.dx * size.width +
          sin(animationValue * 2 * pi + i) * 10; // تمايل خفيف

      final currentPos = Offset(dx, dy);

      // وميض (تغير الشفافية)
      double opacity =
          (sin(animationValue * 2 * pi * 2 + i) + 1) / 2; // من 0 إلى 1
      dustPaint.color =
          Colors.orange.withValues(alpha: opacity * 0.6); // زيادة الوضوح

      canvas.drawCircle(currentPos, p.radius, dustPaint);
    }
  }

  @override
  bool shouldRepaint(covariant BackgroundPainter oldDelegate) {
    return true;
  }
}
