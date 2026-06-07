import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/app_riverpod.dart';
import '../../services/biometric_service.dart';

class AccountSettingsScreen extends ConsumerStatefulWidget {
  const AccountSettingsScreen({super.key});

  @override
  ConsumerState<AccountSettingsScreen> createState() =>
      _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends ConsumerState<AccountSettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final provider = ref.watch(appRiverpod);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1e293b),
        foregroundColor: Colors.white,
        title: const Text('إعدادات التطبيق',
            style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(20))),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 8),
          _sectionHeader('المظهر والعرض'),
          _buildCard([
            _fontScaleTile(provider),
          ]),
          const SizedBox(height: 20),
          _sectionHeader('الأمان'),
          _buildCard([
            _navTile(
              icon: Icons.lock_outline_rounded,
              label: 'تغيير كلمة المرور',
              subtitle: 'تحديث بيانات الدخول',
              onTap: () => _showChangePasswordSheet(context),
            ),
            _divider(),
            _biometricTile(provider),
          ]),
          const SizedBox(height: 20),
          _sectionHeader('الإشعارات'),
          _buildCard([
            _switchTile(
              icon: Icons.notifications_outlined,
              label: 'الإشعارات العامة',
              subtitle: 'تنبيهات التطبيق والأحداث',
              value: true,
              onChanged: (_) => _showComingSoon(context),
            ),
            _divider(),
            _switchTile(
              icon: Icons.medication_outlined,
              label: 'تذكير الأدوية',
              subtitle: 'مواعيد الجرعات اليومية',
              value: true,
              onChanged: (_) => _showComingSoon(context),
            ),
          ]),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, right: 4),
      child: Text(title,
          textAlign: TextAlign.right,
          style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Color(0xFF64748b),
              letterSpacing: 0.5)),
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 12,
                offset: const Offset(0, 4))
          ]),
      child: Column(children: children),
    );
  }

  Widget _switchTile({
    required IconData icon,
    required String label,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeThumbColor: Colors.white,
            activeTrackColor: const Color(0xFF1e293b),
          ),
          const Spacer(),
          Expanded(
            flex: 6,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(label,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: color ?? const Color(0xFF1e293b),
                        fontSize: 15)),
                Text(subtitle,
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFF94a3b8))),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Icon(icon,
              color: color ?? const Color(0xFF1e293b).withValues(alpha: 0.7),
              size: 22),
        ],
      ),
    );
  }

  Widget _navTile({
    required IconData icon,
    required String label,
    required String subtitle,
    required VoidCallback onTap,
    Color? color,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: const Icon(Icons.arrow_back_ios_new_rounded,
          size: 14, color: Color(0xFF94a3b8)),
      trailing: Icon(icon,
          color: color ?? const Color(0xFF1e293b).withValues(alpha: 0.7),
          size: 22),
      title: Text(label,
          textAlign: TextAlign.right,
          style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color ?? const Color(0xFF1e293b),
              fontSize: 15)),
      subtitle: Text(subtitle,
          textAlign: TextAlign.right,
          style: const TextStyle(fontSize: 12, color: Color(0xFF94a3b8))),
    );
  }

  Widget _fontScaleTile(AppRiverpod provider) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text('${(provider.fontScaleFactor * 100).round()}٪',
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1e293b))),
              const SizedBox(width: 8),
              const Text('حجم الخط',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1e293b))),
              const SizedBox(width: 12),
              const Icon(Icons.text_fields_rounded,
                  color: Color(0xFF1e293b), size: 22),
            ],
          ),
          Slider(
            value: provider.fontScaleFactor,
            min: 0.8,
            max: 1.4,
            divisions: 6,
            activeColor: const Color(0xFF1e293b),
            inactiveColor: const Color(0xFFe2e8f0),
            onChanged: (v) => provider.updateFontScale(v),
          ),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('كبير',
                  style: TextStyle(fontSize: 11, color: Color(0xFF94a3b8))),
              Text('صغير',
                  style: TextStyle(fontSize: 11, color: Color(0xFF94a3b8))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _biometricTile(AppRiverpod provider) {
    return FutureBuilder<bool>(
      future: BiometricService.instance.isAvailable(),
      builder: (context, snapshot) {
        final available = snapshot.data ?? false;
        return FutureBuilder<String>(
          future: BiometricService.instance.getBiometricLabel(),
          builder: (context, labelSnap) {
            final label = labelSnap.data ?? 'التحقق البيومتري';
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(children: [
                available
                    ? Switch.adaptive(
                        value: provider.isBiometricEnabled,
                        activeThumbColor: Colors.white,
                        activeTrackColor: const Color(0xFF1e293b),
                        onChanged: (val) =>
                            _toggleBiometric(context, provider, val),
                      )
                    : const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Text('غير متاح',
                            style: TextStyle(
                                fontSize: 11, color: Color(0xFFcbd5e1))),
                      ),
                const Spacer(),
                Expanded(
                  flex: 6,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(label,
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: available
                                  ? const Color(0xFF1e293b)
                                  : const Color(0xFF94a3b8),
                              fontSize: 15)),
                      Text(
                          available
                              ? 'تسجيل الدخول دون كلمة مرور'
                              : 'الجهاز لا يدعم هذه الميزة',
                          style: const TextStyle(
                              fontSize: 12, color: Color(0xFF94a3b8))),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Icon(Icons.fingerprint_rounded,
                    color: available
                        ? const Color(0xFF1e293b).withValues(alpha: 0.7)
                        : const Color(0xFFcbd5e1),
                    size: 22),
              ]),
            );
          },
        );
      },
    );
  }

  Future<void> _toggleBiometric(
      BuildContext context, AppRiverpod provider, bool enable) async {
    if (enable) {
      final available = await BiometricService.instance.isAvailable();
      if (!available) {
        if (!context.mounted) return;
        _showSnack(context, 'الجهاز لا يدعم التحقق البيومتري', error: true);
        return;
      }
      // تأكيد الهوية بالبيومتري أولاً
      final confirmed = await BiometricService.instance
          .authenticate(reason: 'أكّد هويتك لتفعيل تسجيل الدخول البيومتري');
      if (!confirmed) return;
      if (!context.mounted) return;
      // طلب كلمة المرور لحفظها مع البيومتري
      final password =
          await _askPassword(context, provider.currentAccount?.email ?? '');
      if (password == null) return;
      await provider.saveBiometricCredentials(
          provider.currentAccount?.email ?? '', password);
      await provider.setBiometricEnabled(true);
      if (!context.mounted) return;
      _showSnack(context, 'تم تفعيل تسجيل الدخول البيومتري بنجاح');
    } else {
      await provider.setBiometricEnabled(false);
      if (!context.mounted) return;
      _showSnack(context, 'تم تعطيل التحقق البيومتري');
    }
  }

  /// يعرض dialog لإدخال كلمة المرور ويرجعها عند التأكيد، أو null عند الإلغاء
  Future<String?> _askPassword(BuildContext context, String email) async {
    final ctrl = TextEditingController();
    bool obscure = true;
    return showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text('أدخل كلمة المرور',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(email,
                style: const TextStyle(fontSize: 13, color: Color(0xFF64748b))),
            const SizedBox(height: 16),
            TextField(
              controller: ctrl,
              obscureText: obscure,
              autofocus: true,
              textAlign: TextAlign.right,
              decoration: InputDecoration(
                hintText: 'كلمة المرور',
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                suffixIcon: IconButton(
                  icon: Icon(obscure ? Icons.visibility_off : Icons.visibility,
                      size: 20),
                  onPressed: () => setD(() => obscure = !obscure),
                ),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFe2e8f0))),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFe2e8f0))),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: Color(0xFF1e293b), width: 2)),
              ),
            ),
          ]),
          actionsPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          actions: [
            Row(children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12))),
                  child: const Text('إلغاء'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    if (ctrl.text.isNotEmpty) {
                      Navigator.pop(ctx, ctrl.text);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1e293b),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12))),
                  child: const Text('تأكيد',
                      style: TextStyle(color: Colors.white)),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }

  void _showSnack(BuildContext context, String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg,
          textAlign: TextAlign.center,
          style: const TextStyle(fontFamily: 'Cairo')),
      backgroundColor: error ? Colors.red : const Color(0xFF059669),
      behavior: SnackBarBehavior.floating,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12))),
    ));
  }

  Widget _divider() {
    return const Divider(
        height: 1,
        thickness: 0.5,
        indent: 16,
        endIndent: 16,
        color: Color(0xFFf1f5f9));
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('هذه الميزة قيد التطوير',
          textAlign: TextAlign.center, style: TextStyle(fontFamily: 'Cairo')),
      backgroundColor: Color(0xFF1e293b),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12))),
    ));
  }

  void _showChangePasswordSheet(BuildContext context) {
    final oldCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            left: 20,
            right: 20,
            top: 20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(4))),
          const SizedBox(height: 20),
          const Text('تغيير كلمة المرور',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          _passField(oldCtrl, 'كلمة المرور الحالية'),
          const SizedBox(height: 12),
          _passField(newCtrl, 'كلمة المرور الجديدة'),
          const SizedBox(height: 12),
          _passField(confirmCtrl, 'تأكيد كلمة المرور الجديدة'),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                _showComingSoon(context);
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1e293b),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14))),
              child: const Text('حفظ',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold)),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _passField(TextEditingController ctrl, String hint) {
    return TextField(
      controller: ctrl,
      obscureText: true,
      textAlign: TextAlign.right,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFe2e8f0))),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFe2e8f0))),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFF1e293b), width: 2)),
      ),
    );
  }
}
