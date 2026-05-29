import 'package:flutter/material.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1e293b),
        foregroundColor: Colors.white,
        title: const Text('الأمان والخصوصية',
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
          _buildBanner(),
          const SizedBox(height: 24),
          _sectionHeader('إدارة البيانات'),
          _buildCard([
            _navTile(
              icon: Icons.manage_accounts_outlined,
              label: 'بيانات الحساب المحفوظة',
              subtitle: 'عرض ما يتم تخزينه عنك',
              onTap: () => _showDataSheet(context),
            ),
            _divider(),
            _navTile(
              icon: Icons.history_rounded,
              label: 'سجل النشاط',
              subtitle: 'مراجعة نشاطك داخل التطبيق',
              onTap: () => _showComingSoon(context),
            ),
            _divider(),
            _navTile(
              icon: Icons.delete_sweep_outlined,
              label: 'مسح سجل النشاط',
              subtitle: 'حذف سجل الاستخدام المحفوظ',
              color: Colors.red,
              onTap: () => _showClearHistoryDialog(context),
            ),
          ]),
          const SizedBox(height: 20),
          _sectionHeader('سياسة الخصوصية'),
          _buildPolicyCard(),
          const SizedBox(height: 20),
          _sectionHeader('شروط الاستخدام'),
          _buildTermsCard(),
          const SizedBox(height: 20),
          _sectionHeader('الأذونات'),
          _buildCard([
            _permissionTile(Icons.camera_alt_outlined, 'الكاميرا',
                'لالتقاط صور الملف الشخصي والذكريات'),
            _divider(),
            _permissionTile(Icons.photo_library_outlined, 'معرض الصور',
                'للوصول إلى صور الألبوم الشخصي'),
            _divider(),
            _permissionTile(Icons.notifications_outlined, 'الإشعارات',
                'لإرسال تذكيرات الأدوية والمواعيد'),
            _divider(),
            _permissionTile(Icons.location_on_outlined, 'الموقع الجغرافي',
                'لعرض خريطة المنشأة'),
          ]),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildBanner() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1e293b), Color(0xFF334155)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: const Color(0xFF1e293b).withValues(alpha: 0.3),
              blurRadius: 16,
              offset: const Offset(0, 6))
        ],
      ),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('بياناتك في أمان',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
                SizedBox(height: 6),
                Text(
                    'نحن نحمي خصوصيتك ونلتزم بأعلى\nمعايير أمان البيانات الصحية.',
                    textAlign: TextAlign.right,
                    style: TextStyle(color: Colors.white70, fontSize: 13)),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                shape: BoxShape.circle),
            child: const Icon(Icons.shield_outlined,
                color: Colors.white, size: 32),
          ),
        ],
      ),
    );
  }

  Widget _buildPolicyCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 12,
                offset: const Offset(0, 4))
          ]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _policySection('جمع البيانات',
              'نجمع فقط البيانات الضرورية لتقديم خدمات الرعاية الصحية للمسنين، وتشمل: الاسم، ورقم الهاتف، والبيانات الطبية الأساسية.'),
          const SizedBox(height: 16),
          _policySection('استخدام البيانات',
              'تُستخدم بياناتك حصرياً لتحسين جودة الرعاية المقدمة، ومتابعة الحالة الصحية، والتواصل مع الأسرة والطاقم الطبي.'),
          const SizedBox(height: 16),
          _policySection('مشاركة البيانات',
              'لا نشارك بياناتك مع أي طرف ثالث دون موافقتك الصريحة، باستثناء ما تقتضيه المتطلبات القانونية.'),
          const SizedBox(height: 16),
          _policySection('حماية البيانات',
              'نستخدم تشفيراً من طرف إلى طرف لحماية جميع البيانات المنقولة والمخزنة، وفق معايير HIPAA الدولية للبيانات الصحية.'),
          const SizedBox(height: 16),
          _policySection('حقوقك',
              'يحق لك في أي وقت: الاطلاع على بياناتك، تصحيحها، تصديرها، أو طلب حذفها نهائياً من أنظمتنا.'),
          const SizedBox(height: 16),
          _policySection('تحديث السياسة',
              'نحتفظ بالحق في تحديث سياسة الخصوصية دورياً. سيتم إشعارك بأي تغييرات جوهرية عبر التطبيق مباشرةً.'),
        ],
      ),
    );
  }

  Widget _buildTermsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 12,
                offset: const Offset(0, 4))
          ]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _policySection('قبول الشروط',
              'باستخدامك لتطبيق ونس، فأنت توافق على الالتزام بهذه الشروط والأحكام. إن لم توافق، يرجى التوقف عن استخدام التطبيق.'),
          const SizedBox(height: 16),
          _policySection('الاستخدام المسموح',
              'يُسمح باستخدام التطبيق لأغراض الرعاية الصحية للمسنين فقط. يُحظر أي استخدام تجاري أو غير قانوني للبيانات.'),
          const SizedBox(height: 16),
          _policySection('المسؤولية',
              'التطبيق أداة مساعدة ولا يُعد بديلاً عن الرأي الطبي المتخصص. يتحمل المستخدم مسؤولية القرارات الطبية المتخذة.'),
          const SizedBox(height: 16),
          _policySection('إنهاء الخدمة',
              'نحتفظ بالحق في تعليق أو إنهاء الحساب في حال ثبوت إساءة الاستخدام أو انتهاك هذه الشروط.'),
        ],
      ),
    );
  }

  Widget _policySection(String title, String body) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(title,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1e293b))),
            const SizedBox(width: 8),
            const Icon(Icons.circle, size: 8, color: Color(0xFF1e293b)),
          ],
        ),
        const SizedBox(height: 6),
        Text(body,
            textAlign: TextAlign.right,
            style: const TextStyle(
                fontSize: 13, color: Color(0xFF475569), height: 1.6)),
      ],
    );
  }

  Widget _permissionTile(IconData icon, String label, String subtitle) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      trailing: Icon(icon, color: const Color(0xFF475569), size: 22),
      title: Text(label,
          textAlign: TextAlign.right,
          style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF1e293b),
              fontSize: 15)),
      subtitle: Text(subtitle,
          textAlign: TextAlign.right,
          style: const TextStyle(fontSize: 12, color: Color(0xFF94a3b8))),
      leading: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
            color: const Color(0xFFf0fdf4),
            borderRadius: BorderRadius.circular(8)),
        child: const Text('مفعّل',
            style: TextStyle(
                fontSize: 11,
                color: Color(0xFF059669),
                fontWeight: FontWeight.bold)),
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
      trailing: Icon(icon, color: color ?? const Color(0xFF475569), size: 22),
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

  Widget _divider() => const Divider(
      height: 1,
      thickness: 0.5,
      indent: 16,
      endIndent: 16,
      color: Color(0xFFf1f5f9));

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

  void _showDataSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(4))),
          const SizedBox(height: 20),
          const Text('البيانات المحفوظة',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          _dataRow('الاسم', 'محفوظ'),
          _dataRow('رقم الهاتف', 'محفوظ'),
          _dataRow('البريد الإلكتروني', 'محفوظ'),
          _dataRow('الصورة الشخصية', 'محفوظ'),
          _dataRow('البيانات الطبية', 'محمي ومشفّر'),
          _dataRow('سجل النشاط', 'محفوظ لـ ٣٠ يوم'),
          const SizedBox(height: 16),
        ]),
      ),
    );
  }

  Widget _dataRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
                color: const Color(0xFFf0fdf4),
                borderRadius: BorderRadius.circular(8)),
            child: Text(value,
                style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF059669),
                    fontWeight: FontWeight.bold)),
          ),
          Text(label,
              style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF1e293b),
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  void _showClearHistoryDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('مسح سجل النشاط',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('سيتم حذف سجل نشاطك كاملاً. هل أنت متأكد؟',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Color(0xFF475569))),
        actionsPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
                  Navigator.pop(ctx);
                  _showComingSoon(context);
                },
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12))),
                child: const Text('مسح', style: TextStyle(color: Colors.white)),
              ),
            ),
          ]),
        ],
      ),
    );
  }
}
