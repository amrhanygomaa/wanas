import 'dart:math'; // مكتبة الرياضيات للعمليات الحسابية
import 'package:flutter/material.dart'; // مكتبة فلاتر الأساسية للواجهات
import 'package:flutter_riverpod/flutter_riverpod.dart'; // مكتبة إدارة الحالة ريفربود
import 'dart:ui'; // مكتبة لواجهات المستخدم المتقدمة مثل البلور
import 'package:url_launcher/url_launcher.dart'; // لفتح روابط الخرائط

import '../../providers/app_riverpod.dart'; // استيراد مزود الحالة الخاص بالتطبيق
import 'register_screen.dart'; // استيراد شاشة التسجيل الجديدة

class LoginScreen extends ConsumerStatefulWidget {
  // شاشة تسجيل الدخول كمكون تفاعلي مع ريفربود
  const LoginScreen({super.key}); // مشيد الفئة

  @override
  ConsumerState<LoginScreen> createState() =>
      _LoginScreenState(); // إنشاء حالة المكون
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with TickerProviderStateMixin {
  // حالة الشاشة مع دعم الأنيميشن
  late AnimationController _bgController; // متحكم أنيميشن الخلفية المتحركة
  late AnimationController _fadeController; // متحكم أنيميشن الظهور التدريجي
  late List<Animation<double>> _fadeAnimations; // قائمة حركات الظهور للعناصر
  late TextEditingController
      _identifierController; // متحكم حقل المعرف (هاتف أو إيميل)
  late TextEditingController _passwordController; // متحكم حقل كلمة المرور

  @override
  void initState() {
    // دالة تهيئة الحالة عند بدء الشاشة
    super.initState(); // استدعاء دالة التهيئة الأصلية
    _identifierController = TextEditingController(); // تهيئة متحكم المعرف
    _passwordController = TextEditingController(); // تهيئة متحكم كلمة المرور

    _bgController = AnimationController(
      // إعداد متحكم الخلفية
      vsync: this, // المزامنة مع الشاشة
      duration: const Duration(seconds: 15), // مدة الحركة 15 ثانية
    )..repeat(); // تكرار الحركة باستمرار

    _fadeController = AnimationController(
      // إعداد متحكم الظهور التدريجي
      vsync: this, // المزامنة مع الشاشة
      duration: const Duration(seconds: 1), // مدة الظهور ثانية واحدة
    );

    _fadeAnimations = List.generate(
      // توليد حركات الظهور للعناصر بشكل متتابع
      6, // عدد العناصر التي ستتحرك
      (index) => Tween<double>(begin: 0, end: 1).animate(
        // الحركة من اختفاء إلى ظهور
        CurvedAnimation(
          // نوع منحنى الحركة
          parent: _fadeController, // المتحكم الأب
          curve: Interval(index * 0.1, 1.0,
              curve: Curves.easeOut), // توقيت كل عنصر
        ),
      ),
    );
    _fadeController.forward(); // البدء في تنفيذ أنيميشن الظهور
  }

  @override
  void dispose() {
    // دالة تنظيف الموارد عند إغلاق الشاشة
    _bgController.dispose(); // إغلاق متحكم الخلفية
    _fadeController.dispose(); // إغلاق متحكم الظهور
    _identifierController.dispose(); // إغلاق متحكم المعرف
    _passwordController.dispose(); // إغلاق متحكم كلمة المرور
    super.dispose(); // استدعاء دالة التنظيف الأصلية
  }

  @override
  Widget build(BuildContext context) {
    // دالة بناء واجهة الشاشة
    final size = MediaQuery.of(context).size; // الحصول على حجم الشاشة الحالي
    return Scaffold(
      // الهيكل الأساسي للصفحة
      body: Stack(
        // تكديس العناصر فوق بعضها (الخلفية ثم المحتوى)
        children: [
          // Animated Background - الخلفية المتحركة
          AnimatedBuilder(
            // باني واجهات يعتمد على الأنيميشن
            animation: _bgController, // ربط الباني بمتحكم الخلفية
            builder: (context, child) {
              // دالة بناء عناصر الخلفية
              return Stack(
                // تكديس الطبقات اللونية
                children: [
                  Container(
                    // وعاء الطبقة الأساسية للتدرج اللوني
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        // تدرج لوني خطي
                        begin: Alignment.topLeft, // البداية من أعلى اليسار
                        end: Alignment.bottomRight, // النهاية في أسفل اليمين
                        colors: [
                          Color(0xFFeef2ff), // لون فاتح أول
                          Color(0xFFe0e7ff), // لون فاتح ثانٍ
                          Color(0xFFf3e8ff), // لون مائل للبنفسجي
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    // تحديد موقع الدائرة الأولى المتحركة
                    top: -100 +
                        sin(_bgController.value * 2 * pi) *
                            50, // حركة رأسية جيبية
                    left: -50 +
                        cos(_bgController.value * 2 * pi) *
                            50, // حركة أفقية جيبية
                    child: Container(
                      // وعاء الدائرة الأولى
                      width: size.width * 0.8, // عرض الدائرة 80% من الشاشة
                      height: size.width * 0.8, // ارتفاع الدائرة
                      decoration: BoxDecoration(
                        shape: BoxShape.circle, // شكل دائري
                        gradient: RadialGradient(
                          // تدرج لوني دائري
                          colors: [
                            const Color(0xFF818cf8).withValues(
                                alpha: 0.4), // لون الدائرة مع شفافية
                            Colors.transparent, // تلاشي إلى الشفافية
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    // تحديد موقع الدائرة الثانية المتحركة
                    bottom: -150 +
                        cos(_bgController.value * 2 * pi) *
                            70, // حركة أسفل الشاشة
                    right: -100 +
                        sin(_bgController.value * 2 * pi) *
                            70, // حركة يمين الشاشة
                    child: Container(
                      // وعاء الدائرة الثانية
                      width: size.width * 0.9, // عرض أكبر قليلاً
                      height: size.width * 0.9, // ارتفاع الدائرة
                      decoration: BoxDecoration(
                        shape: BoxShape.circle, // شكل دائري
                        gradient: RadialGradient(
                          // تدرج لوني دائري
                          colors: [
                            const Color(0xFFc084fc)
                                .withValues(alpha: 0.4), // لون بنفسجي مع شفافية
                            Colors.transparent, // تلاشي إلى الشفافية
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),

          // Blur Effect - تأثير الضبابية للزجاج
          Positioned.fill(
            // تغطية كامل الشاشة
            child: BackdropFilter(
              // فلتر لخلفية العناصر
              filter:
                  ImageFilter.blur(sigmaX: 30, sigmaY: 30), // شدة الضبابية 30
              child: Container(
                  color: Colors.white
                      .withValues(alpha: 0.1)), // لون أبيض خفيف جداً
            ),
          ),

          // Content - المحتوى الأساسي
          SafeArea(
            // التأكد من عدم تداخل المحتوى مع حواف الهاتف (النوتش)
            child: Center(
              // توسيط المحتوى في الشاشة
              child: SingleChildScrollView(
                // السماح بالتمرير عند صغر الشاشة
                padding: const EdgeInsets.symmetric(
                    horizontal: 24), // حواف جانبية 24
                child: Column(
                  // ترتيب العناصر رأسياً
                  mainAxisAlignment: MainAxisAlignment.center, // توسيط رأسي
                  crossAxisAlignment:
                      CrossAxisAlignment.stretch, // تمديد العناصر أفقياً
                  children: [
                    FadeTransition(
                      // أنيميشن ظهور الشعار
                      opacity: _fadeAnimations[0], // استخدام أول حركة ظهور
                      child: Column(
                        // عمود للشعار والاسم
                        children: [
                          Container(
                            // وعاء أيقونة التطبيق
                            padding: const EdgeInsets.all(
                                16), // حواف داخلية للأيقونة
                            decoration: BoxDecoration(
                              color: Colors.white, // خلفية بيضاء للأيقونة
                              shape: BoxShape.circle, // شكل دائري
                              boxShadow: [
                                // ظل خفيف للأيقونة
                                BoxShadow(
                                  color: const Color(0xFF6C63FF)
                                      .withValues(alpha: 0.2), // لون الظل
                                  blurRadius: 24, // مدى الظل
                                  offset: const Offset(0, 8), // موقع الظل
                                ),
                              ],
                            ),
                            child: const Icon(
                              // أيقونة الصحة والأمان
                              Icons.health_and_safety,
                              size: 56, // حجم الأيقونة
                              color: Color(0xFF6C63FF), // لون الأيقونة
                            ),
                          ),
                          const SizedBox(height: 24), // مسافة فارغة
                          const Text(
                            // نص اسم التطبيق "ونس"
                            'ونس',
                            textAlign: TextAlign.center, // توسيط النص
                            style: TextStyle(
                              fontSize: 36, // حجم خط كبير
                              fontWeight: FontWeight.w900, // خط عريض جداً
                              color: Color(0xFF1e1b4b), // لون داكن
                              letterSpacing: 1.5, // تباعد الحروف
                            ),
                          ),
                          const SizedBox(height: 8), // مسافة فارغة
                          const Text(
                            // نص وصفي للتطبيق
                            'نظام ونس للمسنين الذكي',
                            textAlign: TextAlign.center, // توسيط النص
                            style: TextStyle(
                              fontSize: 16, // حجم خط متوسط
                              color: Color(0xFF4f46e5), // لون أزرق مريح
                              fontWeight: FontWeight.w600, // خط شبه عريض
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 48), // مسافة قبل الكارت الأساسي

                    // Glassmorphic Card - كارت إدخال البيانات الزجاجي
                    FadeTransition(
                      // أنيميشن ظهور الكارت
                      opacity: _fadeAnimations[1], // ثاني حركة ظهور
                      child: Container(
                        // وعاء محتوى تسجيل الدخول
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(
                              alpha: 0.7), // أبيض شفاف (تأثير الزجاج)
                          borderRadius:
                              BorderRadius.circular(32), // حواف دائرية كبيرة
                          border: Border.all(
                              color: Colors.white, width: 2), // إطار أبيض ناصع
                          boxShadow: [
                            // ظل عميق للكارت
                            BoxShadow(
                              color: const Color(0xFF312e81)
                                  .withValues(alpha: 0.08), // لون ظل نيلي خفيف
                              blurRadius: 32, // مدى تلاشي الظل
                              offset: const Offset(0, 16), // إزاحة الظل للأسفل
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(24), // حواف داخلية للكارت
                        child: Column(
                          // عناصر الكارت الداخلية
                          crossAxisAlignment:
                              CrossAxisAlignment.end, // محاذاة لليمين (عربي)
                          children: [
                            const Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                'تسجيل الدخول',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1e1b4b),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24), // مسافة فارغة

                            const SizedBox(
                                height:
                                    8), // مسافة بسيطة بدلاً من اختيار الأدوار

                            // Inputs - حقول الإدخال
                            FadeTransition(
                              // أنيميشن ظهور حقل المعرف
                              opacity: _fadeAnimations[3], // رابع حركة ظهور
                              child: _buildInput(
                                // بناء حقل إدخال مخصص
                                controller:
                                    _identifierController, // ربط متحكم المعرف
                                label:
                                    'البريد الإلكتروني أو رقم الهاتف', // نص تلميحي
                                icon: Icons
                                    .person_outline_rounded, // أيقونة الشخص
                              ),
                            ),
                            const SizedBox(height: 16), // مسافة بين الحقول

                            FadeTransition(
                              // أنيميشن ظهور حقل كلمة المرور
                              opacity: _fadeAnimations[
                                  3], // نفس توقيت ظهور الحقل السابق
                              child: _buildInput(
                                // بناء حقل إدخال مخصص
                                controller:
                                    _passwordController, // ربط متحكم كلمة المرور
                                label: 'كلمة المرور', // نص تلميحي
                                icon:
                                    Icons.lock_outline_rounded, // أيقونة القفل
                                isPassword: true, // تفعيل خاصية إخفاء النص
                              ),
                            ),
                            const SizedBox(height: 32), // مسافة قبل زر الدخول

                            // Login Button - زر تسجيل الدخول
                            FadeTransition(
                              // أنيميشن ظهور زر الدخول
                              opacity: _fadeAnimations[4], // خامس حركة ظهور
                              child: GestureDetector(
                                // كاشف للمسات المستخدم
                                onTap: () async {
                                  final success =
                                      await ref.read(appRiverpod).login(
                                            _identifierController.text,
                                            _passwordController.text,
                                          );
                                  if (!success && context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                            'خطأ في الدخول، يرجى التأكد من البيانات'),
                                        backgroundColor: Colors.redAccent,
                                      ),
                                    );
                                  }
                                },
                                child: Container(
                                  // وعاء الزر المتدرج
                                  width:
                                      double.infinity, // تمديد الزر بكامل العرض
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 16), // حواف داخلية رأسية للزر
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      // تدرج لوني جذاب للزر
                                      colors: [
                                        Color(0xFF6C63FF),
                                        Color(0xFFA78BFA)
                                      ], // أرجواني وبنفسجي فاتح
                                    ),
                                    borderRadius: BorderRadius.circular(
                                        20), // حواف دائرية للزر
                                    boxShadow: [
                                      // توهج أسفل الزر
                                      BoxShadow(
                                        color: const Color(0xFF6C63FF)
                                            .withValues(
                                                alpha: 0.4), // لون التوهج
                                        blurRadius: 16, // مدى التوهج
                                        offset:
                                            const Offset(0, 8), // إزاحة التوهج
                                      ),
                                    ],
                                  ),
                                  child: const Text(
                                    // نص "دخول" على الزر
                                    'دخول',
                                    textAlign: TextAlign.center, // توسيط النص
                                    style: TextStyle(
                                      color: Colors.white, // نص أبيض ناصع
                                      fontSize: 18, // خط واضح
                                      fontWeight: FontWeight.bold, // عريض
                                      letterSpacing: 1, // تباعد بسيط
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            FadeTransition(
                              opacity: _fadeAnimations[5],
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      TextButton(
                                        onPressed: () => Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (context) =>
                                                  const RegisterScreen()),
                                        ),
                                        child: const Text(
                                          'أنشئ حساباً الآن',
                                          style: TextStyle(
                                            color: Color(0xFF6C63FF),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                          ),
                                        ),
                                      ),
                                      const Text(
                                        'ليس لديك حساب؟',
                                        style: TextStyle(
                                          color: Color(0xFF64748b),
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  TextButton.icon(
                                    onPressed: () =>
                                        _showGuestInquirySheet(context),
                                    icon: const Icon(Icons.info_outline_rounded,
                                        color: Color(0xFF10b981), size: 18),
                                    label: const Text(
                                      'استعلام عن مكان شاغر بالدار',
                                      style: TextStyle(
                                        color: Color(0xFF10b981),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ),
                                  const Divider(height: 24, thickness: 0.5),
                                  TextButton.icon(
                                    onPressed: () => _showDemoRoleSheet(context),
                                    icon: const Icon(Icons.science_rounded,
                                        color: Color(0xFFFF9900), size: 20),
                                    label: const Text(
                                      'الدخول التجريبي (بدون اتصال)',
                                      style: TextStyle(
                                        color: Color(0xFFFF9900),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ),
                                ],
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
          ),
        ],
      ),
    );
  }

  Widget _buildInput({
    // دالة مساعدة لبناء حقول الإدخال بشكل موحد
    required TextEditingController controller, // المتحكم بالنص
    required String label, // التلميح داخل الحقل
    required IconData icon, // الأيقونة الجانبية
    bool isPassword = false, // هل هو حقل كلمة مرور؟
  }) {
    return Container(
      // وعاء الحقل مع التصميم الزجاجي
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.8), // خلفية بيضاء شبه شفافة
        borderRadius: BorderRadius.circular(16), // حواف دائرية متناسقة
        border: Border.all(
            color: const Color(0xFFe2e8f0), width: 1.5), // إطار رمادي فاتح
      ),
      child: TextField(
        // مكون إدخال النص الأساسي
        controller: controller, // ربط المتحكم
        obscureText: isPassword, // إخفاء النص إذا كان كلمة مرور
        textAlign: TextAlign.right, // محاذاة النص لليمين (عربي)
        textDirection: TextDirection.rtl, // اتجاه النص من اليمين لليسار
        decoration: InputDecoration(
          // تصميم مكونات الحقل الداخلية
          hintText: label, // نص تلميحي
          hintStyle: const TextStyle(
              color: Color(0xFF94a3b8), fontSize: 15), // ستايل التلميح
          border: InputBorder.none, // إخفاء الإطار الافتراضي لفلاتر
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 16), // حواف داخلية مريحة
          prefixIcon: Icon(icon,
              color: const Color(0xFF94a3b8),
              size: 20), // الأيقونة في بداية الحقل (يميناً في RTL)
        ),
      ),
    );
  }

  void _showDemoRoleSheet(BuildContext context) {
    final roles = [
      {'role': 'إدارة', 'icon': Icons.admin_panel_settings_rounded, 'color': const Color(0xFF6C63FF), 'desc': 'لوحة تحكم المدير'},
      {'role': 'ممرض', 'icon': Icons.medical_services_rounded, 'color': const Color(0xFF10b981), 'desc': 'متابعة المقيمين والأدوية'},
      {'role': 'مسن', 'icon': Icons.elderly_rounded, 'color': const Color(0xFFFF9900), 'desc': 'واجهة المقيم التفاعلية'},
      {'role': 'أسرة', 'icon': Icons.family_restroom_rounded, 'color': const Color(0xFFEC4899), 'desc': 'متابعة حالة القريب'},
      {'role': 'أخصائي اجتماعي', 'icon': Icons.psychology_rounded, 'color': const Color(0xFF8B5CF6), 'desc': 'التقييمات والشكاوى'},
      {'role': 'متطوع', 'icon': Icons.volunteer_activism_rounded, 'color': const Color(0xFF3B82F6), 'desc': 'فرص التطوع والشهادات'},
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Row(
              children: [
                Icon(Icons.science_rounded, color: Color(0xFFFF9900), size: 24),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'اختر الدور للدخول التجريبي',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1e1b4b),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'سيتم تحميل بيانات تجريبية — لا يحتاج اتصال بالإنترنت',
              style: TextStyle(fontSize: 13, color: Color(0xFF64748b)),
            ),
            const SizedBox(height: 20),
            ...roles.map((r) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  Navigator.pop(context);
                  final provider = ref.read(appRiverpod);
                  provider.loginAsDemo(r['role'] as String);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: (r['color'] as Color).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: (r['color'] as Color).withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      Icon(r['icon'] as IconData, color: r['color'] as Color, size: 28),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              r['role'] as String,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: r['color'] as Color,
                              ),
                            ),
                            Text(
                              r['desc'] as String,
                              style: const TextStyle(fontSize: 12, color: Color(0xFF64748b)),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios_rounded, color: r['color'] as Color, size: 16),
                    ],
                  ),
                ),
              ),
            )),
          ],
        ),
      ),
    );
  }

  void _showGuestInquirySheet(BuildContext context) {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final cityController = TextEditingController();
    String? selectedGovernorate;
    final List<String> selectedFeatures = [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            left: 24,
            right: 24,
            top: 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Center(
                    child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(10)))),
                const SizedBox(height: 20),
                const Align(
                  alignment: Alignment.centerRight,
                  child: Text('البحث والاستعلام عن دار رعاية',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1e1b4b))),
                ),
                const SizedBox(height: 4),
                const Text(
                    'اختر المواصفات المطلوبة وسيقوم النظام بالبحث عن الدار المناسبة وإرسال طلبك.',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF64748b),
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 24),
                
                // Dropdown for Governorate
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFe2e8f0), width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF000000).withValues(alpha: 0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                      BoxShadow(
                        color: const Color(0xFF000000).withValues(alpha: 0.03),
                        blurRadius: 1,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      dropdownColor: const Color(0xFFf8fafc),
                      borderRadius: BorderRadius.circular(16),
                      hint: const Text('اختر المحافظة', style: TextStyle(color: Color(0xFF94a3b8), fontSize: 15)),
                      value: selectedGovernorate,
                      items: ['القاهرة', 'الجيزة', 'الإسكندرية', 'القليوبية']
                          .map((gov) => DropdownMenuItem(
                                value: gov,
                                child: Text(gov, textAlign: TextAlign.right),
                              ))
                          .toList(),
                      onChanged: (val) {
                        setModalState(() {
                          selectedGovernorate = val;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _buildInput(
                    controller: cityController,
                    label: 'المنطقة / المدينة',
                    icon: Icons.location_city_outlined),
                const SizedBox(height: 16),
                const Align(
                  alignment: Alignment.centerRight,
                  child: Text('المميزات المطلوبة:',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1e1b4b))),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    'رعاية طبية ٢٤ ساعة',
                    'علاج طبيعي',
                    'غرفة فردية',
                    'حديقة ومتنزه',
                    'أنشطة ترفيهية',
                    'وجبات مخصصة'
                  ].map((feature) {
                    final isSelected = selectedFeatures.contains(feature);
                    return GestureDetector(
                      onTap: () {
                        setModalState(() {
                          if (isSelected) {
                            selectedFeatures.remove(feature);
                          } else {
                            selectedFeatures.add(feature);
                          }
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFF10b981) : const Color(0xFFf0fdf4),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isSelected ? Colors.transparent : const Color(0xFFd1fae5)),
                        ),
                        child: Text(feature,
                            style: TextStyle(
                                color: isSelected ? Colors.white : const Color(0xFF065f46),
                                fontSize: 12,
                                fontWeight: FontWeight.bold)),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                _buildInput(
                    controller: nameController,
                    label: 'الاسم الكامل',
                    icon: Icons.person_outline),
                const SizedBox(height: 12),
                _buildInput(
                    controller: phoneController,
                    label: 'رقم الهاتف للتواصل',
                    icon: Icons.phone_outlined),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: () {
                      if (selectedGovernorate == null || cityController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('يرجى اختيار المحافظة والمنطقة أولاً'),
                            backgroundColor: Colors.redAccent,
                          ),
                        );
                        return;
                      }
                      
                      ref.read(appRiverpod).triggerNotification(
                            title: 'طلب التحاق جديد 📄',
                            body:
                                'طلب استعلام من ${nameController.text} (${phoneController.text}) عن دار في $selectedGovernorate - ${cityController.text} بمميزات: ${selectedFeatures.join('، ')}.',
                            type: 'admin',
                            targetRole: 'إدارة',
                          );
                      Navigator.pop(context);
                      // بدلاً من السناك بار البسيط، نعرض الشيت المفصل
                      _showFacilityResultSheet(context, 'دار الأمل التخصصية للمسنين', selectedGovernorate!);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10b981),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('بحث وإرسال الطلب',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showFacilityResultSheet(BuildContext context, String facilityName, String governorate) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Center(
                child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(10)))),
            const SizedBox(height: 24),
            const Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text('نتيجة البحث الموصى بها',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF10b981))),
                SizedBox(width: 8),
                Icon(Icons.check_circle_rounded, color: Color(0xFF10b981)),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFf8fafc),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFe2e8f0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(facilityName,
                      style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF1e1b4b))),
                  const SizedBox(height: 12),
                  _buildResultRow(Icons.location_on_outlined, '$governorate - شارع النيل بجوار المستشفى المركزي'),
                  const SizedBox(height: 8),
                  _buildResultRow(Icons.phone_outlined, '01122334455 / 02-33445566'),
                  const SizedBox(height: 8),
                  _buildResultRow(Icons.verified_user_outlined, 'مرخصة من وزارة التضامن الاجتماعي (ترخيص رقم ٤٣٢١)'),
                  const SizedBox(height: 8),
                  _buildResultRow(Icons.group_add_outlined, 'السعة: ٥٠ سرير (متاح أماكن شاغرة حالياً)'),
                  const SizedBox(height: 8),
                  _buildResultRow(Icons.date_range_outlined, 'سنة التأسيس: ٢٠١٥'),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                onPressed: () {
                  // فتح موقع الدار على خرائط جوجل
                  launchUrl(Uri.parse('https://maps.google.com/?q=30.0444,31.2357'));
                },
                icon: const Icon(Icons.map_rounded, color: Colors.white),
                label: const Text('عرض الموقع على خرائط جوجل',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3b82f6),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF94a3b8)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('إغلاق',
                    style: TextStyle(
                        color: Color(0xFF64748b),
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultRow(IconData icon, String text) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(text,
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 14, color: Color(0xFF475569))),
        ),
        const SizedBox(width: 8),
        Icon(icon, size: 20, color: const Color(0xFF64748b)),
      ],
    );
  }
}
