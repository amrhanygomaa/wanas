import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart';
import '../../providers/app_riverpod.dart';

class AdminRegisterScreen extends ConsumerStatefulWidget {
  const AdminRegisterScreen({super.key});

  @override
  ConsumerState<AdminRegisterScreen> createState() =>
      _AdminRegisterScreenState();
}

class _AdminRegisterScreenState extends ConsumerState<AdminRegisterScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  // Account Controllers
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // Facility Controllers
  final _facilityNameController = TextEditingController();
  final _facilityAddressController = TextEditingController();
  final _facilityYearController = TextEditingController();
  final _facilityCapacityController = TextEditingController();
  final _facilityLicenseController = TextEditingController();
  final _facilityLocationController = TextEditingController();

  final List<String> _allAmenities = [
    'حديقة واسعة',
    'رعاية طبية 24/7',
    'غرف مكيفة',
    'إنترنت واي فاي',
    'علاج طبيعي',
    'وجبات صحية مخصصة',
    'خدمة غسيل ملابس',
    'كاميرات مراقبة',
    'أنشطة ترفيهية يومية',
    'صالون عناية شخصية',
  ];

  final List<String> _selectedAmenities = [];
  bool _isLoading = false;
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
    _facilityNameController.dispose();
    _facilityAddressController.dispose();
    _facilityYearController.dispose();
    _facilityCapacityController.dispose();
    _facilityLicenseController.dispose();
    _facilityLocationController.dispose();
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
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
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
                              border:
                                  Border.all(color: const Color(0xFFE2E8F0)),
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
                    const SizedBox(height: 16),
                    Center(
                      child: SizedBox(
                        height: 150,
                        child: Lottie.asset(
                          'assets/animations/register.json',
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(Icons.business_rounded,
                                size: 80,
                                color: const Color(0xFF9B7E4B)
                                    .withValues(alpha: 0.3));
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'تسجيل منشأة جديدة',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF5A4B31),
                      ),
                    ),
                    const Text(
                      'ابدأ في إدارة دارك باحترافية وسهولة',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFF64748b),
                      ),
                    ),
                    const SizedBox(height: 32),

                    _sectionTitle('بيانات المدير المسؤول'),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _nameController,
                      label: 'الاسم الكامل للمدير',
                      icon: Icons.person_outline_rounded,
                      validator: (v) => v!.isEmpty ? 'يرجى إدخال الاسم' : null,
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _emailController,
                      label: 'البريد الإلكتروني للعمل',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) => v!.isEmpty || !v.contains('@')
                          ? 'بريد غير صالح'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _passwordController,
                      label: 'كلمة المرور',
                      icon: Icons.lock_outline_rounded,
                      isPassword: true,
                      validator: (v) =>
                          v!.length < 6 ? 'كلمة المرور قصيرة جداً' : null,
                    ),

                    const SizedBox(height: 32),
                    _sectionTitle('بيانات المنشأة (الدار)'),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _facilityNameController,
                      label: 'اسم الدار / المركز',
                      icon: Icons.apartment_rounded,
                      validator: (v) =>
                          v!.isEmpty ? 'يرجى إدخال اسم الدار' : null,
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _facilityAddressController,
                      label: 'العنوان بالتفصيل',
                      icon: Icons.location_on_outlined,
                      validator: (v) =>
                          v!.isEmpty ? 'يرجى إدخال العنوان' : null,
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _facilityYearController,
                      label: 'سنة الإنشاء (مثال: ٢٠١٠)',
                      icon: Icons.date_range_rounded,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _facilityCapacityController,
                      label: 'السعة الاستيعابية للمكان',
                      icon: Icons.group_add_rounded,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _facilityLicenseController,
                      label: 'رقم ترخيص وزارة التضامن',
                      icon: Icons.verified_user_outlined,
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _facilityLocationController,
                      label: 'رابط الموقع على خرائط جوجل',
                      icon: Icons.map_rounded,
                      keyboardType: TextInputType.url,
                    ),

                    const SizedBox(height: 32),
                    _sectionTitle('مميزات وخدمات الدار'),
                    const SizedBox(height: 12),
                    const Text(
                      'اختر الخدمات المتوفرة في منشأتك لتظهر للمستخدمين:',
                      style: TextStyle(fontSize: 14, color: Color(0xFF64748b)),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 12,
                      children: _allAmenities.map((amenity) {
                        final isSelected = _selectedAmenities.contains(amenity);
                        return FilterChip(
                          label: Text(amenity),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedAmenities.add(amenity);
                              } else {
                                _selectedAmenities.remove(amenity);
                              }
                            });
                          },
                          selectedColor:
                              const Color(0xFF9B7E4B).withValues(alpha: 0.1),
                          checkmarkColor: const Color(0xFF9B7E4B),
                          labelStyle: TextStyle(
                            color: isSelected
                                ? const Color(0xFF9B7E4B)
                                : const Color(0xFF64748b),
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                          backgroundColor: const Color(0xFFF8FAFC),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: isSelected
                                  ? const Color(0xFF9B7E4B)
                                  : const Color(0xFFE2E8F0),
                              width: 1.5,
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 48),
                    SizedBox(
                      height: 58,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleRegister,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF9B7E4B),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white)
                            : const Text(
                                'إنشاء حساب المنشأة',
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 24,
          decoration: BoxDecoration(
            color: const Color(0xFF9B7E4B),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF5A4B31),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
      ),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword,
        textAlign: TextAlign.right,
        keyboardType: keyboardType,
        validator: validator,
        decoration: InputDecoration(
          hintText: label,
          hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 16),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          prefixIcon: Icon(icon, color: const Color(0xFF94A3B8), size: 22),
        ),
      ),
    );
  }

  Future<void> _handleRegister() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        await ref.read(appRiverpod).registerAdmin(
              name: _nameController.text,
              email: _emailController.text,
              password: _passwordController.text,
              facilityName: _facilityNameController.text,
              facilityAddress: _facilityAddressController.text,
              amenities: _selectedAmenities,
              facilityYearOfEst: _facilityYearController.text.isNotEmpty
                  ? _facilityYearController.text
                  : null,
              facilityCapacity: _facilityCapacityController.text.isNotEmpty
                  ? _facilityCapacityController.text
                  : null,
              facilityLicenseNumber: _facilityLicenseController.text.isNotEmpty
                  ? _facilityLicenseController.text
                  : null,
              facilityLocationUrl: _facilityLocationController.text.isNotEmpty
                  ? _facilityLocationController.text
                  : null,
            );

        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم تسجيل المنشأة بنجاح! يمكنك الآن تسجيل الدخول'),
              backgroundColor: Color(0xFF10b981),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString()),
              backgroundColor: const Color(0xFFef4444),
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }
}
