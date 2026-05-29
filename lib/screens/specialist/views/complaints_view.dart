import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/app_riverpod.dart';
import '../../../models/app_models.dart';

/* 
 * واجهة تتبع وإدارة الشكاوى: 
 * تقوم هذه الشاشة بعرض قائمة الشكاوى الواردة من الأهالي، وتوفر أدوات 
 * لتصفية الشكاوى حسب حالتها (مفتوحة، قيد المعالجة، مكتملة)، 
 * بالإضافة إلى عرض الجدول الزمني لكل شكوى للمتابعة اللحظية.
 */

class SpecialistComplaintsView extends ConsumerWidget {
  final List<Animation<double>> fadeAnimations;
  final AnimationController floatController;
  final AnimationController shimmerController;
  final AnimationController popController;
  final void Function(int) onNavigate;
  final bool isAdmin;

  const SpecialistComplaintsView({
    super.key,
    required this.fadeAnimations,
    required this.floatController,
    required this.shimmerController,
    required this.popController,
    required this.onNavigate,
    this.isAdmin = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = ref.watch(appRiverpod);

    /* 
     * إدارة حالات الشكاوى:
     * يتم هنا فصل الشكاوى برمجياً بناءً على الحالة (Status)
     * لضمان ظهور كل شكوى في القسم المخصص لها في واجهة المستخدم.
     */

    return Directionality(
      textDirection: TextDirection.rtl,
      child: SingleChildScrollView(
        child: Column(
          children: [
            _buildSearchRow(context, provider),
            _buildFilterRow(provider),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  _buildSectionLabel(
                      'تحتاج تدخل فوري', const Color(0xFFef4444), 3,
                      isBlink: true),
                  const SizedBox(height: 8),
                  ...provider.filteredSocialComplaints
                      .where((c) => c.status == 'open' && c.priority == 'high')
                      .map((c) => _buildDetailedComplaintCard(context, ref, c)),
                  const SizedBox(height: 20),
                  _buildSectionLabel(
                      'قيد المعالجة', const Color(0xFFf59e0b), 4),
                  const SizedBox(height: 8),
                  ...provider.filteredSocialComplaints
                      .where((c) => c.status == 'progress')
                      .map((c) => _buildDetailedComplaintCard(context, ref, c)),
                  const SizedBox(height: 20),
                  _buildSectionLabel(
                      'مُغلقة مؤخراً', const Color(0xFF10b981), 5),
                  const SizedBox(height: 8),
                  ...provider.filteredSocialComplaints
                      .where((c) => c.status == 'done')
                      .map((c) => _buildDetailedComplaintCard(context, ref, c)),
                  const SizedBox(height: 24),
                  _buildMonthlyStats(provider.filteredSocialComplaints),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchRow(BuildContext context, AppRiverpod provider) {
    final primaryColor =
        isAdmin ? const Color(0xFF0ea5e9) : const Color(0xFFea580c);
    final secondaryColor =
        isAdmin ? const Color(0xFF0284c7) : const Color(0xFFf97316);
    final bgColor = isAdmin ? const Color(0xFFf0f9ff) : const Color(0xFFfff7ed);
    final borderColor =
        isAdmin ? const Color(0xFFbae6fd) : const Color(0xFFfed7aa);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: Colors.white,
          border: Border(bottom: BorderSide(color: borderColor))),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
              decoration: BoxDecoration(
                  color: bgColor,
                  border: Border.all(color: borderColor),
                  borderRadius: BorderRadius.circular(10)),
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: TextField(
                  onChanged: (v) {
                    provider.setComplaintSearchQuery(v);
                  },
                  textAlign: TextAlign.right,
                  decoration: const InputDecoration(
                    hintText: 'ابحث بالاسم أو نوع الشكوى...',
                    hintStyle:
                        TextStyle(color: Color(0xFF94a3b8), fontSize: 12),
                    suffixIcon:
                        Icon(Icons.search, color: Color(0xFF94a3b8), size: 16),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
          ),
          if (!isAdmin) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => _showAddComplaintDialog(context, provider),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  gradient:
                      LinearGradient(colors: [primaryColor, secondaryColor]),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.add, color: Colors.white, size: 14),
                    SizedBox(width: 4),
                    Text('إضافة',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showAddComplaintDialog(BuildContext context, AppRiverpod provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        scrollable: true,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('تسجيل شكوى جديدة', textAlign: TextAlign.right),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const TextField(
              textAlign: TextAlign.right,
              decoration: InputDecoration(labelText: 'اسم المقيم'),
            ),
            const TextField(
              textAlign: TextAlign.right,
              decoration: InputDecoration(labelText: 'نوع الشكوى / العنوان'),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue: 'medium',
              items: const [
                DropdownMenuItem(value: 'high', child: Text('عاجل')),
                DropdownMenuItem(value: 'medium', child: Text('متوسط')),
                DropdownMenuItem(value: 'low', child: Text('خفيف')),
              ],
              onChanged: (v) {},
              decoration: const InputDecoration(labelText: 'الأولوية'),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('تم تسجيل الشكوى بنجاح'),
                backgroundColor: Color(0xFFea580c),
              ));
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFea580c)),
            child: const Text('حفظ', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterRow(AppRiverpod provider) {
    final isAdmin = provider.currentRole == 'مدير';
    final primaryColor =
        isAdmin ? const Color(0xFF0ea5e9) : const Color(0xFFea580c);
    final secondaryColor =
        isAdmin ? const Color(0xFF0284c7) : const Color(0xFFf97316);

    final filters = [
      'الكل (١٥)',
      '🔴 مفتوحة',
      '🟡 جاري',
      '✅ مُغلقة',
      '🏠 خدمات',
      '😔 نفسي',
      '🍽️ طعام'
    ];
    return NewsTickerChips(
      filters: filters,
      selectedStatus: provider.selectedComplaintStatus,
      onSelected: (f) => provider.setSelectedComplaintStatus(f),
      primaryColor: primaryColor,
      secondaryColor: secondaryColor,
    );
  }

  Widget _buildSectionLabel(String label, Color color, int index,
      {bool isBlink = false}) {
    return FadeTransition(
      opacity: fadeAnimations[min(index, 11)],
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Text(label,
              style: const TextStyle(
                  color: Color(0xFF1e293b),
                  fontSize: 16,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // بناء كارت الشكوى التفصيلي: يعرض كافة المعلومات الأساسية وحالة الأولوية
  Widget _buildDetailedComplaintCard(BuildContext context, WidgetRef ref,
      SocialSpecialistComplaint complaint) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.95, end: 1.0),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutBack,
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: child,
        );
      },
      child: GestureDetector(
        onTap: () => _showComplaintDetails(context, ref,
            complaint), // فتح تفاصيل الشكوى والجدول الزمني عند الضغط
        child: FadeTransition(
          opacity: fadeAnimations[4],
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFe2e8f0), width: 1),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4))
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(16))),
                  child: Row(
                    children: [
                      Container(
                          width: 4,
                          height: 36,
                          decoration: BoxDecoration(
                              color: _getPriorityColor(complaint.priority),
                              borderRadius: BorderRadius.circular(4))),
                      const SizedBox(width: 12),
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                            color: const Color(0xFFf1f5f9),
                            borderRadius: BorderRadius.circular(18)),
                        child: Center(
                            child: Text(
                                complaint.residentName.isNotEmpty
                                    ? complaint.residentName[0]
                                    : 'م',
                                style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF475569)))),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(complaint.title,
                                textAlign: TextAlign.right,
                                style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF0f172a))),
                            const SizedBox(height: 4),
                            Text(
                                '${complaint.residentName} — غرفة ${complaint.room} · ${complaint.date}',
                                textAlign: TextAlign.right,
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF334155),
                                    fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                      _buildStatusBadge(complaint.status, complaint.priority),
                    ],
                  ),
                ),
                if (complaint.timeline.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                        border:
                            Border(top: BorderSide(color: Color(0xFFf8fafc)))),
                    child: Column(
                      children: complaint.timeline
                          .map((s) => _buildTimelineRow(
                              s, s == complaint.timeline.last))
                          .toList(),
                    ),
                  ),
                _buildCardActions(context, ref, complaint),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showComplaintDetails(BuildContext context, WidgetRef ref,
      SocialSpecialistComplaint complaint) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Directionality(
          textDirection: TextDirection.rtl,
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOut,
            builder: (context, value, child) => Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(0, 50 * (1 - value)),
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFFf8fafc),
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(30)),
                  ),
                  child: Column(
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 12),
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(2)),
                      ),
                      Expanded(
                        child: Stack(
                          children: [
                            const ComplaintsCardDustAnimation(), // أنيميشن غبار النجوم في الخلفية
                            ListView(
                              controller: scrollController,
                              padding: const EdgeInsets.all(24),
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    _buildStatusBadge(
                                        complaint.status, complaint.priority),
                                    IconButton(
                                      onPressed: () => Navigator.pop(context),
                                      icon: const Icon(Icons.close_rounded,
                                          color: Color(0xFF64748b)),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(complaint.title,
                                              style: const TextStyle(
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xFF0f172a))),
                                          Text(
                                              '${complaint.residentName} · غرفة ${complaint.room}',
                                              style: const TextStyle(
                                                  fontSize: 14,
                                                  color: Color(0xFFea580c))),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 20),
                                    Container(
                                      width: 60,
                                      height: 60,
                                      decoration: BoxDecoration(
                                        color: _getIconBg(complaint.category),
                                        borderRadius: BorderRadius.circular(18),
                                      ),
                                      child: Center(
                                        child: Text(complaint.icon,
                                            style:
                                                const TextStyle(fontSize: 28)),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 32),
                                _buildDetailSectionTitle('تاريخ الشكوى'),
                                const SizedBox(height: 12),
                                Text(
                                  'تم تقديم الشكوى بتاريخ ${complaint.date} بخصوص ${complaint.title}. الحالة الحالية هي "${_getStatusLabel(complaint.status)}".',
                                  textAlign: TextAlign.right,
                                  style: const TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF334155),
                                      height: 1.6),
                                ),
                                const SizedBox(height: 32),
                                _buildDetailSectionTitle('سجل المتابعة'),
                                const SizedBox(height: 16),
                                ...complaint.timeline
                                    .map((s) => _buildTimelineItem(s)),
                                const SizedBox(height: 40),
                                if (complaint.status != 'done')
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Wrap(
                                      spacing: 12,
                                      runSpacing: 12,
                                      alignment: WrapAlignment.center,
                                      children: [
                                        SizedBox(
                                          width: double.infinity,
                                          child: ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  const Color(0xFF10b981),
                                              shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          16)),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 16),
                                            ),
                                            onPressed: () {
                                              Navigator.pop(context);
                                              _showResolutionDialog(
                                                  context, ref, complaint);
                                            },
                                            child: const FittedBox(
                                              fit: BoxFit.scaleDown,
                                              child: Text('إغلاق وحل الشكوى ✓',
                                                  style: TextStyle(
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.bold)),
                                            ),
                                          ),
                                        ),
                                        if (!isAdmin)
                                          SizedBox(
                                            width: double.infinity,
                                            child: OutlinedButton(
                                              style: OutlinedButton.styleFrom(
                                                side: const BorderSide(
                                                    color: Color(0xFFea580c)),
                                                shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            16)),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        vertical: 16),
                                              ),
                                              onPressed: () {
                                                Navigator.pop(context);
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(const SnackBar(
                                                        content: Text(
                                                            'تم تصعيد الشكوى للإدارة')));
                                              },
                                              child: const FittedBox(
                                                fit: BoxFit.scaleDown,
                                                child: Text('تصعيد للإدارة ↑',
                                                    style: TextStyle(
                                                        color:
                                                            Color(0xFFea580c),
                                                        fontWeight:
                                                            FontWeight.bold)),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailSectionTitle(String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF334155))),
        const SizedBox(width: 12),
        Container(
            width: 4,
            height: 18,
            decoration: BoxDecoration(
                color: const Color(0xFFea580c),
                borderRadius: BorderRadius.circular(2))),
      ],
    );
  }

  Widget _buildTimelineItem(ComplaintStep step) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: _getStepColor(step.status),
                  shape: BoxShape.circle,
                ),
              ),
              Container(
                width: 2,
                height: 30,
                color: const Color(0xFFe2e8f0),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(step.text,
                textAlign: TextAlign.right,
                style: TextStyle(
                    fontSize: 14,
                    color: step.status == 'alert'
                        ? const Color(0xFFef4444)
                        : const Color(0xFF1e293b),
                    fontWeight: step.status == 'alert'
                        ? FontWeight.bold
                        : FontWeight.w500)),
          ),
          const Spacer(),
          Text(step.time,
              style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF334155),
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'open':
        return 'مفتوحة';
      case 'progress':
        return 'قيد المعالجة';
      case 'done':
        return 'مكتملة';
      default:
        return status;
    }
  }

  Widget _buildTimelineRow(ComplaintStep step, bool isLast) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: _getStepColor(step.status), width: 3),
                shape: BoxShape.circle,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 24,
                color: const Color(0xFFe2e8f0),
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(step.text,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                      fontSize: 13,
                      color: step.status == 'alert'
                          ? const Color(0xFFef4444)
                          : const Color(0xFF0f172a),
                      fontWeight: step.status == 'alert'
                          ? FontWeight.w800
                          : FontWeight.w600)),
              const SizedBox(height: 2),
              Text(step.time,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF475569),
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCardActions(BuildContext context, WidgetRef ref,
      SocialSpecialistComplaint complaint) {
    bool isClosed = complaint.status == 'done';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Color(0xFFf8fafc)))),
      child: Row(
        children: [
          if (!isClosed) ...[
            Expanded(
              child: _buildActionButton(
                '✓ إغلاق',
                type: 'done',
                onTap: () => _showResolutionDialog(context, ref, complaint),
              ),
            ),
            const SizedBox(width: 6),
            if (!isAdmin) ...[
              Expanded(
                child: _buildActionButton(
                  complaint.status == 'open' ? '✏️ بدء التدخل' : '↑ تصعيد',
                  type: 'primary',
                  onTap: () {
                    if (complaint.status == 'open') {
                      ref.read(appRiverpod).startIntervention(complaint.id);
                    } else {
                      ref.read(appRiverpod).escalateComplaint(complaint.id);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text('تم تصعيد الشكوى للإدارة')));
                    }
                  },
                ),
              ),
              const SizedBox(width: 6),
            ],
          ],
        ],
      ),
    );
  }

  void _showResolutionDialog(BuildContext context, WidgetRef ref,
      SocialSpecialistComplaint complaint) {
    final noteController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('إغلاق الشكوى',
                  style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                      color: Color(0xFF0f172a))),
              const SizedBox(height: 4),
              Text('كيف تم حل المشكلة لـ ${complaint.residentName}؟',
                  style:
                      const TextStyle(fontSize: 12, color: Color(0xFF64748b))),
              const SizedBox(height: 20),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                    color: const Color(0xFFf8fafc),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFe2e8f0))),
                child: TextField(
                  controller: noteController,
                  textAlign: TextAlign.right,
                  maxLines: 3,
                  style:
                      const TextStyle(fontSize: 13, color: Color(0xFF0f172a)),
                  decoration: const InputDecoration(
                      hintText: 'اكتب تفاصيل الحل هنا...',
                      border: InputBorder.none,
                      hintStyle:
                          TextStyle(fontSize: 13, color: Color(0xFF94a3b8))),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF64748b)),
                      child: const Text('إلغاء',
                          style: TextStyle(fontWeight: FontWeight.bold))),
                  ElevatedButton(
                    onPressed: () {
                      if (noteController.text.isNotEmpty) {
                        ref
                            .read(appRiverpod)
                            .closeComplaint(complaint.id, noteController.text);
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content:
                                  Text('تم إغلاق الشكوى وإخطار الأهل بنجاح ✅'),
                              backgroundColor: Color(0xFF10b981)),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10b981),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 0),
                    child: const Text('تأكيد الإغلاق',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(String label,
      {required String type, VoidCallback? onTap}) {
    Color bg = const Color(0xFFfff7ed);
    Color fg = const Color(0xFF9a3412);
    Gradient? grad;
    Border? border = Border.all(color: const Color(0xFFfed7aa));

    if (type == 'primary') {
      grad =
          const LinearGradient(colors: [Color(0xFFea580c), Color(0xFFf97316)]);
      fg = Colors.white;
      border = null;
    } else if (type == 'done') {
      bg = const Color(0xFFd1fae5);
      fg = const Color(0xFF065f46);
      border = Border.all(color: const Color(0xFFa7f3d0));
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(9),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 7),
        decoration: BoxDecoration(
            color: grad == null ? bg : null,
            gradient: grad,
            borderRadius: BorderRadius.circular(9),
            border: border),
        child: Center(
            child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(label,
              style: TextStyle(
                  color: fg, fontSize: 10, fontWeight: FontWeight.bold)),
        )),
      ),
    );
  }

  Widget _buildMonthlyStats(List<SocialSpecialistComplaint> complaints) {
    final psychCount = complaints.where((c) => c.category == 'psych').length;
    final foodCount = complaints.where((c) => c.category == 'food').length;
    final servicesCount = complaints
        .where((c) =>
            c.category == 'services' ||
            c.category == 'default' ||
            (c.category != 'psych' &&
                c.category != 'food' &&
                c.category != 'activities'))
        .length;
    final activitiesCount =
        complaints.where((c) => c.category == 'activities').length;

    final maxCount = [psychCount, foodCount, servicesCount, activitiesCount]
        .reduce((a, b) => a > b ? a : b);
    final displayMax = maxCount > 10 ? maxCount : 10;

    final stats = [
      {
        'lbl': 'نفسي / اجتماعي',
        'val': psychCount,
        'max': displayMax,
        'col': const Color(0xFF6366f1)
      },
      {
        'lbl': 'خدمات الدار',
        'val': servicesCount,
        'max': displayMax,
        'col': const Color(0xFFf59e0b)
      },
      {
        'lbl': 'طعام وتغذية',
        'val': foodCount,
        'max': displayMax,
        'col': const Color(0xFFef4444)
      },
      {
        'lbl': 'أنشطة ورحلات',
        'val': activitiesCount,
        'max': displayMax,
        'col': const Color(0xFF10b981)
      },
    ];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFfed7aa), width: 1.5)),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                      color: Color(0xFF6366f1), shape: BoxShape.circle)),
              const SizedBox(width: 8),
              const Text('إحصائيات هذا الشهر',
                  style: TextStyle(
                      color: Color(0xFF9a3412),
                      fontSize: 11,
                      fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          Column(
            children: stats
                .map((s) => Padding(
                      padding: const EdgeInsets.only(bottom: 7),
                      child: Row(
                        children: [
                          SizedBox(
                              width: 75,
                              child: Text(s['lbl'] as String,
                                  textAlign: TextAlign.right,
                                  style: const TextStyle(
                                      fontSize: 10, color: Color(0xFF64748b)))),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Container(
                              height: 8,
                              decoration: BoxDecoration(
                                  color: const Color(0xFFf1f5f9),
                                  borderRadius: BorderRadius.circular(4)),
                              alignment: Alignment.centerRight,
                              child: FractionallySizedBox(
                                widthFactor:
                                    (s['val'] as int) / (s['max'] as int),
                                child: Container(
                                    decoration: BoxDecoration(
                                        color: s['col'] as Color,
                                        borderRadius:
                                            BorderRadius.circular(4))),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(s['val'].toString(),
                              style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: s['col'] as Color)),
                        ],
                      ),
                    ))
                .toList(),
          ),
          const Divider(color: Color(0xFFf1f5f9), height: 20),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('متوسط وقت الإغلاق',
                  style: TextStyle(
                      color: Color(0xFF1e293b),
                      fontWeight: FontWeight.bold,
                      fontSize: 11)),
              Text('٢.٣ يوم',
                  style: TextStyle(
                      color: Color(0xFFea580c),
                      fontWeight: FontWeight.bold,
                      fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }

  // Helpers
  Widget _buildStatusBadge(String status, String priority) {
    if (priority == 'high' && status == 'open') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
        decoration: BoxDecoration(
            color: const Color(0xFFfee2e2),
            borderRadius: BorderRadius.circular(9)),
        child: const Text('🔴 مفتوحة',
            style: TextStyle(
                color: Color(0xFF7f1d1d),
                fontSize: 10,
                fontWeight: FontWeight.bold)),
      );
    }
    if (status == 'progress') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
        decoration: BoxDecoration(
            color: const Color(0xFFfef3c7),
            borderRadius: BorderRadius.circular(9)),
        child: const Text('🟡 جاري',
            style: TextStyle(
                color: Color(0xFF92400e),
                fontSize: 10,
                fontWeight: FontWeight.bold)),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
          color: const Color(0xFFd1fae5),
          borderRadius: BorderRadius.circular(9)),
      child: const Text('✅ تمّت',
          style: TextStyle(
              color: Color(0xFF065f46),
              fontSize: 10,
              fontWeight: FontWeight.bold)),
    );
  }

  // ignore: unused_element
  Color _getStatusBorderColor(String status, String priority) {
    if (priority == 'high' && status == 'open') return const Color(0xFFfca5a5);
    if (status == 'progress') return const Color(0xFFfde68a);
    if (status == 'done') return const Color(0xFFa7f3d0);
    return const Color(0xFFe2e8f0);
  }

  // ignore: unused_element
  Color _getStatusBgColor(String status, String priority) {
    if (priority == 'high' && status == 'open') return const Color(0xFFfff5f5);
    if (status == 'progress') return const Color(0xFFfffbeb);
    if (status == 'done') return const Color(0xFFf0fdf4);
    return Colors.white;
  }

  Color _getPriorityColor(String p) {
    if (p == 'high') return const Color(0xFFef4444);
    if (p == 'medium') return const Color(0xFFf59e0b);
    return const Color(0xFF10b981);
  }

  // ignore: unused_element
  Color _getPriorityBg(String p) {
    if (p == 'high') return const Color(0xFFfee2e2);
    if (p == 'medium') return const Color(0xFFfef3c7);
    return const Color(0xFFd1fae5);
  }

  // ignore: unused_element
  String _getPriorityLabel(String p) {
    if (p == 'high') return 'عاجل';
    if (p == 'medium') return 'متوسط';
    return 'خفيف';
  }

  Color _getIconBg(String cat) {
    if (cat == 'psych') return const Color(0xFFede9fe);
    if (cat == 'food') return const Color(0xFFfee2e2);
    return const Color(0xFFfef3c7);
  }

  Color _getStepColor(String s) {
    if (s == 'done') return const Color(0xFF10b981);
    if (s == 'alert') return const Color(0xFFef4444);
    if (s == 'pending') return const Color(0xFFf59e0b);
    return const Color(0xFF6366f1);
  }
}

