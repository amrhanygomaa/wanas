// ignore_for_file: unused_element
import 'dart:ui'; // مكتبة الواجهات المتقدمة للفلترة والضبابية
import 'dart:io'; // للتعامل مع ملفات الصور المحلية
import 'package:flutter/material.dart'; // مكتبة فلاتر الأساسية
import 'package:flutter_riverpod/flutter_riverpod.dart'; // مكتبة إدارة الحالة
import '../providers/app_riverpod.dart'; // مزود الحالة الرئيسي
import '../screens/common/profile_screen.dart'; // شاشة الملف الشخصي العامة
import '../screens/nurse/nurse_profile_screen.dart'; // شاشة الملف الشخصي للممرض
import '../screens/common/cloud_health_screen.dart';
import '../screens/common/real_residents_screen.dart';
import '../screens/common/real_notifications_screen.dart';
import 'accessibility_dialog.dart'; // حوار إعدادات سهولة الوصول
import 'cognito_user_card.dart';

class TaptabaDrawer extends ConsumerWidget {
  // فئة القائمة الجانبية الموحدة
  final String? overrideRole; // إمكانية تجاوز الدور الحالي للعرض
  const TaptabaDrawer({super.key, this.overrideRole}); // مشيد الفئة

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // دالة بناء الواجهة
    final provider = ref.watch(appRiverpod); // مراقبة حالة التطبيق
    final role = overrideRole ?? provider.currentRole; // تحديد الدور الوظيفي
    final themeColor = _getRoleColor(role); // اللون المميز حسب الدور
    final hc = provider.isHighContrast; // هل التباين العالي مفعل؟
    final isDark =
        Theme.of(context).brightness == Brightness.dark; // النمط الليلي

