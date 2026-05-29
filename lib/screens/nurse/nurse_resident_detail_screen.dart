import 'package:flutter/material.dart'; // مكتبة فلاتر الأساسية للواجهات
import 'package:flutter_riverpod/flutter_riverpod.dart'; // مكتبة إدارة الحالة
import '../../providers/app_riverpod.dart'; // مزود الحالة الرئيسي للتطبيق
import '../../models/app_models.dart'; // نماذج البيانات (المقيمين، الملاحظات)

class NurseResidentDetailScreen extends ConsumerStatefulWidget {
  // شاشة تفاصيل المقيم الخاصة بالتمريض
  final String residentName; // اسم المقيم
  final String roomNumber; // رقم الغرفة

  const NurseResidentDetailScreen({
    // مشيد الفئة مع البيانات المطلوبة
    super.key,
    required this.residentName,
    required this.roomNumber,
  });

  @override
  ConsumerState<NurseResidentDetailScreen> createState() =>
      _NurseResidentDetailScreenState(); // إنشاء حالة المكون
}

class _NurseResidentDetailScreenState
    extends ConsumerState<NurseResidentDetailScreen>
    with SingleTickerProviderStateMixin {
  // حالة الشاشة مع دعم التبويبات
  late TabController
      _tabController; // متحكم التبويبات (الملف الطبي / الملاحظات)
  final TextEditingController _noteTitleController =
      TextEditingController(); // متحكم عنوان الملاحظة الجديدة
  final TextEditingController _noteContentController =
      TextEditingController(); // متحكم محتوى الملاحظة الجديدة

  @override
  void initState() {
    // دالة التهيئة الأولية
    super.initState();
    _tabController = TabController(length: 2, vsync: this); // إعداد تبويبين
  }

  @override
  void dispose() {
    // تنظيف الموارد عند إغلاق الشاشة
    _tabController.dispose();
    _noteTitleController.dispose();
    _noteContentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // بناء واجهة تفاصيل المقيم
    final provider = ref.watch(appRiverpod); // مراقبة حالة التطبيق
    final residentNotes = provider.getNotesForResident(
        widget.residentName); // جلب الملاحظات التمريضية للمقيم
    final medicalInfo = provider.getMedicalInfo(
        widget.residentName); // جلب المعلومات الطبية (حساسية، أمراض)

    return Scaffold(
      // الهيكل الأساسي للشاشة
      backgroundColor: const Color(0xFFF8FAFC), // خلفية رمادية فاتحة جداً
      appBar: AppBar(
        // شريط العنوان العلوي
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text('الملف الطبي المتكامل',
            style: TextStyle(
                color: Color(0xFF0F172A),
                fontWeight: FontWeight.bold,
                fontSize: 18)),
        leading: IconButton(
          // زر العودة للخلف
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Color(0xFF0F172A), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            // زر طباعة الملف الطبي
            icon: const Icon(Icons.print_rounded, color: Color(0xFF0369A1)),
            onPressed: _printMedicalFile,
          ),
        ],
      ),
      body: Column(
        // ترتيب المحتوى بشكل رأسي
        children: [
          _buildResidentHeader(), // بناء هيدر معلومات المقيم الأساسية
          _buildTabBar(), // بناء شريط التنقل بين الملف والملاحظات
          Expanded(
            // عرض المحتوى بناءً على التبويب المختار
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildMedicalFileTab(
                    medicalInfo,
                    provider.specialistRecommendations
                        .where((r) => r.residentName == widget.residentName)
                        .toList()), // واجهة الملف الطبي
                _buildNotesTab(residentNotes), // واجهة الملاحظات التمريضية
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResidentHeader() {
    // بناء الجزء العلوي الذي يحتوي على اسم وصورة المقيم
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start, // محاذاة لليمن في الـ RTL
              children: [
                Container(
                  // شارة توضح الحالة الصحية (مثال: حالة حرجة)
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text('حالة حرجة 🔴',
                      style: TextStyle(
                          color: Color(0xFFEF4444),
                          fontSize: 10,
                          fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 8),
                Text(widget.residentName,
                    style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A))), // اسم المقيم
                Text('غرفة ${widget.roomNumber} · ٧٨ سنة',
                    style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 14)), // الغرفة والسن
              ],
            ),
          ),
          const SizedBox(width: 12),
          Hero(
            // أنيميشن انتقال الصورة بين الشاشات
            tag: widget.residentName,
            child: CircleAvatar(
              radius: 40,
              backgroundColor: const Color(0xFFE0F2FE),
              child: Text(widget.residentName.substring(0, 2),
                  style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0369A1))),
            ),
          ),
          const SizedBox(width: 20), // لتبعد عن أقصى الشمال
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    // بناء شريط التبويبات المخصص
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        indicatorColor: const Color(0xFF0369A1), // لون مؤشر الاختيار (أزرق طبي)
        indicatorWeight: 3,
        labelColor: const Color(0xFF0369A1),
        unselectedLabelColor: const Color(0xFF94A3B8),
        labelStyle: const TextStyle(
            fontWeight: FontWeight.bold, fontSize: 14, fontFamily: 'Cairo'),
        tabs: const [
          Tab(text: 'الملف الطبي'), // التبويب الأول
          Tab(text: 'الملاحظات'), // التبويب الثاني
        ],
      ),
    );
  }

  Widget _buildMedicalFileTab(
      ResidentMedicalInfo info, List<SpecialistRecommendation> recs) {
    // محتوى تبويب الملف الطبي (أدوية، حساسية، أمراض)
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        if (recs.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text('توصيات الأخصائي النفسي 🧠',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B)))
              ],
            ),
          ),
          ...recs.map((r) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: const Color(0xFFF3E8FF),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFD8B4FE))),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                        child: Text(r.content,
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF6B21A8)))),
                  ],
                ),
              )),
          const SizedBox(height: 20),
        ],
        _buildSectionTitle('الأمراض المزمنة',
            onAdd: () => _showAddItemDialog('مرض مزمن', (v) {
                  final newDiseases = List<String>.from(info.chronicDiseases)
                    ..add(v);
                  ref.read(appRiverpod).updateMedicalInfo(ResidentMedicalInfo(
                        residentName: info.residentName,
                        medications: info.medications,
                        allergies: info.allergies,
                        chronicDiseases: newDiseases,
                      ));
                })),
        _buildInfoCard(info.chronicDiseases.isEmpty
            ? 'لا توجد أمراض مسجلة'
            : info.chronicDiseases.join('، ')),
        const SizedBox(height: 20),
        _buildSectionTitle('الحساسية',
            onAdd: () => _showAddItemDialog('حساسية', (v) {
                  final newAllergies = List<String>.from(info.allergies)
                    ..add(v);
                  ref.read(appRiverpod).updateMedicalInfo(ResidentMedicalInfo(
                        residentName: info.residentName,
                        medications: info.medications,
                        allergies: newAllergies,
                        chronicDiseases: info.chronicDiseases,
                      ));
                })),
        _buildInfoCard(
            info.allergies.isEmpty
                ? 'لا توجد حساسية مسجلة'
                : info.allergies.join('، '),
            color: const Color(0xFFEF4444)),
        const SizedBox(height: 24),
        _buildSectionTitle('الأدوية الحالية', onAdd: _showAddMedicationDialog),
        _buildMedicineList(info.medications),
      ],
    );
  }

  Widget _buildSectionTitle(String title, {VoidCallback? onAdd}) {
    // عنوان قسم مع زر إضافة اختياري
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              textAlign: TextAlign.right,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B))),
          if (onAdd != null)
            IconButton(
              onPressed: onAdd,
              icon: const Icon(Icons.add_circle_outline_rounded,
                  size: 20, color: Color(0xFF0369A1)),
              constraints: const BoxConstraints(),
              padding: EdgeInsets.zero,
            )
          else
            const SizedBox.shrink(),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String text, {Color color = const Color(0xFF0369A1)}) {
    // بطاقة عرض معلومات طبية بسيطة
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Expanded(
              child: Text(text,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B)))),
        ],
      ),
    );
  }

  Widget _buildMedicineList(List<String> meds) {
    // عرض قائمة الأدوية المسجلة للمقيم
    if (meds.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0))),
        child: const Center(
            child: Text('لا توجد أدوية مسجلة',
                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13))),
      );
    }
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: meds
            .map((m) => ListTile(
                  title: Text(m,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.bold)),
                  subtitle: const Text('حسب تعليمات الطبيب',
                      textAlign: TextAlign.right,
                      style: TextStyle(fontSize: 11)),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildNotesTab(List<NursingNote> notes) {
    // محتوى تبويب الملاحظات التمريضية
    return Column(
      children: [
        Expanded(
          child: notes.isEmpty
              ? const Center(
                  child: Text('لا توجد ملاحظات حالياً',
                      style: TextStyle(color: Color(0xFF94A3B8))))
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: notes.length,
                  itemBuilder: (context, index) {
                    final note = notes[index];
                    return _buildNoteItem(note); // بناء عنصر ملاحظة فردي
                  },
                ),
        ),
        _buildNoteInput(), // حقل إدخال ملاحظة جديدة في الأسفل
      ],
    );
  }

  Widget _buildNoteItem(NursingNote note) {
    // بطاقة عرض ملاحظة تمريضية واحدة
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                // اسم كاتب الملاحظة (الممرض المسئول)
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                    color: const Color(0xFFF0F9FF),
                    borderRadius: BorderRadius.circular(6)),
                child: Text(note.author,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0369A1),
                        fontSize: 13)),
              ),
              const Text('منذ فترة قريبة',
                  style: TextStyle(
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.bold,
                      fontSize: 11)), // الوقت التقريبي
            ],
          ),
          const SizedBox(height: 10),
          Text(note.title,
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Color(0xFF1E293B))), // عنوان الملاحظة
          const SizedBox(height: 4),
          Text(note.content,
              textAlign: TextAlign.right,
              style: const TextStyle(
                  fontSize: 13, color: Color(0xFF475569))), // تفاصيل الملاحظة
        ],
      ),
    );
  }

  Widget _buildNoteInput() {
    // حقول إدخال الملاحظة الجديدة (عنوان + محتوى)
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 15,
              offset: const Offset(0, -5))
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  // حقل العنوان
                  controller: _noteTitleController,
                  textAlign: TextAlign.right,
                  decoration: InputDecoration(
                    hintText: 'عنوان الملاحظة...',
                    hintStyle:
                        const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Text('إضافة ملاحظة',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Color(0xFF0369A1))),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                // زر الإرسال والحفظ
                decoration: const BoxDecoration(
                    color: Color(0xFF0369A1), shape: BoxShape.circle),
                child: IconButton(
                  onPressed: () {
                    if (_noteTitleController.text.isNotEmpty &&
                        _noteContentController.text.isNotEmpty) {
                      final newNote = NursingNote(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        residentName: widget.residentName,
                        title: _noteTitleController.text,
                        content: _noteContentController.text,
                        author: ref.read(appRiverpod).currentAccount?.name ??
                            'فريق التمريض',
                        timestamp: DateTime.now(),
                      );
                      ref
                          .read(appRiverpod)
                          .addNursingNote(newNote); // حفظ الملاحظة في الحالة
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text('تمت إضافة الملاحظة بنجاح ✅')));
                      _noteTitleController.clear();
                      _noteContentController.clear();
                    }
                  },
                  icon: const Icon(Icons.send_rounded,
                      color: Colors.white, size: 20),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  // حقل المحتوى التفصيلي
                  controller: _noteContentController,
                  maxLines: 2,
                  textAlign: TextAlign.right,
                  decoration: InputDecoration(
                    hintText: 'اكتب تفاصيل الملاحظة هنا...',
                    hintStyle:
                        const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return _SuccessDialog(message: message);
      },
    );
    Future.delayed(const Duration(seconds: 1, milliseconds: 500), () {
      if (!mounted) return;
      Navigator.pop(context); // إغلاق حوار النجاح
    });
  }

  void _showAddItemDialog(String label, Function(String) onAdd) {
    // حوار منبثق لإضافة عناصر (حساسية، أمراض)
    final TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('إضافة $label جديد',
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
        content: TextField(
          controller: controller,
          textAlign: TextAlign.right,
          decoration: InputDecoration(
            hintText: 'اكتب هنا...',
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                onAdd(controller.text); // تنفيذ دالة الإضافة
                Navigator.pop(context);
                _showSuccessDialog('تمت إضافة $label بنجاح');
              }
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0369A1),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10))),
            child: const Text('إضافة', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showAddMedicationDialog() {
    // حوار خاص لإضافة الأدوية
    final TextEditingController medNameController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('إضافة دواء جديد',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
        content: TextField(
          controller: medNameController,
          textAlign: TextAlign.right,
          decoration: InputDecoration(
            hintText: 'اسم الدواء والجرعة...',
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () {
              if (medNameController.text.isNotEmpty) {
                final provider = ref.read(appRiverpod);
                final info = provider.getMedicalInfo(widget.residentName);
                final newMeds = List<String>.from(info.medications)
                  ..add(medNameController.text);
                provider.updateMedicalInfo(ResidentMedicalInfo(
                  // تحديث القائمة في مزود الحالة
                  residentName: info.residentName,
                  medications: newMeds,
                  allergies: info.allergies,
                  chronicDiseases: info.chronicDiseases,
                ));
                Navigator.pop(context);
                _showSuccessDialog('تمت إضافة الدواء بنجاح');
              }
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0369A1),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10))),
            child: const Text('إضافة', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _printMedicalFile() {
    showDialog(
      context: context,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: Color(0xFF0369A1)),
                SizedBox(height: 24),
                Text('جاري تحويل الملف إلى PDF...',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
              ],
            ),
          ),
        ),
      ),
    );
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      Navigator.pop(context); // إغلاق الحوار
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تحميل الملف الطبي الكامل بنجاح ✅')));
    });
  }
}

class _SuccessDialog extends StatefulWidget {
  final String message;
  const _SuccessDialog({required this.message});

  @override
  State<_SuccessDialog> createState() => _SuccessDialogState();
}

class _SuccessDialogState extends State<_SuccessDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ScaleTransition(
                scale: _scaleAnimation,
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: Color(0xFF10B981),
                  size: 60,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                widget.message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
