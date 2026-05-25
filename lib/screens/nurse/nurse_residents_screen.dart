import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/app_riverpod.dart';
import '../../models/app_models.dart';
import 'nurse_resident_detail_screen.dart';
import 'widgets/healing_particles.dart';
import '../../widgets/live_cloud_residents_banner.dart';
import 'dart:math';

class NurseResidentsScreen extends ConsumerStatefulWidget {
  const NurseResidentsScreen({super.key});

  @override
  ConsumerState<NurseResidentsScreen> createState() =>
      _NurseResidentsScreenState();
}

class _NurseResidentsScreenState extends ConsumerState<NurseResidentsScreen>
    with TickerProviderStateMixin {
  late AnimationController _blinkController;
  late AnimationController _pulseRedController;
  late AnimationController _pulseGrnController;
  late AnimationController _floatController;
  late AnimationController _spinController;

  String _searchQuery = '';
  String _selectedFilter = 'الكل (٢٤)';
  bool _loadMore = false;

  @override
  void initState() {
    super.initState();
    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);

    _pulseRedController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();

    _pulseGrnController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();

    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3500),
    )..repeat(reverse: true);

    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 9),
    )..repeat();
  }

  @override
  void dispose() {
    _blinkController.dispose();
    _pulseRedController.dispose();
    _pulseGrnController.dispose();
    _floatController.dispose();
    _spinController.dispose();
    super.dispose();
  }

  String _getShiftName() {
    final hour = DateTime.now().hour;
    if (hour >= 6 && hour < 14) return 'الوردية الصباحية (٦ ص - ٢ ظ)';
    if (hour >= 14 && hour < 22) return 'الوردية المسائية (٢ ظ - ١٠ م)';
    return 'الوردية الليلية (١٠ م - ٦ ص)';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      body: AnimatedBackground(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    _buildHero(),
                    const LiveCloudResidentsBanner(),
                    _buildSearchAndFilter(isDark),
                    _buildBody(isDark),
                    const SizedBox(
                        height: 100), // Space for parent's bottom nav
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHero() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0369A1), Color(0xFF0EA5E9), Color(0xFF06B6D4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Stack(
        children: [
          const HealingParticles(), // إضافة الأنيميشن
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 30),
              const Text(
                'ملفات المقيمين',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
              Text(
                '٢٤ مقيم — ${_getShiftName()}',
                style: const TextStyle(fontSize: 13, color: Color(0xFFE0F2FE)),
              ),
              const SizedBox(height: 16),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                reverse: true,
                child: Row(
                  children: [
                    _heroChip('حرجة ٢', const Color(0xFFEF4444), blink: true),
                    _heroChip('تحذير ٥', const Color(0xFFFBBF24)),
                    _heroChip('مستقرة ١٧', const Color(0xFF4ADE80)),
                    _heroChip('جديد ١', const Color(0xFFA78BFA)),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ],
      ),
    );
  }

  Widget _heroChip(String label, Color dotColor, {bool blink = false}) {
    return Container(
      margin: const EdgeInsets.only(left: 7),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          blink
              ? FadeTransition(
                  opacity: _blinkController,
                  child: Container(
                    width: 7,
                    height: 7,
                    decoration:
                        BoxDecoration(shape: BoxShape.circle, color: dotColor),
                  ),
                )
              : Container(
                  width: 7,
                  height: 7,
                  decoration:
                      BoxDecoration(shape: BoxShape.circle, color: dotColor),
                ),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
                color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 45,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color:
                            isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                  ),
                  child: TextField(
                    textAlign: TextAlign.right,
                    onChanged: (v) => setState(() => _searchQuery = v),
                    style: TextStyle(
                        color: isDark ? Colors.white : Colors.black,
                        fontSize: 13),
                    decoration: InputDecoration(
                      hintText: '...ابحث بالاسم أو رقم الغرفة',
                      hintStyle: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? Colors.white38
                              : const Color(0xFF94A3B8)),
                      prefixIcon: Icon(Icons.search,
                          color:
                              isDark ? Colors.white38 : const Color(0xFF94A3B8),
                          size: 20),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                height: 45,
                width: 45,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                ),
                child: const Icon(Icons.filter_list_rounded,
                    color: Color(0xFF0369A1)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            reverse: true,
            child: Row(
              children: [
                _filterChip(isDark, 'الكل (٢٤)', 'الكل (٢٤)'),
                _filterChip(isDark, '🔴 حرجة', 'حرجة 🔴'),
                _filterChip(isDark, '🟡 تحذير', 'تحذير 🟡'),
                _filterChip(isDark, '✅ مستقرة', 'مستقرة ✅'),
                _filterChip(isDark, '🆕 جديد', 'جديد'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(bool isDark, String label, String value) {
    bool isSelected = _selectedFilter == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = value),
      child: Container(
        margin: const EdgeInsets.only(left: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF0369A1)
              : (isDark ? const Color(0xFF1E293B) : Colors.white),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: isSelected
                  ? const Color(0xFF0369A1)
                  : (isDark ? Colors.white12 : const Color(0xFFE2E8F0))),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: isSelected
                ? Colors.white
                : (isDark ? Colors.white70 : const Color(0xFF64748B)),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(bool isDark) {
    final provider = ref.watch(appRiverpod);

    String getLatestNote(String name) {
      final notes = provider.getNotesForResident(name);
      return notes.isNotEmpty
          ? '${notes.first.title}: ${notes.first.content}'
          : '';
    }

    bool matchesFilter(String status) {
      if (_selectedFilter.startsWith('الكل')) return true;
      if (_selectedFilter == 'حرجة 🔴') return status == 'critical';
      if (_selectedFilter == 'تحذير 🟡') return status == 'pending';
      if (_selectedFilter == 'مستقرة ✅') return status == 'updated';
      return true;
    }

    bool matchesSearch(SpecialistResidentFile f) {
      if (_searchQuery.isEmpty) return true;
      return f.name.contains(_searchQuery) || f.room.contains(_searchQuery);
    }

    final critical = provider.residentFiles
        .where((f) => f.status == 'critical' && matchesFilter(f.status) && matchesSearch(f))
        .toList();
    final warning = provider.residentFiles
        .where((f) => f.status == 'pending' && matchesFilter(f.status) && matchesSearch(f))
        .toList();
    final stable = provider.residentFiles
        .where((f) => f.status == 'updated' && matchesFilter(f.status) && matchesSearch(f))
        .toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          if (critical.isNotEmpty)
            _buildDynamicSection(
              label: 'حالات تحتاج تدخل فوري',
              labelColor: const Color(0xFFEF4444),
              files: critical,
              type: 'critical',
              statusLabel: '🔴 حرجة',
              statusColor: const Color(0xFFEF4444),
              statusBg: const Color(0xFFFEF2F2),
              getLatestNote: getLatestNote,
            ),
          if (warning.isNotEmpty)
            _buildDynamicSection(
              label: 'تحتاج متابعة دقيقة',
              labelColor: const Color(0xFFF59E0B),
              files: warning,
              type: 'warning',
              statusLabel: '🟡 تحذير',
              statusColor: const Color(0xFF92400E),
              statusBg: const Color(0xFFFEF3C7),
              getLatestNote: getLatestNote,
            ),
          if (stable.isNotEmpty)
            _buildDynamicSection(
              label: 'مستقرة — لا تحتاج تدخل',
              labelColor: const Color(0xFF10B981),
              files: stable,
              type: 'stable',
              statusLabel: '✅ ممتاز',
              statusColor: const Color(0xFF065F46),
              statusBg: const Color(0xFFD1FAE5),
              getLatestNote: getLatestNote,
            ),
          if (critical.isEmpty && warning.isEmpty && stable.isEmpty)
            const Padding(
              padding: EdgeInsets.all(40),
              child: Text(
                'لا توجد بيانات مقيمين بعد. تأكد من المزامنة مع السيرفر.',
                style: TextStyle(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ),
          const SizedBox(height: 12),
          _buildMoreIndicator(),
        ],
      ),
    );
  }

  Widget _buildDynamicSection({
    required String label,
    required Color labelColor,
    required List<SpecialistResidentFile> files,
    required String type,
    required String statusLabel,
    required Color statusColor,
    required Color statusBg,
    required String Function(String) getLatestNote,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: labelColor,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: labelColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...files.map((f) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildResidentCard(
                name: f.name,
                age: f.age != null ? '${f.age} سنة' : '',
                room: 'غرفة ${f.room}',
                diagnoses: f.categories.join(' + '),
                statusLabel: statusLabel,
                statusColor: statusColor,
                statusBg: statusBg,
                type: type,
                meds: [],
                medPercentage: '',
                note: getLatestNote(f.name),
                actions: [
                  if (type == 'critical')
                    _actionBtn('طوارئ',
                        color: const Color(0xFF7F1D1D),
                        bg: const Color(0xFFFEE2E2),
                        onTap: () => _showEmergencyAlert(f.name)),
                  _actionBtn('الملف الكامل',
                      color: type == 'critical'
                          ? Colors.white
                          : const Color(0xFF0369A1),
                      isPrimary: type == 'critical',
                      bg: type == 'critical'
                          ? const Color(0xFF0369A1)
                          : const Color(0xFFF0F9FF),
                      border: type == 'critical' ? null : const Color(0xFFBAE6FD),
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => NurseResidentDetailScreen(
                                  residentName: f.name,
                                  roomNumber: f.room)))),
                  _actionBtn('ملاحظة',
                      color: const Color(0xFF0369A1),
                      bg: const Color(0xFFF0F9FF),
                      border: type != 'critical'
                          ? const Color(0xFFBAE6FD)
                          : null,
                      onTap: () => _showNoteDialog(f.name)),
                ],
              ),
            )),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildResidentCard({
    required String name,
    required String age,
    required String room,
    required String diagnoses,
    required String statusLabel,
    required Color statusColor,
    required Color statusBg,
    required String type,
    List<Widget>? meds,
    String? medPercentage,
    String? note,
    required List<Widget> actions,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    Color cardBorder;
    Color headerBg;
    Color avBg;
    Color avFg;
    Color pipColor;
    bool showPulse = false;

    if (type == 'critical') {
      cardBorder = isDark ? const Color(0xFF991B1B) : const Color(0xFFFCA5A5);
      headerBg = isDark
          ? const Color(0xFF7F1D1D).withValues(alpha: 0.2)
          : const Color(0xFFFFF5F5);
      avBg = isDark
          ? const Color(0xFF7F1D1D).withValues(alpha: 0.3)
          : const Color(0xFFFFE4E6);
      avFg = isDark ? const Color(0xFFFECACA) : const Color(0xFF9F1239);
      pipColor = const Color(0xFFEF4444);
      showPulse = true;
    } else if (type == 'warning') {
      cardBorder = isDark ? const Color(0xFF92400E) : const Color(0xFFFDE68A);
      headerBg = isDark
          ? const Color(0xFF78350F).withValues(alpha: 0.2)
          : const Color(0xFFFFFBEB);
      avBg = isDark
          ? const Color(0xFF78350F).withValues(alpha: 0.3)
          : const Color(0xFFFEF3C7);
      avFg = isDark ? const Color(0xFFFDE68A) : const Color(0xFF92400E);
      pipColor = const Color(0xFFF59E0B);
    } else {
      cardBorder = isDark ? const Color(0xFF075985) : const Color(0xFFE0F2FE);
      headerBg = isDark
          ? const Color(0xFF0C4A6E).withValues(alpha: 0.2)
          : const Color(0xFFF0FDF4);
      avBg = isDark
          ? const Color(0xFF0C4A6E).withValues(alpha: 0.3)
          : const Color(0xFFD1FAE5);
      avFg = isDark ? const Color(0xFFBAE6FD) : const Color(0xFF065F46);
      pipColor = const Color(0xFF10B981);
    }

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cardBorder, width: 1.5),
        boxShadow: [
          BoxShadow(
              color: cardBorder.withValues(alpha: 0.15),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
            color: headerBg,
            child: Row(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: avBg,
                      child: Text(
                        name.substring(0, 2),
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: avFg),
                      ),
                    ),
                    Positioned(
                      bottom: 1,
                      left: 1,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: pipColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: showPulse
                            ? ScaleTransition(
                                scale: Tween<double>(begin: 0.8, end: 1.2)
                                    .animate(_pulseRedController),
                                child: Container(
                                  decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white),
                                ),
                              )
                            : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start, // محاذاة لليمين في الـ RTL
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: statusBg,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          statusLabel,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        name,
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A)),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$room · $age',
                        style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20), // لتبعد عن أقصى الشمال
              ],
            ),
          ),
          // Info Section (Medication Progress)
          if (meds != null && meds.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(13),
              child: Row(
                children: [
                  const Text(
                    'أدوية اليوم 💊',
                    style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 8),
                  ...meds,
                  const Spacer(),
                  Text(
                    medPercentage!,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0369A1)),
                  ),
                ],
              ),
            ),
          if (note != null && note.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(left: 13, right: 13, bottom: 13),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      note,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF475569),
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.edit_note_rounded,
                      color: Color(0xFF0EA5E9), size: 16),
                ],
              ),
            ),
          // Actions
          Container(
            padding: const EdgeInsets.all(13),
            color: const Color(0xFFF8FAFC).withValues(alpha: 0.5),
            child: Row(
              children: actions
                  .map((a) => Expanded(
                      child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: a)))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionBtn(String label,
      {required Color color,
      required Color bg,
      Color? border,
      bool isPrimary = false,
      VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 7),
        decoration: BoxDecoration(
          gradient: isPrimary
              ? const LinearGradient(
                  colors: [Color(0xFF0369A1), Color(0xFF0EA5E9)])
              : null,
          color: isPrimary ? null : bg,
          borderRadius: BorderRadius.circular(10),
          border: border != null ? Border.all(color: border) : null,
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  // --- DIALOGS ---

  void _showNoteDialog(String residentName) {
    final titleController = TextEditingController();
    final contentController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Column(
          children: [
            const Text('إضافة ملاحظة تمريضية',
                textAlign: TextAlign.right,
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0369A1))),
            Text('المقيم: $residentName',
                textAlign: TextAlign.right,
                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              textAlign: TextAlign.right,
              decoration: InputDecoration(
                hintText: 'عنوان الملاحظة (مثال: وجبة الغداء)',
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
            const SizedBox(height: 12),
            TextField(
              controller: contentController,
              maxLines: 4,
              textAlign: TextAlign.right,
              decoration: InputDecoration(
                hintText: 'اكتب تفاصيل الملاحظة هنا...',
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
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text('بواسطة: ${ref.read(appRiverpod).currentAccount?.name ?? 'الممرض'} (مشرف)',
                    style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFF94A3B8),
                        fontWeight: FontWeight.bold)),
                const SizedBox(width: 4),
                const Icon(Icons.person_pin_rounded,
                    size: 14, color: Color(0xFF94A3B8)),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () {
              if (titleController.text.isNotEmpty &&
                  contentController.text.isNotEmpty) {
                final newNote = NursingNote(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  residentName: residentName,
                  title: titleController.text,
                  content: contentController.text,
                  author: '${ref.read(appRiverpod).currentAccount?.name ?? 'الممرض'} (مشرف)',
                  timestamp: DateTime.now(),
                );
                ref.read(appRiverpod).addNursingNote(newNote);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('تم تسجيل الملاحظة بنجاح')));
              }
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0EA5E9),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10))),
            child: const Text('حفظ الملاحظة',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showEmergencyAlert(String residentName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: const Color(0xFF7F1D1D),
        title: const Text('🚨 تأكيد استغاثة',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(
            'هل أنت متأكد من تفعيل حالة الطوارئ لـ $residentName؟ سيتم تنبيه الفريق الطبي فوراً.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 14)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child:
                  const Text('إلغاء', style: TextStyle(color: Colors.white70))),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  backgroundColor: Colors.red,
                  content: Text('تم إرسال إشارة الطوارئ!')));
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.white),
            child: const Text('تأكيد الطوارئ',
                style: TextStyle(
                    color: Color(0xFF7F1D1D), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _loadMoreResidents() {
    // تحميل الكروت فوراً بدون شاشة انتظار
    setState(() {
      _loadMore = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('تم تحميل جميع المقيمين بنجاح ✅'),
      backgroundColor: Color(0xFF10B981),
      behavior: SnackBarBehavior.floating,
    ));
  }

  Widget _buildMoreIndicator() {
    final provider = ref.watch(appRiverpod);
    final total = provider.totalResidentsCount;
    const shown = 4; // عدد الكروت المعروضة حالياً في الواجهة
    final remaining = total - shown;

    if (remaining <= 0 || _loadMore) {
      return const SizedBox
          .shrink(); // إخفاء العنصر إذا لم يكن هناك مقيمون إضافيون أو تم تحميلهم
    }

    return GestureDetector(
      onTap: _loadMoreResidents,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: const Color(0xFFBAE6FD),
              width: 1.5,
              style: BorderStyle.solid),
        ),
        child: Text(
          '+ $remaining مقيم آخر — اضغط لتحميل المزيد',
          textAlign: TextAlign.center,
          style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF0369A1),
              fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

class AnimatedBackground extends StatefulWidget {
  final Widget child;
  const AnimatedBackground({super.key, required this.child});

  @override
  State<AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return CustomPaint(
              painter: BackgroundPainter(_controller.value),
              child: Container(),
            );
          },
        ),
        const SodaBubblesBackground(), // إضافة فقاعات المياه الغازية (+)
        widget.child,
      ],
    );
  }
}

