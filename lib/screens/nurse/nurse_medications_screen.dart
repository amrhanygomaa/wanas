import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/app_riverpod.dart';
import '../../models/app_models.dart';
import 'nurse_resident_detail_screen.dart';
import 'nurse_residents_screen.dart';
import 'package:lottie/lottie.dart';

// شاشة جدول الأدوية للممرض - المحرك الأساسي لمتابعة الحالة الدوائية للمقيمين
class NurseMedicationsScreen extends ConsumerStatefulWidget {
  const NurseMedicationsScreen({super.key});

  @override
  ConsumerState<NurseMedicationsScreen> createState() =>
      _NurseMedicationsScreenState();
}

class _NurseMedicationsScreenState extends ConsumerState<NurseMedicationsScreen>
    with TickerProviderStateMixin {
  late AnimationController
      _blinkController; // متحكم حركات التنبيه (للحالات الفائتة)
  late AnimationController _pulseController; // متحكم حركات النبض البصرية
  late AnimationController _shimmerController; // متحكم حركات التحميل للعناصر
  String _selectedPeriod = 'الظهر'; // الفترة الزمنية المحددة

  @override
  void initState() {
    super.initState();
    // تهيئة المؤثرات الحركية لضمان واجهة مستخدم تفاعلية واحترافية
    _blinkController =
        AnimationController(vsync: this, duration: const Duration(seconds: 1))
          ..repeat(reverse: true);
    _pulseController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1400))
      ..repeat(reverse: true);
    _shimmerController =
        AnimationController(vsync: this, duration: const Duration(seconds: 2))
          ..repeat();
  }

  @override
  void dispose() {
    // إغلاق كافة المتحكمات عند مغادرة الشاشة لتوفير الموارد
    _blinkController.dispose();
    _pulseController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  void _showDoneAnimation(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        Future.delayed(const Duration(seconds: 2), () {
          if (!context.mounted) return;
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          }
        });
        return Center(
          child: Container(
            width: 220,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 100,
                  height: 100,
                  child: Lottie.asset(
                    'assets/animations/Done.json',
                    repeat: false,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                    fontFamily: 'Cairo',
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildSearchFilter(), // شريط البحث والفرز المتقدم
          _buildPeriodTabs(), // التبويبات الزمنية (الصباح، الظهر، إلخ)
          const SizedBox(height: 10),
          _buildOverallProgress(), // عرض نسبة التقدم العامة للوردية
          const SizedBox(height: 10),
          _buildResidentBlocks(), // كروت المقيمين مع تفاصيل الأدوية لكل واحد
          const SizedBox(height: 10),
          _buildGlobalActions(), // الإجراءات الجماعية (مثل التأكيد الكلي)
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildPeriodTabs() {
    return Container(
      decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(bottom: BorderSide(color: Color(0xFFE0F2FE)))),
      child: Row(
        children: [
          _periodTab('الصباح', '٨/٨', const Color(0xFFD1FAE5),
              const Color(0xFF065F46), _selectedPeriod == 'الصباح'),
          _periodTab('الظهر', '٢ فائت', const Color(0xFFFEE2E2),
              const Color(0xFF7F1D1D), _selectedPeriod == 'الظهر'),
          _periodTab('المساء', '٧ قادم', const Color(0xFFFEF3C7),
              const Color(0xFF92400E), _selectedPeriod == 'المساء'),
          _periodTab('الليل', '١٢ قادم', const Color(0xFFFEF3C7),
              const Color(0xFF92400E), _selectedPeriod == 'الليل'),
        ],
      ),
    );
  }

  Widget _periodTab(
      String label, String count, Color bg, Color textC, bool active) {
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedPeriod = label;
          });
        },
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                  color: active ? const Color(0xFF0EA5E9) : Colors.transparent,
                  width: 2.5),
            ),
          ),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Column(
            children: [
              Text(label,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: active
                          ? const Color(0xFF0369A1)
                          : const Color(0xFF475569))),
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                    color: bg, borderRadius: BorderRadius.circular(8)),
                child: Text(count,
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: textC)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchFilter() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Color(0xFFE0F2FE)))),
          child: Row(
            children: [
              const Icon(Icons.search, color: Color(0xFF94A3B8), size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                      color: const Color(0xFFF0F9FF),
                      border: Border.all(color: const Color(0xFFBAE6FD)),
                      borderRadius: BorderRadius.circular(10)),
                  child: const Text('ابحث باسم المقيم أو الدواء...',
                      style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                ),
              ),
            ],
          ),
        )
      ],
    );
  }

  Widget _buildOverallProgress() {
    final provider = ref.watch(appRiverpod);
    final total = provider.medications.length;
    final completed = provider.medications.where((m) => m.isTaken).length;
    final missed =
        provider.medications.where((m) => m.isMissed || m.isSkipped).length;
    final upcoming = provider.medications
        .where((m) => !m.isTaken && !m.isSkipped && !m.isMissed)
        .length;
    final percentage = total > 0 ? (completed / total) : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFE0F2FE), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            SizedBox(
              width: 56,
              height: 56,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: percentage,
                    backgroundColor: const Color(0xFFE0F2FE),
                    color: const Color(0xFF0EA5E9),
                    strokeWidth: 5,
                    strokeCap: StrokeCap.round,
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('${(percentage * 100).toInt()}%',
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0369A1))),
                      const Text('اليوم',
                          style: TextStyle(
                              fontSize: 10, color: Color(0xFF475569))),
                    ],
                  )
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                children: [
                  _statRow(
                      'مكتملة', '$completed جرعة', const Color(0xFF10B981)),
                  _statRow('فائتة', '$missed جرعة', const Color(0xFFEF4444)),
                  _statRow('قادمة', '$upcoming جرعة', const Color(0xFFF59E0B)),
                  _statRow(
                      'الالتزام العام',
                      '${provider.compliancePercentage}%',
                      const Color(0xFF0369A1)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statRow(String lbl, String val, Color valColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: valColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(lbl,
              style: const TextStyle(fontSize: 13, color: Color(0xFF475569))),
          const Spacer(),
          Text(val,
              style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.bold, color: valColor)),
        ],
      ),
    );
  }

  Widget _buildResidentBlocks() {
    final provider = ref.watch(appRiverpod);
    final groupedMeds = <String, List<Medication>>{};
    for (var med in provider.medications) {
      // فلترة الأدوية حسب الفترة الزمنية المحددة (الصباح، الظهر، إلخ)
      if (!med.timeOfDay.contains(_selectedPeriod)) continue;

      final name = med.residentName ?? 'غير محدد';
      if (!groupedMeds.containsKey(name)) groupedMeds[name] = [];
      groupedMeds[name]!.add(med);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        children: [
          ...groupedMeds.entries.map((entry) {
            final name = entry.key;
            final meds = entry.value;
            final matchedResidents = provider.residentFiles
                .where((resident) => resident.name == name);
            final isCritical = matchedResidents.any((resident) =>
                resident.status.toLowerCase().contains('critical') ||
                resident.status.contains('حرج'));
            return _buildResidentCard(name, meds, isCritical);
          }),
          const SizedBox(height: 10),
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NurseResidentsScreen(),
                ),
              );
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFBAE6FD)),
              ),
              child: const Text(
                '+ ٢١ مقيم آخر — اضغط لعرض الكل',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0369A1)),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildResidentCard(
      String name, List<Medication> meds, bool isCritical) {
    final completed = meds.where((m) => m.isTaken).length;
    final total = meds.length;
    final percentage = total > 0 ? (completed / total) : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
            color:
                isCritical ? const Color(0xFFFCA5A5) : const Color(0xFFE2E8F0),
            width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header - Tapping opens Resident Detail
          GestureDetector(
            onTap: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => NurseResidentDetailScreen(
                            residentName: name,
                            roomNumber: isCritical ? '١٠٣' : '١١٢',
                          )));
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                  color: isCritical
                      ? const Color(0xFFFFF5F5)
                      : const Color(0xFFF8FAFC),
                  borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24))),
              child: Row(
                children: [
                  CircleAvatar(
                      radius: 18,
                      backgroundColor: isCritical
                          ? const Color(0xFFFFE4E6)
                          : const Color(0xFFE0F2FE),
                      child: Text(name.substring(0, 2),
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: isCritical
                                  ? const Color(0xFF9F1239)
                                  : const Color(0xFF0369A1)))),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('$name — غرفة ${isCritical ? '١٠٣' : '١١٢'}',
                            style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A))),
                        Text('$total أدوية مسجلة اليوم',
                            style: const TextStyle(
                                fontSize: 12, color: Color(0xFF475569))),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_back_ios_new_rounded,
                      size: 14, color: Color(0xFF94A3B8)),
                ],
              ),
            ),
          ),
          // Grid
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(
              children: [
                _gridHeader(),
                ...meds.map((m) => _drugRow(
                    m.name,
                    m.dosage,
                    m.timeOfDay.contains('الصباح')
                        ? _getStatusWidget(m)
                        : _na(),
                    m.timeOfDay.contains('الظهر') ? _getStatusWidget(m) : _na(),
                    m.timeOfDay.contains('المساء')
                        ? _getStatusWidget(m)
                        : _na(),
                    _na())),
              ],
            ),
          ),
          _progressBar('${(percentage * 100).toInt()}%', percentage,
              isCritical ? const Color(0xFFEF4444) : const Color(0xFF10B981)),
        ],
      ),
    );
  }

  Widget _getStatusWidget(Medication m) {
    if (m.isTaken) return _done();
    // عرض زر التأكيد للممرض دائماً طالما لم يتم أخذ الدواء بعد (التأكيد المزدوج)
    return _pendingNurse(m);
  }

  Widget _circ(String txt, Color bg, Color textC, {bool blink = false}) {
    Widget child = Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(shape: BoxShape.circle, color: bg),
      child: Center(
        child: Text(txt,
            style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.bold, color: textC)),
      ),
    );
    if (blink) {
      child = FadeTransition(
          opacity:
              Tween<double>(begin: 0.15, end: 1.0).animate(_blinkController),
          child: child);
    }
    return child;
  }

  Widget _done() =>
      _circ('✓', const Color(0xFFD1FAE5), const Color(0xFF065F46));
  // ignore: unused_element
  Widget _miss() =>
      _circ('!', const Color(0xFFFEE2E2), const Color(0xFFEF4444), blink: true);
  // ignore: unused_element
  Widget _pend() =>
      _circ('○', const Color(0xFFF1F5F9), const Color(0xFF94A3B8));

  Widget _pendingNurse(Medication m) {
    return GestureDetector(
      onTap: () {
        _showDoneAnimation('تم تأكيد الدواء وإشعار الأسرة ✅');
        ref.read(appRiverpod).nurseConfirmMedication(m.id);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF3C7),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFFD97706)),
        ),
        child: const Text('تأكيد',
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Color(0xFFD97706))),
      ),
    );
  }

  Widget _na() =>
      const Text('—', style: TextStyle(fontSize: 12, color: Color(0xFFCBD5E1)));
  // ignore: unused_element
  Widget _now() {
    return Container(
      width: 30,
      height: 30,
      decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient:
              LinearGradient(colors: [Color(0xFF0369A1), Color(0xFF0EA5E9)])),
      child: const Center(
        child: Text('⏰', style: TextStyle(fontSize: 11)),
      ),
    );
  }

  Widget _progressBar(String txt, double perc, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: const Color(0xFFF8FAFC),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('الالتزام اليومي',
                  style: TextStyle(fontSize: 11, color: Color(0xFF475569))),
              Text(txt,
                  style: TextStyle(
                      fontSize: 11, fontWeight: FontWeight.bold, color: color)),
            ],
          ),
          const SizedBox(height: 4),
          Container(
            height: 5,
            decoration: BoxDecoration(
                color: const Color(0xFFE0F2FE),
                borderRadius: BorderRadius.circular(4)),
            alignment: Alignment.centerRight,
            child: FractionallySizedBox(
              widthFactor: perc,
              child: Container(
                decoration: BoxDecoration(
                    color: color, borderRadius: BorderRadius.circular(4)),
              ),
            ),
          )
        ],
      ),
    );
  }

  // ignore: unused_element
  Widget _actionFooter(List<Widget> btns, {bool isExpanded = true}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
      child: Row(
        children: isExpanded
            ? btns
                .map((b) => Expanded(
                    child: Padding(
                        padding: EdgeInsets.only(left: b == btns.last ? 0 : 7),
                        child: b)))
                .toList()
            : btns,
      ),
    );
  }

  // ignore: unused_element
  Widget _btn(String txt, Color bg, Color fg, Color borderC,
      {bool isGrad = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 7),
      decoration: BoxDecoration(
        color: isGrad ? null : bg,
        gradient: isGrad
            ? const LinearGradient(
                colors: [Color(0xFF0369A1), Color(0xFF0EA5E9)])
            : null,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderC),
      ),
      child: Center(
        child: Text(txt,
            style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.bold, color: fg)),
      ),
    );
  }

  Widget _gridHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          const Expanded(child: SizedBox()),
          _medH('ص'),
          _medH('ظ'),
          _medH('م'),
          _medH('ل'),
        ],
      ),
    );
  }

  Widget _medH(String t) => SizedBox(
      width: 48,
      child: Center(
          child: Text(t,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF64748B)))));

  Widget _drugRow(
      String n, String d, Widget c1, Widget c2, Widget c3, Widget c4,
      {bool isLast = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
          border: Border(
              bottom: BorderSide(
                  color:
                      isLast ? Colors.transparent : const Color(0xFFF1F5F9)))),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(n,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A))),
                Text(d,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 11, color: Color(0xFF475569))),
              ],
            ),
          ),
          Flexible(child: SizedBox(width: 48, child: Center(child: c1))),
          Flexible(child: SizedBox(width: 48, child: Center(child: c2))),
          Flexible(child: SizedBox(width: 48, child: Center(child: c3))),
          Flexible(child: SizedBox(width: 48, child: Center(child: c4))),
        ],
      ),
    );
  }

  Widget _buildGlobalActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: InkWell(
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم إرسال التقرير بنجاح إلى الإدارة والأسرة',
                  style: TextStyle(fontFamily: 'Cairo')),
              backgroundColor: Color(0xFF10b981),
              duration: Duration(seconds: 2),
            ),
          );
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
              color: const Color(0xFFF0F9FF),
              border: Border.all(color: const Color(0xFFBAE6FD), width: 1.5),
              borderRadius: BorderRadius.circular(12)),
          child: const Center(
              child: Text('إرسال تقرير',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0369A1)))),
        ),
      ),
    );
  }
}
