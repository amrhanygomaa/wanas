import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart';
import '../../providers/app_riverpod.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  late AnimationController _floatController;
  late AnimationController _pageTransitionController;

  // بيانات صفحات الترحيب - الألوان مأخوذة مباشرة من ملفات الأنيميشن
  final List<OnboardingData> _pages = [
    OnboardingData(
      title: 'وصلت',
      description: 'بيتك الثاني ومجتمعك الذي ينبض بالحياة والدفء',
      primaryColor: const Color(0xFF00C896), // أخضر سيان - لون جسم الروبوت
      secondaryColor: const Color(0xFF4ADE80), // أخضر فاتح - إضاءة الروبوت
      icon: Icons.home_rounded,
      lottieAsset: 'assets/animations/welcome.json',
    ),
    OnboardingData(
      title: 'قريبون',
      description: 'افتح نوافذ التواصل مع عائلتك والأخصائيين بضغطة واحدة',
      primaryColor: const Color(0xFFFF5039), // برتقالي حيوي الأنيميشن
      secondaryColor: const Color(0xFFFF8ECC), // وردي ناعم
      icon: Icons.favorite_rounded,
      lottieAsset: 'assets/animations/connect.json',
    ),
    OnboardingData(
      title: 'اطمن',
      description: 'نظام ذكي يذكرك بمواعيد أدويتك ويتابع حالتك بدقة',
      primaryColor: const Color(0xFF2CA6FF), // أزرق طبي
      secondaryColor: const Color(0xFFF0ADB5), // وردي بشري
      icon: Icons.health_and_safety_rounded,
      lottieAsset: 'assets/animations/health.json',
    ),
    OnboardingData(
      title: 'معاك',
      description: 'اختر هويتك وادخل عالم ونس المتكامل',
      primaryColor: const Color(0xFF21257C), // نيلي غامق
      secondaryColor: const Color(0xFF4AA5FF), // سماوي لامع
      icon: Icons.rocket_launch_rounded,
      lottieAsset: 'assets/animations/start.json',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
    _pageTransitionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _floatController.dispose();
    _pageTransitionController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    } else {
      ref.read(appRiverpod).completeOnboarding();
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentColor = _pages[_currentPage].primaryColor;
    return Scaffold(
      backgroundColor: Colors.white,
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              currentColor.withValues(alpha: 0.06),
              Colors.white,
              Colors.white,
            ],
            stops: const [0.0, 0.45, 1.0],
          ),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final screenH = constraints.maxHeight;
            final screenW = constraints.maxWidth;
            // أحجام نسبية تضمن التناسق على كل الشاشات
            final lottieSize = screenH * 0.36;
            final titleSize = screenW * 0.115; // ~44px على شاشة 390px
            final descSize = screenW * 0.043; // ~17px
            final btnFontSize = screenW * 0.048;
            final footerPadBottom = screenH * 0.07;

            return Stack(
              children: [
                // خلفية فقاعات متحركة بلون الصفحة
                _buildAnimatedBackground(currentColor),

                Column(
                  children: [
                    // منطقة المحتوى
                    Expanded(
                      child: PageView.builder(
                        controller: _pageController,
                        itemCount: _pages.length,
                        onPageChanged: (idx) {
                          setState(() => _currentPage = idx);
                          _pageTransitionController
                            ..reset()
                            ..forward();
                        },
                        itemBuilder: (context, index) {
                          return _buildPage(
                            _pages[index],
                            lottieSize,
                            titleSize,
                            descSize,
                            screenH,
                          );
                        },
                      ),
                    ),

                    // الشريط السفلي: الزر + المؤشرات
                    _buildFooter(currentColor, btnFontSize, footerPadBottom),
                  ],
                ),
              ],
            );
          },
        ),
      ), // AnimatedContainer
    );
  }

  // ======== الخلفية المتحركة ========
  Widget _buildAnimatedBackground(Color color) {
    return AnimatedBuilder(
      animation: _floatController,
      builder: (context, _) {
        return Stack(
          children: [
            _buildBlob(240, color.withValues(alpha: 0.18), -60, 60, 1.2),
            _buildBlob(180, color.withValues(alpha: 0.12), 230, -50, 1.6),
            _buildBlob(130, color.withValues(alpha: 0.09), 30, 400, 2.0),
          ],
        );
      },
    );
  }

  Widget _buildBlob(
      double size, Color color, double right, double top, double speed) {
    final offset = sin(_floatController.value * pi * 2 * speed) * 18;
    return Positioned(
      right: right + offset,
      top: top + offset,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      ),
    );
  }

  // ======== صفحة واحدة ========
  Widget _buildPage(
    OnboardingData data,
    double lottieSize,
    double titleSize,
    double descSize,
    double screenH,
  ) {
    return FadeTransition(
      opacity: _pageTransitionController,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: screenH * 0.04),

            // ====== أنيميشن Lottie ======
            _buildLottie(data, lottieSize),

            SizedBox(height: screenH * 0.04),

            // ====== العنوان ======
            Text(
              data.title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: titleSize,
                fontWeight: FontWeight.w900,
                color: data.primaryColor,
                letterSpacing: -1,
                height: 1.0,
              ),
            ),

            SizedBox(height: screenH * 0.018),

            // ====== الوصف داخل بطاقة شفافة ======
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                horizontal: 20,
                vertical: screenH * 0.018,
              ),
              decoration: BoxDecoration(
                color: data.primaryColor.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: data.primaryColor.withValues(alpha: 0.15),
                  width: 1.2,
                ),
              ),
              child: Text(
                data.description,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: descSize,
                  color: const Color(0xFF475569),
                  height: 1.75,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

            SizedBox(height: screenH * 0.02),
          ],
        ),
      ),
    );
  }

  // ====== Lottie مع Fallback ======
  Widget _buildLottie(OnboardingData data, double lottieSize) {
    return AnimatedBuilder(
      animation: _floatController,
      builder: (context, _) {
        return Transform.translate(
          offset: Offset(0, 10 * sin(_floatController.value * pi * 2)),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // دايرة مضيئة بلون الصفحة خلف الأنيميشن
              Container(
                width: lottieSize * 0.80,
                height: lottieSize * 0.80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: data.primaryColor.withValues(alpha: 0.12),
                  boxShadow: [
                    BoxShadow(
                      color: data.primaryColor.withValues(alpha: 0.22),
                      blurRadius: 60,
                      spreadRadius: 12,
                      offset: const Offset(0, 14),
                    ),
                  ],
                ),
              ),
              // الأنيميشن نفسه
              SizedBox(
                width: lottieSize,
                height: lottieSize,
                child: Lottie.asset(
                  data.lottieAsset,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, _) {
                    return Center(
                      child: Icon(
                        data.icon,
                        size: lottieSize * 0.42,
                        color: data.primaryColor.withValues(alpha: 0.5),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ====== الشريط السفلي ======
  Widget _buildFooter(Color color, double btnFontSize, double padBottom) {
    final isLast = _currentPage == _pages.length - 1;
    return Padding(
      padding: EdgeInsets.fromLTRB(28, 0, 28, padBottom),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // زر التالي / ابدأ
          GestureDetector(
            onTap: _nextPage,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
              padding: EdgeInsets.symmetric(
                horizontal: isLast ? 36 : 32,
                vertical: 15,
              ),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.35),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!isLast) ...[
                    const Icon(Icons.arrow_back_ios_new_rounded,
                        color: Colors.white, size: 14),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    isLast ? 'ابدأ الآن' : 'التالي',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: btnFontSize,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // مؤشرات الصفحات
          Row(
            children: List.generate(_pages.length, (index) {
              final isCurrent = _currentPage == index;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeOut,
                margin: const EdgeInsets.only(right: 8),
                width: isCurrent ? 28 : 9,
                height: 9,
                decoration: BoxDecoration(
                  color: isCurrent ? color : const Color(0xFFcbd5e1),
                  borderRadius: BorderRadius.circular(5),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class OnboardingData {
  final String title;
  final String description;
  final Color primaryColor;
  final Color secondaryColor;
  final IconData icon;
  final String lottieAsset;

  OnboardingData({
    required this.title,
    required this.description,
    required this.primaryColor,
    required this.secondaryColor,
    required this.icon,
    required this.lottieAsset,
  });
}
