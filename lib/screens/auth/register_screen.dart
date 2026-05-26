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
      backgroundColor: Colors.white,
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: FadeTransition(
              opacity: _fadeController,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment
                    .stretch, // تمدد العناصر لضمان المحاذاة لليمين
                children: [
                  // Custom Back Button
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
                      child: InkWell(
                        onTap: () => Navigator.pop(context),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: const Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 20,
                            color: Color(0xFF1e1b4b),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Lottie Animation Area
                  Center(
                    child: SizedBox(
                      height: 180,
                      child: Lottie.asset(
                        'assets/animations/register.json',
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(Icons.person_add_alt_1_rounded,
                              size: 80,
                              color: const Color(0xFF6C63FF)
                                  .withValues(alpha: 0.3));
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  const Text(
                    'إنشاء حساب جديد',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1e1b4b),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'خاص بالمتطوعين وأفراد الأسرة فقط',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF64748b),
                    ),
                  ),
                  const SizedBox(height: 32),

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
                  const SizedBox(height: 32),

                  const Text(
                    'أنا أسجل كـ:',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                      color: Color(0xFF1e1b4b),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _roleOption(
                          'متطوع',
                          _selectedRole == 'متطوع',
                          () => setState(() => _selectedRole = 'متطوع'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _roleOption(
                          'فرد أسرة',
                          _selectedRole == 'أسرة',
                          () => setState(() => _selectedRole = 'أسرة'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 48),

                  SizedBox(
                    width: double.infinity,
                    height: 58,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_nameController.text.isEmpty ||
                            _emailController.text.isEmpty) {
                          return;
                        }
                        ref.read(appRiverpod).selfRegister(
                              name: _nameController.text,
                              email: _emailController.text,
                              password: _passwordController.text,
                              role: _selectedRole,
                            );
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                                'تم إنشاء الحساب بنجاح! يمكنك الدخول الآن'),
                            backgroundColor: Color(0xFF10b981),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6C63FF),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: const Text(
                        'إنشاء الحساب',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AdminRegisterScreen(),
                            ),
                          );
                        },
                        child: const Text(
                          'سجل هنا',
                          style: TextStyle(
                            color: Color(0xFF6C63FF),
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      const Text(
                        'هل أنت مدير منشأة؟',
                        style: TextStyle(
                          color: Color(0xFF64748b),
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
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
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        textAlign: TextAlign.right,
        decoration: InputDecoration(
          hintText: label,
          hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 16),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          prefixIcon: Icon(icon,
              color: const Color(0xFF94A3B8),
              size: 22), // prefixIcon is on the right in RTL
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
          color: isSelected ? const Color(0xFFF5F3FF) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color:
                isSelected ? const Color(0xFF6C63FF) : const Color(0xFFE2E8F0),
            width: 2.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF6C63FF).withValues(alpha: 0.1),
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
                  ? const Color(0xFF6C63FF)
                  : const Color(0xFF64748B),
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }
}
