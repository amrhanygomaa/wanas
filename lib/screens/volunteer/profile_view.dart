import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/app_riverpod.dart';
import '../../models/app_models.dart';
import 'widgets/add_skill_dialog.dart';
import 'widgets/edit_profile_sheet.dart';
import 'widgets/volunteer_background.dart';

class VolunteerProfileView extends ConsumerWidget {
  final List<Animation<double>> fadeAnimations;
  final AnimationController floatController;
  final AnimationController shimmerController;
  final AnimationController popController;
  final VoidCallback onSeeAllOpportunities;

  const VolunteerProfileView({
    super.key,
    required this.fadeAnimations,
    required this.floatController,
    required this.shimmerController,
    required this.popController,
    required this.onSeeAllOpportunities,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = ref.watch(appRiverpod);

    return VolunteerAnimatedBackground(
      child: Padding(
        padding: const EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16), // إضافة مسافة من فوق وحشو جانبي لمنع الالتصاق بالحواف
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSectionLabel('ملفي الشخصي', const Color(0xFF065f46), 0),
            const SizedBox(height: 12),
            _buildProfileCard(context, ref),
            const SizedBox(height: 24),
            _buildSectionLabel('فرص تطوعية جديدة', const Color(0xFF059669), 1,
                action: GestureDetector(
                  onTap: onSeeAllOpportunities,
                  child: const Text('عرض الكل',
                      style: TextStyle(
                          color: Color(0xFF059669),
                          fontSize: 11,
                          fontWeight: FontWeight.bold)),
                )),
            const SizedBox(height: 12),
            if (provider.volunteerOpportunities.isEmpty)
              _buildEmptyStateCard(
                icon: Icons.lightbulb_outline_rounded,
                title: 'لا توجد فرص تطوعية متاحة',
                subtitle: 'تحقق مرة أخرى لاحقاً للفرص الجديدة',
              )
            else
              ...provider.volunteerOpportunities
                  .map((o) => _buildOpportunityCard(context, o)),
            const SizedBox(height: 24),
            _buildSectionLabel('حجوزاتي القادمة', const Color(0xFF059669), 2),
            const SizedBox(height: 12),
            if (provider.volunteerBookings.isEmpty)
              _buildEmptyStateCard(
                icon: Icons.calendar_month_outlined,
                title: 'لا توجد حجوزاتي القادمة',
                subtitle: 'ابدأ بحجز فرص تطوعية جديدة لعرضها هنا',
              )
            else
              ...provider.volunteerBookings
                  .map((b) => _buildBookingCard(context, b)),
            const SizedBox(height: 24),
            _buildSectionLabel('سجل الساعات', const Color(0xFF059669), 3),
            const SizedBox(height: 12),
            _buildHoursLog(context, provider),
            const SizedBox(height: 24),
            _buildSectionLabel('شهاداتي وإنجازاتي', const Color(0xFFf59e0b), 4),
            const SizedBox(height: 12),
            if (provider.volunteerCertificates.isEmpty)
              _buildEmptyStateCard(
                icon: Icons.emoji_events_outlined,
                title: 'لا توجد شهاداتي وإنجازاتي',
                subtitle: 'أكمل ساعات تطوعية للحصول على شهادات وإنجازات',
              )
            else
              _buildCertificatesCarousel(provider),
            const SizedBox(height: 24),
            _buildSectionLabel('التقييم والآراء', const Color(0xFF6366f1), 5),
            const SizedBox(height: 12),
            _buildRatingSection(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label, Color color, int index,
      {Widget? action}) {
    return FadeTransition(
      opacity: fadeAnimations[min(index, 11)],
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Text(label,
                  style: TextStyle(
                      color: color, fontSize: 14, fontWeight: FontWeight.bold)),
            ],
          ),
          if (action != null) action,
        ],
      ),
    );
  }

  Widget _buildProfileCard(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(appRiverpod).volunteerProfile;
    return FadeTransition(
      opacity: fadeAnimations[1],
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFa7f3d0), width: 1.5),
        ),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                        colors: [Color(0xFF059669), Color(0xFF10b981)]),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                      child: Text(
                          profile.name
                              .substring(0, min(2, profile.name.length)),
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold))),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        alignment: WrapAlignment.start,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          Text(profile.name,
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                                color: const Color(0xFFd1fae5),
                                borderRadius: BorderRadius.circular(8)),
                            child: const Text('✓ موثّق',
                                style: TextStyle(
                                    color: Color(0xFF065f46),
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      Text('${profile.location} · مسجل منذ مارس ٢٠٢٤',
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF475569),
                              fontWeight: FontWeight.w500)),
                      const SizedBox(height: 8),
                      Wrap(
                        alignment: WrapAlignment.start,
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          if (profile.instagramUrl != null &&
                              profile.instagramUrl!.isNotEmpty)
                            _socialIcon('📸'),
                          if (profile.facebookUrl != null &&
                              profile.facebookUrl!.isNotEmpty)
                            _socialIcon('🔵'),
                          if (profile.linkedinUrl != null &&
                              profile.linkedinUrl!.isNotEmpty)
                            _socialIcon('💼'),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  children: [
                    IconButton(
                      onPressed: () => _showEditProfile(context),
                      icon: const Icon(Icons.edit_note_rounded,
                          color: Color(0xFF059669)),
                    ),
                    IconButton(
                      onPressed: () => _simulateShare(context, profile),
                      icon: const Icon(Icons.share_rounded,
                          color: Color(0xFF059669), size: 20),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(profile.bio,
                textAlign: TextAlign.right,
                style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF334155),
                    height: 1.5,
                    fontWeight: FontWeight.w500)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.start,
              children: [
                ...profile.skills.map((s) => _buildSkillTag(s, ref: ref)),
                GestureDetector(
                  onTap: () => _showAddSkill(context, ref),
                  child: _buildSkillTag('+ إضافة مهارة', isAction: true),
                ),
              ],
            ),
            if (profile.cvFileName != null ||
                profile.recommendationFileName != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(10)),
                child: const Row(
                  children: [
                    Text('تم إرفاق الملفات المهنية بنجاح',
                        style:
                            TextStyle(fontSize: 9, color: Color(0xFF065f46))),
                    SizedBox(width: 8),
                    Icon(Icons.check_circle,
                        color: Color(0xFF10b981), size: 14),
                  ],
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _socialIcon(String emoji) {
    return Container(
      margin: const EdgeInsets.only(left: 8),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
          color: const Color(0xFFF0FDF4),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFd1fae5))),
      child: Text(emoji, style: const TextStyle(fontSize: 12)),
    );
  }

  void _showEditProfile(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const EditProfileSheet(),
    );
  }

  void _showAddSkill(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AddSkillDialog(
        onAdd: (s) => ref.read(appRiverpod).addVolunteerSkill(s),
      ),
    );
  }

  void _simulateShare(BuildContext context, VolunteerProfile profile) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('تم نسخ رابط ملفك الشخصي للمشاركة! 🔗',
            style: TextStyle(fontFamily: 'Cairo')),
        backgroundColor: const Color(0xFF0369A1),
        action: SnackBarAction(
            label: 'ممتاز', textColor: Colors.white, onPressed: () {}),
      ),
    );
  }

  Widget _buildSkillTag(String label, {bool isAction = false, WidgetRef? ref}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isAction ? Colors.white : const Color(0xFFd1fae5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFa7f3d0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF065f46))),
          if (!isAction && ref != null)
            GestureDetector(
              onTap: () => ref.read(appRiverpod).removeVolunteerSkill(label),
              child: const Padding(
                padding: EdgeInsets.only(left: 6),
                child: Icon(Icons.close, size: 12, color: Color(0xFF065f46)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildOpportunityCard(BuildContext context, VolunteerOpportunity opp) {
    return AnimatedBuilder(
      animation: floatController,
      builder: (context, child) {
        return Transform.translate(
          offset:
              opp.isNew ? Offset(0, -4 * floatController.value) : Offset.zero,
          child: child,
        );
      },
      child: GestureDetector(
        onTap: () => _showOpportunityDetails(context, opp),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: opp.isNew
                    ? const Color(0xFF10b981)
                    : const Color(0xFFa7f3d0),
                width: 1.5),
            boxShadow: opp.isNew
                ? [
                    BoxShadow(
                        color: const Color(0xFF10b981).withValues(alpha: 0.1),
                        blurRadius: 10,
                        spreadRadius: 2)
                  ]
                : [],
          ),
          child: Stack(
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                        color: const Color(0xFFf0fdf4),
                        borderRadius: BorderRadius.circular(12)),
                    child: Center(
                        child: Text(opp.icon,
                            style: const TextStyle(fontSize: 20))),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(opp.title,
                                textAlign: TextAlign.right,
                                style: const TextStyle(
                                    fontSize: 14, fontWeight: FontWeight.bold)),
                            if (opp.isNew) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                    color: const Color(0xFF10b981),
                                    borderRadius: BorderRadius.circular(6)),
                                child: const Text('جديدة!',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 8,
                                        fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(opp.org,
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                                color: Color(0xFF475569),
                                fontSize: 11,
                                fontWeight: FontWeight.w500)),
                        const SizedBox(height: 8),
                        Wrap(
                          alignment: WrapAlignment.start,
                          spacing: 4,
                          runSpacing: 4,
                          children:
                              opp.tags.map((t) => _buildBadge(t)).toList(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildGlowButton('احجز الآن'),
                        const SizedBox(height: 8),
                        Text('⏱ ${opp.hours} ساعة · يضيف لرصيدك',
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                                color: Color(0xFF475569),
                                fontSize: 11,
                                fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGlowButton(String label) {
    return AnimatedBuilder(
      animation: shimmerController,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF059669), Color(0xFF10b981), Color(0xFF059669)],
              stops: [0.0, 0.5, 1.0],
            ),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF10b981).withValues(alpha: 0.35),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Text(label,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold)),
        );
      },
    );
  }

  Widget _buildBadge(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
          color: const Color(0xFFd1fae5),
          borderRadius: BorderRadius.circular(8)),
      child: Text(label,
          style: const TextStyle(
              color: Color(0xFF065f46),
              fontSize: 11,
              fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildBookingCard(BuildContext context, VolunteerBooking booking) {
    return GestureDetector(
      onTap: () => _showBookingDetails(context, booking),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFa7f3d0), width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 48,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Color(0xFF059669), Color(0xFF10b981)]),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('${booking.day}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold)),
                  Text(booking.month,
                      style: const TextStyle(color: Colors.white, fontSize: 8)),
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
                          color: Color(0xFF475569),
                          fontSize: 11,
                          fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                  color: const Color(0xFFd1fae5),
                  borderRadius: BorderRadius.circular(8)),
              child: const Text('✓ مؤكد',
                  style: TextStyle(
                      color: Color(0xFF065f46),
                      fontSize: 10,
                      fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHoursLog(BuildContext context, AppRiverpod provider) {
    final progress = provider.volunteerHours / provider.volunteerGoal;
    return GestureDetector(
      onTap: () => _showHoursLogDetails(context, provider),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
              colors: [Color(0xFF065f46), Color(0xFF059669)]),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: const Color(0xFF065f46).withValues(alpha: 0.2),
                blurRadius: 12,
                offset: const Offset(0, 6))
          ],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('⏱ ${provider.volunteerHours}',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold)),
                      Text('ساعة تطوعية هذا الشهر',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 11)),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${provider.volunteerGoal}',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold)),
                      Text('الهدف',
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 9)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildShimmerProgressBar(progress),
            const SizedBox(height: 8),
            Text(
                '${(progress * 100).toInt()}% من هدفك — باقي ${provider.volunteerGoal - provider.volunteerHours} ساعة للشهادة الذهبية 🏆',
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9), fontSize: 10)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _buildLogChip('قراءة: ١٥ س'),
                _buildLogChip('دعم نفسي: ١٢ س'),
                _buildLogChip('ترفيه: ١١ س'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerProgressBar(double progress) {
    return AnimatedBuilder(
      animation: shimmerController,
      builder: (context, child) {
        return Container(
          height: 10,
          width: double.infinity,
          decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10)),
          child: LayoutBuilder(builder: (context, constraints) {
            return Container(
              height: 10,
              width: constraints.maxWidth * progress,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: const [
                    Color(0xFF10b981),
                    Color(0xFF6ee7b7),
                    Color(0xFF10b981)
                  ],
                  stops: [
                    shimmerController.value - 0.4,
                    shimmerController.value,
                    shimmerController.value + 0.4,
                  ],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildLogChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(10)),
      child: Text(label,
          style: const TextStyle(
              color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildEmptyStateCard({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFa7f3d0), width: 1.5),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFFf0fdf4),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Icon(
                icon,
                size: 28,
                color: const Color(0xFF059669),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
              fontFamily: 'Cairo',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF64748B),
              fontFamily: 'Cairo',
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCertificatesCarousel(AppRiverpod provider) {
    return _CertificatesTicker(
      certificates: provider.volunteerCertificates,
      popController: popController,
    );
  }

  Widget _buildRatingSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFa7f3d0), width: 1.5),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: const Color(0xFFfffbeb),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFfde68a))),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('قيّم جلسة التطوع السابقة',
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.bold)),
                      const Text('جلسة الأحد ٦ أبريل · انتظر تقييمك',
                          style: TextStyle(fontSize: 10, color: Colors.grey)),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: List.generate(
                            5,
                            (index) => Text(index < 4 ? '★' : '☆',
                                style: TextStyle(
                                    color: index < 4
                                        ? Colors.amber
                                        : Colors.grey[300],
                                    fontSize: 16))),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                      color: Color(0xFFfbbf24), shape: BoxShape.circle)),
              const SizedBox(width: 8),
              const Text('تقييمات المقيمين لي',
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFfbbf24))),
            ],
          ),
          const SizedBox(height: 8),
          _buildRatingRow('التعامل', 5.0),
          _buildRatingRow('التحضير', 4.0),
          _buildRatingRow('الالتزام', 5.0),
        ],
      ),
    );
  }

  Widget _buildRatingRow(String label, double rating) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
              width: 60,
              child: Text(label,
                  style:
                      const TextStyle(color: Color(0xFF374151), fontSize: 11))),
          const SizedBox(width: 12),
          Row(
            children: List.generate(
                5,
                (i) => Text(i < rating ? '★' : '☆',
                    style: TextStyle(
                        color: i < rating ? Colors.amber : Colors.grey[300],
                        fontSize: 12))),
          ),
          const Spacer(),
          Text('$rating',
              style: TextStyle(
                  color: rating >= 5
                      ? const Color(0xFF10b981)
                      : const Color(0xFFf59e0b),
                  fontSize: 10,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  void _showOpportunityDetails(BuildContext context, VolunteerOpportunity opp) {
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
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        if (opp.isNew) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                                color: const Color(0xFF10b981),
                                borderRadius: BorderRadius.circular(8)),
                            child: const Text('فرصة جديدة',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(width: 12),
                        ],
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                              color: const Color(0xFFf0fdf4),
                              borderRadius: BorderRadius.circular(12)),
                          child: Text(opp.icon,
                              style: const TextStyle(fontSize: 24)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(opp.title,
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF065f46))),
                    Text(opp.org,
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF059669),
                            fontWeight: FontWeight.w500)),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        _buildDetailChip(
                            '${opp.hours} ساعة', Icons.timer_outlined),
                        const SizedBox(width: 12),
                        _buildDetailChip(
                            '${opp.points} نقطة', Icons.stars_rounded),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        _buildDetailChip(
                            opp.dateInfo, 'assets/icons/calendar.png'),
                        const SizedBox(width: 12),
                        _buildDetailChip(
                            'المقاعد: ${opp.filledSlots}/${opp.totalSlots}',
                            Icons.people_outline),
                      ],
                    ),
                    const SizedBox(height: 32),
                    const Text('وصف الفرصة التطوعية',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1e293b))),
                    const SizedBox(height: 12),
                    Text(
                        opp.description.isEmpty
                            ? 'انضم إلينا في هذه الفرصة التطوعية المميزة للمساهمة في دعم ورعاية كبار السن. مهاراتك يمكن أن تصنع فرقاً كبيراً في حياتهم اليومية.'
                            : opp.description,
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF475569),
                            height: 1.6)),
                    const SizedBox(height: 24),
                    const Text('المهارات المطلوبة',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1e293b))),
                    const SizedBox(height: 12),
                    Wrap(
                      alignment: WrapAlignment.start,
                      spacing: 8,
                      runSpacing: 8,
                      children: opp.tags.map((t) => _buildBadge(t)).toList(),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                          'تم حجز الفرصة بنجاح! سيتم التواصل معك قريباً 🌿'),
                      backgroundColor: Color(0xFF059669),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF059669),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: const Text('تأكيد الحجز الآن',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailChip(String label, dynamic icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
          color: const Color(0xFFf8fafc),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFe2e8f0))),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF475569))),
          const SizedBox(width: 8),
          if (icon is IconData)
            Icon(icon, size: 16, color: const Color(0xFF059669))
          else if (icon is String)
            Image.asset(icon,
                width: 16, height: 16, color: const Color(0xFF059669)),
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
        height: MediaQuery.of(context).size.height * 0.7,
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
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                              color: const Color(0xFFd1fae5),
                              borderRadius: BorderRadius.circular(8)),
                          child: const Text('حجز مؤكد',
                              style: TextStyle(
                                  color: Color(0xFF065f46),
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                              color: const Color(0xFFf0fdf4),
                              borderRadius: BorderRadius.circular(12)),
                          child:
                              const Text('📋', style: TextStyle(fontSize: 24)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(booking.title,
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF065f46))),
                    const SizedBox(height: 8),
                    Text('تم تأكيد موعدك بنجاح. نحن في انتظارك!',
                        textAlign: TextAlign.right,
                        style:
                            TextStyle(fontSize: 14, color: Colors.grey[600])),
                    const SizedBox(height: 32),
                    _buildBookingInfoRow(
                        'الموعد', booking.timeInfo, Icons.access_time_rounded),
                    _buildBookingInfoRow(
                        'التاريخ',
                        '${booking.day} ${booking.month} ٢٠٢٤',
                        'assets/icons/calendar.png'),
                    _buildBookingInfoRow(
                        'المكان',
                        booking.location.isEmpty
                            ? 'دار الرعاية الرئيسي'
                            : booking.location,
                        Icons.location_on_outlined),
                    _buildBookingInfoRow('النقاط المتوقعة',
                        '${booking.points} نقطة', Icons.stars_rounded),
                    const SizedBox(height: 32),
                    const Text('تعليمات هامة',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1e293b))),
                    const SizedBox(height: 12),
                    const Text(
                        '• يرجى الحضور قبل الموعد بـ ١٥ دقيقة.\n• تأكد من إبراز الكود الخاص بك عند الوصول.\n• في حال الاعتذار، يرجى التواصل قبل ٢٤ ساعة.',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF475569),
                            height: 1.8)),
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
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        side: const BorderSide(color: Color(0xFFe2e8f0)),
                      ),
                      child: const Text('إغلاق',
                          style: TextStyle(
                              color: Color(0xFF475569),
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content:
                                    Text('تم إضافة الموعد لتقويمك الشخصي 📅')));
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF059669),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: const Text('إضافة للتقويم',
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

  void _showHoursLogDetails(BuildContext context, AppRiverpod provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
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
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                              color: const Color(0xFFf0fdf4),
                              borderRadius: BorderRadius.circular(12)),
                          child:
                              const Text('⏱', style: TextStyle(fontSize: 24)),
                        ),
                        const Text('تفاصيل سجل الساعات',
                            style: TextStyle(
                                color: Color(0xFF065f46),
                                fontSize: 16,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildMonthlyGoalCard(provider),
                    const SizedBox(height: 32),
                    const Text('توزيع الساعات حسب الفئة',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1e293b))),
                    const SizedBox(height: 16),
                    _buildCategoryHourRow(
                        'قراءة ومرافقة', 15, const Color(0xFF10b981)),
                    _buildCategoryHourRow(
                        'دعم نفسي واجتماعي', 12, const Color(0xFF6366f1)),
                    _buildCategoryHourRow(
                        'ترفيه وألعاب', 11, const Color(0xFFf59e0b)),
                    _buildCategoryHourRow(
                        'مساعدة طبية بسيطة', 8, const Color(0xFFef4444)),
                    const SizedBox(height: 32),
                    const Text('سجل النشاطات الأخيرة',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1e293b))),
                    const SizedBox(height: 12),
                    _buildHistoryLogItem(
                        'جلسة تطوع', 'الأحد، ٢٠ أبريل', '٣ ساعات'),
                    _buildHistoryLogItem(
                        'مرافقة في الحديقة', 'الخميس، ١٧ أبريل', '٢ ساعة'),
                    _buildHistoryLogItem('أمسية ترفيهية - قسم (أ)',
                        'الثلاثاء، ١٥ أبريل', '٤ ساعات'),
                    _buildHistoryLogItem(
                        'دعم نفسي', 'السبت، ١٢ أبريل', '١.٥ ساعة'),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF065f46),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: const Text('فهمت',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlyGoalCard(AppRiverpod provider) {
    final progress = provider.volunteerHours / provider.volunteerGoal;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF065f46),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${provider.volunteerGoal} س',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                  Text('الهدف الشهري',
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 10)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${provider.volunteerHours} س',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold)),
                  Text('تم إنجازها',
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 12)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildShimmerProgressBar(progress),
          const SizedBox(height: 12),
          Text(
              'باقي لك ${provider.volunteerGoal - provider.volunteerHours} ساعة للحصول على شهادة التقدير لهذا الشهر 🌟',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9), fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildCategoryHourRow(String label, int hours, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          Row(
            children: [
              Text('$hours س',
                  style: TextStyle(
                      color: color, fontWeight: FontWeight.bold, fontSize: 13)),
              const Spacer(),
              Text(label,
                  style:
                      const TextStyle(fontSize: 12, color: Color(0xFF475569))),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: hours / 20,
              backgroundColor: color.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryLogItem(String title, String date, String hours) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFFf1f5f9)))),
      child: Row(
        children: [
          Text(hours,
              style: const TextStyle(
                  color: Color(0xFF059669),
                  fontWeight: FontWeight.bold,
                  fontSize: 13)),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1e293b))),
              Text(date,
                  textAlign: TextAlign.right,
                  style:
                      const TextStyle(fontSize: 10, color: Color(0xFF64748b))),
            ],
          ),
          const SizedBox(width: 12),
          const Icon(Icons.check_circle_outline,
              size: 16, color: Color(0xFF10b981)),
        ],
      ),
    );
  }

  Widget _buildBookingInfoRow(String title, String val, dynamic icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Text(val,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF059669))),
          const Spacer(),
          Text(title, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
        ],
      ),
    );
  }
}

