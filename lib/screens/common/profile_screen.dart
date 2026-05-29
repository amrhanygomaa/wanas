import 'dart:io'; // للتعامل مع ملفات الصور المحلية
import 'package:flutter/material.dart'; // مكتبة فلاتر الأساسية للواجهات
import 'package:flutter_riverpod/flutter_riverpod.dart'; // مكتبة إدارة الحالة
import 'package:lottie/lottie.dart'; // مكتبة الأنيميشن
import 'package:url_launcher/url_launcher.dart'; // لفتح الروابط الجغرافية
import '../../providers/app_riverpod.dart'; // مزود الحالة الرئيسي للتطبيق
import '../../models/app_models.dart'; // نماذج البيانات المستخدمة
import '../../widgets/taptaba_scaffold.dart'; // الهيكل الموحد للشاشة
import 'account_settings_screen.dart';
import 'privacy_screen.dart';
import 'help_support_screen.dart';

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
      // استخدام الهيكل الموحد مع إخفاء الـ AppBar الافتراضي لمطابقة تصميم الممرض
      hideAppBar: true,
      overrideRole: role, // تمرير الدور للقائمة الجانبية
      body: Stack(
        children: [
          CustomScrollView(
            // جعل المحتوى قابلاً للتمرير بتأثير الارتداد
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildHeroHeader(context, ref, account, role, themeColor,
                  provider), // بناء شريط العنوان الممتد الموحد
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20.0), // هوامش جانبية
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
              ),
            ],
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
    // 1. Determine dynamic multi-color gradient based on role
    List<Color> gradientColors = [
      themeColor,
      themeColor.withValues(alpha: 0.8)
    ];
    switch (role) {
      case 'ممرض':
        gradientColors = const [
          Color(0xFF0369A1),
          Color(0xFF0EA5E9),
          Color(0xFF06B6D4)
        ];
        break;
      case 'متطوع':
        gradientColors = const [
          Color(0xFF047857),
          Color(0xFF10B981),
          Color(0xFF34D399)
        ];
        break;
      case 'عائلة':
        gradientColors = const [
          Color(0xFFC2410C),
          Color(0xFFF97316),
          Color(0xFFFF9F1C)
        ];
        break;
      case 'أخصائي':
      case 'أخصائي اجتماعي':
        gradientColors = const [
          Color(0xFFEA580C),
          Color(0xFFF97316),
          Color(0xFFFBBF24)
        ];
        break;
      case 'مدير':
      case 'إدارة':
        gradientColors = const [
          Color(0xFF0F172A),
          Color(0xFF1E293B),
          Color(0xFF475569)
        ];
        break;
      case 'مسن':
      default:
        gradientColors = const [
          Color(0xFF4F46E5),
          Color(0xFF6366F1),
          Color(0xFF818CF8)
        ];
        break;
    }

    // 2. Determine dynamic role-specific subtitle
    String dynamicSubtitle = '';
    switch (role) {
      case 'ممرض':
        dynamicSubtitle = account?.specialty != null
            ? '${account?.specialty} — الوردية ${account?.shift ?? "الصباحية"}'
            : 'مشرف تمريض — الوردية الصباحية';
        break;
      case 'أخصائي':
      case 'أخصائي اجتماعي':
        dynamicSubtitle = account?.specialty != null
            ? 'أخصائي ${account?.specialty} — المستوى الذهبي'
            : 'أخصائي اجتماعي — المستوى الذهبي';
        break;
      case 'مسن':
        dynamicSubtitle = 'خبير سعادة — الغرفة ${account?.room ?? "104"}';
        break;
      case 'مدير':
      case 'إدارة':
        dynamicSubtitle =
            'مدير المنشأة — ${account?.facilityName ?? (provider.facilityName.isEmpty ? "المنشأة" : provider.facilityName)}';
        break;
      case 'عائلة':
        dynamicSubtitle =
            'حساب العائلة — قريب المقيم: ${provider.residentFiles.isNotEmpty ? provider.residentFiles.first.name : "بانتظار بيانات AWS"}';
        break;
      case 'متطوع':
      default:
        dynamicSubtitle = 'سفير السعادة — ${provider.volunteerHours} ساعة تطوع';
        break;
    }

    // 3. Determine dynamic badge membership/employee code
    String dynamicCode = '#N-4892';
    String codeLabel = 'كود الموظف';
    switch (role) {
      case 'ممرض':
        dynamicCode = '#N-4892';
        codeLabel = 'كود الموظف';
        break;
      case 'أخصائي':
      case 'أخصائي اجتماعي':
        dynamicCode = '#S-3819';
        codeLabel = 'كود الأخصائي';
        break;
      case 'مسن':
        dynamicCode = '#E-2082';
        codeLabel = 'كود خبير السعادة';
        break;
      case 'مدير':
      case 'إدارة':
        dynamicCode = '#M-9021';
        codeLabel = 'كود المدير';
        break;
      case 'عائلة':
        dynamicCode = '#F-5521';
        codeLabel = 'كود العائلة';
        break;
      case 'متطوع':
      default:
        dynamicCode = '#V-7712';
        codeLabel = 'كود المتطوع';
        break;
    }

    return SliverAppBar(
      expandedHeight: 280,
      pinned: true,
      elevation: 0,
      backgroundColor: gradientColors.first,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(
          onPressed: () => _showLogoutDialog(context, ref),
          icon: const Icon(Icons.logout_rounded, color: Colors.white),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradientColors,
            ),
          ),
          child: Stack(
            children: [
              // Dynamic Role-based Particles Background Animation
              RoleParticles(role: role),

              // Header Content
              Positioned.fill(
                child: FadeTransition(
                  opacity: _fadeAnimations[0],
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 35),

                      // Styled Centered Avatar with White Outline
                      Stack(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 8,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: account?.imageUrl != null &&
                                    account!.imageUrl!.isNotEmpty
                                ? (account.imageUrl!.startsWith('http')
                                    ? CircleAvatar(
                                        radius: 50,
                                        backgroundImage:
                                            NetworkImage(account.imageUrl!),
                                      )
                                    : CircleAvatar(
                                        radius: 50,
                                        backgroundImage:
                                            FileImage(File(account.imageUrl!)),
                                      ))
                                : CircleAvatar(
                                    radius: 50,
                                    backgroundColor:
                                        themeColor.withValues(alpha: 0.2),
                                    child: Text(
                                      (account != null &&
                                              account.name.isNotEmpty)
                                          ? account.name.substring(0, 1)
                                          : 'م',
                                      style: TextStyle(
                                          fontSize: 46,
                                          fontWeight: FontWeight.bold,
                                          color: themeColor),
                                    ),
                                  ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: InkWell(
                              onTap: () => provider.pickProfileImage(),
                              child: Container(
                                padding: const EdgeInsets.all(7),
                                decoration: BoxDecoration(
                                  color: themeColor,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: Colors.white, width: 2.5),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Colors.black12,
                                      blurRadius: 4,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Icon(Icons.edit_rounded,
                                    color: Colors.white, size: 16),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Name Text
                      Text(
                        account?.name ?? 'مستخدم',
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(
                              color: Colors.black26,
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                      ),

                      // Role Subtitle
                      Text(
                        dynamicSubtitle,
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 15,
                          fontWeight: FontWeight.normal,
                          shadows: const [
                            Shadow(
                              color: Colors.black12,
                              blurRadius: 3,
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Employee/Member Code Capsule Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '$codeLabel: $dynamicCode',
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
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
        {'label': 'المركز', 'value': 'ونس', 'icon': Icons.business_rounded},
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
              account?.facilityName ?? 'ونس', themeColor,
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
              (account != null &&
                      account.facilityCapacity != null &&
                      account.facilityCapacity!.isNotEmpty)
                  ? '${account.facilityCapacity} مقيم'
                  : 'غير محددة',
              themeColor,
              onTap: () =>
                  _showEditFacilityDialog(context, ref, account, themeColor)),
          _buildInfoTile(
              Icons.map_rounded,
              'موقع الدار على الخريطة',
              (account != null &&
                      account.facilityLocationUrl != null &&
                      account.facilityLocationUrl!.isNotEmpty)
                  ? 'اضغط لفتح الموقع 📍'
                  : 'لم يتم تحديده',
              themeColor, onTap: () {
            if (account != null &&
                account.facilityLocationUrl != null &&
                account.facilityLocationUrl!.isNotEmpty) {
              launchUrl(Uri.parse(account.facilityLocationUrl!));
            } else {
              _showEditFacilityDialog(context, ref, account, themeColor);
            }
          }),
          if (account != null &&
              account.amenities != null &&
              account.amenities!.isNotEmpty)
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
              account?.facilityName ?? 'ونس', themeColor),
        ] else if (role == 'ممرض' || role == 'أخصائي') ...[
          _buildSectionHeader('البيانات الوظيفية', themeColor),
          const SizedBox(height: 15),
          _buildInfoTile(Icons.workspace_premium_outlined, 'التخصص الوظيفي',
              account?.specialty ?? 'طاقم رعاية', themeColor),
          _buildInfoTile(Icons.access_time_rounded, 'فترة العمل (الوردية)',
              account?.shift ?? 'غير محددة', themeColor),
          _buildInfoTile(Icons.business_rounded, 'جهة العمل',
              account?.facilityName ?? 'ونس', themeColor),
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
          _buildInfoTile(
              Icons.family_restroom_rounded,
              'القريب المتابع',
              ref.read(appRiverpod).residentFiles.isNotEmpty
                  ? ref.read(appRiverpod).residentFiles.first.name
                  : 'بانتظار بيانات AWS',
              themeColor),
          _buildInfoTile(Icons.contact_phone_outlined, 'طوارئ المنشأة',
              account?.facilityName ?? 'ونس', themeColor),
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
    return Column(
      children: [
        _buildActionTile(
          Icons.settings_outlined,
          'إعدادات الحساب',
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const AccountSettingsScreen())),
        ),
        _buildActionTile(
          Icons.security_rounded,
          'الأمان والخصوصية',
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const PrivacyScreen())),
        ),
        _buildActionTile(
          Icons.help_outline_rounded,
          'المساعدة والدعم',
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const HelpSupportScreen())),
        ),
      ],
    );
  }

  Widget _buildActionTile(IconData icon, String label,
      {required VoidCallback onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF1E293B)),
        title: Text(label,
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
        onTap: onTap,
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
              _buildDialogField(locationController,
                  'رابط الموقع على خرائط جوجل', Icons.map_rounded, themeColor),
              const SizedBox(height: 30),
              _buildSaveButton(context, themeColor, () async {
                final updated = account.copyWith(
                  facilityName: nameController.text,
                  facilityAddress: addrController.text,
                  facilityPhone: phoneController.text,
                  facilityEmail: emailController.text,
                  facilityYearOfEst: yearController.text,
                  facilityCapacity: capacityController.text,
                  licenseNumber: licenseController.text,
                  facilityLocationUrl: locationController.text,
                );
                ref.read(appRiverpod).updateCurrentAccount(updated);
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

class RoleParticles extends StatefulWidget {
  final String role;
  const RoleParticles({super.key, required this.role});

  @override
  State<RoleParticles> createState() => _RoleParticlesState();
}

class _RoleParticlesState extends State<RoleParticles>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    IconData particleIcon = Icons.add_rounded;
    Color particleColor = Colors.white;

    switch (widget.role) {
      case 'مسن':
        particleIcon = Icons.star_rounded;
        particleColor = const Color(0xFFFFD700); // ذهبي للمسن
        break;
      case 'متطوع':
        particleIcon = Icons.favorite_rounded;
        particleColor = const Color(0xFFD1FAE5); // أخضر فاتح للمتطوع
        break;
      case 'عائلة':
        particleIcon = Icons.favorite_rounded;
        particleColor = const Color(0xFFFFE4E6); // وردي دافئ للعائلة
        break;
      case 'أخصائي':
      case 'أخصائي اجتماعي':
        particleIcon = Icons.auto_awesome_rounded;
        particleColor = const Color(0xFFFEF3C7); // أمبر دافئ للأخصائي
        break;
      case 'مدير':
      case 'إدارة':
        particleIcon = Icons.shield_rounded;
        particleColor = const Color(0xFFE2E8F0); // سيلفر خفيف للمدير
        break;
      case 'ممرض':
      default:
        particleIcon = Icons.add_rounded;
        particleColor = Colors.white;
        break;
    }

    return Positioned.fill(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Stack(
            children: List.generate(8, (index) {
              final speed = 0.8 + (index * 0.25);
              final progress =
                  (_controller.value * speed + (index * 0.15)) % 1.0;

              // توزيع أفقي مختلف لكل جسيم
              final leftOffset = 15.0 + (index * 48.0) % 360;

              return Positioned(
                left: leftOffset,
                bottom: (progress * 260) - 35, // ترتفع بهدوء وتختفي
                child: Opacity(
                  opacity: (1.0 - progress) * 0.22, // تتلاشى تدريجياً
                  child: Transform.rotate(
                    angle: progress *
                        2.0 *
                        3.1415, // دوران خفيف يعطي إحساساً بالحيوية
                    child: Icon(
                      particleIcon,
                      size: 16.0 + (index * 8) % 24, // أحجام عشوائية متناسقة
                      color: particleColor,
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
