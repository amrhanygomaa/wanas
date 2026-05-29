import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../providers/app_riverpod.dart';
import '../../../models/app_models.dart';
import '../widgets/healing_particles.dart';

class MedicalAdminView extends ConsumerStatefulWidget {
  const MedicalAdminView({super.key});

  @override
  ConsumerState<MedicalAdminView> createState() => _MedicalAdminViewState();
}

class _MedicalAdminViewState extends ConsumerState<MedicalAdminView> {
  final TextEditingController _medName = TextEditingController();
  final TextEditingController _medDosage = TextEditingController();
  final TextEditingController _specialistName = TextEditingController();
  final TextEditingController _sessionNotes = TextEditingController();
  final TextEditingController _prescTitle = TextEditingController();
  final TextEditingController _bpSys = TextEditingController();
  final TextEditingController _bpDia = TextEditingController();
  final TextEditingController _glucose = TextEditingController();
  final TextEditingController _temp = TextEditingController();
  final TextEditingController _searchResident = TextEditingController();

  String _selectedResident = '';
  String _selectedTime = 'الصباح';
  String _sessionType = 'doctor'; // 'doctor' or 'pt'

  File? _prescriptionImage;
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _medName.dispose();
    _medDosage.dispose();
    _specialistName.dispose();
    _sessionNotes.dispose();
    _prescTitle.dispose();
    _bpSys.dispose();
    _bpDia.dispose();
    _glucose.dispose();
    _temp.dispose();
    _searchResident.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = ref.watch(appRiverpod);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                _buildResidentSelector(provider),
                const SizedBox(height: 32),
                const Text('الإجراءات السريعة',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A))),
                const SizedBox(height: 16),
                _buildQuickActionsGrid(provider),
                const SizedBox(height: 32),
                _buildSectionHeader(
                    'آخر العمليات المسجلة', Icons.history_rounded),
                const SizedBox(height: 16),
                ...provider.medicalSessions
                    .take(3)
                    .map((s) => _buildSessionLog(s, provider)),
                const SizedBox(height: 12),
                ...provider.medicalPrescriptions
                    .take(2)
                    .map((p) => _buildPrescriptionCard(p, provider)),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0369A1), Color(0xFF0EA5E9), Color(0xFF38BDF8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          const HealingParticles(),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text('الإدارة الطبية',
                        style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
                  ],
                ),
                const SizedBox(height: 8),
                Text('التحكم المركزي في الأدوية، الجلسات، والتقارير الطبية',
                    style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.9))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResidentSelector(AppRiverpod provider) {
    final residents = provider.residentFiles;
    final residentNames = residents.map((r) => r.name).toList();
    if (residentNames.isNotEmpty &&
        !residentNames.contains(_selectedResident)) {
      _selectedResident = residentNames.first;
      _searchResident.text = residents.first.room;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
              color: const Color(0xFF0F172A).withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: const Color(0xFFF0F9FF),
                borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.search_rounded,
                color: Color(0xFF0369A1), size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('البحث عن مقيم (بالاسم أو رقم الغرفة)',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF475569))),
                const SizedBox(height: 2),
                DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: residentNames.contains(_selectedResident)
                        ? _selectedResident
                        : null,
                    hint: const Text('لا توجد بيانات مقيمين من AWS'),
                    items: residents
                        .map(
                          (resident) => DropdownMenuItem(
                            value: resident.name,
                            child: Text(
                              '${resident.room} - ${resident.name}',
                              textAlign: TextAlign.right,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (val) {
                      if (val == null) return;
                      setState(() {
                        _selectedResident = val;
                        _searchResident.text = residents
                            .firstWhere((resident) => resident.name == val)
                            .room;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsGrid(AppRiverpod provider) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.1,
      children: [
        _buildActionTile(
          title: 'دواء جديد',
          icon: Icons.medication_rounded,
          color: const Color(0xFF0EA5E9),
          onTap: () => _showAddMedicationSheet(provider),
        ),
        _buildActionTile(
          title: 'علامات حيوية',
          icon: Icons.monitor_heart_rounded,
          color: const Color(0xFFF43F5E),
          onTap: () => _showVitalsSheet(provider),
        ),
        _buildActionTile(
          title: 'توثيق جلسة',
          icon: Icons.person_search_rounded,
          color: const Color(0xFF6366F1),
          onTap: () => _showLogSessionSheet(provider),
        ),
        _buildActionTile(
          title: 'رفع روشتة',
          icon: Icons.file_upload_rounded,
          color: const Color(0xFF10B981),
          onTap: () => _showUploadPrescriptionSheet(provider),
        ),
      ],
    );
  }

  Widget _buildActionTile(
      {required String title,
      required IconData icon,
      required Color color,
      required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color.withValues(alpha: 0.5), width: 1.5),
          boxShadow: [
            BoxShadow(
                color: color.withValues(alpha: 0.15),
                blurRadius: 10,
                offset: const Offset(0, 4))
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 12),
            Text(title,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A))),
          ],
        ),
      ),
    );
  }

  // --- Bottom Sheets Methods ---

  void _showAddMedicationSheet(AppRiverpod provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildSheetContainer(
        title: 'تسجيل دواء جديد لـ ${_selectedResident.split(' ')[0]}',
        color: const Color(0xFF0EA5E9),
        child: Column(
          children: [
            _buildTextField(_medName, 'اسم الدواء (مثال: كونكور ٥ ملغ)',
                Icons.medical_services_outlined),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                    child: _buildDropdown(
                        _selectedTime, ['الصباح', 'الظهر', 'المساء'], (v) {
                  setState(() => _selectedTime = v!);
                })),
                const SizedBox(width: 12),
                Expanded(
                    child: _buildTextField(_medDosage, 'الجرعة (مثال: قرص)',
                        Icons.shutter_speed_outlined)),
              ],
            ),
            const SizedBox(height: 24),
            _buildActionBtn('حفظ الدواء', const Color(0xFF0EA5E9), () {
              if (_medName.text.isNotEmpty) {
                provider.addMedication(
                    _selectedResident,
                    Medication(
                      id: DateTime.now().toString(),
                      name: _medName.text,
                      dosage: _medDosage.text,
                      timeDescription: 'حسب الجدول',
                      timeOfDay: _selectedTime,
                      dayTag: 'اليوم',
                    ));
                _medName.clear();
                _medDosage.clear();
                Navigator.pop(context);
                _showSuccess('تم تسجيل الدواء بنجاح');
              }
            }),
          ],
        ),
      ),
    );
  }

  void _showVitalsSheet(AppRiverpod provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(builder: (context, setSheetState) {
        return _buildSheetContainer(
          title: 'العلامات الحيوية',
          color: const Color(0xFFF43F5E),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                      child: _buildTextField(
                          _bpDia, 'الانبساطي', Icons.bloodtype_outlined)),
                  const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Text('/',
                          style: TextStyle(fontSize: 20, color: Colors.grey))),
                  Expanded(
                      child: _buildTextField(
                          _bpSys, 'الانقباضي', Icons.speed_rounded)),
                ],
              ),
              const SizedBox(height: 16),
              _buildTextField(
                  _glucose, 'مستوى السكر (مجم/دل)', Icons.water_drop_outlined),
              const SizedBox(height: 16),
              _buildTextField(
                  _temp, 'درجة الحرارة (°م)', Icons.thermostat_rounded),
              const SizedBox(height: 24),
              _buildActionBtn('حفظ العلامات', const Color(0xFFF43F5E), () {
                if (_bpSys.text.isNotEmpty &&
                    _glucose.text.isNotEmpty &&
                    _temp.text.isNotEmpty) {
                  provider.saveMedicalVitals(
                      residentName: _selectedResident,
                      bp: '${_bpSys.text}/${_bpDia.text}',
                      sugar: _glucose.text,
                      temp: _temp.text);
                  _bpSys.clear();
                  _bpDia.clear();
                  _glucose.clear();
                  _temp.clear();
                  Navigator.pop(context);
                  _showSuccess('تم حفظ العلامات الحيوية');
                }
              }),
            ],
          ),
        );
      }),
    );
  }

  void _showLogSessionSheet(AppRiverpod provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(builder: (context, setSheetState) {
        return _buildSheetContainer(
          title: 'توثيق جلسة طبية',
          color: const Color(0xFF6366F1),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                      child: _buildSessionTypeSelector(
                          'زيارة طبيب',
                          Icons.local_hospital_rounded,
                          'doctor',
                          () => setSheetState(() => _sessionType = 'doctor'))),
                  const SizedBox(width: 12),
                  Expanded(
                      child: _buildSessionTypeSelector(
                          'علاج طبيعي',
                          Icons.accessibility_new_rounded,
                          'pt',
                          () => setSheetState(() => _sessionType = 'pt'))),
                ],
              ),
              const SizedBox(height: 20),
              _buildTextField(_specialistName, 'اسم الطبيب أو الأخصائي',
                  Icons.badge_outlined),
              const SizedBox(height: 16),
              _buildTextField(
                  _sessionNotes, 'ملاحظات الجلسة', Icons.note_alt_outlined,
                  maxLines: 2),
              const SizedBox(height: 24),
              _buildActionBtn('توثيق الجلسة', const Color(0xFF6366F1), () {
                if (_specialistName.text.isNotEmpty) {
                  provider.logMedicalSession(MedicalSession(
                    id: DateTime.now().toString(),
                    type: _sessionType,
                    specialistName: _specialistName.text,
                    time:
                        '${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}',
                    date: 'اليوم',
                    notes: _sessionNotes.text,
                    residentName: _selectedResident,
                  ));
                  _specialistName.clear();
                  _sessionNotes.clear();
                  Navigator.pop(context);
                  _showSuccess('تم توثيق الجلسة بنجاح');
                }
              }),
            ],
          ),
        );
      }),
    );
  }

  void _showUploadPrescriptionSheet(AppRiverpod provider) {
    _prescriptionImage = null; // Reset
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(builder: (context, setSheetState) {
        return _buildSheetContainer(
          title: 'رفع مستند للملف',
          color: const Color(0xFF10B981),
          child: Column(
            children: [
              if (_prescriptionImage != null)
                Stack(
                  children: [
                    Container(
                      width: double.infinity,
                      height: 180,
                      margin: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        image: DecorationImage(
                          image: FileImage(_prescriptionImage!),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 24,
                      right: 8,
                      child: GestureDetector(
                        onTap: () =>
                            setSheetState(() => _prescriptionImage = null),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                              color: Colors.black54, shape: BoxShape.circle),
                          child: const Icon(Icons.close,
                              color: Colors.white, size: 20),
                        ),
                      ),
                    ),
                  ],
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () =>
                            _pickImage(ImageSource.camera, setSheetState),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0FDF4),
                            border: Border.all(
                                color: const Color(0xFF86EFAC),
                                style: BorderStyle.solid),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Column(
                            children: [
                              Icon(Icons.camera_alt_outlined,
                                  color: Color(0xFF10B981), size: 32),
                              SizedBox(height: 8),
                              Text('التقط صورة',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF166534),
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () =>
                            _pickImage(ImageSource.gallery, setSheetState),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0FDF4),
                            border: Border.all(
                                color: const Color(0xFF86EFAC),
                                style: BorderStyle.solid),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Column(
                            children: [
                              Icon(Icons.photo_library_outlined,
                                  color: Color(0xFF10B981), size: 32),
                              SizedBox(height: 8),
                              Text('اختر من المعرض',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF166534),
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 16),
              _buildTextField(_prescTitle, 'عنوان المستند (مثال: روشتة الصدر)',
                  Icons.title_rounded),
              const SizedBox(height: 24),
              _buildActionBtn('حفظ في السجل', const Color(0xFF10B981), () {
                if (_prescTitle.text.isNotEmpty && _prescriptionImage != null) {
                  Navigator.pop(context); // Close sheet
                  _showUploadProgress(() {
                    provider.addPrescription(MedicalPrescription(
                      id: DateTime.now().toString(),
                      title: _prescTitle.text,
                      doctorName: 'مرفق جديد',
                      date: 'اليوم',
                      residentName: _selectedResident,
                      imagePath: _prescriptionImage!.path,
                    ));
                    _prescTitle.clear();
                    _showSuccess('تم رفع المستند وأرشفته');
                  });
                } else {
                  _showSuccess('يرجى اختيار صورة وكتابة عنوان المستند أولاً');
                }
              }),
            ],
          ),
        );
      }),
    );
  }

  Future<void> _pickImage(ImageSource source, StateSetter setSheetState) async {
    if (source == ImageSource.camera) {
      var status = await Permission.camera.request();
      if (!status.isGranted) {
        _showSuccess('يرجى إعطاء صلاحية الكاميرا للمتابعة');
        return;
      }
    } else {
      var status = await Permission.photos.request();
      if (!status.isGranted && !status.isLimited) {
        status = await Permission.storage.request();
        if (!status.isGranted) {
          _showSuccess('يرجى إعطاء صلاحية المعرض للمتابعة');
          return;
        }
      }
    }

    try {
      final XFile? pickedFile = await _picker.pickImage(source: source);
      if (pickedFile != null) {
        setSheetState(() {
          _prescriptionImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      _showSuccess('حدث خطأ أثناء الوصول للملفات');
    }
  }

  Widget _buildSheetContainer(
      {required String title, required Color color, required Widget child}) {
    return Container(
      padding: EdgeInsets.only(
        left: 24, right: 24, top: 24,
        bottom:
            MediaQuery.of(context).viewInsets.bottom + 24, // Handle keyboard
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
            topLeft: Radius.circular(32), topRight: Radius.circular(32)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
                child: Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                        color: const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(10)))),
            const SizedBox(height: 24),
            Text(title,
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 24),
            child,
          ],
        ),
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: const Color(0xFF0F172A),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  // --- Utility Widgets ---

  Widget _buildTextField(
      TextEditingController controller, String hint, IconData icon,
      {int maxLines = 1, Function(String)? onChanged}) {
    return Container(
      decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0))),
      child: TextField(
        controller: controller,
        textAlign: TextAlign.right,
        maxLines: maxLines,
        onChanged: onChanged,
        keyboardType: TextInputType.text,
        style: const TextStyle(color: Colors.black, fontSize: 13),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
          prefixIcon: Icon(icon, color: const Color(0xFF94A3B8), size: 18),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildDropdown(
      String value, List<String> items, Function(String?) onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0))),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF1E293B),
              fontWeight: FontWeight.bold,
              fontFamily: 'Cairo'),
          items: items
              .map((e) => DropdownMenuItem(
                  value: e, child: Text(e, textAlign: TextAlign.right)))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildActionBtn(String label, Color color, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: Text(label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildSessionTypeSelector(
      String label, IconData icon, String type, VoidCallback onTap) {
    bool isSelected = _sessionType == type;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEEF2FF) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: isSelected
                  ? const Color(0xFF6366F1)
                  : const Color(0xFFE2E8F0),
              width: 1.5),
        ),
        child: Column(
          children: [
            Icon(icon,
                color: isSelected
                    ? const Color(0xFF6366F1)
                    : const Color(0xFF94A3B8),
                size: 24),
            const SizedBox(height: 8),
            Text(label,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isSelected
                        ? const Color(0xFF6366F1)
                        : const Color(0xFF64748B))),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF64748B), size: 20),
        const SizedBox(width: 8),
        Text(title,
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B))),
      ],
    );
  }

  Widget _buildSessionLog(MedicalSession s, AppRiverpod provider) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
                color: Color(0xFFF1F5F9), shape: BoxShape.circle),
            child: const Icon(Icons.history_edu_rounded,
                size: 20, color: Color(0xFF0369A1)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.specialistName,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A))),
                const SizedBox(height: 2),
                Text('${s.residentName} · ${s.time}',
                    style: const TextStyle(
                        fontSize: 13, color: Color(0xFF475569))),
              ],
            ),
          ),
          _buildSessionBadge(s.type),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () => provider.deleteMedicalSession(s.id),
            icon: const Icon(Icons.delete_outline,
                color: Color(0xFFEF4444), size: 20),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionBadge(String type) {
    bool isDoc = type == 'doctor';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
          color: isDoc ? const Color(0xFFF0F9FF) : const Color(0xFFEEF2FF),
          borderRadius: BorderRadius.circular(10)),
      child: Text(isDoc ? 'زيارة طبيب' : 'علاج طبيعي',
          style: TextStyle(
              color: isDoc ? const Color(0xFF0369A1) : const Color(0xFF6366F1),
              fontSize: 10,
              fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildPrescriptionCard(MedicalPrescription p, AppRiverpod provider) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.1),
                shape: BoxShape.circle),
            child: const Icon(Icons.file_present_rounded,
                color: Color(0xFF10B981), size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p.title,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A))),
                const SizedBox(height: 2),
                Text('${p.residentName} · ${p.date}',
                    style: const TextStyle(
                        fontSize: 13, color: Color(0xFF475569))),
              ],
            ),
          ),
          const Icon(Icons.download_rounded,
              color: Color(0xFF94A3B8), size: 20),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () => provider.deletePrescription(p.id),
            icon: const Icon(Icons.delete_outline,
                color: Color(0xFFEF4444), size: 20),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  void _showUploadProgress(VoidCallback onComplete) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(32)),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                  color: Color(0xFF10B981), strokeWidth: 3),
              SizedBox(height: 24),
              Text('جاري معالجة المستند...',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      fontFamily: 'Cairo',
                      decoration: TextDecoration.none,
                      color: Color(0xFF0F172A))),
              SizedBox(height: 8),
              Text('يتم أرشفته في ملف المقيم الآن',
                  style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                      decoration: TextDecoration.none,
                      fontFamily: 'Cairo')),
            ],
          ),
        ),
      ),
    );
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      Navigator.pop(context);
      onComplete();
    });
  }
}
