import 'package:flutter/material.dart'; // مكتبة فلاتر الأساسية للواجهات
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/app_riverpod.dart';
import 'widgets/healing_particles.dart'; // الأنيميشن الموحد

class NurseProfileScreen extends ConsumerWidget {
  // شاشة الملف الشخصي الخاصة بالممرض
  const NurseProfileScreen({super.key}); // مشيد الفئة

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // دالة بناء الواجهة
    final isDark = Theme.of(context).brightness ==
        Brightness.dark; // التحقق من النمط الليلي
    final provider = ref.watch(appRiverpod);

    return Scaffold(
      // الهيكل الأساسي للشاشة
      backgroundColor: isDark
          ? const Color(0xFF0F172A)
          : const Color(0xFFF8FAFC), // خلفية متغيرة حسب النمط
      body: CustomScrollView(
        // استخدام التمرير المخصص (Slivers)
        slivers: [
          _buildSliverAppBar(
              context, provider), // بناء شريط العنوان المتحرك مع الهيدر
          SliverToBoxAdapter(
            // محتوى الشاشة القابل للتمرير
            child: Padding(
              padding: const EdgeInsets.all(20), // هوامش جانبية
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, // ترتيب RTL
                children: [
                  _buildStatsGrid(
                      context), // شبكة الإحصائيات (ساعات، دقة، تقييم)
                  const SizedBox(height: 24),
                  _buildSectionTitle(context,
                      'جدول الورديات القادمة 🗓️'), // عنوان جدول الورديات
                  _buildShiftSchedule(context), // عرض قائمة الورديات القادمة
                  const SizedBox(height: 24),
                  _buildSectionTitle(context, 'الإنجازات'), // عنوان الإنجازات
                  _buildBadges(context), // عرض الأوسمة المحققة
                  const SizedBox(height: 24),
                  _buildSectionTitle(
                      context, 'آراء الأسر وتقييم الأداء ⭐'), // عنوان التقييمات
                  _buildFeedbackCard(context), // بطاقة رأي من أسرة مقيم
                  const SizedBox(height: 100), // مسافة سفلية إضافية
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context, AppRiverpod provider) {
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
                    Text(provider.currentAccount?.name ?? 'فريق التمريض',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold)), // اسم الممرض
                    Text(provider.currentAccount?.specialty ?? 'تمريض',
                        style: const TextStyle(
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

  Widget _buildStatsGrid(BuildContext context) {
    // بناء شبكة إحصائيات الأداء
    return Row(
      children: [
        Expanded(
            child: _statCard(
                context,
                'ساعات العمل',
                '١,٢٤٠',
                Icons.timer_outlined,
                const Color(0xFF0EA5E9))), // إحصائية الساعات
        const SizedBox(width: 12),
        Expanded(
            child: _statCard(
                context,
                'دقة الأدوية',
                '٩٩.٢٪',
                Icons.verified_user_outlined,
                const Color(0xFF10B981))), // إحصائية الدقة
        const SizedBox(width: 12),
        Expanded(
            child: _statCard(
                context,
                'التقييم',
                '٤.٩/٥',
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

  Widget _buildFeedbackCard(BuildContext context) {
    // بناء بطاقة التقييمات وآراء الأسر
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('أحد أفراد الأسرة',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? Colors.white
                              : Colors.black)), // اسم صاحب الرأي
                  Text('منذ ٣ أيام',
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
                  child: const Text('أ',
                      style:
                          TextStyle(color: Color(0xFF0369A1)))), // حرف تعريفي
            ],
          ),
          const SizedBox(height: 12),
          Text(
            // نص الرأي أو التقييم بالعربية
            '"فريق التمريض متعاون ويهتم بالتفاصيل الطبية والجانب النفسي. شكراً لجهودكم."',
            textAlign: TextAlign.right,
            style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white70 : const Color(0xFF475569),
                height: 1.5,
                fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }
}
