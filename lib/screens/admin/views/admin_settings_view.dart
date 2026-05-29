import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/app_riverpod.dart';
import '../../../services/facility_settings_service.dart';

class AdminSettingsView extends ConsumerStatefulWidget {
  final List<Animation<double>> fadeAnimations;

  const AdminSettingsView({super.key, required this.fadeAnimations});

  @override
  ConsumerState<AdminSettingsView> createState() => _AdminSettingsViewState();
}

class _AdminSettingsViewState extends ConsumerState<AdminSettingsView> {
  final _ambulance = TextEditingController();
  final _doctor = TextEditingController();
  final _codeBlue = TextEditingController();
  final _emergencyNotes = TextEditingController();

  final _accountName = TextEditingController();
  final _bankName = TextEditingController();
  final _bankAccountNumber = TextEditingController();
  final _bankIban = TextEditingController();
  final _walletProvider = TextEditingController();
  final _walletNumber = TextEditingController();
  final _billingInstructions = TextEditingController();

  final _facilityName = TextEditingController();
  final _facilityAddress = TextEditingController();
  final _facilityPhone = TextEditingController();
  final _facilityEmail = TextEditingController();
  final _facilityLegalFooter = TextEditingController();

  bool _isLoading = true;
  bool _isSavingEmergency = false;
  bool _isSavingBilling = false;
  bool _isSavingProfile = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadAll());
  }

  Future<void> _loadAll() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final svc = FacilitySettingsService.instance;
      final results = await Future.wait([
        svc.emergencyContacts(),
        svc.billingSettings(),
        svc.facilityProfile(),
      ]);
      final emergency = results[0] as EmergencyContactsSettings;
      final billing = results[1] as FacilityBillingSettings;
      final profile = results[2] as FacilityProfileSettings;

      _ambulance.text = emergency.ambulance ?? '';
      _doctor.text = emergency.doctor ?? '';
      _codeBlue.text = emergency.codeBlue ?? '';
      _emergencyNotes.text = emergency.notes ?? '';

      _accountName.text = billing.accountName ?? '';
      _bankName.text = billing.bankName ?? '';
      _bankAccountNumber.text = billing.bankAccountNumber ?? '';
      _bankIban.text = billing.bankIban ?? '';
      _walletProvider.text = billing.walletProvider ?? '';
      _walletNumber.text = billing.walletNumber ?? '';
      _billingInstructions.text = billing.instructions ?? '';

      _facilityName.text = profile.facilityName ?? '';
      _facilityAddress.text = profile.address ?? '';
      _facilityPhone.text = profile.phone ?? '';
      _facilityEmail.text = profile.email ?? '';
      _facilityLegalFooter.text = profile.reportLegalFooter ?? '';
    } catch (e) {
      _error = 'تعذر تحميل إعدادات المنشأة: $e';
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveEmergency() async {
    setState(() => _isSavingEmergency = true);
    try {
      await FacilitySettingsService.instance.updateEmergencyContacts(
        ambulance: _ambulance.text.trim(),
        doctor: _doctor.text.trim(),
        codeBlue: _codeBlue.text.trim(),
        notes: _emergencyNotes.text.trim(),
      );
      await ref.read(appRiverpod).loadEmergencyContacts();
      if (mounted) _toast('تم حفظ أرقام الطوارئ');
    } catch (e) {
      if (mounted) _toast('فشل الحفظ: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isSavingEmergency = false);
    }
  }

  Future<void> _saveBilling() async {
    setState(() => _isSavingBilling = true);
    try {
      await FacilitySettingsService.instance.updateBillingSettings(
        accountName: _accountName.text.trim(),
        bankName: _bankName.text.trim(),
        bankAccountNumber: _bankAccountNumber.text.trim(),
        bankIban: _bankIban.text.trim(),
        walletProvider: _walletProvider.text.trim(),
        walletNumber: _walletNumber.text.trim(),
        instructions: _billingInstructions.text.trim(),
      );
      await ref.read(appRiverpod).loadBillingSettings();
      if (mounted) _toast('تم حفظ بيانات الدفع');
    } catch (e) {
      if (mounted) _toast('فشل الحفظ: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isSavingBilling = false);
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _isSavingProfile = true);
    try {
      await FacilitySettingsService.instance.updateFacilityProfile(
        facilityName: _facilityName.text.trim(),
        address: _facilityAddress.text.trim(),
        phone: _facilityPhone.text.trim(),
        email: _facilityEmail.text.trim(),
        reportLegalFooter: _facilityLegalFooter.text.trim(),
      );
      await ref.read(appRiverpod).loadFacilityProfileSettings();
      if (mounted) _toast('تم حفظ بيانات المنشأة');
    } catch (e) {
      if (mounted) _toast('فشل الحفظ: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isSavingProfile = false);
    }
  }

  void _toast(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontFamily: 'Cairo')),
        backgroundColor:
            isError ? const Color(0xFFEF4444) : const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void dispose() {
    _ambulance.dispose();
    _doctor.dispose();
    _codeBlue.dispose();
    _emergencyNotes.dispose();
    _accountName.dispose();
    _bankName.dispose();
    _bankAccountNumber.dispose();
    _bankIban.dispose();
    _walletProvider.dispose();
    _walletNumber.dispose();
    _billingInstructions.dispose();
    _facilityName.dispose();
    _facilityAddress.dispose();
    _facilityPhone.dispose();
    _facilityEmail.dispose();
    _facilityLegalFooter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 80),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(Icons.error_outline, color: Color(0xFFEF4444), size: 48),
            const SizedBox(height: 12),
            Text(_error!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontFamily: 'Cairo', fontSize: 13)),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _loadAll,
              icon: const Icon(Icons.refresh),
              label: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _sectionTitle('إعدادات المنشأة', Icons.business_rounded),
          const SizedBox(height: 8),
          const Text(
            'تُحفظ مباشرة في قاعدة بيانات AWS RDS وتظهر للموظفين والأسر فوراً.',
            style: TextStyle(
                fontSize: 11, color: Color(0xFF64748B), fontFamily: 'Cairo'),
          ),
          const SizedBox(height: 20),
          _card(
            title: 'بيانات المنشأة',
            icon: Icons.apartment_rounded,
            color: const Color(0xFF0EA5E9),
            children: [
              _field(_facilityName, 'اسم المنشأة'),
              _field(_facilityAddress, 'العنوان'),
              _field(_facilityPhone, 'رقم الهاتف',
                  keyboardType: TextInputType.phone),
              _field(_facilityEmail, 'البريد الإلكتروني',
                  keyboardType: TextInputType.emailAddress),
              _field(_facilityLegalFooter, 'تذييل قانوني للتقارير',
                  maxLines: 2),
              const SizedBox(height: 8),
              _saveBtn(_isSavingProfile, _saveProfile),
            ],
          ),
          const SizedBox(height: 16),
          _card(
            title: 'أرقام الطوارئ',
            icon: Icons.emergency_rounded,
            color: const Color(0xFFEF4444),
            children: [
              _field(_ambulance, 'إسعاف', keyboardType: TextInputType.phone),
              _field(_doctor, 'الطبيب المسؤول',
                  keyboardType: TextInputType.phone),
              _field(_codeBlue, 'Code Blue', keyboardType: TextInputType.phone),
              _field(_emergencyNotes, 'ملاحظات إضافية', maxLines: 2),
              const SizedBox(height: 8),
              _saveBtn(_isSavingEmergency, _saveEmergency),
            ],
          ),
          const SizedBox(height: 16),
          _card(
            title: 'بيانات الدفع للأسر',
            icon: Icons.payments_rounded,
            color: const Color(0xFF10B981),
            children: [
              _field(_accountName, 'اسم صاحب الحساب'),
              _field(_bankName, 'اسم البنك'),
              _field(_bankAccountNumber, 'رقم الحساب البنكي',
                  keyboardType: TextInputType.number),
              _field(_bankIban, 'IBAN'),
              _field(_walletProvider, 'مزوّد المحفظة (مثل: فودافون كاش)'),
              _field(_walletNumber, 'رقم المحفظة',
                  keyboardType: TextInputType.phone),
              _field(_billingInstructions, 'تعليمات إضافية للأسر', maxLines: 3),
              const SizedBox(height: 8),
              _saveBtn(_isSavingBilling, _saveBilling),
            ],
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF0EA5E9).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: const Color(0xFF0EA5E9), size: 22),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            fontFamily: 'Cairo',
            color: Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }

  Widget _card({
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Cairo',
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        style: const TextStyle(fontFamily: 'Cairo', fontSize: 13),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(fontFamily: 'Cairo', fontSize: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF0EA5E9), width: 1.5),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          isDense: true,
        ),
      ),
    );
  }

  Widget _saveBtn(bool isLoading, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: isLoading ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF0EA5E9),
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        icon: isLoading
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2),
              )
            : const Icon(Icons.save_rounded, size: 18),
        label: Text(
          isLoading ? 'جاري الحفظ...' : 'حفظ',
          style: const TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
