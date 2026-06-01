import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart'; // مكتبة فلاتر للواجهات
import 'package:lottie/lottie.dart'; // مكتبة الأنيميشن
import 'nurse_reports_screen.dart'; // شاشة التقارير الخاصة بالتمريض
import 'nurse_residents_screen.dart'; // شاشة قائمة المقيمين
import 'nurse_resident_detail_screen.dart'; // شاشة تفاصيل المقيم
import 'nurse_profile_screen.dart'; // شاشة الملف الشخصي للممرض
import 'shift_handoff_screen.dart'; // شاشة تسليم واستلام الوردية
import 'views/medical_admin_view.dart'; // واجهة الإدارة الطبية
import 'views/operations_view.dart'; // واجهة العمليات اليومية
import 'package:flutter_riverpod/flutter_riverpod.dart'; // مكتبة إدارة الحالة
import 'package:url_launcher/url_launcher.dart'; // مكتبة لفتح الروابط والاتصال
import 'package:permission_handler/permission_handler.dart'; // مكتبة إدارة الصلاحيات
import '../../providers/app_riverpod.dart'; // مزود الحالة الرئيسي
import '../../models/app_models.dart'; // نماذج البيانات الخاصة بالتطبيق
import 'widgets/healing_particles.dart'; // الأنميشن الخاص بعلامات الشفاء
// القائمة الجانبية الموحدة
import '../../widgets/taptaba_scaffold.dart'; // الهيكل الموحد للتطبيق

// أرقام الطوارئ (يمكن للإدارة تعديلها من هنا حالياً، ومستقبلاً من لوحة التحكم)
class EmergencyContacts {
  static const String ambulance = '128';
  static const String doctor = '01012345678';
  static const String codeBlue = '01112345678';
}

class NurseDashboardScreen extends ConsumerStatefulWidget {
  // شاشة لوحة تحكم الممرض
  const NurseDashboardScreen({super.key}); // مشيد الفئة

  @override
  ConsumerState<NurseDashboardScreen> createState() =>
      _NurseDashboardScreenState(); // إنشاء حالة المكون
}

