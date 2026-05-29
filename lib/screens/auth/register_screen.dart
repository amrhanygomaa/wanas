import 'dart:ui'; // مكتبة البلور والتأثيرات الزجاجية
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart';
import '../../providers/app_riverpod.dart';
import 'admin_register_screen.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen>
    with TickerProviderStateMixin {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String _selectedRole = 'أسرة';
  late AnimationController _fadeController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // الخلفية الأنيقة المتسقة مع شاشة تسجيل الدخول - صورة wanas_splash_bg
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFFAF7F2), // درجة كريمي فاتحة ونقية
                  Color(0xFFF3EFE9), // درجة كريمي دافئة
                  Color(0xFFE9E4DC), // درجة أغمق للعمق البصري
                ],
              ),
            ),
            child: Image.asset(
              'assets/icons/loginback.png',
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              errorBuilder: (context, error, stackTrace) =>
                  const SizedBox.shrink(),
            ),
          ),

          // Blur Effect - تأثير الضبابية للزجاج
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
              child: Container(color: Colors.white.withValues(alpha: 0.05)),
            ),
          ),

          // Content - المحتوى الأساسي
          SafeArea(
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: FadeTransition(
                    opacity: _fadeController,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // زر الرجوع المخصص الأنيق والمتناسق مع السمة الجديدة
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Padding(
                            padding:
                                const EdgeInsets.only(top: 12.0, bottom: 8.0),
                            child: InkWell(
                              onTap: () => Navigator.pop(context),
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.7),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: const Color(0xFFE9E4DC),
                                      width: 1.5),
                                ),
                                child: const Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  size: 20,
                                  color: Color(0xFF5A4B31),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Lottie Animation Area
                        Center(
                          child: SizedBox(
                            height: 140,
                            child: Lottie.asset(
                              'assets/animations/register.json',
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(Icons.person_add_alt_1_rounded,
                                    size: 80,
                                    color: const Color(0xFFD2AF7D)
                                        .withValues(alpha: 0.3));
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        const Text(
                          'إنشاء حساب جديد',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF5A4B31),
                            fontFamily: 'Cairo',
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'خاص بالمتطوعين وأفراد الأسرة فقط',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF8F7C56),
                            fontFamily: 'Cairo',
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Glassmorphic Card - كارت البيانات الزجاجي
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(32),
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF312e81)
                                    .withValues(alpha: 0.08),
                                blurRadius: 32,
                                offset: const Offset(0, 16),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildInput(
                                controller: _nameController,
                                label: 'الاسم الكامل',
                                icon: Icons.person_outline_rounded,
                              ),
                              const SizedBox(height: 16),
                              _buildInput(
                                controller: _emailController,
                                label: 'البريد الإلكتروني',
                                icon: Icons.email_outlined,
                              ),
                              const SizedBox(height: 16),
                              _buildInput(
                                controller: _passwordController,
                                label: 'كلمة المرور',
                                icon: Icons.lock_outline_rounded,
                                isPassword: true,
                              ),
                              const SizedBox(height: 24),

                              const Align(
                                alignment: Alignment.centerRight,
                                child: Text(
                                  'أنا أسجل كـ:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Color(0xFF5A4B31),
                                    fontFamily: 'Cairo',
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: _roleOption(
                                      'متطوع',
                                      _selectedRole == 'متطوع',
                                      () => setState(
                                          () => _selectedRole = 'متطوع'),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _roleOption(
                                      'فرد أسرة',
                                      _selectedRole == 'أسرة',
                                      () => setState(
                                          () => _selectedRole = 'أسرة'),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 32),

                              // زر إنشاء الحساب المتدرج الذهبي الفخم
                              GestureDetector(
                                onTap: _isLoading
                                    ? null
                                    : () async {
                                        if (_nameController.text.isEmpty ||
                                            _emailController.text.isEmpty) {
                                          return;
                                        }
                                        setState(() => _isLoading = true);
                                        try {
                                          await ref
                                              .read(appRiverpod)
                                              .selfRegister(
                                                name: _nameController.text,
                                                email: _emailController.text,
                                                password:
                                                    _passwordController.text,
                                                role: _selectedRole,
                                              );
                                          if (!context.mounted) return;
                                          Navigator.pop(context);
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                  'تم إنشاء الحساب بنجاح! يمكنك الدخول الآن'),
                                              backgroundColor:
                                                  Color(0xFF10b981),
                                            ),
                                          );
                                        } catch (e) {
                                          if (!context.mounted) return;
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Text(e.toString()),
                                              backgroundColor:
                                                  const Color(0xFFef4444),
                                            ),
                                          );
                                        } finally {
                                          if (mounted) {
                                            setState(() => _isLoading = false);
                                          }
                                        }
                                      },
                                child: Container(
                                  width: double.infinity,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFFD2AF7D),
                                        Color(0xFFE1BE8C),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFFD2AF7D)
                                            .withValues(alpha: 0.35),
                                        blurRadius: 16,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child: _isLoading
                                      ? const SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: Center(
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.4,
                                              color: Colors.white,
                                            ),
                                          ),
                                        )
                                      : const Text(
                                          'إنشاء الحساب',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            fontFamily: 'Cairo',
                                          ),
                                        ),
                                ),
                              ),
                              const SizedBox(height: 24),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const AdminRegisterScreen(),
                                        ),
                                      );
                                    },
                                    child: const Text(
                                      'سجل هنا',
                                      style: TextStyle(
                                        color: Color(0xFF9B7E4B),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                        fontFamily: 'Cairo',
                                      ),
                                    ),
                                  ),
                                  const Text(
                                    'هل أنت مدير منشأة؟',
                                    style: TextStyle(
                                      color: Color(0xFF8F7C56),
                                      fontSize: 14,
                                      fontFamily: 'Cairo',
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInput({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE9E4DC), width: 1.5),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        textAlign: TextAlign.right,
        textDirection: TextDirection.rtl,
        decoration: InputDecoration(
          hintText: label,
          hintStyle: const TextStyle(
              color: Color(0xFFB09D76), fontSize: 15, fontFamily: 'Cairo'),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          prefixIcon: Icon(icon, color: const Color(0xFF8F7C56), size: 20),
        ),
      ),
    );
  }

  Widget _roleOption(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFFAF5E1)
              : Colors.white.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color:
                isSelected ? const Color(0xFFD2AF7D) : const Color(0xFFE9E4DC),
            width: isSelected ? 2.5 : 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFFD2AF7D).withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ]
              : null,
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected
                  ? const Color(0xFF9B7E4B)
                  : const Color(0xFF8F7C56),
              fontWeight: FontWeight.bold,
              fontSize: 16,
              fontFamily: 'Cairo',
            ),
          ),
        ),
      ),
    );
  }
}
