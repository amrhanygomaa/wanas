import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart'; // مكتبة اختيار الصور
import '../../../providers/app_riverpod.dart';
import '../../../models/app_models.dart';

class SpecialistActivitiesView extends ConsumerStatefulWidget {
  final List<Animation<double>> fadeAnimations;
  final AnimationController floatController;
  final AnimationController shimmerController;
  final AnimationController popController;
  final void Function(int) onNavigate;

  const SpecialistActivitiesView({
    super.key,
    required this.fadeAnimations,
    required this.floatController,
    required this.shimmerController,
    required this.popController,
    required this.onNavigate,
  });

  @override
  ConsumerState<SpecialistActivitiesView> createState() =>
      _SpecialistActivitiesViewState();
}

class _SpecialistActivitiesViewState
    extends ConsumerState<SpecialistActivitiesView> {
  @override
  Widget build(BuildContext context) {
    final provider = ref.watch(appRiverpod);
    final List<Map<String, dynamic>> activityRows = provider.activities
        .map<Map<String, dynamic>>((activity) => {
              'id': activity.id,
              'title': activity.name,
              'type': activity.badges,
              'date': activity.time,
              'status': activity.status,
              'icon': activity.emoji,
              'color': const Color(0xFF3b82f6),
              'bg': const Color(0xFFdbeafe),
              'target': 'من AWS',
              'location': activity.location,
              'supervisor': provider.currentAccount?.name ?? 'فريق الرعاية',
            })
        .toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          // العنوان الرئيسي
          FadeTransition(
            opacity: widget.fadeAnimations[0],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('الأنشطة والرحلات',
                        style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF1e293b))),
                    Text('تنظيم وإدارة الأنشطة الترفيهية',
                        style:
                            TextStyle(fontSize: 14, color: Color(0xFF64748b))),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () => _showAddActivityModal(context),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('إضافة نشاط',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFea580c),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // قائمة الأنشطة
          Expanded(
            child: ListView.builder(
              itemCount: activityRows.length,
              itemBuilder: (context, index) {
                final act = activityRows[index];
                return FadeTransition(
                  opacity: widget.fadeAnimations[1],
                  child: Container(
                    margin: const EdgeInsets.only(
                        bottom: 12), // تقليل المسافة الخارجية قليلاً
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical:
                            8), // تقليل الحشو الداخلي بشكل كبير لحل الأوفرفلو
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                          BorderRadius.circular(16), // تقليل الانحناء قليلاً
                      border:
                          Border.all(color: const Color(0xFFe2e8f0), width: 1),
                      boxShadow: [
                        BoxShadow(
                          color:
                              (act['color'] as Color).withValues(alpha: 0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment
                          .center, // جعلها في المنتصف لتوزيع المساحة
                      children: [
                        // الأيقونة أو الصورة
                        Container(
                          width: 48, // تقليل الحجم ليوفر مساحة
                          height: 48,
                          decoration: BoxDecoration(
                            color: act['bg'] as Color,
                            borderRadius: BorderRadius.circular(10),
                            image: act['image'] != null
                                ? DecorationImage(
                                    image: NetworkImage(act['image'] as String),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: act['image'] == null
                              ? Center(
                                  child: Text(act['icon'] as String,
                                      style: const TextStyle(fontSize: 22)),
                                )
                              : null,
                        ),
                        const SizedBox(width: 12), // تقليل المسافة
                        // التفاصيل
                        Flexible(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(act['title'] as String,
                                  maxLines:
                                      1, // منع السطر الثاني لعدم حدوث أوفرفلو
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      fontSize: 15, // تقليل حجم الخط قليلاً
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF0f172a))),
                              const SizedBox(
                                  height: 3), // تقليل المسافات البينية
                              // السطر الأول: التاريخ والنوع
                              Wrap(
                                spacing: 8,
                                runSpacing: 2,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.access_time_filled_rounded,
                                          size: 12, color: Colors.grey[700]),
                                      const SizedBox(width: 2),
                                      Text(act['date'] as String,
                                          style: const TextStyle(
                                              fontSize: 11,
                                              color: Color(0xFF334155),
                                              fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: (act['color'] as Color)
                                          .withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(act['type'] as String,
                                        style: TextStyle(
                                            fontSize: 10,
                                            color: act['color'] as Color,
                                            fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              // السطر الثاني: المكان والمستهدفين
                              Wrap(
                                spacing: 8,
                                runSpacing: 2,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.location_on_rounded,
                                          size: 12, color: Colors.grey[700]),
                                      const SizedBox(width: 2),
                                      Text(act['location'] as String,
                                          style: const TextStyle(
                                              fontSize: 11,
                                              color: Color(0xFF334155),
                                              fontWeight: FontWeight.w500)),
                                    ],
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.people_alt_rounded,
                                          size: 12, color: Colors.grey[700]),
                                      const SizedBox(width: 2),
                                      Text(act['target'] as String,
                                          style: const TextStyle(
                                              fontSize: 11,
                                              color: Color(0xFF334155),
                                              fontWeight: FontWeight.w500)),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              // السطر الثالث: المشرف
                              Row(
                                children: [
                                  Icon(Icons.person_rounded,
                                      size: 12, color: Colors.grey[700]),
                                  const SizedBox(width: 2),
                                  Text('المشرف: ${act['supervisor']}',
                                      style: const TextStyle(
                                          fontSize: 11,
                                          color: Color(0xFF334155),
                                          fontWeight: FontWeight.w500)),
                                ],
                              ),
                            ],
                          ),
                        ),
                        // الحالة والقائمة
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // الحالة
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: act['bg'] as Color,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                act['status'] as String,
                                style: TextStyle(
                                    fontSize: 10,
                                    color: act['color'] as Color,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                            // زر التعديل والحذف
                            PopupMenuButton<String>(
                              color: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: const BorderSide(
                                    color: Color(0xFFe2e8f0), width: 1.5),
                              ),
                              icon: Icon(Icons.more_vert_rounded,
                                  color: Colors.grey[600], size: 18),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onSelected: (value) async {
                                if (value == 'edit') {
                                  _showAddActivityModal(context,
                                      editActivity: act, index: index);
                                } else if (value == 'delete') {
                                  await ref
                                      .read(appRiverpod)
                                      .deleteActivitySession(
                                          act['id'] as String);
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('تم حذف النشاط بنجاح!',
                                          style:
                                              TextStyle(fontFamily: 'Cairo')),
                                      backgroundColor: Color(0xFFea580c),
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                }
                              },
                              itemBuilder: (BuildContext context) =>
                                  <PopupMenuEntry<String>>[
                                const PopupMenuItem<String>(
                                  value: 'edit',
                                  child: Row(
                                    children: [
                                      Icon(Icons.edit_rounded,
                                          color: Color(0xFFea580c), size: 18),
                                      SizedBox(width: 8),
                                      Text('تعديل',
                                          style:
                                              TextStyle(fontFamily: 'Cairo')),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem<String>(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Icon(Icons.delete_rounded,
                                          color: Colors.red, size: 18),
                                      SizedBox(width: 8),
                                      Text('حذف',
                                          style: TextStyle(
                                              fontFamily: 'Cairo',
                                              color: Colors.red)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showAddActivityModal(BuildContext context,
      {Map<String, dynamic>? editActivity, int? index}) {
    final titleController = TextEditingController(
        text: editActivity != null ? editActivity['title'] as String : '');
    final locationController = TextEditingController(
        text: editActivity != null ? editActivity['location'] as String : '');
    final supervisorController = TextEditingController(
        text: editActivity != null ? editActivity['supervisor'] as String : '');
    final dateController = TextEditingController(
        text: editActivity != null ? editActivity['date'] as String : '');
    String selectedType =
        editActivity != null ? editActivity['type'] as String : 'نشاط';

    final List<Map<String, String>> hobbies = [
      {'name': 'لكل المقيمين', 'icon': '👥'},
      {'name': 'شطرنج', 'icon': '♟️'},
      {'name': 'قراءة', 'icon': '📚'},
      {'name': 'رسم', 'icon': '🎨'},
      {'name': 'طاولة', 'icon': '🎲'},
      {'name': 'دومينو', 'icon': '🀰'},
      {'name': 'ألعاب ورقية', 'icon': '🃏'},
      {'name': 'نحت على الخشب', 'icon': '🪵'},
      {'name': 'تلوين فخار', 'icon': '🏺'},
      {'name': 'حياكة وتطريز', 'icon': '🧵'},
      {'name': 'أشغال يدوية', 'icon': '✂️'},
      {'name': 'موسيقى وعزف', 'icon': '🎵'},
      {'name': 'زراعة ونباتات', 'icon': '🌱'},
      {'name': 'رياضة خفيفة', 'icon': '🧘'},
      {'name': 'طبخ وحلوى', 'icon': '🧁'},
      {'name': 'تصوير فوتوغرافي', 'icon': '📸'},
      {'name': 'مشاهدة أفلام', 'icon': '🎬'},
      {'name': 'سرد حكايات', 'icon': '🗣️'},
      {'name': 'تمارين تنفس', 'icon': '🌬️'},
      {'name': 'كتابة إبداعية', 'icon': '✍️'},
      {'name': 'ألعاب تركيز', 'icon': '🧩'},
    ];

    String selectedTarget = 'لكل المقيمين';
    if (editActivity != null) {
      final t = editActivity['target'] as String;
      if (t == 'all') {
        selectedTarget = 'لكل المقيمين';
      } else if (t == 'special' || t == 'culture' || t == 'specialist') {
        selectedTarget = 'لكل المقيمين';
      } else {
        selectedTarget = t;
      }
    }

    bool isHobbiesExpanded = false;
    // Auto-expand if the selected target is not in the first 6 items
    final initialIndex = hobbies.indexWhere((h) => h['name'] == selectedTarget);
    if (initialIndex > 5) {
      isHobbiesExpanded = true;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setStateModal) => Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: const BoxDecoration(
            color: Color(0xFFf8fafc),
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: Stack(
            children: [
              const ActivitiesCardDustAnimation(),
              Padding(
                padding: const EdgeInsets.all(24),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                              editActivity != null
                                  ? 'تعديل النشاط'
                                  : 'إضافة نشاط جديد',
                              style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0f172a))),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.close_rounded,
                                color: Color(0xFF64748b)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const Text('عنوان النشاط أو الرحلة',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF334155))),
                      const SizedBox(height: 8),
                      TextField(
                        controller: titleController,
                        decoration: InputDecoration(
                          hintText: 'مثال: رحلة إلى حديقة الحيوان',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  const BorderSide(color: Color(0xFFe2e8f0))),
                          enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  const BorderSide(color: Color(0xFFe2e8f0))),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text('النوع',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF334155))),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () {
                                setStateModal(() {
                                  selectedType = 'نشاط';
                                });
                              },
                              borderRadius: BorderRadius.circular(16),
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 250),
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 16, horizontal: 12),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: selectedType == 'نشاط'
                                            ? const Color(0xFFea580c)
                                            : const Color(0xFFe2e8f0),
                                        width: selectedType == 'نشاط' ? 2 : 1.5,
                                      ),
                                      boxShadow: selectedType == 'نشاط'
                                          ? [
                                              BoxShadow(
                                                color: const Color(0xFFea580c)
                                                    .withValues(alpha: 0.12),
                                                offset: const Offset(0, 6),
                                                blurRadius: 12,
                                                spreadRadius: 1,
                                              ),
                                            ]
                                          : [
                                              BoxShadow(
                                                color: Colors.black
                                                    .withValues(alpha: 0.04),
                                                offset: const Offset(0, 4),
                                                blurRadius: 8,
                                              ),
                                            ],
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: selectedType == 'نشاط'
                                                ? const Color(0xFFfff7ed)
                                                : const Color(0xFFf8fafc),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            Icons.home_rounded,
                                            color: selectedType == 'نشاط'
                                                ? const Color(0xFFea580c)
                                                : const Color(0xFF64748b),
                                            size: 26,
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        Text(
                                          'نشاط داخلي',
                                          style: TextStyle(
                                            fontFamily: 'Cairo',
                                            fontSize: 13.5,
                                            fontWeight: selectedType == 'نشاط'
                                                ? FontWeight.bold
                                                : FontWeight.w600,
                                            color: selectedType == 'نشاط'
                                                ? const Color(0xFFea580c)
                                                : const Color(0xFF475569),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (selectedType == 'نشاط')
                                    const Positioned(
                                      top: 8,
                                      right: 8,
                                      child: Icon(
                                        Icons.check_circle_rounded,
                                        color: Color(0xFFea580c),
                                        size: 18,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: InkWell(
                              onTap: () {
                                setStateModal(() {
                                  selectedType = 'رحلة';
                                });
                              },
                              borderRadius: BorderRadius.circular(16),
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 250),
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 16, horizontal: 12),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: selectedType == 'رحلة'
                                            ? const Color(0xFFea580c)
                                            : const Color(0xFFe2e8f0),
                                        width: selectedType == 'رحلة' ? 2 : 1.5,
                                      ),
                                      boxShadow: selectedType == 'رحلة'
                                          ? [
                                              BoxShadow(
                                                color: const Color(0xFFea580c)
                                                    .withValues(alpha: 0.12),
                                                offset: const Offset(0, 6),
                                                blurRadius: 12,
                                                spreadRadius: 1,
                                              ),
                                            ]
                                          : [
                                              BoxShadow(
                                                color: Colors.black
                                                    .withValues(alpha: 0.04),
                                                offset: const Offset(0, 4),
                                                blurRadius: 8,
                                              ),
                                            ],
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: selectedType == 'رحلة'
                                                ? const Color(0xFFfff7ed)
                                                : const Color(0xFFf8fafc),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            Icons.directions_bus_rounded,
                                            color: selectedType == 'رحلة'
                                                ? const Color(0xFFea580c)
                                                : const Color(0xFF64748b),
                                            size: 26,
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        Text(
                                          'رحلة خارجية',
                                          style: TextStyle(
                                            fontFamily: 'Cairo',
                                            fontSize: 13.5,
                                            fontWeight: selectedType == 'رحلة'
                                                ? FontWeight.bold
                                                : FontWeight.w600,
                                            color: selectedType == 'رحلة'
                                                ? const Color(0xFFea580c)
                                                : const Color(0xFF475569),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (selectedType == 'رحلة')
                                    const Positioned(
                                      top: 8,
                                      right: 8,
                                      child: Icon(
                                        Icons.check_circle_rounded,
                                        color: Color(0xFFea580c),
                                        size: 18,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      const Text('المكان',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF334155))),
                      const SizedBox(height: 8),
                      TextField(
                        controller: locationController,
                        decoration: InputDecoration(
                          hintText: 'مثال: قاعة الأنشطة الكبرى',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  const BorderSide(color: Color(0xFFe2e8f0))),
                          enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  const BorderSide(color: Color(0xFFe2e8f0))),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text('الفئة المستهدفة (النشاط أو الهواية)',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF334155))),
                      const SizedBox(height: 12),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 2.5,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        itemCount: isHobbiesExpanded ? hobbies.length : 6,
                        itemBuilder: (context, hobbyIndex) {
                          final hobby = hobbies[hobbyIndex];
                          final isSelected = selectedTarget == hobby['name'];
                          return InkWell(
                            onTap: () {
                              setStateModal(() {
                                selectedTarget = hobby['name']!;
                              });
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              curve: Curves.easeInOut,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isSelected
                                      ? const Color(0xFFea580c)
                                      : const Color(0xFFe2e8f0),
                                  width: isSelected ? 2 : 1.5,
                                ),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: const Color(0xFFea580c)
                                              .withValues(alpha: 0.18),
                                          offset: const Offset(0, 6),
                                          blurRadius: 10,
                                          spreadRadius: 0.5,
                                        ),
                                        const BoxShadow(
                                          color: Colors.white,
                                          offset: Offset(-2, -2),
                                          blurRadius: 5,
                                        ),
                                      ]
                                    : [
                                        BoxShadow(
                                          color: Colors.black
                                              .withValues(alpha: 0.06),
                                          offset: const Offset(0, 4),
                                          blurRadius: 8,
                                        ),
                                        const BoxShadow(
                                          color: Colors.white,
                                          offset: Offset(-2, -2),
                                          blurRadius: 4,
                                        ),
                                      ],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? const Color(0xFFfff7ed)
                                          : const Color(0xFFf8fafc),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Text(
                                      hobby['icon']!,
                                      style: const TextStyle(fontSize: 18),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      hobby['name']!,
                                      style: TextStyle(
                                        fontFamily: 'Cairo',
                                        fontSize: 12.5,
                                        fontWeight: isSelected
                                            ? FontWeight.bold
                                            : FontWeight.w600,
                                        color: isSelected
                                            ? const Color(0xFFea580c)
                                            : const Color(0xFF334155),
                                      ),
                                    ),
                                  ),
                                  if (isSelected)
                                    const Icon(
                                      Icons.check_circle_rounded,
                                      color: Color(0xFFea580c),
                                      size: 18,
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      Center(
                        child: TextButton.icon(
                          onPressed: () {
                            setStateModal(() {
                              isHobbiesExpanded = !isHobbiesExpanded;
                            });
                          },
                          icon: Icon(
                            isHobbiesExpanded
                                ? Icons.keyboard_arrow_up_rounded
                                : Icons.keyboard_arrow_down_rounded,
                            color: const Color(0xFFea580c),
                            size: 18,
                          ),
                          label: Text(
                            isHobbiesExpanded
                                ? 'عرض أقل'
                                : 'المزيد من الهوايات والأنشطة',
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              color: Color(0xFFea580c),
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            backgroundColor: const Color(0xFFfff7ed),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: const BorderSide(
                                  color: Color(0xFFffedd5), width: 1),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text('المشرف المسؤول',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF334155))),
                      const SizedBox(height: 8),
                      TextField(
                        controller: supervisorController,
                        decoration: InputDecoration(
                          hintText: 'اسم المشرف من بيانات AWS',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  const BorderSide(color: Color(0xFFe2e8f0))),
                          enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  const BorderSide(color: Color(0xFFe2e8f0))),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text('صورة النشاط (اختياري)',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF334155))),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () async {
                          final ImagePicker picker = ImagePicker();
                          final XFile? image = await picker.pickImage(
                              source: ImageSource.gallery);
                          if (image != null) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('تم اختيار الصورة بنجاح!',
                                      style: TextStyle(fontFamily: 'Cairo')),
                                  backgroundColor: Color(0xFF10b981),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            }
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFe2e8f0)),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.image_search_rounded,
                                  color: Color(0xFFea580c), size: 20),
                              SizedBox(width: 8),
                              Text('اختر صورة للنشاط',
                                  style: TextStyle(
                                      color: Color(0xFFea580c),
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text('التاريخ والوقت',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF334155))),
                      const SizedBox(height: 8),
                      TextField(
                        controller: dateController,
                        readOnly: true,
                        onTap: () async {
                          DateTime? pickedDate = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime.now(),
                            lastDate: DateTime(2101),
                            builder: (context, child) {
                              return Theme(
                                data: Theme.of(context).copyWith(
                                  colorScheme: const ColorScheme.light(
                                    primary: Color(0xFFea580c),
                                    onPrimary: Colors.white,
                                    onSurface: Color(0xFF0f172a),
                                  ),
                                ),
                                child: child!,
                              );
                            },
                          );
                          if (pickedDate != null) {
                            if (context.mounted) {
                              TimeOfDay? pickedTime = await showTimePicker(
                                context: context,
                                initialTime: TimeOfDay.now(),
                                initialEntryMode: TimePickerEntryMode.input,
                                builder: (context, child) {
                                  return Theme(
                                    data: Theme.of(context).copyWith(
                                      colorScheme: const ColorScheme.light(
                                        primary: Color(0xFFea580c),
                                        onPrimary: Colors.white,
                                        onSurface: Color(0xFF0f172a),
                                      ),
                                      timePickerTheme:
                                          const TimePickerThemeData(
                                        backgroundColor: Colors.white,
                                        dialHandColor: Color(0xFFea580c),
                                        dialBackgroundColor: Color(0xFFfff7ed),
                                        entryModeIconColor: Color(0xFFea580c),
                                        hourMinuteColor: Color(0xFFfff7ed),
                                        hourMinuteTextColor: Color(0xFFea580c),
                                        dayPeriodColor: Color(0xFFfff7ed),
                                        dayPeriodTextColor: Color(0xFFea580c),
                                        dayPeriodBorderSide: BorderSide(
                                            color: Color(0xFFea580c)),
                                      ),
                                    ),
                                    child: child!,
                                  );
                                },
                              );
                              if (pickedTime != null) {
                                if (!context.mounted) return;
                                final formattedDate =
                                    "${pickedDate.year}/${pickedDate.month}/${pickedDate.day} - ${pickedTime.format(context)}";
                                setStateModal(() {
                                  dateController.text = formattedDate;
                                });
                              }
                            }
                          }
                        },
                        decoration: InputDecoration(
                          hintText: 'اختر التاريخ والوقت',
                          filled: true,
                          fillColor: Colors.white,
                          suffixIcon: const Icon(Icons.calendar_today_rounded,
                              color: Color(0xFFea580c)),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  const BorderSide(color: Color(0xFFe2e8f0))),
                          enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  const BorderSide(color: Color(0xFFe2e8f0))),
                        ),
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: () async {
                            final activity = Activity(
                              id: (editActivity?['id'] as String?) ??
                                  DateTime.now()
                                      .millisecondsSinceEpoch
                                      .toString(),
                              name: titleController.text,
                              emoji: selectedType == 'رحلة' ? '🌳' : '🎨',
                              location: locationController.text,
                              time: dateController.text.isNotEmpty
                                  ? dateController.text
                                  : 'غير محدد',
                              status: 'coming',
                              badges: selectedType,
                              pointsReward: 30,
                              dayTag: 'اليوم',
                            );
                            if (editActivity != null) {
                              await ref
                                  .read(appRiverpod)
                                  .updateActivity(activity);
                            } else {
                              await ref.read(appRiverpod).addActivity(activity);
                            }
                            if (!context.mounted) return;

                            Navigator.pop(context);

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    editActivity != null
                                        ? 'تم تحديث النشاط بنجاح!'
                                        : 'تم حفظ النشاط بنجاح!',
                                    style:
                                        const TextStyle(fontFamily: 'Cairo')),
                                backgroundColor: const Color(0xFF10b981),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFea580c),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                          ),
                          child: Text(
                              editActivity != null
                                  ? 'تحديث النشاط'
                                  : 'حفظ النشاط',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// كلاسات الأنيميشن الخاصة بغبار النجوم
class ActivitiesCardDustParticle {
  Offset position;
  double speed;
  double radius;
  ActivitiesCardDustParticle(
      {required this.position, required this.speed, required this.radius});
}

class ActivitiesCardDustAnimation extends StatefulWidget {
  const ActivitiesCardDustAnimation({super.key});

  @override
  State<ActivitiesCardDustAnimation> createState() =>
      _ActivitiesCardDustAnimationState();
}

class _ActivitiesCardDustAnimationState
    extends State<ActivitiesCardDustAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<ActivitiesCardDustParticle> _dust;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 15))
          ..repeat();

    final random = Random();
    _dust = List.generate(100, (index) {
      return ActivitiesCardDustParticle(
        position: Offset(random.nextDouble(), random.nextDouble()),
        speed: random.nextDouble() * 0.05 + 0.02,
        radius: random.nextDouble() * 1.5 + 0.5,
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            painter: ActivitiesCardDustPainter(
                dust: _dust, animationValue: _controller.value),
          );
        },
      ),
    );
  }
}

class ActivitiesCardDustPainter extends CustomPainter {
  final List<ActivitiesCardDustParticle> dust;
  final double animationValue;

  ActivitiesCardDustPainter({required this.dust, required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFea580c).withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;

    for (var i = 0; i < dust.length; i++) {
      final p = dust[i];

      // حركة للأعلى
      double dy = (p.position.dy * size.height) -
          (animationValue * p.speed * size.height);
      if (dy < 0) dy += size.height;

      double dx =
          p.position.dx * size.width + sin(animationValue * 2 * pi + i) * 5;

      final currentPos = Offset(dx, dy);

      double opacity = (sin(animationValue * 2 * pi * 2 + i) + 1) / 2;
      paint.color = const Color(0xFFea580c).withValues(alpha: opacity * 0.4);

      canvas.drawCircle(currentPos, p.radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant ActivitiesCardDustPainter oldDelegate) {
    return true;
  }
}
