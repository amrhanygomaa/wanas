import 'package:flutter/material.dart'; // مكتبة فلاتر الأساسية للواجهات
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/app_riverpod.dart';
import '../../services/admin_users_service.dart';
import 'widgets/healing_particles.dart'; // الأنيميشن الموحد

class NurseProfileScreen extends ConsumerStatefulWidget {
  const NurseProfileScreen({super.key});

  @override
  ConsumerState<NurseProfileScreen> createState() => _NurseProfileScreenState();
}

class _NurseProfileScreenState extends ConsumerState<NurseProfileScreen> {
  Future<List<StaffReview>>? _reviewsFuture;
  String? _reviewsUserId;

  Future<List<StaffReview>> _loadReviews(String? userId) {
    if (userId == null || userId.isEmpty) {
      return Future.value(const []);
    }
    if (_reviewsUserId != userId || _reviewsFuture == null) {
      _reviewsUserId = userId;
      _reviewsFuture = AdminUsersService.instance.getUserReviews(userId);
    }
    return _reviewsFuture!;
  }

  @override
  Widget build(BuildContext context) {
    // دالة بناء الواجهة
    final isDark = Theme.of(context).brightness ==
        Brightness.dark; // التحقق من النمط الليلي
    final provider = ref.watch(appRiverpod);
    final reviewsFuture = _loadReviews(provider.backendUserId);

    return Scaffold(
      // الهيكل الأساسي للشاشة
      backgroundColor: isDark
          ? const Color(0xFF0F172A)
          : const Color(0xFFF8FAFC), // خلفية متغيرة حسب النمط
      body: CustomScrollView(
        // استخدام التمرير المخصص (Slivers)
        slivers: [
          _buildSliverAppBar(
              context, provider.currentAccount?.name ?? 'الممرض'),
          SliverToBoxAdapter(
            // محتوى الشاشة القابل للتمرير
            child: FutureBuilder<List<StaffReview>>(
              future: reviewsFuture,
              builder: (context, snapshot) {
                final isLoading =
                    snapshot.connectionState == ConnectionState.waiting;
                final reviews = snapshot.data ?? const <StaffReview>[];
                return Padding(
                  padding: const EdgeInsets.all(20), // هوامش جانبية
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start, // ترتيب RTL
                    children: [
                      _buildStatsGrid(context, reviews,
                          isLoadingReviews:
                              isLoading), // شبكة الإحصائيات (ساعات، دقة، تقييم)
                      const SizedBox(height: 24),
                      _buildSectionTitle(context,
                          'جدول الورديات القادمة 🗓️'), // عنوان جدول الورديات
                      _buildShiftSchedule(
                          context), // عرض قائمة الورديات القادمة
                      const SizedBox(height: 24),
                      _buildSectionTitle(
                          context, 'الإنجازات'), // عنوان الإنجازات
                      _buildBadges(context), // عرض الأوسمة المحققة
                      const SizedBox(height: 24),
                      _buildSectionTitle(context,
                          'آراء الأسر وتقييم الأداء ⭐'), // عنوان التقييمات
                      _buildFeedbackCard(
                        context,
                        reviews,
                        isLoading: isLoading,
                        error: snapshot.error,
                      ), // بطاقة رأي من أسرة مقيم
                      const SizedBox(height: 100), // مسافة سفلية إضافية
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context, String nurseName) {
    // بناء شريط العنوان المتمدد
    return SliverAppBar(
      expandedHeight: 280, // الارتفاع الأقصى عند التمدد
      pinned: true, // يبقى شريط العنوان ظاهراً عند التمرير
      backgroundColor: const Color(0xFF0369A1), // اللون الأزرق الطبي المميز
      leading: IconButton(
        // زر العودة
        icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        // محتوى الهيدر المتغير الحجم
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              // تدرج لوني أزرق احترافي
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF0369A1), Color(0xFF0EA5E9)],
            ),
          ),
          child: Stack(
            children: [
              const HealingParticles(), // الأنيميشن الموحد
              Positioned.fill(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),
                    _buildProfileImage(), // عرض صورة الملف الشخصي
                    const SizedBox(height: 16),
                    Text(nurseName,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold)),
                    const Text('مشرف تمريض — المستوى الذهبي',
                        style: TextStyle(
                            color: Color(0xFFE0F2FE),
                            fontSize: 15)), // المسمى الوظيفي والمستوى
                    const SizedBox(height: 12),
                    Container(
                      // بطاقة تعريفية بكود الموظف
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20)),
                      child: const Text('كود الموظف: #N-4892',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.bold)),
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

  Widget _buildProfileImage() {
    // بناء دائرة الصورة الشخصية
    return Container(
      padding: const EdgeInsets.all(4),
      decoration:
          const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
      child: CircleAvatar(
        radius: 50,
        backgroundColor: Colors.blue.shade100,
        child: const Icon(Icons.person,
            size: 60, color: Color(0xFF0369A1)), // أيقونة افتراضية
      ),
    );
  }

  Widget _buildStatsGrid(BuildContext context, List<StaffReview> reviews,
      {required bool isLoadingReviews}) {
    // بناء شبكة إحصائيات الأداء
    final averageRating = reviews.isEmpty
        ? null
        : reviews.map((r) => r.rating).reduce((a, b) => a + b) / reviews.length;
    final ratingText = isLoadingReviews
        ? '...'
        : averageRating == null
            ? 'لا يوجد'
            : '${averageRating.toStringAsFixed(1)}/٥';
    return Row(
      children: [
        Expanded(
            child: _statCard(
                context,
                'ساعات العمل',
                'غير متاح',
                Icons.timer_outlined,
                const Color(0xFF0EA5E9))), // إحصائية الساعات
        const SizedBox(width: 12),
        Expanded(
            child: _statCard(
                context,
                'دقة الأدوية',
                'غير متاح',
                Icons.verified_user_outlined,
                const Color(0xFF10B981))), // إحصائية الدقة
        const SizedBox(width: 12),
        Expanded(
            child: _statCard(
                context,
                'التقييم',
                ratingText,
                Icons.star_outline_rounded,
                const Color(0xFFFBBF24))), // إحصائية التقييم
      ],
    );
  }

  Widget _statCard(BuildContext context, String label, String value,
      IconData icon, Color color) {
    // بناء كارت إحصائي واحد
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 1.5),
        boxShadow: [
          BoxShadow(
              color: color.withValues(alpha: 0.15),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(value,
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark
                      ? Colors.white
                      : const Color(0xFF0F172A))), // القيمة بالأرقام
          Text(label,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isDark
                      ? Colors.white70
                      : const Color(0xFF475569))), // المسمى بالعربية
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    // بناء عنوان جانبي للأقسام
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 8),
      child: Text(title,
          style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF1E293B))),
    );
  }

  Widget _buildShiftSchedule(BuildContext context) {
    // بناء قائمة جدول الورديات
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          _shiftRow(context, 'الإثنين - ٢٧ أبريل', '٠٦:٠٠ ص - ٠٢:٠٠ ظ',
              'صباحية', true), // وردية صباحية
          const Divider(height: 20, color: Colors.white10),
          _shiftRow(context, 'الثلاثاء - ٢٨ أبريل', '٠٦:٠٠ ص - ٠٢:٠٠ ظ',
              'صباحية', true), // وردية صباحية
          const Divider(height: 20, color: Colors.white10),
          _shiftRow(context, 'الأربعاء - ٢٩ أبريل', 'راحة أسبوعية', '-',
              false), // يوم راحة
        ],
      ),
    );
  }

  Widget _shiftRow(BuildContext context, String date, String time, String type,
      bool active) {
    // بناء سطر وردية واحدة
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Container(
          // شارة نوع الوردية
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: active
                ? (isDark
                    ? const Color(0xFF0369A1).withValues(alpha: 0.2)
                    : const Color(0xFFF0F9FF))
                : (isDark ? Colors.white10 : const Color(0xFFF1F5F9)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(type,
              style: TextStyle(
                  color: active
                      ? (isDark
                          ? const Color(0xFF38BDF8)
                          : const Color(0xFF0369A1))
                      : (isDark ? Colors.white38 : const Color(0xFF64748B)),
                  fontSize: 12,
                  fontWeight: FontWeight.bold)),
        ),
        const Spacer(),
        Column(
          // تفاصيل التاريخ والوقت
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(date,
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black)),
            Text(time,
                style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white60 : const Color(0xFF64748B))),
          ],
        ),
      ],
    );
  }

  Widget _buildBadges(BuildContext context) {
    // بناء قسم الإنجازات بشكل أفقي
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal, // تمرير أفقي
      reverse: true, // يبدأ من اليمين (RTL)
      child: Row(
        children: [
          _achievementCard('موظف الشهر', 'مايو ٢٠٢٦', const Color(0xFF10B981)),
          _achievementCard(
              'شهادة BLS', 'تم التجديد بنجاح', const Color(0xFF0EA5E9)),
          _achievementCard(
              '١٠٠٪ رضا المرضى', 'خلال الربع الأول', const Color(0xFFF59E0B)),
          _achievementCard(
              'دورة العناية المركزة', 'إتمام بنجاح', const Color(0xFFEF4444)),
        ],
      ),
    );
  }

  Widget _achievementCard(String title, String subtitle, Color color) {
    // بناء كارت إنجاز واحد
    return Container(
      margin: const EdgeInsets.only(left: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(subtitle,
              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
        ],
      ),
    );
  }

  Widget _buildFeedbackCard(BuildContext context, List<StaffReview> reviews,
      {required bool isLoading, Object? error}) {
    // بناء بطاقة التقييمات وآراء الأسر
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final latestReview = reviews.isEmpty ? null : reviews.first;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
            color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          if (isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else if (error != null)
            _feedbackEmptyState(
              context,
              'تعذر تحميل التقييمات من AWS.',
              Icons.cloud_off_rounded,
            )
          else if (latestReview == null)
            _feedbackEmptyState(
              context,
              'لا توجد تقييمات منشورة لهذا الحساب بعد.',
              Icons.rate_review_outlined,
            )
          else ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(latestReview.fromName,
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? Colors.white
                                : Colors.black)), // اسم صاحب الرأي
                    Text(_reviewDate(latestReview.createdAt),
                        style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? Colors.white38
                                : const Color(0xFF94A3B8))), // توقيت الرأي
                  ],
                ),
                const SizedBox(width: 12),
                CircleAvatar(
                    backgroundColor: Colors.blue.shade50,
                    child: Text(
                      latestReview.fromName.isEmpty
                          ? '؟'
                          : latestReview.fromName.substring(0, 1),
                      style: const TextStyle(color: Color(0xFF0369A1)),
                    )), // حرف تعريفي
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: List.generate(
                5,
                (index) => Icon(
                  index < latestReview.rating.round()
                      ? Icons.star_rounded
                      : Icons.star_border_rounded,
                  size: 18,
                  color: const Color(0xFFFBBF24),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              latestReview.comment,
              textAlign: TextAlign.right,
              style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.white70 : const Color(0xFF475569),
                  height: 1.5,
                  fontStyle: FontStyle.italic),
            ),
          ],
        ],
      ),
    );
  }

  Widget _feedbackEmptyState(
      BuildContext context, String message, IconData icon) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Icon(icon,
            color: isDark ? Colors.white38 : const Color(0xFF94A3B8), size: 22),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            message,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.white60 : const Color(0xFF64748B),
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  String _reviewDate(DateTime? date) {
    if (date == null) return '';
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays == 0) return 'اليوم';
    if (diff.inDays == 1) return 'أمس';
    if (diff.inDays < 7) return 'منذ ${diff.inDays} أيام';
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