class _NurseDashboardScreenState extends ConsumerState<NurseDashboardScreen>
    with TickerProviderStateMixin {
  // حالة الشاشة مع دعم الأنيميشن والتوقيت
  int _currentTabIndex = 0; // الفهرس الحالي للتبويبات
  Timer? _timer; // مؤقت لحساب وقت الوردية
  final List<String> _dismissedAlerts = []; // التنبيهات التي تم حذفها بالسحب

  late AnimationController _pulseController; // متحكم أنيميشن النبض للتنبيهات

  String _selectedFilter = 'الكل'; // الفلتر المختار لعرض المقيمين

  double _dragPosition = 0;
  final double _triggerThreshold = 150.0;
  bool _isDragging = false;

  void _startShiftTimer() {
    // دالة لبدء مؤقت تنازلي لنهاية الوردية
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      // تحديث كل ثانية
      if (!mounted) return; // التأكد من أن الشاشة ما زالت مفتوحة
      final now = DateTime.now(); // الوقت الحالي
      DateTime shiftEnd; // موعد نهاية الوردية

      // منطق تحديد نهاية الوردية بناءً على الوقت الحالي (صباحية، مسائية، ليلية)
      if (now.hour >= 6 && now.hour < 14) {
        shiftEnd =
            DateTime(now.year, now.month, now.day, 14, 0, 0); // تنتهي 2 ظهراً
      } else if (now.hour >= 14 && now.hour < 22) {
        shiftEnd =
            DateTime(now.year, now.month, now.day, 22, 0, 0); // تنتهي 10 مساءً
      } else {
        if (now.hour >= 22) {
          shiftEnd = DateTime(
              now.year, now.month, now.day + 1, 6, 0, 0); // تنتهي 6 صباح غد
        } else {
          shiftEnd = DateTime(
              now.year, now.month, now.day, 6, 0, 0); // تنتهي 6 صباح اليوم
        }
      }

      final diff = shiftEnd.difference(now); // حساب الفرق الزمني
      if (diff.isNegative) {
        // إذا انتهى الوقت
        _timerHours = 0;
        _timerMins = 0;
        _timerSecs = 0;
      } else {
        setState(() {
          // تحديث عرض الوقت في الواجهة
          _timerHours = diff.inHours; // الساعات المتبقية
          _timerMins = diff.inMinutes % 60; // الدقائق المتبقية
          _timerSecs = diff.inSeconds % 60; // الثواني المتبقية
        });
      }
    });
  }

  int _timerHours = 0; // متغير تخزين الساعات المتبقية
  int _timerMins = 0; // متغير تخزين الدقائق المتبقية
  int _timerSecs = 0; // متغير تخزين الثواني المتبقية

  @override
  void initState() {
    // دالة التهيئة الأولية
    super.initState(); // استدعاء التهيئة الأصلية
    _pulseController = AnimationController(
        // إعداد أنيميشن النبض
        vsync: this,
        duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true); // تكرار الحركة ذهاباً وإياباً

    _startShiftTimer(); // بدء تشغيل مؤقت الوردية
  }

  @override
  void dispose() {
    // تنظيف الموارد عند إغلاق الشاشة
    _timer?.cancel(); // إيقاف المؤقت
    _pulseController.dispose(); // إغلاق متحكم النبض
    super.dispose(); // استدعاء التنظيف الأصلي
  }

  @override
  Widget build(BuildContext context) {
    // بناء واجهة الشاشة الرئيسية للممرض
    final provider = ref.watch(appRiverpod); // مراقبة حالة التطبيق

    return TaptabaScaffold(
      // استخدام الهيكل الموحد
      title: 'ونس', // عنوان الصفحة
      titleColor: const Color(0xFF0369A1), // لون العنوان الأزرق الطبي
      overrideRole: 'ممرض', // تحديد دور المستخدم كممرض
      bottomNavigationBar: _buildBottomNav(), // بناء شريط التنقل السفلي
      body: Stack(
        children: [
          IndexedStack(
            // عرض المحتوى بناءً على التبويب المختار
            index: _currentTabIndex, // التبويب الحالي
            children: [
              AnimatedBackground(
                  child:
                      _buildHomeView(provider)), // واجهة الرئيسية (نظرة عامة)
              const NurseResidentsScreen(), // واجهة قائمة المقيمين (لديها خلفيتها الخاصة)
              const AnimatedBackground(
                  child: OperationsView()), // واجهة العمليات والرعاية
              const AnimatedBackground(
                  child: MedicalAdminView()), // واجهة الإدارة الطبية
              const AnimatedBackground(
                  child: NurseReportsScreen()), // واجهة التقارير والتحليلات
            ],
          ),
          _buildDraggableSOS(), // زر الطوارئ المخفي القابل للسحب
        ],
      ),
    );
  }

  Widget _buildHomeView(AppRiverpod provider) {
    // بناء واجهة "الرئيسية" للممرض (مبسطة)
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          _buildHero(), // بناء الجزء العلوي (الهوية والوردية)
          _buildOperationalAlerts(provider), // بناء تنبيهات المخزون والمهام
          _buildShiftHandoffCard(provider), // بناء بطاقة تسليم الوردية
          _buildKPIs(), // بناء مؤشرات الأداء الرئيسية
          _buildResidentsSection(
              provider), // بناء قائمة المقيمين ذات الأولوية (مبسط)
          const SizedBox(height: 100), // مسافة فارغة في الأسفل
        ],
      ),
    );
  }

  Widget _buildOperationalAlerts(AppRiverpod provider) {
    // بناء تنبيهات العمليات (نقص مخزون أو مهام معلقة)
    final lowStockItems = provider.inventoryItems
        .where((i) => i.isLowStock)
        .toList(); // جرد الأصناف الناقصة
    final pendingTasks = provider.careTasks
        .where((t) => !t.isCompleted)
        .toList(); // جرد المهام غير المكتملة

    final showLowStock = lowStockItems.isNotEmpty &&
        !((_dismissedAlerts as dynamic)?.contains('نقص في المخزون!') ?? false);
    final showPendingTasks = pendingTasks.isNotEmpty &&
        !((_dismissedAlerts as dynamic)?.contains('مهام رعاية معلقة') ?? false);

    if (!showLowStock && !showPendingTasks) {
      return const SizedBox.shrink(); // إخفاء إذا لم يوجد تنبيهات
    }

    return Padding(
      // هوامش حول التنبيهات
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      child: Column(
        children: [
          if (showLowStock) // تنبيه نقص المخزون
            _alertCard(
              'نقص في المخزون!',
              'يوجد ${lowStockItems.length} أصناف أوشكت على النفاذ',
              const Color(0xFFEF4444),
              () => setState(
                  () => _currentTabIndex = 2), // الانتقال لتبويب العمليات
              onDismissed: (direction) {
                setState(() {
                  _dismissedAlerts.add('نقص في المخزون!');
                });
              },
            ),
          if (showLowStock && showPendingTasks) const SizedBox(height: 8),
          if (showPendingTasks) // تنبيه المهام المعلقة
            _alertCard(
              'مهام رعاية معلقة',
              'لديك ${pendingTasks.length} مهام متبقية لليوم',
              const Color(0xFFF59E0B),
              () => setState(
                  () => _currentTabIndex = 2), // الانتقال لتبويب العمليات
              onDismissed: (direction) {
                setState(() {
                  _dismissedAlerts.add('مهام رعاية معلقة');
                });
              },
            ),
        ],
      ),
    );
  }

  Widget _alertCard(String title, String sub, Color color, VoidCallback onTap,
      {required ValueChanged<DismissDirection>? onDismissed}) {
    // قالب بطاقة التنبيه
    return Dismissible(
      key: Key(title),
      direction: DismissDirection.horizontal,
      onDismissed: onDismissed,
      background: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFEF4444),
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_outline_rounded,
            color: Colors.white, size: 28),
      ),
      secondaryBackground: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFEF4444),
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        child: const Icon(Icons.delete_outline_rounded,
            color: Colors.white, size: 28),
      ),
      child: GestureDetector(
        // كاشف للمسات
        onTap: onTap,
        child: Container(
          // تصميم البطاقة
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.5), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.15),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.bold,
                            fontSize: 14)), // عنوان التنبيه
                    const SizedBox(height: 4),
                    Text(sub,
                        style: TextStyle(
                            color: color.withValues(alpha: 0.8),
                            fontSize: 12)), // نص فرعي للتنبيه
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Returns true if the nurse has already submitted a handoff in the current
  /// shift window (morning 06-14, evening 14-22, night 22-06).
  bool _hasSubmittedCurrentShift(AppRiverpod provider) {
    final now = DateTime.now();
    final shiftStart = _currentShiftStart(now);
    return provider.handoffs
        .any((h) => h.timestamp.isAfter(shiftStart) && !h.timestamp.isAfter(now));
  }

  DateTime _currentShiftStart(DateTime now) {
    if (now.hour >= 6 && now.hour < 14) {
      return DateTime(now.year, now.month, now.day, 6, 0);
    } else if (now.hour >= 14 && now.hour < 22) {
      return DateTime(now.year, now.month, now.day, 14, 0);
    } else if (now.hour >= 22) {
      return DateTime(now.year, now.month, now.day, 22, 0);
    } else {
      return DateTime(now.year, now.month, now.day - 1, 22, 0);
    }
  }

  void _showPreviousHandoffs(AppRiverpod provider) {
    final handoffs = provider.handoffs;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(4)),
              ),
            ),
            const SizedBox(height: 16),
            const Text('سجلات التسليم السابقة',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A))),
            const SizedBox(height: 16),
            if (handoffs.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(
                  child: Text('لا توجد سجلات تسليم سابقة',
                      style: TextStyle(
                          fontSize: 14, color: Color(0xFF94A3B8))),
                ),
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: handoffs.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, color: Color(0xFFE2E8F0)),
                  itemBuilder: (_, i) {
                    final h = handoffs[i];
                    final dt = h.timestamp;
                    final dateLabel =
                        '${dt.day}/${dt.month}/${dt.year}  ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                                color: const Color(0xFFE0F2FE),
                                borderRadius: BorderRadius.circular(10)),
                            child: const Icon(Icons.swap_horiz_rounded,
                                color: Color(0xFF0369A1), size: 18),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(h.nurseName,
                                    style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF0F172A))),
                                const SizedBox(height: 2),
                                Text(h.shiftType,
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF0369A1))),
                                if (h.notes.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(h.notes,
                                      style: const TextStyle(
                                          fontSize: 11,
                                          color: Color(0xFF475569),
                                          height: 1.4)),
                                ],
                              ],
                            ),
                          ),
                          Text(dateLabel,
                              style: const TextStyle(
                                  fontSize: 10, color: Color(0xFF94A3B8))),
                        ],
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildShiftHandoffCard(AppRiverpod provider) {
    final alreadySubmitted = _hasSubmittedCurrentShift(provider);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
              color: const Color(0xFF0EA5E9).withValues(alpha: 0.5),
              width: 1.5),
          boxShadow: [
            BoxShadow(
                color: const Color(0xFF0369A1).withValues(alpha: 0.15),
                blurRadius: 10,
                offset: const Offset(0, 4))
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('إدارة تسليم الوردية',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Color(0xFF0F172A))),
                      Text(
                        alreadySubmitted
                            ? 'تم تسليم الوردية الحالية ✅'
                            : 'جاهز للتسليم؟ قم بتجهيز تقريرك الآن',
                        style: TextStyle(
                            fontSize: 11,
                            color: alreadySubmitted
                                ? const Color(0xFF059669)
                                : const Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _showPreviousHandoffs(provider),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('السجلات السابقة',
                        style: TextStyle(
                            fontSize: 12, color: Color(0xFF64748B))),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: alreadySubmitted
                        ? null
                        : () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const ShiftHandoffScreen())),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0369A1),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: const Color(0xFFE2E8F0),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: Text(
                      alreadySubmitted ? 'تم التسليم' : 'بدء التسليم الآن',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: alreadySubmitted
                              ? const Color(0xFF94A3B8)
                              : Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getShiftName() {
    // دالة للحصول على اسم الوردية بناءً على الساعة
    final hour = DateTime.now().hour;
    if (hour >= 6 && hour < 14) return 'الوردية الصباحية (٦ ص - ٢ ظ)';
    if (hour >= 14 && hour < 22) return 'الوردية المسائية (٢ ظ - ١٠ م)';
    return 'الوردية الليلية (١٠ م - ٦ ص)';
  }

  Widget _buildHero() {
    final provider = ref.watch(appRiverpod);
    final nurseName = provider.currentAccount?.name ?? 'فريق التمريض';
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0369A1), Color(0xFF0EA5E9), Color(0xFF38BDF8)],
        ),
      ),
      child: Stack(
        children: [
          const HealingParticles(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'لوحة المشرف',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      GestureDetector(
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    const NurseProfileScreen())),
                        child: Text(
                          '$nurseName — ${_getShiftName()}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444).withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            FadeTransition(
                              opacity: _pulseController,
                              child: Container(
                                width: 7,
                                height: 7,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Color(0xFFFCA5A5),
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Flexible(
                              child: Text(
                                'حالات تحتاج تدخل فوري',
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'الوردية تنتهي',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$_timerHours:${_timerMins.toString().padLeft(2, '0')}:${_timerSecs.toString().padLeft(2, '0')}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKPIs() {
    // بناء مؤشرات الأداء الرئيسية (KPIs)
    return Padding(
      // هوامش حول المؤشرات
      padding: const EdgeInsets.all(12),
      child: Row(
        // ترتيب المؤشرات أفقياً
        children: [
          _buildKPICard(
              '${ref.watch(appRiverpod).totalResidentsCount}',
              'إجمالي المقيمين',
              'جميعهم نشطون',
              const Color(0xFF0369A1),
              const Color(0xFF10B981)), // كارت عدد المقيمين
          const SizedBox(width: 8),
          _buildKPICard(
              '${ref.watch(appRiverpod).criticalResidentsCount}',
              'حالات حرجة',
              'تحتاج متابعة',
              const Color(0xFFEF4444),
              const Color(0xFFEF4444)), // كارت الحالات الحرجة
          const SizedBox(width: 8),
          _buildKPICard(
              '${ref.watch(appRiverpod).medications.where((m) => !m.isTaken).length}',
              'جرعات متبقية',
              'هذا الصباح',
              const Color(0xFF0369A1),
              const Color(0xFFF59E0B)), // كارت الجرعات المتبقية
          const SizedBox(width: 8),
          _buildKPICard(
              '${ref.watch(appRiverpod).compliancePercentage}٪',
              'الالتزام بالدواء',
              'هذا الأسبوع',
              const Color(0xFF0369A1),
              const Color(0xFF10B981)), // كارت نسبة الالتزام
        ],
      ),
    );
  }

  Widget _buildKPICard(
      String val, String lbl, String sub, Color valColor, Color subColor) {
    // قالب بطاقة مؤشر الأداء - تم تعديله ليكون مرناً بالكامل
    return Expanded(
      // توزيع البطاقات بالتساوي
      child: Container(
        // تصميم البطاقة
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFBAE6FD), width: 1.5),
          boxShadow: [
            BoxShadow(
                color: const Color(0xFF0369A1).withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 4))
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FittedBox(
              // يضمن أن القيمة الرقمية لن تخرج عن حدود الكارت مهما كان حجم الخط
              fit: BoxFit.scaleDown,
              child: Text(
                val,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: valColor,
                ),
              ),
            ),
            const SizedBox(height: 4),
            MarqueeText(
              text: lbl,
              style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            MarqueeText(
              text: sub,
              style: TextStyle(
                fontSize: 11,
                color: subColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ignore: unused_element
  Widget _buildTabs() {
    // بناء فلاتر فرز المقيمين (التبويبات العلوية)
    final tabs = [
      'دواء متأخر',
      'مستقرة ✅',
      'تحذير 🟡',
      'حرجة 🔴',
      'الكل'
    ]; // قائمة الفلاتر
    return SingleChildScrollView(
      // السماح بالتمرير الأفقي للفلاتر
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: tabs.map((t) {
          final isAct = t == _selectedFilter; // هل الفلتر حالياً هو المختار؟
          return GestureDetector(
            // كاشف للمسات
            onTap: () =>
                setState(() => _selectedFilter = t), // تحديث الفلتر عند الضغط
            child: Container(
              margin: const EdgeInsets.only(left: 6),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                gradient: isAct // تدرج لوني للمختار فقط
                    ? const LinearGradient(
                        colors: [Color(0xFF0369A1), Color(0xFF0EA5E9)])
                    : null,
                color: isAct ? null : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color:
                        isAct ? Colors.transparent : const Color(0xFFBAE6FD)),
              ),
              child: Text(
                // اسم الفلتر
                t,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isAct ? Colors.white : const Color(0xFF0369A1),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color dotColor) {
    // بناء عنوان القسم مع نقطة ملونة
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
      child: Row(
        children: [
          Container(
            // نقطة اللون الجانبية
            width: 8,
            height: 8,
            decoration: BoxDecoration(shape: BoxShape.circle, color: dotColor),
          ),
          const SizedBox(width: 8),
          Text(
            // نص العنوان
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0369A1),
            ),
          ),
        ],
      ),
    );
  }

  // ignore: unused_element
  Widget _vitalChip(String text, Color bg, Color color) {
    // بناء شريحة عرض العلامات الحيوية
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildResidentsSection(AppRiverpod provider) {
    // بناء قسم قائمة المقيمين (مبسط كمثال)
    String getLatestNote(String name) {
      final cleanName = name.split(' — ')[0];
      final notes = provider.getNotesForResident(cleanName);
      return notes.isNotEmpty
          ? '${notes.first.title}: ${notes.first.content}'
          : '';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSectionHeader(
                  'المقيمون — أولوية المتابعة', const Color(0xFFEF4444)),
              TextButton(
                onPressed: () => setState(
                    () => _currentTabIndex = 1), // الانتقال لتبويب المقيمين
                child: const Text('عرض الكل',
                    style: TextStyle(
                        color: Color(0xFF0EA5E9),
                        fontWeight: FontWeight.bold,
                        fontSize: 12)),
              ),
            ],
          ),
        ),
        if (provider.residentFiles.isEmpty)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('لا توجد بيانات مقيمين من السيرفر الآن',
                style: TextStyle(color: Color(0xFF64748B))),
          )
        else
          ...provider.residentFiles.take(3).map((resident) {
            final isCritical =
                resident.status.toLowerCase().contains('critical') ||
                    resident.status.contains('حرج');
            final isWarning =
                resident.status.toLowerCase().contains('pending') ||
                    resident.status.toLowerCase().contains('warning');
            final category = isCritical
                ? 'حرجة 🔴'
                : isWarning
                    ? 'متابعة 🟡'
                    : 'مستقرة ✅';
            return _buildResCard(
              name: '${resident.name} — غرفة ${resident.room}',
              room: resident.age == null
                  ? 'من السيرفر'
                  : '${resident.age} سنة · من السيرفر',
              av: resident.initials,
              avBg: isCritical
                  ? const Color(0xFFFFE4E6)
                  : const Color(0xFFE0F2FE),
              avColor: isCritical
                  ? const Color(0xFF9F1239)
                  : const Color(0xFF0369A1),
              statusColor: isCritical
                  ? const Color(0xFFEF4444)
                  : const Color(0xFF0EA5E9),
              borderColor: isCritical
                  ? const Color(0xFFFCA5A5)
                  : const Color(0xFFBAE6FD),
              bg: isCritical
                  ? const Color(0xFFFFF5F5)
                  : const Color(0xFFF0F9FF),
              btnText: isCritical ? 'تدخّل' : 'متابعة',
              btnColor: isCritical
                  ? const Color(0xFFEF4444)
                  : const Color(0xFF0EA5E9),
              warnText: resident.categories.join(' · '),
              category: category,
              note: getLatestNote(resident.name),
            );
          }),
      ],
    );
  }

  Widget _buildResCard({
    required String name,
    required String room,
    required String av,
    required Color avBg,
    required Color avColor,
    required Color statusColor,
    required Color borderColor,
    required Color bg,
    required String btnText,
    required Color btnColor,
    required String warnText,
    required String category,
    bool isStable = false,
    String? note,
  }) {
    final nameOnly = name.split(' — ')[0];

    return Container(
      margin: const EdgeInsets.only(bottom: 12, left: 12, right: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => NurseResidentDetailScreen(
                residentName: nameOnly,
                roomNumber: room.replaceAll('غرفة ', '').split(' · ')[0],
              ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: avBg,
                      child: Text(
                        av,
                        style: TextStyle(
                          color: avColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: statusColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nameOnly,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            isStable
                                ? Icons.check_circle_rounded
                                : Icons.info_rounded,
                            size: 14,
                            color: isStable
                                ? const Color(0xFF10B981)
                                : const Color(0xFFEF4444),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              warnText,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                color: isStable
                                    ? const Color(0xFF10B981)
                                    : const Color(0xFFEF4444),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // زر الطوارئ السريع
                GestureDetector(
                  onTap: () => _showEmergencyAlert(nameOnly),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.emergency_share_rounded,
                      color: Color(0xFFEF4444),
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ignore: unused_element
  Widget _inputRow(String emoji, String lbl, TextEditingController controller,
      String unit, Color bg, bool hasBtn) {
    // بناء صف إدخال بيانات (مثل الضغط أو السكر)
    return Row(
      children: [
        Container(
          // أيقونة تعبيرية للبيان
          width: 36,
          height: 36,
          decoration:
              BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
          child:
              Center(child: Text(emoji, style: const TextStyle(fontSize: 16))),
        ),
        const SizedBox(width: 10),
        Expanded(
            // تسمية البيان (Label)
            child: Text(lbl,
                style:
                    const TextStyle(color: Color(0xFF64748B), fontSize: 13))),
        Container(
          // حقل الإدخال الرقمي
          width: 80,
          decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              borderRadius: BorderRadius.circular(8)),
          child: TextField(
            controller: controller,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
                fontSize: 13),
            decoration: const InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              border: InputBorder.none,
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          // وحدة القياس (مثل مجم/ديسيلتر)
          width: 40,
          child: Text(unit,
              style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
        ),
        const SizedBox(width: 8),
        if (hasBtn) // زر الربط مع أجهزة القياس الخارجية (بلوتوث)
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0EA5E9),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
              minimumSize: const Size(0, 30),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('🔗 جهاز',
                style: TextStyle(color: Colors.white, fontSize: 11)),
          )
        else
          const SizedBox(width: 58)
      ],
    );
  }

  // ignore: unused_element
  Widget _bar(double h, Color c) {
    // بناء أعمدة الرسم البياني للإحصائيات
    return Expanded(
      child: TweenAnimationBuilder(
        duration: const Duration(milliseconds: 1000),
        tween: Tween<double>(begin: 0, end: h),
        builder: (context, val, child) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Container(
              height: val,
              decoration: BoxDecoration(
                color: c,
                borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(4), topRight: Radius.circular(4)),
              ),
            ),
          );
        },
      ),
    );
  }

  // ignore: unused_element
  Widget _buildMedScheduleSection() {
    // بناء قسم جدول مواعيد الأدوية لليوم
    final provider = ref.watch(appRiverpod);
    final allMeds = provider.medications;

    // تجميع الأدوية حسب المقيم لعرضها في صفوف منظمة
    final Map<String, List<Medication>> groupedMeds = {};
    for (var med in allMeds) {
      final name = med.residentName ?? 'غير محدد';
      if (!groupedMeds.containsKey(name)) groupedMeds[name] = [];
      groupedMeds[name]!.add(med);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                // زر للانتقال لتبويب العمليات لمشاهدة تفاصيل أكثر
                onPressed: () => setState(() => _currentTabIndex = 2),
                child: const Text('عرض الكل 📊',
                    style: TextStyle(
                        color: Color(0xFF0EA5E9),
                        fontWeight: FontWeight.bold,
                        fontSize: 12)),
              ),
              _buildSectionHeader(
                  'جدول الأدوية — اليوم', const Color(0xFF6366F1)),
            ],
          ),
          Container(
            // حاوية الجدول الرئيسي
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE0F2FE), width: 1.5),
            ),
            child: Column(
              children: [
                Container(
                  // ترويسة الجدول (الفترات الزمنية)
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: const BoxDecoration(
                      color: Color(0xFFF0F9FF),
                      borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16))),
                  child: Row(
                    children: [
                      const Expanded(
                          child: Text('الدواء / المقيم',
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF64748B)))),
                      _medH('ص'), // صباحاً
                      _medH('ظ'), // ظهراً
                      _medH('م'), // مساءً
                      _medH('ل'), // ليلاً
                    ],
                  ),
                ),
                ...groupedMeds.entries.map((entry) {
                  // إنشاء صف لكل مقيم وأدويته
                  final name = entry.key;
                  final meds = entry.value;
                  final medNames = meds.map((m) => m.name).join(' + ');

                  // منطق تحديد حالة الدواء لكل فترة زمنية في الجدول
                  String d1 = '-', d2 = '-', d3 = '-', d4 = '-';
                  for (var m in meds) {
                    final status = m.isTaken
                        ? '✓'
                        : ((m.isMissed || m.isSkipped) ? '!' : '⏰');
                    if (m.timeOfDay == 'الصباح') d1 = status;
                    if (m.timeOfDay == 'الظهر') d2 = status;
                    if (m.timeOfDay == 'المساء') d3 = status;
                  }

                  return Column(
                    children: [
                      _medRow(name, medNames, d1, d2, d3, d4),
                      const Divider(height: 1, color: Color(0xFFF0F9FF)),
                    ],
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _medH(String txt) {
    // خلية ترويسة الجدول
    return SizedBox(
        width: 40,
        child: Text(txt,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Color(0xFF64748B))));
  }

  Widget _medRow(
      String n, String s, String d1, String d2, String d3, String d4) {
    // صف بيانات المقيم في جدول الأدوية
    final residents =
        ref.read(appRiverpod).residentFiles.where((r) => r.name == n).toList();
    final roomNumber = residents.isEmpty ? '' : residents.first.room;
    return GestureDetector(
      onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => NurseResidentDetailScreen(
                  residentName: n, roomNumber: roomNumber))),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.arrow_back_ios_new_rounded,
                          size: 10, color: Color(0xFF94A3B8)),
                      const SizedBox(width: 4),
                      Text(n, // اسم المقيم
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A))),
                    ],
                  ),
                  Text(s, // أسماء الأدوية
                      style: const TextStyle(
                          fontSize: 11, color: Color(0xFF64748B))),
                ],
              ),
            ),
            _doseCell(d1, n), // خلية الجرعة الصباحية
            _doseCell(d2, n), // خلية الجرعة الظهرية
            _doseCell(d3, n), // خلية الجرعة المسائية
            _doseCell(d4, n), // خلية الجرعة الليلية
          ],
        ),
      ),
    );
  }

  Widget _doseCell(String st, String resident) {
    // خلية حالة الجرعة (ملونة حسب الحالة)
    Color bg = const Color(0xFFF3F4F6); // لون افتراضي (لا يوجد دواء)
    Color fg = const Color(0xFF9CA3AF);
    if (st == '✓') {
      // تم الإعطاء (أخضر)
      bg = const Color(0xFFD1FAE5);
      fg = const Color(0xFF065F46);
    } else if (st == '!') {
      // فاشلة/تجاوزت (أحمر)
      bg = const Color(0xFFFEE2E2);
      fg = const Color(0xFF7F1D1D);
    } else if (st == '⏰') {
      // بانتظار الموعد (أصفر)
      bg = const Color(0xFFFEF3C7);
      fg = const Color(0xFF92400E);
    }

    return GestureDetector(
      onTap: () {
        // فتح نافذة التأكيد عند الضغط على الخلية
        final provider = ref.read(appRiverpod);
        final residentMeds = provider.medications
            .where((m) => m.residentName == resident)
            .toList();
        if (residentMeds.isEmpty) return;
        final med = residentMeds.firstWhere(
          (m) =>
              (st == '⏰' && !m.isTaken && !m.isSkipped) ||
              (st == '✓' && m.isTaken) ||
              (st == '!' && m.isMissed),
          orElse: () => residentMeds.first,
        );

        _showDoseConfirmation(med);
      },
      child: SizedBox(
        width: 40,
        child: Center(
          child: Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(shape: BoxShape.circle, color: bg),
            child: Center(
              child: Text(st,
                  style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.bold, color: fg)),
            ),
          ),
        ),
      ),
    );
  }

  void _showDoseConfirmation(Medication med) {
    // نافذة تأكيد إعطاء الجرعة الدوائية
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 24),
            const Text('تأكيد جرعة الدواء',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0369A1))),
            const SizedBox(height: 8),
            Text('المقيم: ${med.residentName}',
                style: const TextStyle(fontSize: 14, color: Color(0xFF64748B))),
            Text('${med.name} — ${med.dosage}',
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A))),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  // زر التأكيد النهائي
                  child: ElevatedButton(
                    onPressed: () {
                      ref.read(appRiverpod).nurseConfirmMedication(med.id);
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text('تم تسجيل إعطاء الدواء بنجاح')));
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('تم الإعطاء',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  // زر لتسجيل سبب عدم الإعطاء
                  child: OutlinedButton(
                    onPressed: () => _showSkipReasonDialog(med),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: Color(0xFFEF4444)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('تجاوز الجرعة ❌',
                        style: TextStyle(
                            color: Color(0xFFEF4444),
                            fontWeight: FontWeight.bold,
                            fontSize: 16)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  void _showSkipReasonDialog(Medication med) {
    // نافذة اختيار سبب تجاوز الجرعة
    final reasons = [
      'رفض المريض',
      'غير متاح',
      'نائم',
      'حالة صحية لا تسمح',
      'صائم'
    ];
    Navigator.pop(context); // إغلاق النافذة السابقة

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('سبب تجاوز الجرعة',
            textAlign: TextAlign.right,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: reasons
              .map((r) => ListTile(
                    title: Text(r, textAlign: TextAlign.right),
                    onTap: () {
                      ref.read(appRiverpod).skipMedication(med.id, r);
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text('تم تسجيل تجاوز الجرعة: $r ⚠️')));
                    },
                  ))
              .toList(),
        ),
      ),
    );
  }

  // ignore: unused_element
  void _showNoteDialog(String residentName) {
    // نافذة إضافة ملاحظة تمريضية جديدة
    final titleController = TextEditingController();
    final contentController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Column(
          children: [
            const Text('إضافة ملاحظة تمريضية',
                textAlign: TextAlign.right,
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0369A1))),
            Text('المقيم: $residentName',
                textAlign: TextAlign.right,
                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              // حقل العنوان
              controller: titleController,
              textAlign: TextAlign.right,
              decoration: InputDecoration(
                hintText: 'عنوان الملاحظة (مثال: وجبة الغداء)',
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              // حقل التفاصيل (متعدد الأسطر)
              controller: contentController,
              maxLines: 4,
              textAlign: TextAlign.right,
              decoration: InputDecoration(
                hintText: 'اكتب تفاصيل الملاحظة هنا...',
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text(
                    'بواسطة: ${ref.read(appRiverpod).currentAccount?.name ?? 'فريق التمريض'}',
                    style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFF94A3B8),
                        fontWeight: FontWeight.bold)),
                const SizedBox(width: 4),
                const Icon(Icons.person_pin_rounded,
                    size: 14, color: Color(0xFF94A3B8)),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء')),
          ElevatedButton(
            // زر الحفظ النهائي للملاحظة
            onPressed: () {
              if (titleController.text.isNotEmpty &&
                  contentController.text.isNotEmpty) {
                final newNote = NursingNote(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  residentName: residentName,
                  title: titleController.text,
                  content: contentController.text,
                  author: ref.read(appRiverpod).currentAccount?.name ??
                      'فريق التمريض',
                  timestamp: DateTime.now(),
                );
                ref.read(appRiverpod).addNursingNote(newNote);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('تم تسجيل الملاحظة بنجاح')));
              }
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0EA5E9),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10))),
            child: const Text('حفظ الملاحظة',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showEmergencyAlert(String residentName) {
    // نافذة تأكيد إرسال استغاثة طارئة لمقيم محدد
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: const Color(0xFF7F1D1D),
        title: const Text('🚨 تأكيد استغاثة',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(
            'هل أنت متأكد من تفعيل حالة الطوارئ لـ $residentName؟ سيتم تنبيه الفريق الطبي فوراً.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 14)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child:
                  const Text('إلغاء', style: TextStyle(color: Colors.white70))),
          ElevatedButton(
            // زر التأكيد (يؤدي لإرسال إشارات التنبيه)
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  backgroundColor: Colors.red,
                  content: Text('تم إرسال إشارة الطوارئ!')));
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.white),
            child: const Text('تأكيد الطوارئ',
                style: TextStyle(
                    color: Color(0xFF7F1D1D), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    // بناء شريط التنقل السفلي المخصص للممرض
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        border: Border(
            top: BorderSide(
                color: isDark ? Colors.white12 : const Color(0xFFE0F2FE))),
      ),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _navItem(Icons.dashboard_rounded, 'الرئيسية', _currentTabIndex == 0,
              onTap: () => setState(() => _currentTabIndex = 0)),
          _navItem(Icons.people_alt_rounded, 'المقيمين', _currentTabIndex == 1,
              onTap: () => setState(() => _currentTabIndex = 1)),
          _navItem(
              Icons.business_center_rounded, 'العمليات', _currentTabIndex == 2,
              onTap: () => setState(() => _currentTabIndex = 2)),
          _navItem(Icons.medical_services_rounded, 'الإدارة الطبية',
              _currentTabIndex == 3,
              onTap: () => setState(() => _currentTabIndex = 3)),
          _navItem(
              Icons.receipt_long_rounded, 'التقارير', _currentTabIndex == 4,
              onTap: () => setState(() => _currentTabIndex = 4)),
        ],
      ),
    );
  }

  Widget _navItem(IconData icon, String label, bool active,
      {VoidCallback? onTap}) {
    // بناء عنصر واحد في شريط التنقل
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon,
              size: 28, // حجم أيقونة أكبر لتكون "أثقل"
              color: active
                  ? const Color(0xFF0EA5E9)
                  : (isDark
                      ? Colors.white54
                      : const Color(
                          0xFF64748B))), // لون أغمق قليلاً للعناصر غير النشطة
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
                fontSize: 12, // خط أكبر قليلاً
                fontWeight:
                    active ? FontWeight.w900 : FontWeight.bold, // خط أسمك
                color: active
                    ? const Color(0xFF0EA5E9)
                    : (isDark ? Colors.white54 : const Color(0xFF64748B))),
          ),
          if (active) ...[
            // إظهار نقطة تحت العنصر النشط
            const SizedBox(height: 2),
            Container(
                width: 5,
                height: 5,
                decoration: const BoxDecoration(
                    shape: BoxShape.circle, color: Color(0xFF0EA5E9)))
          ] else ...[
            const SizedBox(height: 7), // الحفاظ على نفس الارتفاع
          ]
        ],
      ),
    );
  }

  Widget _buildDraggableSOS() {
    final size = MediaQuery.of(context).size;

    return AnimatedPositioned(
      duration: _isDragging ? Duration.zero : const Duration(milliseconds: 300),
      right: -_dragPosition, // المقبض ملتصق باليمين
      bottom: size.height * 0.09, // موقعه أقرب للأسفل
      child: GestureDetector(
        onHorizontalDragUpdate: (details) {
          setState(() {
            _isDragging = true;
            _dragPosition =
                (_dragPosition - details.delta.dx).clamp(0.0, size.width * 0.8);
          });
        },
        onHorizontalDragEnd: (details) {
          setState(() => _isDragging = false);
          if (_dragPosition > _triggerThreshold) {
            _dragPosition = 0;
            _showEmergencyDialog();
          } else {
            _dragPosition = 0;
          }
        },
        child: Container(
          height: 50,
          decoration: BoxDecoration(
            color: const Color(0xFFef4444),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(25),
              bottomLeft: Radius.circular(25),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 10,
                offset: const Offset(-2, 0),
              ),
            ],
            gradient: const LinearGradient(
              colors: [Color(0xFFef4444), Color(0xFFb91c1c)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 30,
                alignment: Alignment.center,
                child: const Icon(
                  Icons.chevron_left_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 100),
                width: _dragPosition > 20 ? _dragPosition : 0,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const NeverScrollableScrollPhysics(),
                  child: Container(
                    padding: const EdgeInsets.only(right: 20),
                    child: const Row(
                      children: [
                        Icon(Icons.warning_amber_rounded,
                            color: Colors.white, size: 20),
                        SizedBox(width: 6),
                        Text(
                          'اسحب للطوارئ',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Cairo',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEmergencyDialog() {
    // نافذة اختيار نوع حالة الطوارئ العامة
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 24),
            const Text('إجراء طوارئ فوري 🚨',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFEF4444))),
            const SizedBox(height: 8),
            Text('برجاء اختيار نوع الطوارئ لتنبيه الطاقم المعني',
                style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white60 : const Color(0xFF64748B))),
            const SizedBox(height: 24),
            Row(
              // شبكة خيارات الطوارئ (إسعاف، طبيب، كود بلو، إدارة)
              children: [
                Expanded(
                    child: _emergencyAction(
                        'طلب إسعاف',
                        Icons.airport_shuttle_rounded,
                        const Color(0xFFEF4444),
                        () => _triggerEmergency('سيارة إسعاف'))),
                const SizedBox(width: 12),
                Expanded(
                    child: _emergencyAction(
                        'الطبيب المناوب',
                        Icons.local_hospital_rounded,
                        const Color(0xFFF59E0B),
                        () => _triggerEmergency('الطبيب المناوب'))),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                    child: _emergencyAction(
                        'كود بلو (قلبي)',
                        Icons.favorite_rounded,
                        const Color(0xFFB91C1C),
                        () => _triggerEmergency('Code Blue'))),
                const SizedBox(width: 12),
                Expanded(
                    child: _emergencyAction(
                        'تنبيه الإدارة',
                        Icons.notifications_active_rounded,
                        const Color(0xFF6366F1),
                        () => _triggerEmergency('الإدارة'))),
              ],
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _emergencyAction(
      String label, IconData icon, Color color, VoidCallback onTap) {
    // بناء زر واحد لنوع الطوارئ
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            label == 'طلب إسعاف'
                ? Lottie.asset('assets/animations/ambulancia.json',
                    width: 50, height: 50)
                : label == 'الطبيب المناوب'
                    ? Lottie.asset('assets/animations/doctors.json',
                        width: 50, height: 50)
                    : label == 'كود بلو (قلبي)'
                        ? Lottie.asset('assets/animations/heart.json',
                            width: 50, height: 50)
                        : label == 'تنبيه الإدارة'
                            ? Lottie.asset('assets/animations/allert.json',
                                width: 50, height: 50)
                            : Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(label,
                style: TextStyle(
                    color: color, fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Future<void> _triggerEmergency(String type) async {
    // معالجة تفعيل حالة الطوارئ (الاتصال بالإسعاف أو تنبيه الطاقم)
    Navigator.pop(context); // إغلاق النافذة

    final status = await Permission.phone.request();
    if (!mounted) return;

    if (status.isGranted) {
      String phoneNumber = '';
      if (type == 'سيارة إسعاف') {
        phoneNumber = EmergencyContacts.ambulance;
      } else if (type == 'الطبيب المناوب') {
        phoneNumber = EmergencyContacts.doctor;
      } else if (type == 'Code Blue') {
        phoneNumber = EmergencyContacts.codeBlue;
      }

      if (phoneNumber.isNotEmpty) {
        final Uri telUri = Uri.parse('tel:$phoneNumber');
        final canLaunch = await canLaunchUrl(telUri);
        if (!mounted) return;
        if (canLaunch) {
          await launchUrl(telUri);
          return; // الخروج بعد الاتصال
        }
      }
    } else if (type == 'سيارة إسعاف' ||
        type == 'الطبيب المناوب' ||
        type == 'Code Blue') {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('يجب منح إذن الاتصال لإجراء المكالمة الطارئة 📞'),
        backgroundColor: Color(0xFFF59E0B),
      ));
      return;
    }

    // إذا كان تنبيه الإدارة أو في حال عدم وجود رقم (أو فشل الاتصال)
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(type == 'الإدارة'
          ? 'تم إرسال تنبيه عاجل للوحة تحكم الإدارة 🔔'
          : 'تم إرسال تنبيه $type لجميع الطاقم المعني 🚨'),
      backgroundColor:
          type == 'الإدارة' ? const Color(0xFF10B981) : const Color(0xFFEF4444),
      behavior: SnackBarBehavior.floating,
    ));
  }
}

class MarqueeText extends StatefulWidget {
  final String text;
  final TextStyle style;
  final TextAlign textAlign;

  const MarqueeText({
    super.key,
    required this.text,
    required this.style,
    this.textAlign = TextAlign.center,
  });

  @override
  State<MarqueeText> createState() => _MarqueeTextState();
}

class _MarqueeTextState extends State<MarqueeText> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startScrolling();
    });
  }

  void _startScrolling() {
    Future.delayed(const Duration(seconds: 1), () {
      if (_scrollController.hasClients) {
        double maxScroll = _scrollController.position.maxScrollExtent;
        if (maxScroll > 0) {
          _scrollController
              .animateTo(
            maxScroll,
            duration: Duration(milliseconds: (maxScroll * 30).toInt()),
            curve: Curves.linear,
          )
              .then((_) {
            Future.delayed(const Duration(seconds: 1), () {
              if (_scrollController.hasClients) {
                _scrollController.jumpTo(0);
                _startScrolling();
              }
            });
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      controller: _scrollController,
      child:
          Text(widget.text, style: widget.style, textAlign: widget.textAlign),
    );
  }
}

class AnimatedBackground extends StatefulWidget {
  final Widget child;
  const AnimatedBackground({super.key, required this.child});

  @override
  State<AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 50), // أبطأ قليلاً
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return CustomPaint(
              painter: BackgroundPainter(_controller.value),
              child: Container(),
            );
          },
        ),
        const SodaBubblesBackground(), // إضافة فقاعات المياه الغازية (+)
        widget.child,
      ],
    );
  }
}

