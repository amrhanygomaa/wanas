import 'dart:io'; // للتعامل مع ملفات الصور المحلية
import 'package:flutter/material.dart'; // مكتبة فلاتر الأساسية للواجهات
import 'package:flutter_riverpod/flutter_riverpod.dart'; // مكتبة إدارة الحالة
import 'package:lottie/lottie.dart'; // مكتبة الأنيميشن
import 'package:url_launcher/url_launcher.dart'; // فتح روابط الخريطة
import '../../providers/app_riverpod.dart'; // مزود الحالة الرئيسي للتطبيق
import '../../models/app_models.dart'; // نماذج البيانات المستخدمة
import '../../widgets/taptaba_scaffold.dart'; // الهيكل الموحد للشاشة

class ProfileScreen extends ConsumerStatefulWidget {
  // شاشة الملف الشخصي العامة (لكل الأدوار)
  final String? overrideRole;
  const ProfileScreen({super.key, this.overrideRole}); // مشيد الفئة

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late List<Animation<double>> _fadeAnimations;
  bool _showSuccess = false;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200));

    _fadeAnimations = List.generate(5, (index) {
      return Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
          parent: _fadeController,
          curve: Interval(index * 0.15, 1.0, curve: Curves.easeOut),
        ),
      );
    });

    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  void _triggerSuccess() async {
    setState(() => _showSuccess = true);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      setState(() => _showSuccess = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // دالة بناء الواجهة
    final provider = ref.watch(appRiverpod); // مراقبة حالة التطبيق
    final account = provider.currentAccount; // جلب بيانات الحساب الحالي
    final role =
        widget.overrideRole ?? provider.currentRole; // جلب الدور الوظيفي الحالي
    final themeColor =
        _getRoleColor(role); // تحديد اللون الرئيسي بناءً على الدور

    return TaptabaScaffold(
      // استخدام الهيكل الموحد
      title: 'الملف الشخصي', // عنوان الشاشة
      titleColor: themeColor, // تلوين العنوان بلون الدور
      overrideRole: role, // تمرير الدور للقائمة الجانبية
      body: Stack(
        children: [
          SingleChildScrollView(
            // جعل المحتوى قابلاً للتمرير
            physics:
                const BouncingScrollPhysics(), // تأثير الارتداد عند التمرير
            child: Column(
              // ترتيب العناصر رأسياً
              children: [
                FadeTransition(
                  opacity: _fadeAnimations[0],
                  child: _buildHeroHeader(
                      context,
                      ref,
                      account,
                      role,
                      themeColor,
                      provider), // بناء الجزء العلوي (الصورة والاسم)
                ),
                Padding(
                  padding: const EdgeInsets.all(20.0), // هوامش داخلية
                  child: Column(
                    children: [
                      FadeTransition(
                        opacity: _fadeAnimations[1],
                        child: _buildStatsSection(
                            role, provider, themeColor), // قسم الإحصائيات
                      ),
                      const SizedBox(height: 30), // مسافة فاصلة
                      FadeTransition(
                        opacity: _fadeAnimations[2],
                        child: _buildInformationSection(context, ref, account,
                            role, themeColor), // قسم المعلومات الشخصية
                      ),
                      const SizedBox(height: 30), // مسافة فاصلة
                      FadeTransition(
                        opacity: _fadeAnimations[3],
                        child: _buildActionsSection(themeColor), // قسم الروابط
                      ),
                      const SizedBox(height: 50), // مسافة في النهاية
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (_showSuccess) _buildSuccessOverlay(),
        ],
      ),
    );
  }

  Color _getRoleColor(String role) {
    // دالة لتحديد اللون المميز لكل دور وظيفي
    switch (role) {
      case 'ممرض':
        return const Color(0xFF0369A1); // أزرق طبي
      case 'متطوع':
        return const Color(0xFF059669); // أخضر متطوع
      case 'عائلة':
        return const Color(0xFFea580c); // برتقالي عائلة
      case 'أخصائي':
      case 'أخصائي اجتماعي':
        return const Color(0xFFea580c); // برتقالي أخصائي
      case 'مدير':
      case 'إدارة':
        return const Color(0xFF1e293b); // كحلي مدير
      case 'مسن':
      default:
        return const Color(0xFF6C63FF); // موف مسن (خبير سعادة)
    }
  }

  Widget _buildHeroHeader(
      BuildContext context,
      WidgetRef ref,
      AppAccount? account,
      String role,
      Color themeColor,
      AppRiverpod provider) {
    // بناء الهيدر الفاخر بتدرج لوني
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 40, 20, 40),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          // تدرج لوني يعتمد على لون الدور
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [themeColor, themeColor.withValues(alpha: 0.8)],
        ),
        borderRadius: const BorderRadius.only(
          // حواف دائرية سفلية
          bottomLeft: Radius.circular(50),
          bottomRight: Radius.circular(50),
        ),
      ),
      child: Column(
        children: [
          Row(
            // شريط التحكم العلوي داخل الهيدر
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                // زر العودة
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: Colors.white),
              ),
              IconButton(
                // زر تسجيل الخروج السريع
                onPressed: () => _showLogoutDialog(context, ref),
                icon: const Icon(Icons.logout_rounded, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Stack(
            // عرض الصورة الشخصية مع زر التعديل
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                    color: Colors.white, shape: BoxShape.circle),
                child: account?.imageUrl != null &&
                        account!.imageUrl!.isNotEmpty
                    ? (account.imageUrl!.startsWith('http')
                        ? CircleAvatar(
                            radius: 55,
                            backgroundImage: NetworkImage(account.imageUrl!),
                          )
                        : CircleAvatar(
                            radius: 55,
                            backgroundImage: FileImage(File(account.imageUrl!)),
                          ))
                    : CircleAvatar(
                        radius: 55,
                        backgroundColor: themeColor.withValues(alpha: 0.2),
                        child: Text(
                          (account?.name != null && account!.name.isNotEmpty)
                              ? account.name.substring(0, 1)
                              : 'م',
                          style: TextStyle(
                              fontSize: 50,
                              fontWeight: FontWeight.bold,
                              color: themeColor),
                        ),
                      ),
              ),
              Positioned(
                // زر القلم لتعديل الصورة
                bottom: 5,
                right: 5,
                child: InkWell(
                  onTap: () => provider.pickProfileImage(),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                        color: themeColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3)),
                    child: const Icon(Icons.edit_rounded,
                        color: Colors.white, size: 20),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(account?.name ?? 'مستخدم',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w900)), // اسم المستخدم
          if (role == 'مدير' && account?.facilityName != null) ...[
            const SizedBox(height: 4),
            Text(account!.facilityName!,
                style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                    fontWeight: FontWeight.w500)),
          ],
          const SizedBox(height: 12),
          Container(
            // شارة توضح الدور الوظيفي
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
                role == 'مسن'
                    ? 'خبير سعادة'
                    : (role == 'مدير' ? 'مدير المنشأة' : role),
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection(
      String role, AppRiverpod provider, Color themeColor) {
    // بناء قسم الإحصائيات المتغير حسب الدور
    List<Map<String, dynamic>> stats = [];

    if (role == 'مسن') {
      // إحصائيات المسن
      stats = [
        {
          'label': 'النقاط',
          'value': '${provider.currentUser.points}',
          'icon': Icons.stars_rounded
        },
        {
          'label': 'الأنشطة',
          'value': '${provider.currentUser.completedActivities}',
          'icon': Icons.check_circle_rounded
        },
        {
          'label': 'الأيام',
          'value': '${provider.currentUser.streakDays}',
          'icon': Icons.calendar_today_rounded
        },
      ];
    } else if (role == 'متطوع') {
      // إحصائيات المتطوع
      stats = [
        {
          'label': 'الساعات',
          'value': '${provider.volunteerHours}',
          'icon': Icons.timer_rounded
        },
        {
          'label': 'المهام',
          'value': '${provider.volunteerBookings.length}',
          'icon': Icons.assignment_turned_in_rounded
        },
        {
          'label': 'التقييم',
          'value': '${provider.averageRating}',
          'icon': Icons.star_rounded
        },
      ];
    } else if (role == 'مدير' || role == 'إدارة') {
      // إحصائيات المدير
      stats = [
        {
          'label': 'النزلاء',
          'value': '${provider.residentFiles.length}',
          'icon': Icons.people_rounded
        },
        {
          'label': 'الموظفين',
          'value': '${provider.staffPerformanceList.length}',
          'icon': Icons.badge_rounded
        },
        {
          'label': 'التنبيهات',
          'value': '${provider.notifications.length}',
          'icon': Icons.notifications_active_rounded
        },
      ];
    } else if (role == 'ممرض' || role == 'أخصائي') {
      // إحصائيات الموظف
      stats = [
        {
          'label': 'الحالات',
          'value': '١٢',
          'icon': Icons.assignment_ind_rounded
        },
        {'label': 'المهام', 'value': '٨', 'icon': Icons.task_alt_rounded},
        {'label': 'التقييم', 'value': '٤.٩', 'icon': Icons.star_rounded},
      ];
    } else if (role == 'أسرة') {
      // إحصائيات الأسرة
      stats = [
        {'label': 'الحالة', 'value': 'مستقر', 'icon': Icons.favorite_rounded},
        {'label': 'زيارات', 'value': '٣', 'icon': Icons.calendar_month_rounded},
        {'label': 'تنبيهات', 'value': '٥', 'icon': Icons.notifications_rounded},
      ];
    } else {
      stats = [
        {'label': 'المركز', 'value': 'طبطبة', 'icon': Icons.business_rounded},
        {
          'label': 'الحالة',
          'value': 'نشط',
          'icon': Icons.check_circle_outline_rounded
        },
      ];
    }

    return Row(
      // عرض الكروت بجانب بعضها
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: stats.map((s) => _buildStatCard(s, themeColor)).toList(),
    );
  }

  Widget _buildStatCard(Map<String, dynamic> stat, Color themeColor) {
    // بناء كارت إحصائي واحد
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 5))
        ],
      ),
      child: Column(
        children: [
          Icon(stat['icon'],
              color: themeColor, size: 28), // الأيقونة بلون الدور
          const SizedBox(height: 8),
          Text(stat['value'],
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B))), // القيمة
          Text(stat['label'],
              style: const TextStyle(
                  fontSize: 10, color: Colors.grey)), // العنوان التوضيحي
        ],
      ),
    );
  }

  Widget _buildInformationSection(BuildContext context, WidgetRef ref,
      AppAccount? account, String role, Color themeColor) {
    // بناء قسم المعلومات الشخصية الأساسية
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('المعلومات الأساسية', themeColor,
            onEdit: role == 'مسن'
                ? null
                : () =>
                    _showEditPersonalDialog(context, ref, account, themeColor)),
        const SizedBox(height: 15),
        _buildInfoTile(Icons.person_outline, 'الاسم الكامل',
            account?.name ?? 'غير متوفر', themeColor,
            onTap: role == 'مسن'
                ? null
                : () =>
                    _showEditPersonalDialog(context, ref, account, themeColor)),
        _buildInfoTile(Icons.email_outlined, 'البريد الإلكتروني',
            account?.email ?? 'غير متوفر', themeColor,
            onTap: role == 'مسن'
                ? null
                : () =>
                    _showEditPersonalDialog(context, ref, account, themeColor)),
        _buildInfoTile(Icons.phone_outlined, 'رقم الهاتف',
            account?.phone ?? 'غير متوفر', themeColor,
            onTap: role == 'مسن'
                ? null
                : () =>
                    _showEditPersonalDialog(context, ref, account, themeColor)),
        const SizedBox(height: 30),
        if (role == 'مدير' || role == 'إدارة') ...[
          _buildSectionHeader('بيانات المنشأة (الدار)', themeColor,
              onEdit: () =>
                  _showEditFacilityDialog(context, ref, account, themeColor)),
          const SizedBox(height: 15),
          _buildInfoTile(Icons.apartment_rounded, 'اسم المنشأة',
              account?.facilityName ?? 'طبطبة', themeColor,
              onTap: () =>
                  _showEditFacilityDialog(context, ref, account, themeColor)),
          _buildInfoTile(Icons.location_on_outlined, 'عنوان المنشأة',
              account?.facilityAddress ?? 'لم يتم تحديده', themeColor,
              onTap: () =>
                  _showEditFacilityDialog(context, ref, account, themeColor)),
          _buildInfoTile(Icons.phone_android_rounded, 'رقم تواصل الدار',
              account?.facilityPhone ?? 'غير متوفر', themeColor,
              onTap: () =>
                  _showEditFacilityDialog(context, ref, account, themeColor)),
          _buildInfoTile(Icons.alternate_email_rounded, 'البريد الرسمي للدار',
              account?.facilityEmail ?? 'غير متوفر', themeColor,
              onTap: () =>
                  _showEditFacilityDialog(context, ref, account, themeColor)),
          _buildInfoTile(Icons.verified_user_rounded, 'رقم الترخيص الحكومي',
              account?.licenseNumber ?? 'جاري التحقق', themeColor,
              onTap: () =>
                  _showEditFacilityDialog(context, ref, account, themeColor)),
          _buildInfoTile(Icons.date_range_rounded, 'سنة الإنشاء',
              account?.facilityYearOfEst ?? 'غير محددة', themeColor,
              onTap: () =>
                  _showEditFacilityDialog(context, ref, account, themeColor)),
          _buildInfoTile(
              Icons.group_add_rounded,
              'السعة الاستيعابية',
              account?.facilityCapacity?.isNotEmpty == true
                  ? '${account!.facilityCapacity} مقيم'
                  : 'غير محددة',
              themeColor,
              onTap: () =>
                  _showEditFacilityDialog(context, ref, account, themeColor)),
          _buildInfoTile(
              Icons.map_rounded,
              'موقع الدار',
              account?.facilityLocationUrl?.isNotEmpty == true
                  ? 'اضغط لفتح الموقع'
                  : 'لم يتم تحديده',
              themeColor, onTap: () {
            final url = account?.facilityLocationUrl;
            if (url != null && url.isNotEmpty) {
              launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
            } else {
              _showEditFacilityDialog(context, ref, account, themeColor);
            }
          }),
          if (account?.amenities != null && account!.amenities!.isNotEmpty)
            _buildAmenitiesSection(account.amenities!, themeColor),
        ] else if (role == 'مسن') ...[
          _buildSectionHeader('بيانات الإقامة والرعاية', themeColor),
          const SizedBox(height: 15),
          _buildInfoTile(Icons.meeting_room_outlined, 'الغرفة والموقع',
              account?.room ?? 'جاري التسكين', themeColor),
          _buildInfoTile(Icons.bloodtype_outlined, 'فصيلة الدم',
              account?.bloodType ?? 'غير مسجل', themeColor),
          _buildInfoTile(Icons.directions_walk_rounded, 'الحالة الحركية',
              account?.mobilityStatus ?? 'مستقل', themeColor),
          _buildInfoTile(Icons.restaurant_rounded, 'النظام الغذائي',
              account?.dietType ?? 'عادي', themeColor),
          if (account?.chronicDiseases != null &&
              account!.chronicDiseases!.isNotEmpty)
            _buildListSection(
                'الأمراض المزمنة', account.chronicDiseases!, Colors.red),
          _buildInfoTile(Icons.business_rounded, 'المنشأة التابع لها',
              account?.facilityName ?? 'طبطبة', themeColor),
        ] else if (role == 'ممرض' || role == 'أخصائي') ...[
          _buildSectionHeader('البيانات الوظيفية', themeColor),
          const SizedBox(height: 15),
          _buildInfoTile(Icons.workspace_premium_outlined, 'التخصص الوظيفي',
              account?.specialty ?? 'طاقم رعاية', themeColor),
          _buildInfoTile(Icons.access_time_rounded, 'فترة العمل (الوردية)',
              account?.shift ?? 'غير محددة', themeColor),
          _buildInfoTile(Icons.business_rounded, 'جهة العمل',
              account?.facilityName ?? 'طبطبة', themeColor),
        ] else if (role == 'متطوع') ...[
          _buildSectionHeader('بيانات التطوع', themeColor),
          const SizedBox(height: 15),
          _buildInfoTile(
              Icons.volunteer_activism_outlined,
              'مجال التطوع الرئيسي',
              account?.specialty ?? 'دعم اجتماعي',
              themeColor),
          _buildInfoTile(Icons.history_edu_outlined, 'تاريخ الانضمام',
              '١٢ مارس ٢٠٢٤', themeColor),
        ] else if (role == 'أسرة') ...[
          _buildSectionHeader('بيانات المتابعة', themeColor),
          const SizedBox(height: 15),
          _buildInfoTile(Icons.family_restroom_rounded, 'القريب المتابع',
              'أ. محمود عبد العزيز (والد)', themeColor),
          _buildInfoTile(Icons.contact_phone_outlined, 'طوارئ المنشأة',
              account?.facilityName ?? 'طبطبة', themeColor),
          _buildInfoTile(Icons.verified_user_outlined, 'حالة التصريح',
              'نشط - دخول كامل', themeColor),
        ],
      ],
    );
  }

  Widget _buildListSection(String title, List<String> items, Color color) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(
                  fontSize: 10, color: color, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: items
                .map((a) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: color.withValues(alpha: 0.2)),
                      ),
                      child: Text(a,
                          style: TextStyle(
                              color: color,
                              fontSize: 11,
                              fontWeight: FontWeight.bold)),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildAmenitiesSection(List<String> amenities, Color themeColor) {
    return _buildListSection(
        'الخدمات والمميزات المتاحة', amenities, themeColor);
  }

  Widget _buildInfoTile(
      dynamic icon, String label, String value, Color themeColor,
      {VoidCallback? onTap}) {
    // بناء سطر معلومة واحدة بشكل واضح وقابل للتفاعل
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02), blurRadius: 5)
            ],
          ),
          child: Row(
            children: [
              Icon(icon, color: const Color(0xFF64748B), size: 22),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: const TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                            fontWeight: FontWeight.bold)), // مسمى الحقل
                    const SizedBox(height: 2),
                    Text(value,
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF1E293B))), // القيمة أوضح وأكبر
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionsSection(Color themeColor) {
    // بناء قسم الأفعال والإعدادات
    return Column(
      children: [
        _buildActionTile(
            Icons.settings_outlined, 'إعدادات الحساب'), // الإعدادات
        _buildActionTile(Icons.security_rounded, 'الأمان والخصوصية'), // الأمان
        _buildActionTile(
            Icons.help_outline_rounded, 'المساعدة والدعم'), // الدعم
      ],
    );
  }

  Widget _buildActionTile(dynamic icon, String label) {
    // بناء عنصر اختيار واحد (ListTile)
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF1E293B)),
        title: Text(label,
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
        trailing:
            const Icon(Icons.arrow_forward_ios_rounded, size: 14), // سهم التنقل
        onTap: () {},
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        tileColor: Colors.white,
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    // حوار تأكيد تسجيل الخروج
    final hc = ref.read(appRiverpod).isHighContrast;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: hc ? const Color(0xFF252525) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        title: Text('تأكيد الخروج',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontWeight: FontWeight.bold,
                color: hc ? Colors.white : Colors.black)),
        content: Text(
            'هل أنت متأكد أنك تريد تسجيل الخروج والعودة لصفحة الدخول؟',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 16, color: hc ? Colors.white70 : Colors.black87)),
        actionsPadding: const EdgeInsets.all(25),
        actions: [
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  // زر الموافقة على الخروج
                  onPressed: () {
                    Navigator.pop(ctx); // إغلاق الحوار
                    Navigator.pop(context); // العودة من شاشة البروفايل
                    ref
                        .read(appRiverpod)
                        .logout(); // تنفيذ عملية الخروج من النظام
                  },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFef4444),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15))),
                  child: const Text('نعم، اخرج',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16)),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: OutlinedButton(
                  // زر الإلغاء
                  onPressed: () => Navigator.pop(ctx),
                  style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      side: BorderSide(
                          color: hc ? Colors.white24 : const Color(0xFFcbd5e1)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15))),
                  child: Text('إلغاء',
                      style: TextStyle(
                          color: hc ? Colors.white60 : const Color(0xFF64748b),
                          fontWeight: FontWeight.bold,
                          fontSize: 16)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color themeColor,
      {VoidCallback? onEdit}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title,
            style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B))),
        if (onEdit != null)
          IconButton(
            onPressed: onEdit,
            icon: Icon(Icons.edit_note_rounded, size: 26, color: themeColor),
            constraints: const BoxConstraints(),
            padding: EdgeInsets.zero,
          ),
      ],
    );
  }

  void _showEditPersonalDialog(BuildContext context, WidgetRef ref,
      AppAccount? account, Color themeColor) {
    if (account == null) return;
    final nameController = TextEditingController(text: account.name);
    final phoneController = TextEditingController(text: account.phone);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
                width: 50,
                height: 5,
                decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(5))),
            const SizedBox(height: 20),
            const Text('تعديل البيانات الأساسية',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 25),
            _buildDialogField(nameController, 'الاسم الكامل',
                Icons.person_outline, themeColor),
            const SizedBox(height: 15),
            _buildDialogField(phoneController, 'رقم الهاتف',
                Icons.phone_outlined, themeColor),
            const SizedBox(height: 30),
            _buildSaveButton(context, themeColor, () async {
              final updated = account.copyWith(
                  name: nameController.text, phone: phoneController.text);
              ref.read(appRiverpod).updateCurrentAccount(updated);
              Navigator.pop(context);
              _triggerSuccess();
            }),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  void _showEditFacilityDialog(BuildContext context, WidgetRef ref,
      AppAccount? account, Color themeColor) {
    if (account == null) return;
    final nameController = TextEditingController(text: account.facilityName);
    final addrController = TextEditingController(text: account.facilityAddress);
    final phoneController = TextEditingController(text: account.facilityPhone);
    final emailController = TextEditingController(text: account.facilityEmail);
    final yearController =
        TextEditingController(text: account.facilityYearOfEst);
    final capacityController =
        TextEditingController(text: account.facilityCapacity);
    final licenseController =
        TextEditingController(text: account.licenseNumber);
    final locationController =
        TextEditingController(text: account.facilityLocationUrl);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                  width: 50,
                  height: 5,
                  decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(5))),
              const SizedBox(height: 20),
              const Text('تعديل بيانات المنشأة',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 25),
              _buildDialogField(nameController, 'اسم المنشأة',
                  Icons.apartment_rounded, themeColor),
              const SizedBox(height: 15),
              _buildDialogField(addrController, 'عنوان المنشأة',
                  Icons.location_on_outlined, themeColor),
              const SizedBox(height: 15),
              _buildDialogField(phoneController, 'رقم تواصل الدار',
                  Icons.phone_android_rounded, themeColor),
              const SizedBox(height: 15),
              _buildDialogField(emailController, 'البريد الرسمي',
                  Icons.alternate_email_rounded, themeColor),
              const SizedBox(height: 15),
              _buildDialogField(yearController, 'سنة الإنشاء',
                  Icons.date_range_rounded, themeColor),
              const SizedBox(height: 15),
              _buildDialogField(capacityController, 'السعة الاستيعابية',
                  Icons.group_add_rounded, themeColor),
              const SizedBox(height: 15),
              _buildDialogField(licenseController, 'رقم الترخيص',
                  Icons.verified_user_outlined, themeColor),
              const SizedBox(height: 15),
              _buildDialogField(locationController, 'رابط الموقع على الخريطة',
                  Icons.map_rounded, themeColor),
              const SizedBox(height: 30),
              _buildSaveButton(context, themeColor, () async {
                await ref.read(appRiverpod).updateFacilityProfileSettings(
                      account: account,
                      facilityName: nameController.text,
                      facilityAddress: addrController.text,
                      facilityPhone: phoneController.text,
                      facilityEmail: emailController.text,
                      licenseNumber: licenseController.text,
                      facilityYearOfEst: yearController.text,
                      facilityCapacity: capacityController.text,
                      facilityLocationUrl: locationController.text,
                    );
                if (!context.mounted) return;
                Navigator.pop(context);
                _triggerSuccess();
              }),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDialogField(TextEditingController controller, String label,
      IconData icon, Color themeColor) {
    return TextField(
      controller: controller,
      textAlign: TextAlign.right,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: themeColor),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: Colors.grey[300]!)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: Colors.grey[300]!)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: themeColor, width: 2)),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
      ),
    );
  }

  Widget _buildSaveButton(
      BuildContext context, Color themeColor, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: themeColor,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          elevation: 0,
        ),
        child: const Text('حفظ التغييرات',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white)),
      ),
    );
  }

  Widget _buildSuccessOverlay() {
    return Container(
      color: Colors.black.withValues(alpha: 0.3),
      child: Center(
        child: Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1), blurRadius: 20)
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Lottie.asset(
                'assets/animations/Done.json',
                width: 120,
                height: 120,
                repeat: false,
              ),
              const Text(
                'تم الحفظ بنجاح',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