// --- Certificates Ticker Widget ---

class _CertificatesTicker extends StatefulWidget {
  final List<VolunteerCertificate> certificates;
  final AnimationController popController;

  const _CertificatesTicker({
    required this.certificates,
    required this.popController,
  });

  @override
  State<_CertificatesTicker> createState() => _CertificatesTickerState();
}

class _CertificatesTickerState extends State<_CertificatesTicker> {
  late ScrollController _scrollController;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startTimer();
    });
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(milliseconds: 30), (timer) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.offset + 0.5);
        if (_scrollController.offset >=
            _scrollController.position.maxScrollExtent) {
          _scrollController.jumpTo(0);
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
    final infiniteItems = [
      ...widget.certificates,
      ...widget.certificates,
      ...widget.certificates,
    ];

    return SizedBox(
      height: 110,
      child: ListView.builder(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        itemCount: infiniteItems.length,
        itemBuilder: (context, index) {
          final cert = infiniteItems[index];
          return ScaleTransition(
            scale: widget.popController,
            child: Container(
              width: 95,
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
              decoration: BoxDecoration(
                gradient: cert.isLocked
                    ? LinearGradient(
                        colors: [
                          Colors.white.withValues(alpha: 0.4),
                          Colors.grey.shade50.withValues(alpha: 0.2)
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : const LinearGradient(
                        colors: [Colors.white, Color(0xFFf0fdf4)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: cert.isLocked
                      ? const Color(0xFFcbd5e1).withValues(alpha: 0.4)
                      : const Color(0xFF34d399).withValues(alpha: 0.6),
                  width: cert.isLocked ? 1 : 1.5,
                ),
                boxShadow: cert.isLocked
                    ? null
                    : [
                        BoxShadow(
                          color:
                              const Color(0xFF059669).withValues(alpha: 0.06),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
              ),
              child: Opacity(
                opacity: cert.isLocked ? 0.5 : 1.0,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Top Accent Symbol/Ornament (Minimalist Gold Star)
                    Text(
                      '★',
                      style: TextStyle(
                        color: cert.isLocked
                            ? const Color(0xFF94a3b8).withValues(alpha: 0.5)
                            : const Color(0xFFfbbf24),
                        fontSize: 12,
                      ),
                    ),

                    // Certificate Title
                    Expanded(
                      child: Center(
                        child: Text(
                          cert.name,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: cert.isLocked
                                ? const Color(0xFF64748b)
                                : const Color(0xFF065f46),
                            height: 1.2,
                          ),
                        ),
                      ),
                    ),

                    // Mini Decorative Gold/Green Divider
                    Container(
                      width: 16,
                      height: 1.5,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        color: cert.isLocked
                            ? const Color(0xFFcbd5e1)
                            : const Color(0xFF34d399),
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),

                    // Certificate Date/Subtitle
                    Text(
                      cert.isLocked ? cert.progressInfo : cert.date,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF64748b),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