class BackgroundPainter extends CustomPainter {
  final double progress;
  BackgroundPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint1 = Paint()
      ..color = const Color(0xFFBAE6FD).withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;

    // Draw some circles that move based on progress!
    final center1 = Offset(
        size.width * 0.2, size.height * (0.2 + 0.1 * sin(progress * 2 * pi)));
    canvas.drawCircle(center1, 150, paint1);

    final paint2 = Paint()
      ..color = const Color(0xFFD1FAE5).withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;
    final center2 = Offset(
        size.width * 0.8, size.height * (0.8 - 0.1 * cos(progress * 2 * pi)));
    canvas.drawCircle(center2, 200, paint2);

    final paint3 = Paint()
      ..color = const Color(0xFFFEF08A).withValues(alpha: 0.1)
      ..style = PaintingStyle.fill;
    final center3 = Offset(
        size.width * 0.5, size.height * (0.5 + 0.05 * sin(progress * 4 * pi)));
    canvas.drawCircle(center3, 100, paint3);
  }

  @override
  bool shouldRepaint(covariant BackgroundPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class SodaBubblesBackground extends StatefulWidget {
  const SodaBubblesBackground({super.key});

  @override
  State<SodaBubblesBackground> createState() => _SodaBubblesBackgroundState();
}

class _SodaBubblesBackgroundState extends State<SodaBubblesBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20), // أبطأ قليلاً
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final size = MediaQuery.of(context).size;
          return Stack(
            children: List.generate(30, (index) {
              // كثرها (30 particles)
              final speed = 0.5 + (index * 0.15); // سرعات متفاوتة
              final progress =
                  (_controller.value * speed + (index * 0.05)) % 1.0;

              // توزيع أفقي عشوائي بناءً على الـ index
              final left = (index * 17.0) % size.width;

              return Positioned(
                left: left,
                bottom: progress *
                    size.height, // تتصاعد من الأسفل للأعلى بكامل طول الشاشة
                child: Opacity(
                  opacity: (1.0 - progress) * 0.7, // جعلها باينة أكثر
                  child: RotationTransition(
                    turns: AlwaysStoppedAnimation(progress * 2), // دوران مستمر
                    child: Icon(
                      Icons.add_rounded,
                      size: 12.0 + (index * 6) % 30, // تكبير الحجم قليلاً
                      color: const Color(0xFF0EA5E9)
                          .withValues(alpha: 0.6), // توضيح اللون أكثر
                    ),
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}