class BackgroundPainter extends CustomPainter {
  final double progress;
  BackgroundPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint1 = Paint()
      ..color = const Color(0xFFBAE6FD).withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;

    // Draw some circles that move based on progress!
    final center1 = Offset(
        size.width * 0.2, size.height * (0.2 + 0.1 * sin(progress * 2 * pi)));
    canvas.drawCircle(center1, 150, paint1);

    final paint2 = Paint()
      ..color = const Color(0xFFD1FAE5).withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;
    final center2 = Offset(
        size.width * 0.8, size.height * (0.8 - 0.1 * cos(progress * 2 * pi)));
    canvas.drawCircle(center2, 200, paint2);

    final paint3 = Paint()
      ..color = const Color(0xFFFEF08A).withValues(alpha: 0.1)
      ..style = PaintingStyle.fill;
    final center3 = Offset(
        size.width * 0.5, size.height * (0.5 + 0.05 * sin(progress * 4 * pi)));
    canvas.drawCircle(center3, 100, paint3);
  }

  @override
  bool shouldRepaint(covariant BackgroundPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class SodaBubblesBackground extends StatefulWidget {
  const SodaBubblesBackground({super.key});

  @override
  State<SodaBubblesBackground> createState() => _SodaBubblesBackgroundState();
}

class _SodaBubblesBackgroundState extends State<SodaBubblesBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 15))
          ..repeat();
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
          final size = MediaQuery.of(context).size;
          return Stack(
            children: List.generate(30, (index) {
              // كثرها (30 particles)
              final speed = 0.5 + (index * 0.15); // سرعات متفاوتة
              final progress =
                  (_controller.value * speed + (index * 0.05)) % 1.0;

              // توزيع أفقي عشوائي بناءً على الـ index
              final left = (index * 17.0) % size.width;

              return Positioned(
                left: left,
                bottom: progress *
                    size.height, // تتصاعد من الأسفل للأعلى بكامل طول الشاشة
                child: Opacity(
                  opacity: (1.0 - progress) * 0.7, // جعلها باينة أكثر
                  child: RotationTransition(
                    turns: AlwaysStoppedAnimation(progress * 2), // دوران مستمر
                    child: Icon(
                      Icons.add_rounded,
                      size: 12.0 + (index * 6) % 30, // تكبير الحجم قليلاً
                      color: const Color(0xFF0EA5E9)
                          .withValues(alpha: 0.6), // توضيح اللون أكثر
                    ),
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}
