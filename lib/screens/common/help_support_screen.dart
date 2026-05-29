import 'package:flutter/material.dart';

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  int? _expandedFaq;

  static const _faqs = [
    (
      q: 'كيف أتواصل مع أسرة المقيم؟',
      a: 'من خلال قسم "جسر الأسرة" في لوحة التحكم، يمكنك إرسال رسائل ومشاركة التحديثات مع ذوي المقيم مباشرةً.'
    ),
    (
      q: 'كيف أسجل تقرير وردية جديد؟',
      a: 'انتقل إلى "تسليم الوردية" من لوحة تحكم الممرض، واملأ بيانات الحالة والملاحظات، ثم اضغط "إرسال التقرير".'
    ),
    (
      q: 'كيف أضيف دواءً جديداً للمقيم؟',
      a: 'من شاشة "الأدوية"، اضغط على زر الإضافة (+) وأدخل اسم الدواء والجرعة والتوقيت. سيتم إشعار الممرض المسؤول تلقائياً.'
    ),
    (
      q: 'كيف أحجز زيارة لقريبي؟',
      a: 'من لوحة تحكم الأسرة، اختر "حجز زيارة" وحدد التاريخ والوقت المناسب. ستصلك رسالة تأكيد خلال ٢٤ ساعة.'
    ),
    (
      q: 'هل يمكنني استرداد كلمة المرور؟',
      a: 'نعم. من شاشة تسجيل الدخول، اضغط "نسيت كلمة المرور" وأدخل بريدك الإلكتروني المسجل لاستقبال رابط الاسترداد.'
    ),
    (
      q: 'ما معنى النقاط والمكافآت للمتطوع؟',
      a: 'تُمنح النقاط عند إتمام كل مهمة تطوعية. تراكم النقاط يُحسب في شهادة التطوع النهائية ويُعرض في ملفك الشخصي.'
    ),
    (
      q: 'كيف أتحكم في إشعارات التطبيق؟',
      a: 'من "إعدادات الحساب" ثم "الإشعارات"، يمكنك تفعيل أو تعطيل كل نوع من الإشعارات حسب تفضيلاتك.'
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1e293b),
        foregroundColor: Colors.white,
        title: const Text('المساعدة والدعم',
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
          _buildContactCards(context),
          const SizedBox(height: 24),
          _sectionHeader('الأسئلة الشائعة'),
          _buildFaqList(),
          const SizedBox(height: 24),
          _sectionHeader('تواصل معنا'),
          _buildContactForm(context),
          const SizedBox(height: 24),
          _sectionHeader('معلومات التطبيق'),
          _buildAppInfo(),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildContactCards(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _contactCard(
            icon: Icons.headset_mic_outlined,
            label: 'دعم مباشر',
            sub: 'تحدث مع فريقنا',
            color: const Color(0xFF0ea5e9),
            onTap: () => _showComingSoon(context),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _contactCard(
            icon: Icons.email_outlined,
            label: 'راسلنا',
            sub: 'support@wanas.app',
            color: const Color(0xFF059669),
            onTap: () => _showComingSoon(context),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _contactCard(
            icon: Icons.bug_report_outlined,
            label: 'إبلاغ',
            sub: 'عن مشكلة',
            color: const Color(0xFFf59e0b),
            onTap: () => _showReportSheet(context),
          ),
        ),
      ],
    );
  }

  Widget _contactCard({
    required IconData icon,
    required String label,
    required String sub,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                  color: color.withValues(alpha: 0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 4))
            ]),
        child: Column(children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 8),
          Text(label,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1e293b))),
          Text(sub,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 10, color: Color(0xFF94a3b8))),
        ]),
      ),
    );
  }

  Widget _buildFaqList() {
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
      child: Column(
        children: List.generate(_faqs.length, (i) {
          final isLast = i == _faqs.length - 1;
          final isExpanded = _expandedFaq == i;
          return Column(
            children: [
              InkWell(
                borderRadius: BorderRadius.vertical(
                  top: i == 0 ? const Radius.circular(18) : Radius.zero,
                  bottom: isLast ? const Radius.circular(18) : Radius.zero,
                ),
                onTap: () =>
                    setState(() => _expandedFaq = isExpanded ? null : i),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      Icon(
                          isExpanded
                              ? Icons.keyboard_arrow_up_rounded
                              : Icons.keyboard_arrow_down_rounded,
                          color: const Color(0xFF94a3b8),
                          size: 20),
                      const Spacer(),
                      Expanded(
                        flex: 8,
                        child: Text(_faqs[i].q,
                            textAlign: TextAlign.right,
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: isExpanded
                                    ? FontWeight.bold
                                    : FontWeight.w600,
                                color: isExpanded
                                    ? const Color(0xFF1e293b)
                                    : const Color(0xFF334155))),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                            color: isExpanded
                                ? const Color(0xFF1e293b)
                                : const Color(0xFFf1f5f9),
                            shape: BoxShape.circle),
                        child: Center(
                          child: Text('${i + 1}',
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: isExpanded
                                      ? Colors.white
                                      : const Color(0xFF94a3b8))),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (isExpanded)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFe2e8f0))),
                  child: Text(_faqs[i].a,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                          fontSize: 13, color: Color(0xFF475569), height: 1.7)),
                ),
              if (!isLast)
                const Divider(
                    height: 1,
                    thickness: 0.5,
                    indent: 16,
                    endIndent: 16,
                    color: Color(0xFFf1f5f9)),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildContactForm(BuildContext context) {
    final ctrl = TextEditingController();
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
          const Text('أرسل استفساراً',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1e293b))),
          const SizedBox(height: 4),
          const Text('سيتم الرد خلال ٢٤ ساعة عمل',
              style: TextStyle(fontSize: 12, color: Color(0xFF94a3b8))),
          const SizedBox(height: 16),
          TextField(
            controller: ctrl,
            maxLines: 4,
            textAlign: TextAlign.right,
            decoration: InputDecoration(
              hintText: 'اكتب استفساركم أو اقتراحكم هنا...',
              hintStyle:
                  const TextStyle(fontSize: 13, color: Color(0xFF94a3b8)),
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
                  borderSide:
                      const BorderSide(color: Color(0xFF1e293b), width: 2)),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () {
                ctrl.clear();
                _showComingSoon(context);
              },
              icon:
                  const Icon(Icons.send_rounded, color: Colors.white, size: 18),
              label: const Text('إرسال',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15)),
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1e293b),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14))),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppInfo() {
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
      child: Column(children: [
        _infoRow('اسم التطبيق', 'ونس — Wanas'),
        _divider(),
        _infoRow('الإصدار', '١.٢.٠'),
        _divider(),
        _infoRow('آخر تحديث', 'مايو ٢٠٢٦'),
        _divider(),
        _infoRow('المطوّر', 'Helpers Tech'),
        _divider(),
        _infoRow('التواصل', 'support@wanas.app'),
        _divider(),
        _infoRow('الموقع', 'wanas.app'),
      ]),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(value,
              style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF475569),
                  fontWeight: FontWeight.w500)),
          Text(label,
              style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF1e293b),
                  fontWeight: FontWeight.bold)),
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

  Widget _divider() =>
      const Divider(height: 1, thickness: 0.5, color: Color(0xFFf1f5f9));

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

  void _showReportSheet(BuildContext context) {
    String? selected;
    final categories = [
      'خطأ تقني في التطبيق',
      'مشكلة في البيانات',
      'مشكلة في الأداء',
      'اقتراح تحسين',
      'أخرى',
    ];
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
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
            const Text('الإبلاغ عن مشكلة',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            ...categories.map((cat) => GestureDetector(
                  onTap: () => setModal(() => selected = cat),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(children: [
                      Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: selected == cat
                                  ? const Color(0xFF1e293b)
                                  : const Color(0xFFcbd5e1),
                              width: 2),
                          color: selected == cat
                              ? const Color(0xFF1e293b)
                              : Colors.transparent,
                        ),
                        child: selected == cat
                            ? const Icon(Icons.check,
                                color: Colors.white, size: 14)
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(cat,
                            textAlign: TextAlign.right,
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: selected == cat
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: const Color(0xFF1e293b))),
                      ),
                    ]),
                  ),
                )),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: selected == null
                    ? null
                    : () {
                        Navigator.pop(ctx);
                        _showComingSoon(context);
                      },
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1e293b),
                    disabledBackgroundColor: const Color(0xFFe2e8f0),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14))),
                child: const Text('إرسال البلاغ',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
