import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/app_riverpod.dart';
import '../../models/app_models.dart';

// شاشة تسليم الوردية (Shift Handoff) - لضمان انتقال آمن وسلس للمعلومات بين الممرضين
class ShiftHandoffScreen extends ConsumerStatefulWidget {
  const ShiftHandoffScreen({super.key});

  @override
  ConsumerState<ShiftHandoffScreen> createState() => _ShiftHandoffScreenState();
}

class _ShiftHandoffScreenState extends ConsumerState<ShiftHandoffScreen> {
  bool _isConfirmed = false; // حالة إقرار الممرض بصحة البيانات المسلمة
  final TextEditingController _incomingNurseName =
      TextEditingController(); // متحكم اسم الممرض المستلم
  bool _isGeneratingSummary = false;
  String? _aiSummary;

  @override
  void dispose() {
    _incomingNurseName.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = ref.watch(appRiverpod);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('تسليم الوردية',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontSize: 18)),
        backgroundColor: const Color(0xFF0369A1),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded,
              color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          _buildTopBanner(), // بنر توضيحي لنوع الوردية (صباحية/مسائية)
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // قسم ملخص القراءات الحيوية المسجلة خلال الوردية
                  _buildSectionHeader('ملخص القراءات الحيوية'),
                  _buildSummaryCard([
                    _summaryRow('قراءات ضغط الدم', '١٨ قراءة تم تسجيلها'),
                    _summaryRow('قراءات السكر', '١٢ قراءة تم تسجيلها'),
                    _summaryRow('حالات خارج المعدل', '٢ حالة (تم التعامل)',
                        isCritical: true),
                  ]),
                  const SizedBox(height: 24),

                  // قسم ملخص الأدوية التي تم إعطاؤها أو تأجيلها
                  _buildSectionHeader('سجل الأدوية'),
                  _buildSummaryCard([
                    _summaryRow('أدوية تم إعطاؤها', '٦٤ جرعة'),
                    _summaryRow('أدوية مؤجلة/مرفوضة', '٠ جرعة'),
                    _summaryRow('أدوية طوارئ (PRN)', '١ جرعة (أسبوسيد)'),
                  ]),
                  const SizedBox(height: 24),

                  // قسم الملاحظات التمريضية الجديدة المضافة للمقيمين
                  _buildSectionHeader('الملاحظات التمريضية'),
                  _buildSummaryCard([
                    _summaryRow('إجمالي الملاحظات',
                        '${provider.nursingNotes.length} ملاحظة جديدة'),
                    _summaryRow('تحديثات الملف الطبي', '٤ تحديثات'),
                  ]),
                  const SizedBox(height: 16),
                  _buildAiSummarySection(provider),
                  const SizedBox(height: 32),

