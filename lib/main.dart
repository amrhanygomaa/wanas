import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart'; // مكتبة فلاتر الأساسية
import 'firebase_options.dart';
import 'package:flutter/services.dart'; // مكتبة التحكم في خصائص النظام
import 'package:flutter_localizations/flutter_localizations.dart'; // دعم اللغة العربية
import 'package:flutter_riverpod/flutter_riverpod.dart'; // مكتبة إدارة الحالة
import 'nav_wrapper.dart'; // غلاف التنقل
import 'screens/auth/login_screen.dart'; // شاشة تسجيل الدخول
import 'screens/nurse/nurse_dashboard_screen.dart'; // لوحة تحكم الممرض
import 'screens/volunteer/volunteer_dashboard_screen.dart'; // لوحة تحكم المتطوع
import 'screens/family/family_dashboard_screen.dart'; // لوحة تحكم الأسرة
import 'screens/specialist/specialist_dashboard_screen.dart'; // لوحة تحكم الأخصائي
import 'screens/admin/admin_dashboard_screen.dart'; // لوحة تحكم الإدارة
import 'screens/onboarding/onboarding_screen.dart'; // شاشة البداية
import 'screens/onboarding/splash_screen.dart'; // شاشة تحميل ونس
import 'providers/app_riverpod.dart'; // مزود الحالة
import 'services/notification_service.dart'; // خدمة التنبيهات;
import 'services/app_navigation_service.dart';

/* 
 * الدالة الرئيسية لتشغيل التطبيق:
 * 1. تهيئة بيئة النظام لضمان عمل الأدوات بشكل صحيح.
 * 2. تثبيت اتجاه الشاشة على الوضع الطولي (Portrait) فقط.
 * 3. تفعيل ProviderScope لربط إدارة الحالة بالتطبيق.
 */
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // تهيئة Firebase (لازم قبل أي شيء)
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerStatefulWidget {
  // المكون الرئيسي
  const MyApp({super.key}); // مشيد الفئة

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  @override
  void initState() {
    super.initState();
    unawaited(_initializeNotificationsOnce());
  }

  Future<void> _initializeNotificationsOnce() async {
    final provider = ref.read(appRiverpod);
    final notifService = ref.read(notificationServiceProvider);
    await notifService.initialize(ref);
    provider.scheduleMedicationReminders(notifService);
  }

  @override
  Widget build(BuildContext context) {
    // بناء واجهة المستخدم
    final provider = ref.watch(appRiverpod); // مراقبة الحالة

    Widget getHomeWidget() {
      // شاشة تحميل لطيفة حتى تكتمل قراءة الجلسة والبيانات من التخزين/الباك اند.
      if (!provider.isInitialized) {
        return const WanasSplashScreen();
      }

      // تحديد الشاشة الحالية بناءً على حالة المستخدم
      if (!provider.hasSeenOnboarding) {
        return const OnboardingScreen(); // فحص شاشة البداية
      }
      if (!provider.isAuthenticated) {
        return const LoginScreen(); // فحص تسجيل الدخول
      }

      switch (provider.currentRole) {
        // فحص دور المستخدم وتوجيهه لشاشته
        case 'ممرض':
          return const NurseDashboardScreen();
        case 'متطوع':
          return const VolunteerDashboardScreen();
        case 'مسن':
          return const NavWrapper();
        case 'أخصائي اجتماعي':
          return const SocialSpecialistDashboardScreen();
        case 'أسرة':
          return const FamilyDashboardScreen();
        case 'إدارة':
          return const AdminDashboardScreen();
        default:
          return const LoginScreen();
      }
    }

    return MaterialApp(
      navigatorKey: AppNavigationService.navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'ونس',
      // ── Arabic RTL Configuration ──────────────────────────────
      locale: const Locale('ar', 'SA'),
      supportedLocales: const [Locale('ar', 'SA')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      // ────────────────────────────────────────────────────────────
      themeMode: (provider.isDarkMode || provider.isHighContrast)
          ? ThemeMode.dark
          : ThemeMode.light,
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl, // إجبار اتجاه اليمين لليسار
          child: Stack(
            children: [
              MediaQuery(
                data: MediaQuery.of(context).copyWith(
                    textScaler: TextScaler.linear(provider.fontScaleFactor)),
                child: child!,
              ),
              if (provider.isRefreshingSession) _buildRefreshOverlay(),
            ],
          ),
        );
      },
      theme: ThemeData(
        fontFamily: 'Cairo',
        useMaterial3: true,
        brightness: Brightness.light,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        // ضبط اتجاه النص في الثيم
        typography: Typography.material2021(platform: TargetPlatform.android),
      ),
      home: getHomeWidget(),
    );
  }

  Widget _buildRefreshOverlay() {
    return Container(
      color: Colors.black.withValues(alpha: 0.5),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(20)),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: Color(0xFF6C63FF)),
              SizedBox(height: 16),
              Text('جاري تحديث الجلسة...',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black)),
              Text('برجاء الانتظار لحظة واحدة',
                  style: TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }
}
