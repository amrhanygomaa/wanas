import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/app_riverpod.dart';
import '../../models/app_models.dart';
import 'widgets/volunteer_background.dart';

class VolunteerBookingsView extends ConsumerStatefulWidget {
  final List<Animation<double>> fadeAnimations;
  final AnimationController floatController;
  final AnimationController shimmerController;
  final AnimationController popController;

  const VolunteerBookingsView({
    super.key,
    required this.fadeAnimations,
    required this.floatController,
    required this.shimmerController,
    required this.popController,
  });

  @override
  ConsumerState<VolunteerBookingsView> createState() =>
      _VolunteerBookingsViewState();
}

class _VolunteerBookingsViewState extends ConsumerState<VolunteerBookingsView> {
  int _selectedStatusTab = 0; // 0: Upcoming, 1: Completed, 2: Cancelled
  late Timer _countdownTimer;
  String _countdownText = '';

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  @override
  void dispose() {
    _countdownTimer.cancel();
    super.dispose();
  }

  void _startCountdown() {
    _updateCountdown();
    _countdownTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _updateCountdown();
    });
  }

  void _updateCountdown() {
    final now = DateTime.now();
    final upcoming = ref
        .read(appRiverpod)
        .volunteerBookings
        .where((booking) => booking.startTime.isAfter(now))
        .toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
    if (upcoming.isEmpty) {
      setState(() => _countdownText = 'لا توجد جلسات قادمة من AWS');
      return;
    }
    final target = upcoming.first.startTime;
    final diff = target.difference(now);

    if (diff.isNegative) {
      setState(() => _countdownText = 'بدأت الجلسة!');
    } else {
      setState(() => _countdownText =
          'باقي ${diff.inHours} ساعة و${diff.inMinutes % 60} دقيقة');
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = ref.watch(appRiverpod);

    return VolunteerAnimatedBackground(
      child: Column(
        children: [
          _buildSummaryStrip(provider),
          _buildTabFilter(),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (provider.volunteerBookings
                        .any((b) => b.isRatingRequired)) ...[
                      _buildRatingPrompt(provider.volunteerBookings
                          .firstWhere((b) => b.isRatingRequired)),
                      const SizedBox(height: 16),
                    ],
                    _buildSectionLabel(
                        'الجلسة القادمة', const Color(0xFF10b981), 0),
                    const SizedBox(height: 12),
                    _buildNextSessionCard(provider.volunteerBookings
                        .firstWhere((b) => b.status == 'confirmed')),
                    const SizedBox(height: 24),
                    _buildSectionLabel(
                        'حجوزاتي القادمة', const Color(0xFF6366f1), 1),
                    const SizedBox(height: 12),
                    ...provider.volunteerBookings
                        .where((b) => b.status == 'confirmed')
                        .skip(1)
                        .map((b) => _buildBookingCard(b)),
                    const SizedBox(height: 24),
                    _buildSectionLabel(
                        'آخر جلسة مكتملة', const Color(0xFF6366f1), 2),
                    const SizedBox(height: 12),
                    _buildCompletedSessionCard(provider.volunteerBookings
                        .firstWhere((b) => b.status == 'done')),
                    const SizedBox(height: 24),
                    _buildMonthlyStats(provider),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryStrip(AppRiverpod provider) {
    final upcomingCount =
        provider.volunteerBookings.where((b) => b.status == 'confirmed').length;
    final doneCount =
        provider.volunteerBookings.where((b) => b.status == 'done').length;
    final ratingCount =
        provider.volunteerBookings.where((b) => b.isRatingRequired).length;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFd1fae5))),
      ),
      child: Row(
        children: [
          _buildSummaryCell('${provider.volunteerHours}', 'ساعة هذا الشهر',
              const Color(0xFF0f172a)),
          _buildSummaryCell(
              '$ratingCount', 'تقييم مطلوب', const Color(0xFFf59e0b)),
          _buildSummaryCell('$doneCount', 'مكتملة', const Color(0xFF6366f1)),
          _buildSummaryCell('$upcomingCount', 'قادمة', const Color(0xFF059669)),
        ],
      ),
    );
  }

  Widget _buildSummaryCell(String val, String lbl, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: const BoxDecoration(
            border: Border(left: BorderSide(color: Color(0xFFd1fae5)))),
        child: Column(
          children: [
            Text(val,
                style: TextStyle(
                    color: color, fontSize: 18, fontWeight: FontWeight.bold)),
            Text(lbl,
                style: const TextStyle(color: Color(0xFF94a3b8), fontSize: 8),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildTabFilter() {
    final tabs = ['القادمة (٢)', 'المكتملة (١٢)', 'الملغاة (١)'];
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFd1fae5))),
      ),
      child: Row(
        children: List.generate(tabs.length, (index) {
          final isSelected = _selectedStatusTab == index;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedStatusTab = index),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  border: Border(
                      bottom: BorderSide(
                          color: isSelected
                              ? const Color(0xFF10b981)
                              : Colors.transparent,
                          width: 2.5)),
                ),
                child: Text(tabs[index],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: isSelected
                            ? const Color(0xFF059669)
                            : const Color(0xFF94a3b8),
                        fontSize: 10,
                        fontWeight: FontWeight.bold)),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildRatingPrompt(VolunteerBooking booking) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFfffbeb),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFfde68a)),
      ),
      child: Row(
        children: [
          const Text('⭐', style: TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('قيّم جلسة التطوع السابقة',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0f172a))),
                Text('${booking.title} · ${booking.day} ${booking.month}',
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                        fontSize: 10, color: Color(0xFF64748b))),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: List.generate(
                      5,
                      (index) => Text(index < 4 ? '★' : '☆',
                          style: TextStyle(
                              color:
                                  index < 4 ? Colors.amber : Colors.grey[300],
                              fontSize: 16))),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              ref.read(appRiverpod).submitBookingRating(booking.id);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('شكراً لتقييمك! تم حفظ مشاركتك بنجاح.',
                      style: TextStyle(fontFamily: 'Cairo')),
                  backgroundColor: Color(0xFFF59E0B),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Color(0xFFf59e0b), Color(0xFFfbbf24)]),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text('قيّم الآن',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label, Color color, int index) {
    return FadeTransition(
      opacity: widget.fadeAnimations[min(index, 11)],
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Text(label,
              style: TextStyle(
                  color: color, fontSize: 13, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildNextSessionCard(VolunteerBooking booking) {
    return AnimatedBuilder(
      animation: widget.floatController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, -5 * widget.floatController.value),
          child: child,
        );
      },
      child: GestureDetector(
        onTap: () => _showBookingDetails(context, booking),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [Color(0xFF059669), Color(0xFF10b981)]),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                  color: const Color(0xFF10b981).withValues(alpha: 0.35),
                  blurRadius: 15,
                  spreadRadius: 2),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(14)),
                    child: const Center(
                        child: Text('🧠', style: TextStyle(fontSize: 24))),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('غداً — الخميس ١٠ أبريل',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w500)),
                        const SizedBox(height: 4),
                        Text(booking.title,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold)),
                        Text(booking.timeInfo,
                            style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.85),
                                fontSize: 11)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10)),
                child: Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  children: [
                    Flexible(
                      child: Text(_countdownText,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold)),
                    ),
                    const Text('⏱', style: TextStyle(fontSize: 14)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  GestureDetector(
                    onTap: () {
                      ref.read(appRiverpod).confirmAttendance(booking.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              'تم تأكيد حضورك في "${booking.title}" ✅',
                              style: const TextStyle(fontFamily: 'Cairo')),
                          backgroundColor: const Color(0xFF10B981),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12)),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle_outline,
                              color: Color(0xFF059669), size: 14),
                          SizedBox(width: 6),
                          Text('تأكيد الحضور',
                              style: TextStyle(
                                  color: Color(0xFF059669),
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                  Text('+${booking.points} نقطة عند الإتمام',
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 11)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBookingCard(VolunteerBooking booking) {
    return GestureDetector(
      onTap: () => _showBookingDetails(context, booking),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: booking.isUrgent
                  ? const Color(0xFF10b981)
                  : const Color(0xFFd1fae5),
              width: booking.isUrgent ? 2 : 1.5),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 50,
                    decoration: BoxDecoration(
                      gradient:
                          LinearGradient(colors: indexTabToColor(booking.day)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('${booking.day}',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold)),
                        Text(booking.month,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 8)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(booking.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0f172a))),
                        Text(booking.timeInfo,
                            style: const TextStyle(
                                color: Color(0xFF475569),
                                fontSize: 11,
                                fontWeight: FontWeight.w500)),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            const Icon(Icons.location_on_outlined,
                                color: Color(0xFF94a3b8), size: 12),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(booking.location,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      color: Color(0xFF64748b),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                        color: const Color(0xFFd1fae5),
                        borderRadius: BorderRadius.circular(10)),
                    child: const Text('✓ مؤكد',
                        style: TextStyle(
                            color: Color(0xFF065f46),
                            fontSize: 10,
                            fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            if (booking.isUrgent) ...[
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: const BoxDecoration(
                    color: Color(0xFFf0fdf4),
                    border: Border(top: BorderSide(color: Color(0xFFd1fae5)))),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('📍 تسجيل الحضور عند الوصول',
                        style: TextStyle(
                            color: Color(0xFF065f46),
                            fontSize: 10,
                            fontWeight: FontWeight.bold)),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                          color: const Color(0xFF059669),
                          borderRadius: BorderRadius.circular(10)),
                      child: const Row(
                        children: [
                          Icon(Icons.location_searching,
                              color: Colors.white, size: 12),
                          SizedBox(width: 6),
                          Text('check-in',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: Color(0xFFf0fdf4)))),
              child: Row(
                children: [
                  _buildSmallCardAction('📋 تفاصيل', onTap: () {
                    _showBookingDetails(context, booking);
                  }),
                  const SizedBox(width: 6),
                  _buildSmallCardAction('🗺️ الاتجاهات', onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            'جاري فتح الخرائط للذهاب إلى: ${booking.location}',
                            style: const TextStyle(fontFamily: 'Cairo')),
                        backgroundColor: const Color(0xFF10b981),
                      ),
                    );
                  }),
                  const SizedBox(width: 6),
                  _buildSmallCardAction('✕ إلغاء', isDanger: true, onTap: () {
                    _showCancelConfirmation(booking);
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Color> indexTabToColor(int day) {
    if (day == 10) return [const Color(0xFF059669), const Color(0xFF10b981)];
    return [const Color(0xFF6366f1), const Color(0xFF818cf8)];
  }

  Widget _buildSmallCardAction(String label,
      {bool isDanger = false, VoidCallback? onTap}) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isDanger ? const Color(0xFFfff5f5) : const Color(0xFFf0fdf4),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
                color: isDanger
                    ? const Color(0xFFfca5a5)
                    : const Color(0xFFa7f3d0)),
          ),
          child: Text(label,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: isDanger
                      ? const Color(0xFFef4444)
                      : const Color(0xFF065f46),
                  fontSize: 10,
                  fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  void _showCancelConfirmation(VolunteerBooking booking) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('إلغاء الحجز',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
        content: Text(
          'هل أنت متأكد من رغبتك في إلغاء حجز "${booking.title}"؟\nهذا قد يؤثر على تقييمك كمتطوع.',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 13, fontFamily: 'Cairo'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
                const Text('رجوع', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(appRiverpod).cancelBooking(booking.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('تم إلغاء الحجز "${booking.title}" بنجاح.',
                      style: const TextStyle(fontFamily: 'Cairo')),
                  backgroundColor: const Color(0xFFef4444),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFef4444),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10))),
            child: const Text('تأكيد الإلغاء',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletedSessionCard(VolunteerBooking booking) {
    return GestureDetector(
      onTap: () => _showBookingDetails(context, booking),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFe0e7ff), width: 1.5),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [Color(0xFF6366f1), Color(0xFF818cf8)]),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('${booking.day}',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.bold)),
                        Text(booking.month,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 8)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(booking.title,
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.bold)),
                        Text(booking.timeInfo,
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                                color: Color(0xFF64748b), fontSize: 10)),
                        const Wrap(
                          alignment: WrapAlignment.start,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Icon(Icons.check_circle_outline,
                                color: Color(0xFF10b981), size: 12),
                            SizedBox(width: 4),
                            Text('تم توثيق ٢ ساعة بنجاح ✓',
                                textAlign: TextAlign.right,
                                style: TextStyle(
                                    color: Color(0xFF10b981),
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  const Text('مكتملة',
                      style: TextStyle(
                          color: Color(0xFF3730a3),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          backgroundColor: Color(0xFFe0e7ff))),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: Color(0xFFf0fdf4)))),
              child: Row(
                children: [
                  const Text('٢ ساعة',
                      style: TextStyle(color: Color(0xFF64748b), fontSize: 10)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      height: 6,
                      decoration: BoxDecoration(
                          color: const Color(0xFFf0fdf4),
                          borderRadius: BorderRadius.circular(4)),
                      alignment: Alignment.centerRight,
                      child: FractionallySizedBox(
                        widthFactor: 0.76,
                        child: Container(
                            decoration: BoxDecoration(
                                color: const Color(0xFF10b981),
                                borderRadius: BorderRadius.circular(4))),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text('٣٨/٥٠',
                      style: TextStyle(
                          color: Color(0xFF059669),
                          fontSize: 10,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: Color(0xFFf0fdf4)))),
              child: Row(
                children: [
                  _buildSmallActionBtn('📄 تحميل شهادة الجلسة', flex: 2,
                      onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('جاري تجهيز شهادة التطوع للتحميل... 📄',
                            style: TextStyle(fontFamily: 'Cairo')),
                        backgroundColor: Color(0xFF6366F1),
                      ),
                    );
                  }),
                  const SizedBox(width: 8),
                  _buildSmallActionBtn('⭐ تقييم', onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                            'شكراً لمشاركتك! جاري فتح صفحة التقييم... ⭐',
                            style: TextStyle(fontFamily: 'Cairo')),
                        backgroundColor: Color(0xFFF59E0B),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSmallActionBtn(String label,
      {int flex = 1, VoidCallback? onTap}) {
    return Expanded(
      flex: flex,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: flex > 1 ? Colors.white : const Color(0xFFf0fdf4),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFa7f3d0)),
          ),
          child: Text(label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Color(0xFF065f46),
                  fontSize: 10,
                  fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  Widget _buildMonthlyStats(AppRiverpod provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFd1fae5), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSectionLabel('إحصائيات أبريل', const Color(0xFF059669), 3),
          const SizedBox(height: 12),
          _buildStatMiniRow('⏱', 'ساعات هذا الشهر',
              '${provider.volunteerHours} / ${provider.volunteerGoal}'),
          _buildStatMiniRow('📅', 'جلسات مكتملة', '١٢ جلسة'),
          _buildStatMiniRow('⭐', 'متوسط تقييمك', '٤.٧ / ٥'),
          _buildStatMiniRow('🏆', 'باقي للشهادة الذهبية', '١٢ ساعة',
              isShimmer: true),
        ],
      ),
    );
  }

  Widget _buildStatMiniRow(String icon, String label, String val,
      {bool isShimmer = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFFf0fdf4)))),
      child: Row(
        children: [
          if (isShimmer)
            AnimatedBuilder(
              animation: widget.shimmerController,
              builder: (context, child) {
                return ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: const [
                      Color(0xFF059669),
                      Color(0xFF34d399),
                      Color(0xFF059669)
                    ],
                    stops: [
                      widget.shimmerController.value - 0.2,
                      widget.shimmerController.value,
                      widget.shimmerController.value + 0.2
                    ],
                  ).createShader(bounds),
                  child: Text(val,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold)),
                );
              },
            )
          else
            Text(val,
                style: const TextStyle(
                    color: Color(0xFF059669),
                    fontSize: 13,
                    fontWeight: FontWeight.bold)),
          const Spacer(),
          Text(label,
              style: const TextStyle(fontSize: 11, color: Color(0xFF374151))),
          const SizedBox(width: 12),
          Text(icon, style: const TextStyle(fontSize: 15)),
        ],
      ),
    );
  }

  void _showBookingDetails(BuildContext context, VolunteerBooking booking) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                        color: const Color(0xFFdcfce7),
                        borderRadius: BorderRadius.circular(12)),
                    child: const Text('🧠', style: TextStyle(fontSize: 24)),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('تفاصيل الحجز',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF064e3b))),
                      Text(
                          booking.status == 'confirmed'
                              ? 'حجز مؤكد ✅'
                              : 'حجز مكتمل ✨',
                          style: const TextStyle(
                              fontSize: 11, color: Color(0xFF10b981))),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(booking.title,
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1e293b))),
                    const SizedBox(height: 8),
                    Text(booking.timeInfo,
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF059669),
                            fontWeight: FontWeight.w500)),
                    const SizedBox(height: 24),
                    const Divider(color: Color(0xFFf1f5f9)),
                    const SizedBox(height: 16),
                    _buildBookingDetailRow(
                        'المكان', booking.location, Icons.location_on_outlined),
                    _buildBookingDetailRow('النقاط المكتسبة',
                        '${booking.points} نقطة', Icons.stars_rounded),
                    _buildBookingDetailRow(
                        'التاريخ',
                        '${booking.day} ${booking.month}',
                        'assets/icons/calendar.png'),
                    const SizedBox(height: 32),
                    const Text('وصف الجلسة',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1e293b))),
                    const SizedBox(height: 12),
                    const Text(
                        'هذه الجلسة تهدف إلى تقديم الدعم النفسي والاجتماعي للمسنين من خلال الأنشطة الجماعية والنقاشات المثرية.',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF64748b),
                            height: 1.6)),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        side: const BorderSide(color: Color(0xFFe2e8f0)),
                      ),
                      child: const Text('إغلاق',
                          style: TextStyle(
                              color: Color(0xFF64748b),
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (booking.status == 'confirmed')
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content:
                                Text('تم تأكيد حضورك في "${booking.title}" ✅'),
                            backgroundColor: const Color(0xFF059669),
                          ));
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF059669),
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                        child: const Text('تأكيد الحضور',
                            style: TextStyle(fontWeight: FontWeight.bold)),
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

  Widget _buildBookingDetailRow(String label, String value, dynamic icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF059669)),
          const SizedBox(width: 12),
          Text(label,
              style: const TextStyle(fontSize: 12, color: Color(0xFF64748b))),
          const SizedBox(width: 12),
          Expanded(
            child: Text(value,
                textAlign: TextAlign.left,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF334155))),
          ),
        ],
      ),
    );
  }
}