    return Drawer(
      // المكون الأساسي للقائمة
      width: MediaQuery.of(context).size.width * 0.85, // العرض
      backgroundColor: Colors.transparent, // خلفية شفافة
      elevation: 0, // إخفاء الظل
      child: Stack(
        // تكديس العناصر
        children: [
          // خلفية زجاجية فاخرة
          if (!hc) // إذا لم يكن التباين العالي مفعلاً
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12), // ضبابية
              child: Container(
                decoration: BoxDecoration(
                  color: (isDark ? const Color(0xFF0F172A) : themeColor)
                      .withValues(alpha: 0.05)
                      .withAlpha(240), // تلوين خفيف
                  borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(35),
                      bottomLeft: Radius.circular(35)), // حواف دائرية
                  border: Border(
                    // إطار جمالي
                    left: BorderSide(
                        color: themeColor.withValues(alpha: 0.3), width: 1.5),
                    top: BorderSide(
                        color:
                            Colors.white.withValues(alpha: isDark ? 0.05 : 0.2),
                        width: 1.5),
                    bottom: BorderSide(
                        color:
                            Colors.white.withValues(alpha: isDark ? 0.05 : 0.2),
                        width: 1.5),
                  ),
                ),
              ),
            )
          else // وضع التباين العالي
            Container(
              decoration: const BoxDecoration(
                color: Color(0xFF1E1E1E), // لون صلب
                borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(35),
                    bottomLeft: Radius.circular(35)), // حواف
              ),
            ),

          Column(
            // محتوى القائمة
            children: [
              _buildModernHeader(provider, role, themeColor), // رأس القائمة
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: (hc || isDark)
                        ? const Color(0xFF1E293B)
                        : Colors.white, // خلفية
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(35),
                    ),
                  ),
                  child: ListView(
                    // القائمة
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 15),
                    children: [
                      const CognitoUserCard(),
                      _buildPremiumMenuItem(
                        // زر الملف الشخصي
                        context,
                        Icons.person_outline_rounded,
                        'الحساب الشخصي',
                        () {
                          Navigator.pop(context); // إغلاق
                          Widget targetScreen;
                          if (role == 'ممرض') {
                            targetScreen =
                                const NurseProfileScreen(); // شاشة ممرض
                          } else {
                            targetScreen =
                                ProfileScreen(overrideRole: role); // شاشة عامة
                          }

                          Navigator.push(
                            // تنقل
                            context,
                            MaterialPageRoute(
                              builder: (context) => targetScreen,
                            ),
                          );
                        },
                        themeColor,
                        hc,
                      ),
                      _buildPremiumMenuItem(
                        // إعدادات الوصول
                        context,
                        Icons.text_fields_rounded,
                        'إعدادات الرؤية والخط',
                        () {
                          Navigator.pop(context); // إغلاق
                          showModalBottomSheet(
                              // حوار الوصول
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (ctx) => const AccessibilityDialog());
                        },
                        themeColor,
                        hc,
                      ),
                      _buildPremiumMenuItem(
                        context,
                        Icons.cloud_done_rounded,
                        'صحة السحابة (AWS)',
                        () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const CloudHealthScreen(),
                            ),
                          );
                        },
                        const Color(0xFFFF9900),
                        hc,
                      ),
                      _buildPremiumMenuItem(
                        context,
                        Icons.people_alt_rounded,
                        'المقيمون من AWS RDS',
                        () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const RealResidentsScreen(),
                            ),
                          );
                        },
                        const Color(0xFFFF9900),
                        hc,
                      ),
                      _buildPremiumMenuItem(
                        context,
                        Icons.notifications_active_rounded,
                        'الإشعارات من AWS RDS',
                        () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const RealNotificationsScreen(),
                            ),
                          );
                        },
                        const Color(0xFFFF9900),
                        hc,
                      ),
                      _buildPremiumMenuItem(
                        // مساعدة
                        context,
                        Icons.support_agent_rounded,
                        'مركز المساعدة',
                        () {},
                        themeColor,
                        hc,
                      ),
                      _buildPremiumMenuItem(
                        // معلومات
                        context,
                        Icons.info_outline_rounded,
                        'عن طبطبة',
                        () {},
                        themeColor,
                        hc,
                      ),
                      _buildPremiumLogoutBtn(context, ref, hc), // تسجيل خروج
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getRoleColor(String role) {
    // دالة الحصول على لون الدور
    switch (role) {
      case 'ممرض':
        return const Color(0xFF0369A1); // أزرق
      case 'متطوع':
        return const Color(0xFF059669); // أخضر
      case 'عائلة':
      case 'أخصائي':
        return const Color(0xFFEA580C); // برتقالي
      case 'مدير':
      case 'إدارة':
        return const Color(0xFF0F172A); // كحلي
      case 'مسن':
      default:
        return const Color(0xFF6C63FF); // موف
    }
  }

  List<Color> _getRoleGradient(String role) {
    // دالة الحصول على تدرج الدور
    switch (role) {
      case 'ممرض':
        return [
          const Color(0xFF0369A1),
          const Color(0xFF0EA5E9),
          const Color(0xFF38BDF8)
        ];
      case 'متطوع':
        return [
          const Color(0xFF064e3b),
          const Color(0xFF059669),
          const Color(0xFF10b981)
        ];
      case 'عائلة':
      case 'أخصائي':
        return [
          const Color(0xFFc2410c),
          const Color(0xFFea580c),
          const Color(0xFFf97316)
        ];
      case 'مدير':
      case 'إدارة':
        return [
          const Color(0xFF0f172a),
          const Color(0xFF1e293b),
          const Color(0xFF334155)
        ];
      case 'مسن':
      default:
        return [
          const Color(0xFF1a0533),
          const Color(0xFF3730a3),
          const Color(0xFF6C63FF)
        ];
    }
  }

  String _getRoleNameDisplay(String role) {
    // دالة الحصول على مسمى الدور
    switch (role) {
      case 'ممرض':
        return 'طاقم التمريض';
      case 'متطوع':
        return 'متطوع سعادة';
      case 'عائلة':
        return 'فرد من العائلة';
      case 'أخصائي':
        return 'أخصائي اجتماعي';
      case 'مدير':
      case 'إدارة':
        return 'مدير المركز';
      case 'مسن':
      default:
        return 'خبير سعادة';
    }
  }

  Widget _buildModernHeader(
      AppRiverpod provider, String role, Color themeColor) {
    // بناء هيدر القائمة
    final account = provider.currentAccount;
    return Container(
      padding: const EdgeInsets.fromLTRB(28, 70, 28, 40),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [themeColor, themeColor.withValues(alpha: 0.8)],
        ),
        borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(45)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                    color: Colors.white, shape: BoxShape.circle),
                child: account?.imageUrl != null &&
                        account!.imageUrl!.isNotEmpty
                    ? (account.imageUrl!.startsWith('http')
                        ? CircleAvatar(
                            radius: 35,
                            backgroundImage: NetworkImage(account.imageUrl!),
                          )
                        : CircleAvatar(
                            radius: 35,
                            backgroundImage: FileImage(File(account.imageUrl!)),
                          ))
                    : CircleAvatar(
                        radius: 35,
                        backgroundColor: themeColor.withValues(alpha: 0.2),
                        child: Text(
                          (account?.name != null && account!.name.isNotEmpty)
                              ? account.name.substring(0, 1)
                              : 'م',
                          style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: themeColor),
                        ),
                      ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(account?.name ?? 'مستخدم',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w900)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(15)),
                      child: Text(_getRoleNameDisplay(role),
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),
          _buildRoleQuickStat(role, provider),
        ],
      ),
    );
  }

  Widget _buildRoleQuickStat(String role, AppRiverpod provider) {
    // بناء إحصائية سريعة
    String label = 'إحصائيات';
    String value = 'متفاعل';
    IconData icon = Icons.analytics_rounded;

    if (role == 'مسن') {
      label = 'النقاط';
      value = '${provider.currentUser.points}';
      icon = Icons.stars_rounded;
    } else if (role == 'متطوع') {
      label = 'ساعات';
      value = '${provider.volunteerHours}';
      icon = Icons.timer_rounded;
    }

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white, size: 28),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(color: Colors.white, fontSize: 10)),
              Text(value,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumMenuItem(BuildContext context, IconData icon,
      String label, VoidCallback onTap, Color themeColor, bool hc) {
    // بناء عنصر قائمة
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: (hc || isDark) ? Colors.white : themeColor),
      title: Text(label,
          style:
              TextStyle(color: (hc || isDark) ? Colors.white : Colors.black87)),
    );
  }

  Widget _buildPremiumLogoutBtn(BuildContext context, WidgetRef ref, bool hc) {
    // بناء زر خروج
    return ListTile(
      onTap: () => ref.read(appRiverpod).logout(),
      leading: const Icon(Icons.logout, color: Colors.red),
      title: const Text('تسجيل الخروج', style: TextStyle(color: Colors.red)),
    );
  }
}
