import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart'; // مكتبة التقاط الصور
import '../../../providers/app_riverpod.dart'; // مزود الحالة العام
import '../../../models/app_models.dart'; // نماذج البيانات
import '../../../widgets/ai_insights_panel.dart'; // لوحة رؤى الذكاء الاصطناعي

class SpecialistHomeView extends ConsumerWidget {
  final List<Animation<double>> fadeAnimations; // قائمة حركات الظهور
  final AnimationController floatController; // متحكم الحركة العائمة
  final AnimationController shimmerController; // متحكم اللمعان
  final AnimationController popController; // متحكم حركات القفز
  final void Function(int) onNavigate; // دالة للتنقل بين التبويبات

  const SpecialistHomeView({
    super.key,
    required this.fadeAnimations,
    required this.floatController,
    required this.shimmerController,
    required this.popController,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = ref.watch(appRiverpod); // مراقبة حالة الـ Provider

    return Column(
      children: [
        _buildFilterStrip(
            provider), // شريط فلاتر أنواع الاحتياجات (نفسي، أسري...)
        _buildFloorTabs(provider), // تبويبات الطوابق (الأول، الثاني...)

        // لوحة رؤى الذكاء الاصطناعي (US-08-04) — متصلة بـ AWS Bedrock
        AIInsightsPanel(
          isEnabled: provider.isAIInsightsEnabled,
          insight:
              provider.aiInsights.isNotEmpty ? provider.aiInsights[0] : null,
          onToggle: () => provider.toggleAIInsights(true),
          isLoading: provider.isLoadingAiInsight,
          mode: provider.aiInsightMode,
          onRefresh: () => provider.refreshAiInsightFromBackend(),
        ),

        Expanded(
          child: Column(
            children: [
              _buildActionRow(context, ref,
                  provider), // أزرار الإجراءات (بث سعادة، تسجيل احتياج)
              _buildNursingHandoffsSection(provider), // ملخص ملاحظات التمريض
              _buildStatsStrip(provider), // شريط الإحصائيات السريع
              Expanded(
                  child: _buildNeedsList(provider)), // قائمة الاحتياجات المسجلة
            ],
          ),
        ),
      ],
    );
  }

  // بناء شريط الفلترة العلوي
  Widget _buildFilterStrip(AppRiverpod provider) {
    final filters = [
      {
        'label': 'الكل',
        'count': '١٣',
        'color': const Color(0xFF9a3412),
        'bg': const Color(0xFFfff7ed)
      },
      {
        'label': 'نفسي',
        'count': '٦',
        'color': const Color(0xFF4c1d95),
        'bg': const Color(0xFFede9fe)
      },
      {
        'label': 'أسري',
        'count': '٤',
        'color': const Color(0xFF92400e),
        'bg': const Color(0xFFfef3c7)
      },
      {
        'label': 'مالي',
        'count': '٢',
        'color': const Color(0xFF7f1d1d),
        'bg': const Color(0xFFfee2e2)
      },
      {
        'label': 'طبي',
        'count': '١',
        'color': const Color(0xFF065f46),
        'bg': const Color(0xFFd1fae5)
      },
    ];

    return Container(
      height: 50,
      color: Colors.white,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        reverse: true,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: filters.map((f) {
            final String label = f['label'] as String;
            final isAct = provider.selectedSpecialistFilter == label;
            return GestureDetector(
              onTap: () => provider.setSelectedSpecialistFilter(label),
              child: Container(
                margin: const EdgeInsets.only(left: 6),
                padding:
                    const EdgeInsets.symmetric(horizontal: 11, vertical: 4),
                decoration: BoxDecoration(
                    color: f['bg'] as Color,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color:
                            isAct ? (f['color'] as Color) : Colors.transparent,
                        width: 1.5)),
                child: Text('${f['label']} (${f['count']})',
                    style: TextStyle(
                        color: f['color'] as Color,
                        fontSize: 10,
                        fontWeight: isAct ? FontWeight.bold : FontWeight.w500)),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // بناء تبويبات الطوابق لاختيار مكان المقيم
  Widget _buildFloorTabs(AppRiverpod provider) {
    final floors = [
      'الطابق الأول',
      'الطابق الثاني',
      'الطابق الثالث',
      'المشترك'
    ];
    return Container(
      height: 40,
      decoration: const BoxDecoration(
          color: Color(0xFFf8fafc),
          border: Border(bottom: BorderSide(color: Color(0xFFe2e8f0)))),
      child: Row(
        children: List.generate(floors.length, (index) {
          final isAct = provider.selectedFloor == index + 1;
          return Expanded(
            child: GestureDetector(
              onTap: () => provider.setSelectedFloor(index + 1),
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                    color: isAct ? Colors.white : Colors.transparent,
                    border: Border(
                        bottom: BorderSide(
                            color: isAct
                                ? const Color(0xFFea580c)
                                : Colors.transparent,
                            width: 2))),
                child: Text(floors[index],
                    style: TextStyle(
                        color: isAct
                            ? const Color(0xFFea580c)
                            : const Color(0xFF94a3b8),
                        fontSize: 10,
                        fontWeight: isAct ? FontWeight.bold : FontWeight.w500)),
              ),
            ),
          );
        }),
      ),
    );
  }

  // بناء صف الأزرار الرئيسية في الصفحة
  Widget _buildActionRow(
      BuildContext context, WidgetRef ref, AppRiverpod provider) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // زر "بث سعادة" لمشاركة صور المقيمين مع أهلهم
          Expanded(
            child: GestureDetector(
              onTap: () => _showAddMomentSheet(context, ref, provider),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [Color(0xFF0ea5e9), Color(0xFF38bdf8)]),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.blue.withValues(alpha: 0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 4))
                    ]),
                child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.camera_alt_rounded,
                          color: Colors.white, size: 16),
                      SizedBox(width: 8),
                      Text('بث سعادة 📸',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.bold))
                    ]),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // زر "تسجيل احتياج" لطلب تدخل للفريق الإداري أو الطبي
          Expanded(
            child: GestureDetector(
              onTap: () => _showAddNeedSheet(context, ref),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [Color(0xFFea580c), Color(0xFFf97316)]),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.orange.withValues(alpha: 0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 4))
                    ]),
                child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add, color: Colors.white, size: 16),
                      SizedBox(width: 8),
                      Text('تسجيل احتياج',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.bold))
                    ]),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // زر "توصية نفسية" لمخاطبة التمريض
          Expanded(
            child: GestureDetector(
              onTap: () => _showAddRecommendationSheet(context, ref, provider),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [Color(0xFF8b5cf6), Color(0xFFa855f7)]),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.purple.withValues(alpha: 0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 4))
                    ]),
                child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.psychology, color: Colors.white, size: 14),
                      SizedBox(width: 4),
                      Text('توصية نفسية',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold))
                    ]),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // نافذة إضافة توصية للتمريض
  void _showAddRecommendationSheet(
      BuildContext context, WidgetRef ref, AppRiverpod provider) {
    String selectedResident = provider.filteredResidentScores.isNotEmpty
        ? provider.filteredResidentScores.first.name
        : (provider.residentFiles.isNotEmpty
            ? provider.residentFiles.first.name
            : '');
    final textController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              top: 20,
              left: 24,
              right: 24),
          decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Center(
                  child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(10)))),
              const SizedBox(height: 20),
              const Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text('إضافة توصية للتمريض 🧠',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B)))
                ],
              ),
              const SizedBox(height: 20),
              const Text('اسم المقيم',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF64748B))),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0))),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: selectedResident,
                    items: provider.filteredResidentScores
                        .map((r) => DropdownMenuItem(
                            value: r.name, child: Text(r.name)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setModalState(() => selectedResident = val);
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text('محتوى التوصية',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF64748B))),
              const SizedBox(height: 8),
              TextField(
                controller: textController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText:
                      'مثال: تعاملوا معه بهدوء اليوم وتجنبوا الأخبار السيئة...',
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (textController.text.isNotEmpty) {
                      provider
                          .addSpecialistRecommendation(SpecialistRecommendation(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        residentName: selectedResident,
                        content: textController.text,
                        time: 'الآن',
                      ));
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text('تم إرسال التوصية بنجاح!')));
                    }
                  },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8b5cf6),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16))),
                  child: const Text('إرسال التوصية',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // نافذة التقاط ومشاركة الصور (بث السعادة)
  void _showAddMomentSheet(
      BuildContext context, WidgetRef ref, AppRiverpod provider) {
    String? selectedImagePath;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              top: 20,
              left: 24,
              right: 24),
          decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Center(
                  child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(10)))),
              const SizedBox(height: 20),
              const Text('بث لحظة سعادة 📸✨',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0f172a))),
              const Text('شارك عائلات المقيمين أجمل اللحظات اليومية',
                  style: TextStyle(fontSize: 13, color: Color(0xFF64748b))),
              const SizedBox(height: 24),
              const Text('التقط أو اختر صورة',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1e293b))),
              const SizedBox(height: 12),
              Row(
                children: [
                  // اختيار صورة من المعرض
                  Expanded(
                    child: GestureDetector(
                        onTap: () async {
                          final picker = ImagePicker();
                          final img = await picker.pickImage(
                              source: ImageSource.gallery);
                          if (img != null) {
                            setModalState(() => selectedImagePath = img.path);
                          }
                        },
                        child: Container(
                            height: 100,
                            decoration: BoxDecoration(
                                color: const Color(0xFFf0f9ff),
                                borderRadius: BorderRadius.circular(16),
                                border:
                                    Border.all(color: const Color(0xFFbae6fd))),
                            child: const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.photo_library_outlined,
                                      color: Color(0xFF0ea5e9)),
                                  Text('المعرض',
                                      style: TextStyle(
                                          fontSize: 10,
                                          color: Color(0xFF0ea5e9)))
                                ]))),
                  ),
                  const SizedBox(width: 12),
                  // التقاط صورة بالكاميرا
                  Expanded(
                    child: GestureDetector(
                        onTap: () async {
                          final picker = ImagePicker();
                          final img = await picker.pickImage(
                              source: ImageSource.camera);
                          if (img != null) {
                            setModalState(() => selectedImagePath = img.path);
                          }
                        },
                        child: Container(
                            height: 100,
                            decoration: BoxDecoration(
                                color: const Color(0xFFfff7ed),
                                borderRadius: BorderRadius.circular(16),
                                border:
                                    Border.all(color: const Color(0xFFfed7aa))),
                            child: const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.camera_alt_outlined,
                                      color: Color(0xFFea580c)),
                                  Text('الكاميرا',
                                      style: TextStyle(
                                          fontSize: 10,
                                          color: Color(0xFFea580c)))
                                ]))),
                  ),
                ],
              ),
              // عرض معاينة للصورة المختارة
              if (selectedImagePath != null) ...[
                const SizedBox(height: 16),
                Container(
                    height: 150,
                    width: double.infinity,
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        image: DecorationImage(
                            image: FileImage(File(selectedImagePath!)),
                            fit: BoxFit.cover))),
              ],
              const SizedBox(height: 24),
              const Text('المقيم المستهدف',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1e293b))),
              const SizedBox(height: 8),
              Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                      color: const Color(0xFFf8fafc),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFe2e8f0))),
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          provider.residentFiles.isNotEmpty
                              ? 'غرفة ${provider.residentFiles.first.room} (${provider.residentFiles.first.name})'
                              : 'اختر مقيماً',
                          style: const TextStyle(
                              fontSize: 13, color: Color(0xFF0f172a)),
                        ),
                        const Icon(Icons.person_outline,
                            color: Color(0xFF94a3b8), size: 20)
                      ])),
              const SizedBox(height: 32),
              // زر الإرسال النهائي للأهل
              SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0ea5e9),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          elevation: 0),
                      onPressed: selectedImagePath == null
                          ? null
                          : () {
                              final p = ref.read(appRiverpod);
                              final res = p.residentFiles.isNotEmpty
                                  ? p.residentFiles.first
                                  : null;
                              p.addMemoryMoment(MemoryMoment(
                                  id: 'm${DateTime.now().millisecondsSinceEpoch}',
                                  residentId: res?.id ?? 'r1',
                                  residentName: res?.name ?? 'مقيم',
                                  imageUrl: selectedImagePath!,
                                  activityTitle: 'لحظة سعادة جديدة',
                                  date: 'الآن'));
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text(
                                          'تمت مشاركة اللحظة مع الأهل بنجاح! 🎉'),
                                      backgroundColor: Color(0xFF0ea5e9)));
                            },
                      child: const Text('بث السعادة للأهل 🤝',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)))),
            ],
          ),
        ),
      ),
    );
  }

  // نافذة تسجيل احتياج جديد للمقيم
  void _showAddNeedSheet(BuildContext context, WidgetRef ref) {
    final titleCtrl = TextEditingController();
    final roomCtrl = TextEditingController(text: '١٠٣');
    String selectedType = 'نفسي';
    bool isUrgent = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              top: 20,
              left: 20,
              right: 20),
          decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Center(
                  child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                          color: const Color(0xFFe2e8f0),
                          borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 20),
              const Text('تسجيل احتياج جديد 🛡️',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0f172a))),
              const Text('أدخل تفاصيل الحالة لتمكين الفريق من التدخل',
                  style: TextStyle(fontSize: 12, color: Color(0xFF64748b))),
              const SizedBox(height: 24),
              _buildLabel('نوع الاحتياج'),
              const SizedBox(height: 8),
              Row(
                children: ['نفسي', 'أسري', 'مالي', 'طبي'].map((t) {
                  final isSel = selectedType == t;
                  return Expanded(
                      child: GestureDetector(
                          onTap: () => setModalState(() => selectedType = t),
                          child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 2),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                  color: isSel
                                      ? const Color(0xFFfff7ed)
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: isSel
                                          ? const Color(0xFFea580c)
                                          : const Color(0xFFe2e8f0))),
                              child: Center(
                                  child: Text(t,
                                      style: TextStyle(
                                          color: isSel
                                              ? const Color(0xFFea580c)
                                              : const Color(0xFF64748b),
                                          fontSize: 11,
                                          fontWeight: isSel
                                              ? FontWeight.bold
                                              : FontWeight.normal))))));
                }).toList(),
              ),
              const SizedBox(height: 20),
              _buildLabel('وصف الحالة'),
              const SizedBox(height: 8),
              TextField(
                  controller: titleCtrl,
                  textAlign: TextAlign.right,
                  decoration: InputDecoration(
                      hintText: 'مثال: يحتاج دعم نفسي بسبب عزلة مؤقتة...',
                      hintStyle: const TextStyle(
                          fontSize: 12, color: Color(0xFFcbd5e1)),
                      filled: true,
                      fillColor: const Color(0xFFf8fafc),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none))),
              const SizedBox(height: 20),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Switch(
                    value: isUrgent,
                    onChanged: (v) => setModalState(() => isUrgent = v),
                    activeThumbColor: const Color(0xFFea580c)),
                const Text('حالة عاجلة؟',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold))
              ]),
              const SizedBox(height: 32),
              SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFea580c),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          elevation: 0),
                      onPressed: () {
                        if (titleCtrl.text.isNotEmpty) {
                          ref.read(appRiverpod).addSocialNeed(
                              SocialSpecialistNeed(
                                  id: 'n${DateTime.now().millisecondsSinceEpoch}',
                                  roomNumber: roomCtrl.text,
                                  type: selectedType,
                                  label: selectedType.substring(0, 1),
                                  isUrgent: isUrgent));
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('تم تسجيل الاحتياج بنجاح ✅')));
                        }
                      },
                      child: const Text('حفظ وتسجيل',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) => Text(text,
      style: const TextStyle(
          fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF334155)));

  // بناء قسم ملخص ملاحظات التمريض
  Widget _buildNursingHandoffsSection(AppRiverpod provider) {
    if (provider.nursingNotes.isEmpty) return const SizedBox.shrink();

    // نجلب آخر 3 ملاحظات تمريضية فقط لعرضها كملخص للأخصائي
    final recentNotes = provider.nursingNotes.take(3).toList();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: const Color(0xFF6366F1).withValues(alpha: 0.5), width: 1.5),
        boxShadow: [
          BoxShadow(
              color: const Color(0xFF6366F1).withValues(alpha: 0.15),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.nightlight_round,
                  color: Color(0xFF6366F1), size: 18),
              const SizedBox(width: 8),
              const Text('ملاحظات التمريض (Shift Handoffs) 📋',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B))),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                    color: const Color(0xFFEEF2FF),
                    borderRadius: BorderRadius.circular(8)),
                child: const Text('تسليم الوردية',
                    style: TextStyle(
                        fontSize: 9,
                        color: Color(0xFF4F46E5),
                        fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...recentNotes.map((note) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ',
                        style: TextStyle(
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.bold)),
                    Expanded(
                      child: Text('${note.residentName}: ${note.content}',
                          style: const TextStyle(
                              fontSize: 12, color: Color(0xFF334155))),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  // بناء شريط الإحصائيات السريعة في منتصف الصفحة
  Widget _buildStatsStrip(AppRiverpod provider) {
    final stats = [
      {'val': '٢', 'lbl': 'مالي', 'col': const Color(0xFFef4444)},
      {'val': '٤', 'lbl': 'أسري', 'col': const Color(0xFFf59e0b)},
      {'val': '٦', 'lbl': 'نفسي', 'col': const Color(0xFF6366f1)},
      {'val': '١', 'lbl': 'طبي', 'col': const Color(0xFF10b981)},
      {'val': '١٣', 'lbl': 'الكل', 'col': const Color(0xFFea580c)},
    ];

    return Container(
      height: 50,
      decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFf1f5f9)))),
      child: Row(
          children: stats
              .map((s) => Expanded(
                  child: Container(
                      decoration: const BoxDecoration(
                          border: Border(
                              left: BorderSide(color: Color(0xFFf1f5f9)))),
                      child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(s['val'] as String,
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: s['col'] as Color)),
                            Text(s['lbl'] as String,
                                style: const TextStyle(
                                    fontSize: 8, color: Color(0xFF94a3b8)))
                          ]))))
              .toList()),
    );
  }

  // بناء قائمة الاحتياجات المسجلة مرتبة حسب الأولوية
  Widget _buildNeedsList(AppRiverpod provider) {
    final sortedNeeds =
        List<SocialSpecialistNeed>.from(provider.filteredSocialNeeds)
          ..sort((a, b) => (b.isUrgent ? 1 : 0).compareTo(a.isUrgent ? 1 : 0));

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: sortedNeeds.length + 2,
      itemBuilder: (context, index) {
        if (index == 0) {
          return _buildListHeader(
              'عاجل — يحتاج تدخل فوري', const Color(0xFFef4444));
        }
        if (index == 2) {
          return _buildListHeader(
              'يحتاج متابعة مستمرة', const Color(0xFFf59e0b));
        }

        final needIdx = index > 2 ? index - 2 : index - 1;
        if (needIdx >= sortedNeeds.length) return const SizedBox(height: 80);

        final need = sortedNeeds[needIdx];
        return _buildNeedRow(need); // عرض تفاصيل كل احتياج
      },
    );
  }

  Widget _buildListHeader(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, top: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
        Text(title,
            style: const TextStyle(
                color: Color(0xFF9a3412),
                fontSize: 11,
                fontWeight: FontWeight.bold)),
        const SizedBox(width: 6),
        Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle))
      ]),
    );
  }

  // عرض تفاصيل صف الاحتياج الفردي
  Widget _buildNeedRow(SocialSpecialistNeed need) {
    final color = _getColor(need.type);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: need.isUrgent
                ? const Color(0xFFef4444)
                : color.withValues(alpha: 0.5),
            width: 1.5),
        boxShadow: [
          BoxShadow(
              color: (need.isUrgent ? const Color(0xFFef4444) : color)
                  .withValues(alpha: 0.15),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Row(
        children: [
          Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                  color: _getBadgeBg(need.type, need.isUrgent),
                  borderRadius: BorderRadius.circular(8)),
              child: Text(need.isUrgent ? 'عاجل' : need.type,
                  style: TextStyle(
                      color: _getBadgeFg(need.type, need.isUrgent),
                      fontSize: 9,
                      fontWeight: FontWeight.bold))),
          const Spacer(),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('المقيم في غرفة ${need.roomNumber} — احتياج ${need.type}',
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0f172a))),
            Text('غرفة ${need.roomNumber} · تم التحقق مؤخراً',
                style: const TextStyle(fontSize: 10, color: Color(0xFF64748b))),
            const SizedBox(height: 4),
            const Row(mainAxisSize: MainAxisSize.min, children: [
              Text('تحت المراجعة',
                  style: TextStyle(fontSize: 9, color: Color(0xFF94a3b8))),
              SizedBox(width: 4),
              Icon(Icons.access_time, size: 10, color: Color(0xFF94a3b8))
            ])
          ]),
          const SizedBox(width: 12),
          Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                  color: _getIconBg(need.type),
                  borderRadius: BorderRadius.circular(10)),
              child: Center(
                  child: Text(_getEmoji(need.type),
                      style: const TextStyle(fontSize: 15)))),
          const SizedBox(width: 10),
          Container(
              width: 4,
              height: 34,
              decoration: BoxDecoration(
                  color: _getColor(need.type),
                  borderRadius: BorderRadius.circular(4))),
        ],
      ),
    );
  }

  // دوال مساعدة لجلب الألوان والأيقونات بناءً على نوع الحالة
  Color _getBadgeBg(String type, bool urgent) => urgent
      ? const Color(0xFFfee2e2)
      : (type == 'أسري'
          ? const Color(0xFFfef3c7)
          : (type == 'نفسي'
              ? const Color(0xFFede9fe)
              : const Color(0xFFd1fae5)));
  Color _getBadgeFg(String type, bool urgent) => urgent
      ? const Color(0xFF7f1d1d)
      : (type == 'أسري'
          ? const Color(0xFF92400e)
          : (type == 'نفسي'
              ? const Color(0xFF4c1d95)
              : const Color(0xFF065f46)));
  Color _getIconBg(String type) => type == 'مالي'
      ? const Color(0xFFfee2e2)
      : (type == 'أسري'
          ? const Color(0xFFfef3c7)
          : (type == 'نفسي'
              ? const Color(0xFFede9fe)
              : const Color(0xFFd1fae5)));
  Color _getColor(String type) {
    switch (type) {
      case 'نفسي':
        return const Color(0xFF6366f1);
      case 'أسري':
        return const Color(0xFFf59e0b);
      case 'مالي':
        return const Color(0xFFef4444);
      case 'طبي':
        return const Color(0xFF10b981);
      default:
        return Colors.grey;
    }
  }

  String _getEmoji(String type) {
    switch (type) {
      case 'نفسي':
        return '🧠';
      case 'أسري':
        return '👨👩👧';
      case 'مالي':
        return '💰';
      case 'طبي':
        return '🏥';
      default:
        return '📍';
    }
  }
}
