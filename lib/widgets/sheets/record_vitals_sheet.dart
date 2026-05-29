import 'package:flutter/material.dart';
import '../../services/health_service.dart';
import '../../services/residents_service.dart';
import '../../services/api_client.dart';

class RecordVitalsSheet extends StatefulWidget {
  final VoidCallback? onRecorded;
  const RecordVitalsSheet({super.key, this.onRecorded});

  static Future<void> show(BuildContext context,
      {VoidCallback? onRecorded}) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => RecordVitalsSheet(onRecorded: onRecorded),
    );
  }

  @override
  State<RecordVitalsSheet> createState() => _RecordVitalsSheetState();
}

class _RecordVitalsSheetState extends State<RecordVitalsSheet> {
  final _formKey = GlobalKey<FormState>();
  final _hr = TextEditingController();
  final _sys = TextEditingController();
  final _dia = TextEditingController();
  final _temp = TextEditingController();
  final _o2 = TextEditingController();
  final _glucose = TextEditingController();
  final _notes = TextEditingController();
  String? _residentId;
  List<BackendResident> _residents = [];
  bool _loadingResidents = true;
  bool _isSubmitting = false;

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
        _residentId = list.isNotEmpty ? list.first.id : null;
        _loadingResidents = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingResidents = false);
    }
  }

  @override
  void dispose() {
    for (final c in [_hr, _sys, _dia, _temp, _o2, _glucose, _notes]) {
      c.dispose();
    }
    super.dispose();
  }

  int? _asInt(String s) => int.tryParse(s.trim());
  double? _asDouble(String s) => double.tryParse(s.trim());

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_residentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content:
            Text('اختر مقيماً أولاً', style: TextStyle(fontFamily: 'Cairo')),
      ));
      return;
    }
    final hr = _asInt(_hr.text);
    final sys = _asInt(_sys.text);
    final dia = _asInt(_dia.text);
    final temp = _asDouble(_temp.text);
    final o2 = _asInt(_o2.text);
    final glucose = _asInt(_glucose.text);

    if (hr == null &&
        sys == null &&
        temp == null &&
        o2 == null &&
        glucose == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('أدخل قراءة واحدة على الأقل',
            style: TextStyle(fontFamily: 'Cairo')),
      ));
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await HealthService.instance.recordVitals(
        residentId: _residentId!,
        heartRate: hr,
        bloodPressureSystolic: sys,
        bloodPressureDiastolic: dia,
        temperature: temp,
        oxygenSaturation: o2,
        bloodGlucose: glucose,
        notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      );
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFF10B981),
          content: Text(
            '✓ تم تسجيل القراءة في AWS RDS — التنبيهات تُولّد تلقائياً إذا تجاوزت الحدود',
            style: TextStyle(fontFamily: 'Cairo'),
          ),
        ),
      );
      widget.onRecorded?.call();
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
                    'POST /health/vitals · AWS RDS',
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
                  'تسجيل قراءة حيوية',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Cairo',
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'يتم توليد التنبيهات تلقائياً عند تجاوز vital_thresholds',
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFF64748B),
                    fontFamily: 'Cairo',
                  ),
                ),
                const SizedBox(height: 20),
                if (_loadingResidents)
                  const Center(child: CircularProgressIndicator())
                else if (_residents.isEmpty)
                  const Text(
                    'لا يوجد مقيمين في AWS RDS — أضف مقيماً أولاً',
                    style: TextStyle(
                      color: Color(0xFFEF4444),
                      fontFamily: 'Cairo',
                    ),
                  )
                else
                  DropdownButtonFormField<String>(
                    initialValue: _residentId,
                    decoration: _dec('المقيم *'),
                    items: _residents
                        .map((r) => DropdownMenuItem(
                              value: r.id,
                              child: Text(
                                  '${r.fullName}${r.roomNumber != null ? " · غرفة ${r.roomNumber}" : ""}'),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => _residentId = v),
                  ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _numField(_hr, 'النبض (bpm)')),
                    const SizedBox(width: 8),
                    Expanded(child: _numField(_temp, 'الحرارة (°C)')),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _numField(_sys, 'ضغط انقباضي')),
                    const SizedBox(width: 8),
                    Expanded(child: _numField(_dia, 'ضغط انبساطي')),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _numField(_o2, 'الأكسجين (%)')),
                    const SizedBox(width: 8),
                    Expanded(child: _numField(_glucose, 'سكر (mg/dL)')),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _notes,
                  decoration: _dec('ملاحظات (اختياري)'),
                  maxLines: 2,
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
                      _isSubmitting ? 'جاري الحفظ...' : 'حفظ في AWS RDS',
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

  Widget _numField(TextEditingController c, String label) {
    return TextFormField(
      controller: c,
      decoration: _dec(label),
      keyboardType:
          const TextInputType.numberWithOptions(decimal: true, signed: false),
      style: const TextStyle(fontFamily: 'Cairo', fontSize: 14),
    );
  }
}