                  _buildHandoverSection(), // واجهة إدخال بيانات الممرض المستلم والإقرار
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
          _buildActionFooter(), // زر الإنهاء النهائي للوردية
        ],
      ),
    );
  }

  Widget _buildTopBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: const BoxDecoration(
        color: Color(0xFF0369A1),
        borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
      ),
      child: Column(
        children: [
          const Text('تقرير الاستلام والتسليم النهائي',
              style: TextStyle(color: Color(0xFFE0F2FE), fontSize: 12)),
          const SizedBox(height: 4),
          const Text('الوردية الصباحية ➔ الوردية المسائية',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12)),
            child: const Text('الأحد، ٢٦ أبريل ٢٠٢٤',
                style: TextStyle(color: Colors.white, fontSize: 11)),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, right: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B))),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
              color: const Color(0xFF0369A1).withValues(alpha: 0.03),
              blurRadius: 15,
              offset: const Offset(0, 5))
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _summaryRow(String label, String value, {bool isCritical = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B))),
          Text(value,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isCritical
                      ? const Color(0xFFEF4444)
                      : const Color(0xFF0369A1))),
        ],
      ),
    );
  }

  Widget _buildAiSummarySection(AppRiverpod provider) {
    if (_aiSummary != null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F3FF),
          border: Border.all(color: const Color(0xFFC4B5FD)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.auto_awesome, color: Color(0xFF8B5CF6), size: 20),
                SizedBox(width: 8),
                Text('ملخص الذكاء الاصطناعي للشيفت', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF6D28D9))),
              ],
            ),
            const SizedBox(height: 8),
            Text(_aiSummary!, style: const TextStyle(fontSize: 13, color: Color(0xFF4C1D95), height: 1.5)),
          ],
        ),
      );
    }
    
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: _isGeneratingSummary
            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : const Icon(Icons.auto_awesome, size: 18),
        label: Text(_isGeneratingSummary ? 'جاري التلخيص...' : '✨ تلخيص الشيفت بالذكاء الاصطناعي'),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF8B5CF6),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
        onPressed: _isGeneratingSummary ? null : () async {
          setState(() => _isGeneratingSummary = true);
          final summary = await provider.generateShiftSummary('الكل');
          setState(() {
            _aiSummary = summary;
            _isGeneratingSummary = false;
          });
        },
      ),
    );
  }

  Widget _buildHandoverSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient:
            const LinearGradient(colors: [Color(0xFFF1F5F9), Colors.white]),
        borderRadius: BorderRadius.circular(24),
        border:
            Border.all(color: const Color(0xFF0EA5E9).withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('بيانات التسليم للممرض البديل',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A))),
          const SizedBox(height: 16),
          TextField(
            controller: _incomingNurseName,
            textAlign: TextAlign.right,
            decoration: InputDecoration(
              hintText: 'اسم الممرض المستلم',
              hintStyle:
                  const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Checkbox(
                value: _isConfirmed,
                onChanged: (v) => setState(() => _isConfirmed = v!),
                activeColor: const Color(0xFF0EA5E9),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4)),
              ),
              const Expanded(
                  child: Text('أقر بأنني قمت بتسليم كافة المهام والحالات',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B)))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionFooter() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -5))
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: (_isConfirmed && _incomingNurseName.text.isNotEmpty)
              ? () => _handleFinalHandoff()
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0369A1),
            foregroundColor: Colors.white,
            disabledBackgroundColor: const Color(0xFFE2E8F0),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 0,
          ),
          child: const Text('إتمام عملية التسليم والخروج',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  Future<void> _handleFinalHandoff() async {
    final provider = ref.read(appRiverpod);
    final criticalCases = provider.residentFiles
        .where((resident) =>
            resident.status.toLowerCase().contains('critical') ||
            resident.status.contains('حرج'))
        .map((resident) => resident.name)
        .toList();
    await provider.submitHandoff(ShiftHandoff(
      nurseName: provider.currentAccount?.name ?? 'فريق التمريض',
      shiftType: _currentShiftName(),
      notes: 'تم تسليم الوردية بنجاح إلى ${_incomingNurseName.text}',
      timestamp: DateTime.now(),
      criticalCases: criticalCases,
    ));

    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(24)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 24),
              const Text('تم التسليم بنجاح ✅',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      fontFamily: 'Cairo',
                      decoration: TextDecoration.none,
                      color: Color(0xFF0F172A))),
              const SizedBox(height: 12),
              const Text('شكراً لمجهودك في هذه الوردية',
                  style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF64748B),
                      decoration: TextDecoration.none,
                      fontFamily: 'Cairo')),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context); // Exit screen
                  // In a real app, we would log out here
                },
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0369A1),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12))),
                child: const Text('الرجوع للشاشة الرئيسية',
                    style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _currentShiftName() {
    final hour = DateTime.now().hour;
    if (hour >= 6 && hour < 14) return 'الوردية الصباحية';
    if (hour >= 14 && hour < 22) return 'الوردية المسائية';
    return 'الوردية الليلية';
  }
}
