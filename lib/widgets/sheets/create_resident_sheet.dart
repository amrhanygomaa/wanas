import 'package:flutter/material.dart';
import '../../services/residents_service.dart';
import '../../services/api_client.dart';

class CreateResidentSheet extends StatefulWidget {
  final VoidCallback? onCreated;
  const CreateResidentSheet({super.key, this.onCreated});

  static Future<void> show(BuildContext context,
      {VoidCallback? onCreated}) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CreateResidentSheet(onCreated: onCreated),
    );
  }

  @override
  State<CreateResidentSheet> createState() => _CreateResidentSheetState();
}

class _CreateResidentSheetState extends State<CreateResidentSheet> {
  final _formKey = GlobalKey<FormState>();
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _nationalId = TextEditingController();
  final _room = TextEditingController();
  final _notes = TextEditingController();
  DateTime _dateOfBirth =
      DateTime.now().subtract(const Duration(days: 365 * 75));
  DateTime _admissionDate = DateTime.now();
  String _gender = 'male';
  bool _isSubmitting = false;

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _nationalId.dispose();
    _room.dispose();
    _notes.dispose();
    super.dispose();
  }

  String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _pickDate(BuildContext ctx, DateTime initial,
      ValueChanged<DateTime> onPicked) async {
    final picked = await showDatePicker(
      context: ctx,
      initialDate: initial,
      firstDate: DateTime(1920),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null) onPicked(picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);
    try {
      final resident = await ResidentsService.instance.create(
        firstName: _firstName.text.trim(),
        lastName: _lastName.text.trim(),
        dateOfBirth: _fmt(_dateOfBirth),
        gender: _gender,
        admissionDate: _fmt(_admissionDate),
        nationalId:
            _nationalId.text.trim().isEmpty ? null : _nationalId.text.trim(),
        roomNumber: _room.text.trim().isEmpty ? null : _room.text.trim(),
        notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      );
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF10B981),
          content: Text(
            '✓ تم إضافة المقيم ${resident.fullName} في السيرفر',
            style: const TextStyle(fontFamily: 'Cairo'),
          ),
        ),
      );
      widget.onCreated?.call();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.redAccent,
          content: Text('فشل: ${e.message}',
              style: const TextStyle(fontFamily: 'Cairo')),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.redAccent,
          content: Text('فشل: $e', style: const TextStyle(fontFamily: 'Cairo')),
        ),
      );
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
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF9900), Color(0xFFFFB14E)],
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'POST · السيرفر',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'Cairo',
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'إضافة مقيم جديد',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Cairo',
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'يتم حفظ البيانات في PostgreSQL على السيرفر مباشرة',
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFF64748B),
                    fontFamily: 'Cairo',
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _textField(
                        _firstName,
                        'الاسم الأول *',
                        validator: (v) =>
                            (v?.trim().isEmpty ?? true) ? 'مطلوب' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _textField(
                        _lastName,
                        'اسم العائلة *',
                        validator: (v) =>
                            (v?.trim().isEmpty ?? true) ? 'مطلوب' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _pickerField(
                        'تاريخ الميلاد *',
                        _fmt(_dateOfBirth),
                        () => _pickDate(context, _dateOfBirth,
                            (d) => setState(() => _dateOfBirth = d)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _gender,
                        decoration: _decoration('الجنس *'),
                        items: const [
                          DropdownMenuItem(value: 'male', child: Text('ذكر')),
                          DropdownMenuItem(
                              value: 'female', child: Text('أنثى')),
                          DropdownMenuItem(value: 'other', child: Text('آخر')),
                        ],
                        onChanged: (v) => setState(() => _gender = v!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _pickerField(
                        'تاريخ الدخول *',
                        _fmt(_admissionDate),
                        () => _pickDate(context, _admissionDate,
                            (d) => setState(() => _admissionDate = d)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _textField(_room, 'رقم الغرفة'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _textField(_nationalId, 'الرقم القومي (اختياري)'),
                const SizedBox(height: 12),
                _textField(_notes, 'ملاحظات (اختياري)', maxLines: 3),
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
                      _isSubmitting ? 'جاري الحفظ في السيرفر...' : 'حفظ في السيرفر',
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
                const SizedBox(height: 8),
                const Text(
                  '⚠️ تحتاج لحساب بدور Admin في Cognito',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 10,
                    color: Color(0xFF94A3B8),
                    fontFamily: 'Cairo',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _decoration(String label) => InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontFamily: 'Cairo', fontSize: 13),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      );

  Widget _textField(TextEditingController c, String label,
      {int maxLines = 1, String? Function(String?)? validator}) {
    return TextFormField(
      controller: c,
      decoration: _decoration(label),
      style: const TextStyle(fontFamily: 'Cairo', fontSize: 14),
      maxLines: maxLines,
      validator: validator,
    );
  }

  Widget _pickerField(String label, String value, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: _decoration(label),
        child: Text(value,
            style: const TextStyle(fontFamily: 'Cairo', fontSize: 14)),
      ),
    );
  }
}
