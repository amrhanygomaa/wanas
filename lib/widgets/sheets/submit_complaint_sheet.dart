import 'package:flutter/material.dart';
import '../../services/complaints_service.dart';
import '../../services/residents_service.dart';
import '../../services/api_client.dart';

class SubmitComplaintSheet extends StatefulWidget {
  final VoidCallback? onSubmitted;
  const SubmitComplaintSheet({super.key, this.onSubmitted});

  static Future<void> show(BuildContext context,
      {VoidCallback? onSubmitted}) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SubmitComplaintSheet(onSubmitted: onSubmitted),
    );
  }

  @override
  State<SubmitComplaintSheet> createState() => _SubmitComplaintSheetState();
}

class _SubmitComplaintSheetState extends State<SubmitComplaintSheet> {
  final _formKey = GlobalKey<FormState>();
  final _subject = TextEditingController();
  final _description = TextEditingController();
  String _category = 'care_quality';
  String _priority = 'medium';
  String? _residentId;
  List<BackendResident> _residents = [];
  bool _loadingResidents = true;
  bool _isSubmitting = false;

  final _categories = const [
    {'value': 'care_quality', 'label': 'جودة الرعاية'},
    {'value': 'staff_behavior', 'label': 'تعامل الطاقم'},
    {'value': 'facility', 'label': 'المنشأة'},
    {'value': 'food', 'label': 'الطعام'},
    {'value': 'communication', 'label': 'التواصل'},
    {'value': 'general', 'label': 'عام'},
    {'value': 'other', 'label': 'أخرى'},
  ];

  final _priorities = const [
    {'value': 'low', 'label': 'منخفضة'},
    {'value': 'medium', 'label': 'متوسطة'},
    {'value': 'high', 'label': 'عالية'},
    {'value': 'critical', 'label': 'حرجة'},
  ];

  @override
  void initState() {
    super.initState();
    _loadResidents();
  }

  Future<void> _loadResidents() async {
    try {
      final list = await ResidentsService.instance.getAll();
      if (!mounted) return;
      setState(() {
        _residents = list;
        _loadingResidents = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingResidents = false);
    }
  }

  @override
  void dispose() {
    _subject.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);
    try {
      final c = await ComplaintsService.instance.create(
        category: _category,
        subject: _subject.text.trim(),
        description:
            _description.text.trim().isEmpty ? null : _description.text.trim(),
        priority: _priority,
        residentId: _residentId,
      );
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF10B981),
          content: Text(
            '✓ تم تقديم الشكوى (ID: ${c.id.substring(0, 8)}...) في AWS RDS',
            style: const TextStyle(fontFamily: 'Cairo'),
          ),
        ),
      );
      widget.onSubmitted?.call();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: Colors.redAccent,
        content: Text('فشل: ${e.message}',
            style: const TextStyle(fontFamily: 'Cairo')),
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: Colors.redAccent,
        content: Text('فشل: $e', style: const TextStyle(fontFamily: 'Cairo')),
      ));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF9900), Color(0xFFFFB14E)],
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'POST /complaints · AWS RDS',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'Cairo',
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'تقديم شكوى جديدة',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Cairo',
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'ستُحفظ مباشرة في جدول complaints',
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFF64748B),
                    fontFamily: 'Cairo',
                  ),
                ),
                const SizedBox(height: 20),
                if (!_loadingResidents && _residents.isNotEmpty)
                  DropdownButtonFormField<String>(
                    initialValue: _residentId,
                    decoration: _dec('المقيم (اختياري)'),
                    items: [
                      const DropdownMenuItem(
                          value: null, child: Text('بدون مقيم محدد')),
                      ..._residents.map((r) => DropdownMenuItem(
                            value: r.id,
                            child: Text(r.fullName),
                          )),
                    ],
                    onChanged: (v) => setState(() => _residentId = v),
                  ),
                if (!_loadingResidents && _residents.isNotEmpty)
                  const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _category,
                  decoration: _dec('الفئة *'),
                  items: _categories
                      .map((c) => DropdownMenuItem(
                            value: c['value'],
                            child: Text(c['label']!),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _category = v!),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _priority,
                  decoration: _dec('الأولوية *'),
                  items: _priorities
                      .map((p) => DropdownMenuItem(
                            value: p['value'],
                            child: Text(p['label']!),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _priority = v!),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _subject,
                  decoration: _dec('الموضوع *'),
                  style: const TextStyle(fontFamily: 'Cairo', fontSize: 14),
                  validator: (v) =>
                      (v?.trim().isEmpty ?? true) ? 'مطلوب' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _description,
                  decoration: _dec('التفاصيل (اختياري)'),
                  maxLines: 4,
                  style: const TextStyle(fontFamily: 'Cairo', fontSize: 14),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _isSubmitting ? null : _submit,
                    icon: _isSubmitting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.cloud_upload_rounded),
                    label: Text(
                      _isSubmitting ? 'جاري التقديم...' : 'تقديم في AWS RDS',
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF9900),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _dec(String label) => InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontFamily: 'Cairo', fontSize: 13),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      );
}
