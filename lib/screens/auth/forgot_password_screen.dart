import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/api_client.dart';

// شاشة استعادة كلمة السر — مرحلتان:
// 1) إدخال البريد → POST /auth/forgot-password
// 2) إدخال الكود + كلمة سر جديدة → POST /auth/confirm-forgot-password


class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  int _step = 1;
  bool _isLoading = false;
  bool _showPassword = false;

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _newPasswordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isLoading = true);
    try {
      await AuthService.instance.forgotPassword(email: _emailController.text);
      if (!mounted) return;
      setState(() => _step = 2);
      _toast('تم إرسال كود الاستعادة إلى بريدك');
    } on ApiException catch (e) {
      _toast(e.message, isError: true);
    } catch (e) {
      _toast('خطأ غير متوقع: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _confirmReset() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isLoading = true);
    try {
      await AuthService.instance.confirmForgotPassword(
        email: _emailController.text,
        code: _codeController.text,
        newPassword: _newPasswordController.text,
      );
      if (!mounted) return;
      _toast('تم تغيير كلمة السر بنجاح. سجّل دخولك الآن');
      Navigator.of(context).pop();
    } on ApiException catch (e) {
      _toast(e.message, isError: true);
    } catch (e) {
      _toast('خطأ غير متوقع: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _toast(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.redAccent : const Color(0xFF10b981),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: const IconThemeData(color: Color(0xFF1E293B)),
          title: Text(
            _step == 1 ? 'استعادة كلمة السر' : 'تأكيد الكود',
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6C63FF).withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _step == 1
                          ? Icons.lock_reset_rounded
                          : Icons.mark_email_read_rounded,
                      size: 64,
                      color: const Color(0xFF6C63FF),
                    ),
                  ).withConstraint(),
                  const SizedBox(height: 16),
                  Text(
                    _step == 1
                        ? 'أدخل بريدك الإلكتروني لإرسال كود استعادة كلمة السر'
                        : 'أدخل الكود الذي وصلك على بريدك + كلمة السر الجديدة',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 13,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 28),
                  _emailField(),
                  if (_step == 2) ...[
                    const SizedBox(height: 12),
                    _codeField(),
                    const SizedBox(height: 12),
                    _newPasswordField(),
                    const SizedBox(height: 12),
                    _confirmField(),
                  ],
                  const SizedBox(height: 24),
                  _primaryButton(),
                  const SizedBox(height: 12),
                  if (_step == 2) _resendButton(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _emailField() {
    return TextFormField(
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      enabled: _step == 1,
      style: const TextStyle(fontFamily: 'Cairo'),
      decoration: _inputDecoration(
        label: 'البريد الإلكتروني',
        icon: Icons.email_rounded,
      ),
      validator: (v) {
        final s = (v ?? '').trim();
        if (s.isEmpty) return 'البريد مطلوب';
        if (!s.contains('@')) return 'بريد غير صالح';
        return null;
      },
    );
  }

  Widget _codeField() {
    return TextFormField(
      controller: _codeController,
      keyboardType: TextInputType.number,
      style: const TextStyle(fontFamily: 'Cairo', letterSpacing: 4),
      decoration: _inputDecoration(
        label: 'الكود (6 أرقام)',
        icon: Icons.dialpad_rounded,
      ),
      validator: (v) {
        final s = (v ?? '').trim();
        if (s.isEmpty) return 'الكود مطلوب';
        if (s.length < 4) return 'الكود غير صالح';
        return null;
      },
    );
  }

  Widget _newPasswordField() {
    return TextFormField(
      controller: _newPasswordController,
      obscureText: !_showPassword,
      style: const TextStyle(fontFamily: 'Cairo'),
      decoration: _inputDecoration(
        label: 'كلمة السر الجديدة',
        icon: Icons.lock_rounded,
        suffix: IconButton(
          icon: Icon(
            _showPassword ? Icons.visibility_off : Icons.visibility,
            color: const Color(0xFF94A3B8),
            size: 20,
          ),
          onPressed: () => setState(() => _showPassword = !_showPassword),
        ),
      ),
      validator: (v) {
        final s = v ?? '';
        if (s.isEmpty) return 'كلمة السر مطلوبة';
        if (s.length < 8) return 'يجب 8 أحرف على الأقل';
        return null;
      },
    );
  }

  Widget _confirmField() {
    return TextFormField(
      controller: _confirmController,
      obscureText: !_showPassword,
      style: const TextStyle(fontFamily: 'Cairo'),
      decoration: _inputDecoration(
        label: 'تأكيد كلمة السر',
        icon: Icons.lock_outline_rounded,
      ),
      validator: (v) {
        if ((v ?? '') != _newPasswordController.text) {
          return 'كلمتا السر غير متطابقتين';
        }
        return null;
      },
    );
  }

  Widget _primaryButton() {
    return SizedBox(
      height: 52,
      child: FilledButton(
        onPressed: _isLoading ? null : (_step == 1 ? _sendCode : _confirmReset),
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF6C63FF),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: _isLoading
            ? const SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2.5),
              )
            : Text(
                _step == 1 ? 'إرسال الكود' : 'تأكيد وتغيير كلمة السر',
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  Widget _resendButton() {
    return TextButton.icon(
      onPressed: _isLoading
          ? null
          : () {
              setState(() => _step = 1);
              _codeController.clear();
              _newPasswordController.clear();
              _confirmController.clear();
            },
      icon: const Icon(Icons.arrow_forward_rounded,
          color: Color(0xFF6C63FF), size: 18),
      label: const Text(
        'تغيير البريد أو إعادة إرسال الكود',
        style: TextStyle(
          fontFamily: 'Cairo',
          color: Color(0xFF6C63FF),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle:
          const TextStyle(fontFamily: 'Cairo', color: Color(0xFF64748B)),
      prefixIcon: Icon(icon, color: const Color(0xFF6C63FF), size: 20),
      suffixIcon: suffix,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF6C63FF), width: 1.6),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}

extension _CenterCircle on Widget {
  Widget withConstraint() => Center(child: this);
}
