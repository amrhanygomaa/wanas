import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/app_riverpod.dart';
import '../../../models/app_models.dart';
import '../admin_resident_detail_screen.dart';

// واجهة التحكم الرئيسية للمدير - تعرض مؤشرات الأداء والتنبيهات العاجلة
class AdminHomeView extends ConsumerStatefulWidget {
  final List<Animation<double>>
      fadeAnimations; // قائمة حركات الظهور التدريجي للعناصر
  final AnimationController
      floatController; // متحكم حركات الطفو للعناصر الرسومية

  const AdminHomeView(
      {super.key, required this.fadeAnimations, required this.floatController});

  @override
  ConsumerState<AdminHomeView> createState() => _AdminHomeViewState();
}

class _AdminHomeViewState extends ConsumerState<AdminHomeView> {
  bool _showResolved =
      false; // متغير للتحكم في عرض التنبيهات (نشطة أم تمت معالجتها)

  @override
  Widget build(BuildContext context) {
    final provider = ref.watch(appRiverpod);

    // فلترة التنبيهات بناءً على الحالة والدور
    final adminAlerts = provider.notifications
        .where((n) => n.targetRole == 'مدير' || n.targetRole == 'all')
        .where((n) => n.isRead == _showResolved)
        .toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          // عنوان قسم الأداء مع فلتر التاريخ الجديد
          FadeTransition(
            opacity: widget.fadeAnimations[0],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: _buildSectionTitle('الأداء التشغيلي')),
                const SizedBox(width: 8),
                _buildDateFilter(provider),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // شبكة مربعات مؤشرات الأداء (KPIs) - الآن تفاعلية
          _buildKPIGrid(provider.adminStats, context),

          const SizedBox(height: 25),
          // قسم مميزات المنشأة المستعرضة
          if (provider.currentAccount?.amenities != null && provider.currentAccount!.amenities!.isNotEmpty)
            _buildAmenitiesSection(provider.currentAccount!.amenities!),

          const SizedBox(height: 32),
          // عنوان قسم الرسوم البيانية للنمو والصحة
          FadeTransition(
              opacity: widget.fadeAnimations[1],
              child: _buildSectionTitle('منحنى النمو والصحة')),
          const SizedBox(height: 16),
          _buildLargeChartCard(provider),

          const SizedBox(height: 32),
          // قسم التنبيهات مع شريط الفلترة
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                  child: FadeTransition(
                      opacity: widget.fadeAnimations[2],
                      child: _buildSectionTitle('تنبيهات المركز العاجلة'))),
              const SizedBox(width: 8),
              _buildAlertFilter(),
            ],
          ),
          const SizedBox(height: 16),
          if (adminAlerts.isEmpty)
            _buildAlertCard(
                TaptabaNotification(
                    id: '0',
                    title: 'لا توجد تنبيهات حالياً',
                    body: '',
                    time: 'الآن',
                    type: 'stable',
                    isRead: true),
                Colors.green,
                provider)
          else
            ...adminAlerts
                .take(5)
                .map((n) => _buildAlertCard(n, _getAlertColor(n.type), provider)),
        ],
      ),
    );
  }

  Widget _buildAmenitiesSection(List<String> amenities) {
    return FadeTransition(
      opacity: widget.fadeAnimations[1],
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.stars_rounded, color: Color(0xFF6C63FF), size: 24),
                const SizedBox(width: 10),
                _buildSectionTitle('مميزات المنشأة'),
              ],
            ),
            const SizedBox(height: 15),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: amenities.map((a) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF6C63FF).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF6C63FF).withValues(alpha: 0.1)),
                ),
                child: Text(
                  a,
                  style: const TextStyle(
                    color: Color(0xFF6C63FF),
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              )).toList(),
            ),
          ],
        ),
      ),
    );
  }

  // دالة لتحديد لون التنبيه بناءً على نوعه (طبي، شكوى، اجتماعي)
  Color _getAlertColor(String type) {
    switch (type) {
      case 'medical':
        return Colors.red;
      case 'complaint':
        return Colors.orange;
      case 'social':
        return Colors.purple;
      default:
        return Colors.blue;
    }
  }

  // بناء شريط الفلترة (النشط / المعالج)
  Widget _buildAlertFilter() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
          color: const Color(0xFFf1f5f9),
          borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          _filterBtn('المعالج', _showResolved,
              () => setState(() => _showResolved = true)),
          _filterBtn('النشط', !_showResolved,
              () => setState(() => _showResolved = false)),
        ],
      ),
    );
  }

  // بناء زر الفلترة الفردي
  Widget _filterBtn(String label, bool isSel, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSel ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSel
              ? [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4)
                ]
              : null,
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color:
                    isSel ? const Color(0xFF0f172a) : const Color(0xFF64748b))),
      ),
    );
  }

  // بناء فلتر التاريخ (اليوم، الأسبوع، الشهر) للوحة تحكم المدير
  Widget _buildDateFilter(AppRiverpod provider) {
    final filters = ['اليوم', 'أسبوع', 'شهر'];
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
          color: const Color(0xFFf1f5f9),
          borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: filters.map((f) => _dateChip(f, provider)).toList(),
      ),
    );
  }

  // بناء زر اختيار التاريخ الفردي مع تأثير بصري عند الاختيار
  Widget _dateChip(String label, AppRiverpod provider) {
    bool isSel = provider.selectedAdminDateFilter == label;
    return GestureDetector(
      onTap: () =>
          provider.updateAdminDateFilter(label), // تحديث حالة الفلتر في المزود
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSel
              ? Colors.white
              : Colors.transparent, // اللون الأبيض للزر المختار
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSel
              ? [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4)
                ]
              : null,
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color:
                    isSel ? const Color(0xFF0f172a) : const Color(0xFF64748b))),
      ),
    );
  }

  // بناء عنوان القسم مع خط جانبي جمالي لتمييز الأقسام المختلفة
  Widget _buildSectionTitle(String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Container(
            width: 4,
            height: 16,
            decoration: BoxDecoration(
                color: const Color(0xFF0ea5e9),
                borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1e293b)),
          ),
        ),
      ],
    );
  }

  // بناء شبكة مؤشرات الأداء مع دعم الضغط لرؤية التفاصيل (Drill-down)
  Widget _buildKPIGrid(
      List<CenterOperationalStat> stats, BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics:
          const NeverScrollableScrollPhysics(), // منع التمرير داخل الشبكة لأنها داخل قائمة أكبر
      itemCount: stats.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.1),
      itemBuilder: (context, index) {
        final s = stats[index];
        return GestureDetector(
          onTap: () => _showKPIDrillDown(
              context, s), // فتح نافذة التفاصيل التاريخية عند الضغط
          child: FadeTransition(
            opacity: widget.fadeAnimations[index + 1],
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
                gradient: const LinearGradient(
                  colors: [
                    Colors.white,
                    Color(0xFFF8FAFC),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                boxShadow: [
                  // 3D solid edge below the card
                  const BoxShadow(
                    color: Color(0xFFCBD5E1),
                    offset: Offset(0, 5),
                    blurRadius: 0,
                  ),
                  // Soft ambient shadow
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    offset: const Offset(0, 10),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Color(0xFF94a3b8),
                          fontSize: 11,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  FittedBox(
                    // يضمن أن القيم الكبيرة (مثل المبالغ المالية) لن تسبب Overflow
                    fit: BoxFit.scaleDown,
                    child: Text(s.value,
                        style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0f172a))),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      // عرض نسبة النمو أو الانخفاض مع أيقونة مناسبة
                      Expanded(
                        child: Text(
                          s.trend,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            color: s.isPositive
                                ? const Color(0xFF10b981)
                                : const Color(0xFFef4444),
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildMiniTrendChart(
                          s.history, s.isPositive), // الرسم البياني المصغر
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // إظهار نافذة تفاصيل المؤشر (Drill-down) مع عرض البيانات بصورة أعمق
  void _showKPIDrillDown(BuildContext context, CenterOperationalStat stat) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
                child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                        color: const Color(0xFFf1f5f9),
                        borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 24),
            Text('تفاصيل ${stat.label}',
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1e293b))),
            const SizedBox(height: 8),
            const Text('تحليل البيانات التاريخية والنمو في الفترة المختارة',
                style: TextStyle(fontSize: 12, color: Color(0xFF64748b))),
            const SizedBox(height: 32),
            // قائمة المعلومات التفصيلية للمؤشر
            Expanded(
              child: ListView(
                children: [
                  _buildDrillDownRow(
                      'القيمة الحالية', stat.value, Icons.analytics_rounded),
                  _buildDrillDownRow(
                      'معدل النمو', stat.trend, Icons.show_chart_rounded),
                  _buildDrillDownRow(
                      'المتوسط العام', '٨٢٪', Icons.bar_chart_rounded),
                  const SizedBox(height: 24),
                  // منطقة الرسم البياني التفصيلي المتحرك
                  Container(
                    height: 150,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                        color: const Color(0xFFf8fafc),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFf1f5f9))),
                    child: stat.history.isEmpty
                        ? const Center(
                            child: Text('لا توجد بيانات تاريخية',
                                style: TextStyle(
                                    color: Color(0xFF94a3b8), fontSize: 11)))
                        : Stack(
                            children: [
                              // Y Axis Labels
                              Positioned(
                                left: 0,
                                top: 0,
                                child: Text(
                                    '${stat.history.reduce((a, b) => a > b ? a : b).toStringAsFixed(1)}',
                                    style: const TextStyle(
                                        color: Color(0xFF1e293b),
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold)),
                              ),
                              Positioned(
                                left: 0,
                                bottom: 25,
                                child: Text(
                                    '${stat.history.reduce((a, b) => a < b ? a : b).toStringAsFixed(1)}',
                                    style: const TextStyle(
                                        color: Color(0xFF1e293b),
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold)),
                              ),
                              // Chart
                              Padding(
                                padding: const EdgeInsets.only(
                                    left: 35, bottom: 25, top: 10, right: 10),
                                child: CustomPaint(
                                  size: Size.infinite,
                                  painter: LineChartPainter(stat.history),
                                ),
                              ),
                              // X Axis Labels
                              const Positioned(
                                left: 35,
                                bottom: 0,
                                child: Text('البداية',
                                    style: TextStyle(
                                        color: Color(0xFF1e293b),
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold)),
                              ),
                              const Positioned(
                                right: 0,
                                bottom: 0,
                                child: Text('الحالي',
                                    style: TextStyle(
                                        color: Color(0xFF1e293b),
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // إظهار نافذة تفاصيل المؤشر كـ Dialog ينبثق في منتصف الشاشة (نط في وشي)
  void _showKPIDialog(BuildContext context, CenterOperationalStat stat) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black.withValues(alpha: 0.5),
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Container(); // Not used
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return ScaleTransition(
          scale: CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutBack, // تأثير النط في الوش
          ),
          child: AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            backgroundColor: Colors.white,
            contentPadding: const EdgeInsets.all(24),
            content: SizedBox(
              width: MediaQuery.of(context).size.width * 0.85,
              height: 400, // ارتفاع مناسب
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('تفاصيل ${stat.label}',
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1e293b))),
                  const SizedBox(height: 8),
                  const Text(
                      'تحليل البيانات التاريخية والنمو في الفترة المختارة',
                      style: TextStyle(fontSize: 12, color: Color(0xFF64748b))),
                  const SizedBox(height: 24),
                  Expanded(
                    child: ListView(
                      children: [
                        _buildDrillDownRow('القيمة الحالية', stat.value,
                            Icons.analytics_rounded),
                        _buildDrillDownRow(
                            'معدل النمو', stat.trend, Icons.show_chart_rounded),
                        _buildDrillDownRow(
                            'المتوسط العام', '٨٢٪', Icons.bar_chart_rounded),
                        const SizedBox(height: 16),
                        // منطقة الرسم البياني التفصيلي
                        Container(
                          height: 150,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                              color: const Color(0xFFf8fafc),
                              borderRadius: BorderRadius.circular(20),
                              border:
                                  Border.all(color: const Color(0xFFf1f5f9))),
                          child: stat.history.isEmpty
                              ? const Center(
                                  child: Text('لا توجد بيانات تاريخية',
                                      style: TextStyle(
                                          color: Color(0xFF94a3b8),
                                          fontSize: 11)))
                              : Stack(
                                  children: [
                                    // Y Axis Labels
                                    Positioned(
                                      left: 0,
                                      top: 0,
                                      child: Text(
                                          '${stat.history.reduce((a, b) => a > b ? a : b).toStringAsFixed(1)}',
                                          style: const TextStyle(
                                              color: Color(0xFF1e293b),
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold)),
                                    ),
                                    Positioned(
                                      left: 0,
                                      bottom: 25,
                                      child: Text(
                                          '${stat.history.reduce((a, b) => a < b ? a : b).toStringAsFixed(1)}',
                                          style: const TextStyle(
                                              color: Color(0xFF1e293b),
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold)),
                                    ),
                                    // Chart
                                    Padding(
                                      padding: const EdgeInsets.only(
                                          left: 35,
                                          bottom: 25,
                                          top: 10,
                                          right: 10),
                                      child: CustomPaint(
                                        size: Size.infinite,
                                        painter: LineChartPainter(stat.history),
                                      ),
                                    ),
                                    // X Axis Labels
                                    const Positioned(
                                      left: 35,
                                      bottom: 0,
                                      child: Text('البداية',
                                          style: TextStyle(
                                              color: Color(0xFF1e293b),
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold)),
                                    ),
                                    const Positioned(
                                      right: 0,
                                      bottom: 0,
                                      child: Text('الحالي',
                                          style: TextStyle(
                                              color: Color(0xFF1e293b),
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ),
                        ),
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

  // بناء سطر معلومات داخل نافذة الـ Drill-down
  Widget _buildDrillDownRow(String label, String val, IconData icon) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 500),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 12 * value),
            child: Row(
              children: [
                Icon(icon, color: const Color(0xFF0ea5e9), size: 22),
                const SizedBox(width: 12),
                Text(label,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1e293b))),
                const Spacer(),
                Text(val,
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1e293b))),
              ],
            ),
          ),
        );
      },
    );
  }

  // بناء رسم بياني خطي مصغر (Sparkline) باستخدام الأعمدة لتمثيل التاريخ
  Widget _buildMiniTrendChart(List<double> history, bool positive) {
    return SizedBox(
      width: 40,
      height: 20,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: history
            .map((h) => Container(
                  width: 4,
                  height: h * 20, // ارتفاع العمود بناءً على القيمة التاريخية
                  decoration: BoxDecoration(
                      color: (positive
                              ? const Color(0xFF10b981)
                              : const Color(0xFFef4444))
                          .withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(2)),
                ))
            .toList(),
      ),
    );
  }

  // بناء كارت الرسم البياني الكبير لمنحنى الصحة
  Widget _buildLargeChartCard(AppRiverpod provider) {
    // جلب بيانات الإيرادات الحقيقية من الـ Provider
    // الإيرادات هي العنصر الثاني في القائمة (index 1)
    final revenueStat =
        provider.adminStats.length > 1 ? provider.adminStats[1] : null;
    final historyData =
        revenueStat?.history ?? const [40, 60, 30, 80, 50, 90, 70];
    final title = revenueStat?.label ?? 'الإيرادات التشغيلية';
    final valueStr = revenueStat?.value ?? '';

    return GestureDetector(
      onTap: () {
        if (revenueStat != null) {
          _showKPIDialog(context, revenueStat);
        }
      },
      child: Container(
        width: double.infinity,
        height: 140, // تقليل الارتفاع ليصبح أكثر رشاقة
        margin: const EdgeInsets.symmetric(
            horizontal: 16), // إضافة هوامش جانبية لضبط العرض
        padding: const EdgeInsets.all(16), // تقليل البادينج لتوفير مساحة
        decoration: BoxDecoration(
          gradient: const LinearGradient(
              colors: [Color(0xFF0ea5e9), Color(0xFF0284c7)]),
          borderRadius:
              BorderRadius.circular(20), // حواف أقل حدة لتناسب التصميم
          boxShadow: [
            BoxShadow(
                color: const Color(0xFF0ea5e9).withValues(alpha: 0.3),
                blurRadius: 15,
                offset: const Offset(0, 5))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // النص في الأعلى
            Align(
              alignment: Alignment.topRight,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'مقارنة بالشهر الماضي ($valueStr)',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            // الرسم البياني يملأ العرض
            SizedBox(
              height: 50, // تقليل ارتفاع الرسم ليناسب الكارت
              child: CustomPaint(
                size: Size.infinite,
                painter: MiniLineChartPainter(historyData),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // رسم عمود فردي في الرسم البياني
  Widget _chartBar(double height) {
    return Container(
        width: 8,
        height: height,
        decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(4)));
  }

  // بناء كارت التنبيه العاجل (قابل للتفاعل والسحب للحذف)
  Widget _buildAlertCard(
      TaptabaNotification n, Color color, AppRiverpod provider) {
    return Dismissible(
      key: Key(n.id),
      direction: DismissDirection.endToStart, // سحب لليمين في RTL
      onDismissed: (direction) {
        if (_showResolved) {
          provider.deleteNotification(n.id);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم حذف التنبيه نهائياً'),
              duration: Duration(seconds: 1),
            ),
          );
        } else {
          provider.markNotificationAsRead(n.id);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم أرشفة التنبيه'),
              duration: Duration(seconds: 1),
            ),
          );
        }
      },
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        alignment: Alignment.centerRight,
        decoration: BoxDecoration(
            color: Colors.red.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(20)),
        child: const Icon(Icons.delete_sweep_outlined, color: Colors.red),
      ),
      child: InkWell(
        onTap: () {
          if (n.residentId != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) =>
                      AdminResidentDetailScreen(residentId: n.residentId!)),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('لا يوجد ملف مرتبط بهذا التنبيه')));
          }
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withValues(alpha: 0.1))),
          child: Row(
            children: [
              Container(
                  width: 8,
                  height: 8,
                  decoration:
                      BoxDecoration(color: color, shape: BoxShape.circle)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(n.title,
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF334155))),
                    if (n.body.isNotEmpty)
                      Text(n.body,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 9, color: Color(0xFF64748b))),
                  ],
                ),
              ),
              const Spacer(),
              Text(n.time,
                  style:
                      const TextStyle(color: Color(0xFF94a3b8), fontSize: 10)),
              if (!_showResolved)
                IconButton(
                  icon: const Icon(Icons.check_circle_outline,
                      color: Color(0xFF94a3b8), size: 18),
                  onPressed: () => provider.resolveNotification(n.id),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class LineChartPainter extends CustomPainter {
  final List<double> data;
  LineChartPainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final paint = Paint()
      ..color = const Color(0xFF0ea5e9)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final dotPaint = Paint()
      ..color = const Color(0xFF0ea5e9)
      ..style = PaintingStyle.fill;

    final axisPaint = Paint()
      ..color = const Color(0xFFcbd5e1)
      ..strokeWidth = 1;

    // Draw Axes
    canvas.drawLine(const Offset(0, 0), Offset(0, size.height), axisPaint); // Y
    canvas.drawLine(Offset(0, size.height), Offset(size.width, size.height),
        axisPaint); // X

    final maxVal = data.reduce((a, b) => a > b ? a : b);
    final minVal = data.reduce((a, b) => a < b ? a : b);
    final range = maxVal - minVal == 0 ? 1.0 : maxVal - minVal;

    final path = Path();
    final xStep = data.length > 1 ? size.width / (data.length - 1) : 0.0;

    for (int i = 0; i < data.length; i++) {
      final x = i * xStep;
      // Scale Y to fit container height, inverting Y as 0 is top
      final y =
          size.height - ((data[i] - minVal) / range) * (size.height - 20) - 10;

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
      canvas.drawCircle(Offset(x, y), 4, dotPaint);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant LineChartPainter oldDelegate) {
    return oldDelegate.data != data;
  }
}

class MiniLineChartPainter extends CustomPainter {
  final List<double> data;
  MiniLineChartPainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final dotPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final axisPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..strokeWidth = 1;

    // Draw Axes (minimal)
    canvas.drawLine(Offset(0, size.height), Offset(size.width, size.height),
        axisPaint); // X only

    final maxVal = data.reduce((a, b) => a > b ? a : b);
    final minVal = data.reduce((a, b) => a < b ? a : b);
    final range = maxVal - minVal == 0 ? 1.0 : maxVal - minVal;

    final path = Path();
    final xStep = data.length > 1 ? size.width / (data.length - 1) : 0.0;

    for (int i = 0; i < data.length; i++) {
      final x = i * xStep;
      // Scale Y to fit container height with more padding (15px top/bottom)
      final y =
          size.height - ((data[i] - minVal) / range) * (size.height - 30) - 15;

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
      canvas.drawCircle(Offset(x, y), 3, dotPaint);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant MiniLineChartPainter oldDelegate) {
    return oldDelegate.data != data;
  }
}