class NewsTickerChips extends StatefulWidget {
  final List<String> filters;
  final String selectedStatus;
  final Function(String) onSelected;
  final Color primaryColor;
  final Color secondaryColor;

  const NewsTickerChips({
    super.key,
    required this.filters,
    required this.selectedStatus,
    required this.onSelected,
    required this.primaryColor,
    required this.secondaryColor,
  });

  @override
  State<NewsTickerChips> createState() => _NewsTickerChipsState();
}

class _NewsTickerChipsState extends State<NewsTickerChips> {
  late ScrollController _scrollController;
  Timer? _timer;
  bool _isInteracting = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startScrolling();
    });
  }

  void _startScrolling() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 30), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_scrollController.hasClients && !_isInteracting) {
        final maxScroll = _scrollController.position.maxScrollExtent;
        final currentScroll = _scrollController.offset;
        final halfScroll = maxScroll / 2;

        // التحقق مرة أخرى من وجود clients لتجنب الأخطاء أثناء التدمير
        if (_scrollController.hasClients) {
          try {
            if (currentScroll >= halfScroll) {
              _scrollController.jumpTo(currentScroll - halfScroll);
            } else {
              _scrollController.jumpTo(currentScroll + 0.5);
            }
          } catch (e) {
            // تجاهل الخطأ الناتج عن تدمير العناصر أثناء الحركة في أجزاء الثانية الأخيرة
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // مضاعفة العناصر لجعل الحركة مستمرة وشبه دائرية
    final extendedFilters = [...widget.filters, ...widget.filters];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 7),
      height: 48,
      decoration: const BoxDecoration(
          color: Color(0xFFf8fafc),
          border: Border(bottom: BorderSide(color: Color(0xFFe2e8f0)))),
      child: GestureDetector(
        onPanDown: (_) => setState(() => _isInteracting = true),
        onPanEnd: (_) {
          setState(() => _isInteracting = false);
          _startScrolling();
        },
        onPanCancel: () {
          setState(() => _isInteracting = false);
          _startScrolling();
        },
        child: SingleChildScrollView(
          controller: _scrollController,
          scrollDirection: Axis.horizontal,
          child: Row(
            children: extendedFilters.map((f) {
              final isAct = widget.selectedStatus == f;
              return GestureDetector(
                onTap: () => widget.onSelected(f),
                child: Container(
                  margin: const EdgeInsets.only(left: 6),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isAct ? null : Colors.white,
                    gradient: isAct
                        ? LinearGradient(colors: [
                            widget.primaryColor,
                            widget.secondaryColor
                          ])
                        : null,
                    borderRadius: BorderRadius.circular(12),
                    border: isAct
                        ? null
                        : Border.all(color: const Color(0xFFe2e8f0)),
                  ),
                  child: Text(f,
                      style: TextStyle(
                          color: isAct ? Colors.white : const Color(0xFF64748b),
                          fontSize: 12,
                          fontWeight: FontWeight.bold)),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class ComplaintsCardDustParticle {
  Offset position;
  double speed;
  double radius;
  ComplaintsCardDustParticle(
      {required this.position, required this.speed, required this.radius});
}

class ComplaintsCardDustAnimation extends StatefulWidget {
  const ComplaintsCardDustAnimation({super.key});

  @override
  State<ComplaintsCardDustAnimation> createState() =>
      _ComplaintsCardDustAnimationState();
}

class _ComplaintsCardDustAnimationState
    extends State<ComplaintsCardDustAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<ComplaintsCardDustParticle> _dust;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 15))
          ..repeat();

    final random = Random();
    _dust = List.generate(100, (index) {
      // زيادة العدد بناء على طلب المستخدم
      return ComplaintsCardDustParticle(
        position: Offset(random.nextDouble(), random.nextDouble()),
        speed: random.nextDouble() * 0.05 + 0.02,
        radius: random.nextDouble() * 1.5 + 0.5,
      );
    });
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
          return CustomPaint(
            painter: ComplaintsCardDustPainter(
                dust: _dust, animationValue: _controller.value),
          );
        },
      ),
    );
  }
}

class ComplaintsCardDustPainter extends CustomPainter {
  final List<ComplaintsCardDustParticle> dust;
  final double animationValue;

  ComplaintsCardDustPainter({required this.dust, required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFea580c).withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;

    for (var i = 0; i < dust.length; i++) {
      final p = dust[i];

      double dy = (p.position.dy * size.height) -
          (animationValue * p.speed * size.height);
      if (dy < 0) dy += size.height;

      double dx =
          p.position.dx * size.width + sin(animationValue * 2 * pi + i) * 5;

      final currentPos = Offset(dx, dy);

      double opacity = (sin(animationValue * 2 * pi * 2 + i) + 1) / 2;
      paint.color = const Color(0xFFea580c).withValues(alpha: opacity * 0.4);

      canvas.drawCircle(currentPos, p.radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant ComplaintsCardDustPainter oldDelegate) {
    return true;
  }
}
