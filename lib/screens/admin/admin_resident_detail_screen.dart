import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/app_riverpod.dart';
import '../../models/app_models.dart';
import '../../widgets/taptaba_scaffold.dart';

class AdminResidentDetailScreen extends ConsumerStatefulWidget {
  final String residentId;
  const AdminResidentDetailScreen({super.key, required this.residentId});

  @override
  ConsumerState<AdminResidentDetailScreen> createState() =>
      _AdminResidentDetailScreenState();
}

class _AdminResidentDetailScreenState
    extends ConsumerState<AdminResidentDetailScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  bool _isEditMode = false;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 7, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // جلب البيانات الحقيقية من الـ Provider
    final appData = ref.watch(appRiverpod);
    final resident = appData.residentFiles.firstWhere(
      (r) => r.id == widget.residentId,
      orElse: () => SpecialistResidentFile(
        id: widget.residentId,
        name: 'مقيم غير معروف',
        nameEn: 'Unknown',
        room: '--',
        status: 'updated',
        lastUpdate: '',
        initials: '?',
        age: 0,
        phone: '',
        categories: ['resident'],
        familyMembers: [],
      ),
    );

    // تحويل البيانات من SpecialistResidentFile إلى Resident model (الذي تستخدمه الواجهة)
    final r = Resident(
      id: resident.id,
      name: resident.name,
      roomNumber: resident.room,
      gender: 'غير محدد',
      birthDate:
          DateTime.now().subtract(Duration(days: 365 * (resident.age ?? 0))),
      entryDate: DateTime.now(),
      nationalId: 'غير متوفر',
      imageUrl: resident.imageUrl,
      emergencyContactName: 'غير محدد',
      emergencyContactPhone: resident.phone ?? '',
      emergencyRelation: 'غير محدد',
      bloodType: resident.bloodType ?? 'A+',
      chronicDiseases: resident.chronicDiseases ?? [],
      allergies: resident.allergies ?? [],
      insuranceInfo: resident.insuranceInfo ?? 'لا يوجد',
      mobilityStatus: resident.mobilityStatus ?? 'مستقل',
      assistiveDevices: resident.assistiveDevices ?? [],
      cognitiveStatus: resident.cognitiveStatus ?? 'وعي كامل',
      dietType: resident.dietType ?? 'عادي',
      foodRestrictions: resident.foodRestrictions ?? [],
      foodPreferences: resident.foodPreferences ?? 'غير محدد',
      previousProfession: resident.previousProfession ?? 'غير محدد',
      hobbies: resident.hobbies ?? [],
      socialStatus: resident.socialStatus ?? 'غير محدد',
      contractType: 'إقامة دائمة',
      uploadedDocuments: resident.uploadedDocuments ?? [],
    );

    return TaptabaScaffold(
      title: 'ونس',
      titleColor: const Color(0xFF0F172A),
      overrideRole: 'مدير',
      body: Column(
        children: [
          _buildProfileHeader(context, r),
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildPersonalInfo(r),
                _buildMedicalInfo(r),
                _buildMobilityInfo(r),
                _buildDietaryInfo(r),
                _buildSocialInfo(r),
                _buildFamilyLinkInfo(r),
                _buildDocumentsInfo(r),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        indicatorWeight: 3,
        indicatorColor: const Color(0xFF0ea5e9),
        labelColor: const Color(0xFF0369a1),
        unselectedLabelColor: const Color(0xFF94a3b8),
        labelStyle: const TextStyle(
            fontWeight: FontWeight.bold, fontSize: 13, fontFamily: 'Outfit'),
        tabs: const [
          Tab(text: 'البيانات الشخصية'),
          Tab(text: 'الملف الطبي'),
          Tab(text: 'الحالة الحركية'),
          Tab(text: 'النظام الغذائي'),
          Tab(text: 'الجانب الاجتماعي'),
          Tab(text: 'إدارة العائلة'),
          Tab(text: 'المستندات'),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, Resident r) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 50, 24, 30),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0f172a), Color(0xFF1e293b)],
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: Colors.white, size: 22),
                onPressed: () => Navigator.pop(context),
              ),
              const Text('ملف المقيم الشامل',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Outfit')),
              IconButton(
                icon: Icon(
                    _isEditMode
                        ? Icons.check_circle_rounded
                        : Icons.edit_note_rounded,
                    color: _isEditMode ? Colors.greenAccent : Colors.white,
                    size: 28),
                onPressed: () {
                  setState(() => _isEditMode = !_isEditMode);
                  if (!_isEditMode) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('تم حفظ التعديلات بنجاح')));
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 20),
          // صورة المقيم الممركزة
          Hero(
            tag: 'profile_${r.id}',
            child: Stack(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white24, width: 2),
                  ),
                  child: Builder(
                    builder: (context) {
                      final String? imageUrl = r.imageUrl;
                      return CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.white12,
                        backgroundImage:
                            (imageUrl != null && imageUrl.isNotEmpty)
                                ? FileImage(File(imageUrl))
                                : null,
                        child: (imageUrl == null || imageUrl.isEmpty)
                            ? const Icon(Icons.person,
                                color: Colors.white, size: 45)
                            : null,
                      );
                    },
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: () {
                      ref
                          .read(appRiverpod)
                          .pickAndSetResidentImage(widget.residentId);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0ea5e9),
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: const Color(0xFF1e293b), width: 2),
                      ),
                      child: const Icon(
                        Icons.camera_alt_rounded,
                        size: 20,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 15),
          // الاسم والمعلومات الممركزة
          Text(
            r.name,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                fontFamily: 'Outfit'),
          ),
          const SizedBox(height: 8),
          Text(
            'الغرفة ${r.roomNumber}  —  العمر ${r.age} عاماً',
            style: TextStyle(
                fontSize: 14,
                color: Colors.white.withValues(alpha: 0.6),
                letterSpacing: 0.5),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfo(Resident r) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildInfoCard('البيانات الشخصية الأساسية', [
          _infoRow('الاسم بالكامل', r.name, Icons.person_outline),
          _infoRow('الرقم القومي', r.nationalId, Icons.badge_outlined),
          _infoRow(
              'تاريخ الميلاد',
              '${r.birthDate.day}/${r.birthDate.month}/${r.birthDate.year}',
              Icons.calendar_today_outlined),
          _infoRow(
              'تاريخ الدخول',
              '${r.entryDate.day}/${r.entryDate.month}/${r.entryDate.year}',
              Icons.login_rounded),
          _infoRow('رقم الغرفة', r.roomNumber, Icons.door_front_door_outlined),
        ]),
        const SizedBox(height: 16),
        _buildInfoCard('بيانات الطوارئ والوصي', [
          _infoRow('اسم المسؤول', r.emergencyContactName,
              Icons.contact_emergency_outlined),
          _infoRow('صلة القرابة', r.emergencyRelation, Icons.people_outline),
          _infoRow('رقم الهاتف', r.emergencyContactPhone,
              Icons.phone_android_outlined),
        ]),
        const SizedBox(height: 24),
        // زر حذف الملف بالكامل
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: OutlinedButton.icon(
            onPressed: () => _showDeleteConfirmation(context, r),
            icon: const Icon(Icons.delete_forever_rounded,
                color: Colors.redAccent, size: 20),
            label: const Text('حذف ملف المقيم نهائياً',
                style: TextStyle(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Outfit')),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Colors.redAccent.withValues(alpha: 0.3)),
              padding: const EdgeInsets.all(18),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  void _showDeleteConfirmation(BuildContext context, Resident r) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('تأكيد الحذف النهائي ⚠️',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text(
            'هل أنت متأكد من رغبتك في حذف ملف المقيم "${r.name}" بالكامل؟ لا يمكن التراجع عن هذا الإجراء.',
            textAlign: TextAlign.center),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // إغلاق الحوار
              Navigator.pop(context); // العودة للقائمة
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم حذف ملف المقيم بنجاح')));
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white),
            child: const Text('نعم، احذف الملف'),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicalInfo(Resident r) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildInfoCard('الملف الطبي والتحذيرات', [
          _infoRow('فصيلة الدم', r.bloodType, Icons.bloodtype_outlined,
              valColor: Colors.redAccent),
          _infoRow('الأمراض المزمنة', r.chronicDiseases.join('، '),
              Icons.healing_outlined),
          _infoRow(
              'الحساسية',
              r.allergies.isEmpty ? 'لا يوجد' : r.allergies.join('، '),
              Icons.warning_amber_rounded,
              valColor: Colors.orange),
          _infoRow(
              'العمليات السابقة',
              r.pastSurgeries.isEmpty ? 'لا يوجد' : r.pastSurgeries.join('، '),
              Icons.medication_outlined),
        ]),
        const SizedBox(height: 16),
        _buildInfoCard('التأمين الطبي والجهة المعالجة', [
          _infoRow('جهة التأمين', r.insuranceInfo, Icons.shield_outlined),
          _infoRow('الطبيب المتابع', r.primaryDoctorName ?? 'غير محدد',
              Icons.person_search_outlined),
        ]),
      ],
    );
  }

  Widget _buildMobilityInfo(Resident r) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildInfoCard('الحالة الحركية والوظيفية', [
          _infoRow(
              'درجة الحركة', r.mobilityStatus, Icons.directions_walk_rounded),
          _infoRow('الأجهزة المساعدة', r.assistiveDevices.join('، '),
              Icons.accessible_forward_rounded),
          _infoRow(
              'الحالة الذهنية', r.cognitiveStatus, Icons.psychology_outlined),
        ]),
      ],
    );
  }

  Widget _buildDietaryInfo(Resident r) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildInfoCard('نظام الغذاء والتفضيلات', [
          _infoRow(
              'نوع النظام الغذائي', r.dietType, Icons.restaurant_menu_rounded),
          _infoRow('الممنوعات الغذائية', r.foodRestrictions.join('، '),
              Icons.no_food_outlined,
              valColor: Colors.red),
          _infoRow('تفضيلات خاصة', r.foodPreferences,
              Icons.favorite_outline_rounded),
        ]),
      ],
    );
  }

  Widget _buildSocialInfo(Resident r) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildInfoCard('التاريخ الاجتماعي والنشاطات', [
          _infoRow('المهنة السابقة', r.previousProfession,
              Icons.work_outline_rounded),
          _infoRow('الهوايات والنشاطات', r.hobbies.join('، '),
              Icons.interests_outlined),
          _infoRow('الحالة الاجتماعية', r.socialStatus,
              Icons.family_restroom_rounded),
        ]),
      ],
    );
  }

  Widget _buildFamilyLinkInfo(Resident r) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildInfoCard('إدارة ربط العائلة', [
          const Text(
              'ربط المقيم بحساب أحد أفراد العائلة ليتمكن من متابعة التقارير اليومية والأدوية.',
              style: TextStyle(fontSize: 12, color: Color(0xFF64748b))),
          const SizedBox(height: 20),
          _infoRow('البريد المرتبط حالياً', 'family.mahmoud@gmail.com',
              Icons.alternate_email_rounded,
              valColor: Colors.blueAccent),
          const SizedBox(height: 10),
          if (_isEditMode)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showLinkFamilyDialog(),
                icon: const Icon(Icons.link_rounded, size: 18),
                label: const Text('تغيير أو ربط فرد جديد'),
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0ea5e9),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12))),
              ),
            ),
        ]),
      ],
    );
  }

  void _showLinkFamilyDialog() {
    final emailController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ربط فرد من العائلة', textAlign: TextAlign.right),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
                'أدخل البريد الإلكتروني المسجل لفرد العائلة ليتم الربط التلقائي.',
                textAlign: TextAlign.right,
                style: TextStyle(fontSize: 12)),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              textAlign: TextAlign.left,
              decoration: InputDecoration(
                  hintText: 'example@family.com',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12))),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم إرسال طلب الربط بنجاح')));
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0ea5e9),
                foregroundColor: Colors.white),
            child: const Text('تأكيد الربط'),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentsInfo(Resident r) {
    return Stack(
      children: [
        GridView.builder(
          padding: const EdgeInsets.all(20),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 15,
            mainAxisSpacing: 15,
            childAspectRatio: 1.0,
          ),
          itemCount: r.uploadedDocuments.length + 1,
          itemBuilder: (context, index) {
            if (index == r.uploadedDocuments.length) {
              return _buildAddDocCard();
            }
            return _buildDocCard(r.uploadedDocuments[index]);
          },
        ),
        if (_isUploading)
          Container(
            color: Colors.black26,
            child: const Center(
                child: CircularProgressIndicator(color: Colors.white)),
          ),
      ],
    );
  }

  Widget _buildInfoCard(String title, List<Widget> children) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFf1f5f9)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 15,
              offset: const Offset(0, 5))
        ],
      ),
      child: InkWell(
        onTap: _isEditMode ? () => _editSection(title) : null,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0369a1),
                          fontFamily: 'Outfit')),
                  if (_isEditMode)
                    const Icon(Icons.edit_rounded,
                        size: 18, color: Colors.blueAccent),
                ],
              ),
              const Divider(
                  height: 25, color: Color(0xFFf1f5f9), thickness: 1.5),
              ...children,
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value, IconData icon,
      {Color? valColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
                color: const Color(0xFFf1f5f9),
                borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, size: 16, color: const Color(0xFF0ea5e9)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF94a3b8),
                        fontFamily: 'Outfit')),
                Text(
                  value,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: valColor ?? const Color(0xFF1e293b),
                      fontFamily: 'Outfit'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _editSection(String title) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 24,
            right: 24,
            top: 24),
        decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('تعديل قسم: $title',
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            const Text('جاري فتح نموذج التعديل الشامل لهذا القسم...',
                style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0ea5e9),
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15))),
              child: const Text('إغلاق', style: TextStyle(color: Colors.white)),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildDocCard(String path) {
    return GestureDetector(
      onLongPress: () => _confirmDeleteDoc(path),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFf8fafc),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFe2e8f0)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.insert_drive_file_rounded,
                color: Color(0xFF0369a1), size: 45),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(path,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 11, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteDoc(String path) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف المستند؟'),
        content: Text('هل أنت متأكد من حذف "$path"؟'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء')),
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('حذف', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
  }

  Widget _buildAddDocCard() {
    return InkWell(
      onTap: () {
        setState(() => _isUploading = true);
        Future.delayed(const Duration(seconds: 2), () {
          if (!mounted) return;
          setState(() => _isUploading = false);
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('تم رفع المستند بنجاح')));
        });
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: const Color(0xFF0ea5e9),
                style: BorderStyle.solid,
                width: 2)),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_upload_outlined,
                color: Color(0xFF0ea5e9), size: 35),
            SizedBox(height: 8),
            Text('رفع مستند',
                style: TextStyle(
                    color: Color(0xFF0ea5e9),
                    fontSize: 12,
                    fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  // ignore: unused_element
  Widget _buildDeleteBtn() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: OutlinedButton.icon(
        onPressed: () {},
        icon: const Icon(Icons.delete_forever_rounded, color: Colors.red),
        label: const Text('حذف ملف المقيم بالكامل',
            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Colors.red),
            padding: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15))),
      ),
    );
  }
}
