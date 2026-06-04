import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/app_riverpod.dart';
import '../../../models/app_models.dart';

class AdminVolunteerView extends StatelessWidget {
  final List<Animation<double>> fadeAnimations;

  const AdminVolunteerView({super.key, required this.fadeAnimations});

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final provider = ref.watch(appRiverpod);
        final opportunities = provider.volunteerOpportunities;
        final applications = provider.volunteerApplications;
        final pending = applications.where((a) => a.status == 'pending').toList();

        return Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Summary bar
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                        color: const Color(0xFF0ea5e9),
                        borderRadius: BorderRadius.circular(24)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _summaryItem(
                            opportunities.length.toString(), 'إجمالي الفرص'),
                        _summaryItem(
                            opportunities
                                .where((o) => o.status == 'متاحة')
                                .length
                                .toString(),
                            'فرص متاحة'),
                        _summaryItem(
                            pending.length.toString(), 'طلبات منتظرة'),
                      ],
                    ),
                  ),
                  // Pending applications section
                  if (pending.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        const Text('طلبات التطوع المعلّقة',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1e293b))),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                              color: const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(12)),
                          child: Text(
                            '${pending.length}',
                            style: const TextStyle(
                                color: Color(0xFFD97706),
                                fontWeight: FontWeight.bold,
                                fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...pending.map((app) =>
                        _buildApplicationCard(context, provider, app)),
                  ],
                  // All applications (approved/rejected) collapsible
                  if (applications.any((a) => a.status != 'pending')) ...[
                    const SizedBox(height: 16),
                    _buildAllApplicationsSection(context, provider, applications),
                  ],
                  const SizedBox(height: 24),
                  const Text('الفرص التطوعية المتاحة',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1e293b))),
                  const SizedBox(height: 16),
                  if (opportunities.isEmpty)
                    const Center(child: Text('لا توجد فرص متاحة'))
                  else
                    ...opportunities.asMap().entries.map((entry) {
                      final index = entry.key;
                      final opp = entry.value;
                      final oppApps = applications
                          .where((a) => a.opportunityId == opp.id)
                          .toList();
                      return FadeTransition(
                        opacity: fadeAnimations[index % fadeAnimations.length],
                        child: GestureDetector(
                          onTap: () {
                            if (oppApps.isNotEmpty) {
                              _showOpportunityApplications(
                                  context, provider, opp, oppApps);
                            } else {
                              _showEditOpportunitySheet(context, provider, opp);
                            }
                          },
                          child: _buildOpportunityCard(opp, oppApps),
                        ),
                      );
                    }),
                ],
              ),
            ),
            Positioned(
              bottom: 24,
              right: 24,
              child: FloatingActionButton.extended(
                onPressed: () => _showAddOpportunitySheet(context, provider),
                backgroundColor: const Color(0xFF0ea5e9),
                elevation: 4,
                icon: const Icon(Icons.add_circle_outline_rounded,
                    color: Colors.white),
                label: const Text('إنشاء فرصة',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Cairo')),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _summaryItem(String val, String label) {
    return Column(
      children: [
        Text(val,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold)),
        Text(label,
            style: const TextStyle(color: Colors.white70, fontSize: 10)),
      ],
    );
  }

  Widget _buildApplicationCard(
      BuildContext context, AppRiverpod provider, VolunteerApplication app) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFFEF3C7), width: 1.5),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 3))
          ]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                    color: Color(0xFFFEF3C7), shape: BoxShape.circle),
                child: const Icon(Icons.person_rounded,
                    color: Color(0xFFD97706), size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(app.volunteerName,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Color(0xFF1e293b))),
                    Text(app.opportunityTitle,
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xFF64748b))),
                  ],
                ),
              ),
              Text(app.createdAt,
                  style: const TextStyle(
                      fontSize: 10, color: Color(0xFF94a3b8))),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final ok = await provider.approveVolunteerApplication(app.id);
                    if (ok && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('تم قبول المتطوع'),
                        backgroundColor: Color(0xFF10B981),
                      ));
                    }
                  },
                  icon: const Icon(Icons.check_rounded, size: 16),
                  label: const Text('قبول'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    textStyle: const TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.bold,
                        fontSize: 13),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final ok = await provider.rejectVolunteerApplication(app.id);
                    if (ok && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('تم رفض الطلب'),
                        backgroundColor: Color(0xFFEF4444),
                      ));
                    }
                  },
                  icon: const Icon(Icons.close_rounded, size: 16),
                  label: const Text('رفض'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFEF4444),
                    side: const BorderSide(color: Color(0xFFEF4444)),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    textStyle: const TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.bold,
                        fontSize: 13),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAllApplicationsSection(BuildContext context, AppRiverpod provider,
      List<VolunteerApplication> applications) {
    final decided = applications.where((a) => a.status != 'pending').toList();
    if (decided.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('الطلبات المُعالجة (${decided.length})',
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Color(0xFF64748b))),
        const SizedBox(height: 8),
        ...decided.take(5).map((app) => Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0))),
              child: Row(
                children: [
                  Icon(
                    app.status == 'confirmed'
                        ? Icons.check_circle_rounded
                        : Icons.cancel_rounded,
                    color: app.status == 'confirmed'
                        ? const Color(0xFF10B981)
                        : const Color(0xFFEF4444),
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text('${app.volunteerName} — ${app.opportunityTitle}',
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xFF475569))),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                        color: app.status == 'confirmed'
                            ? const Color(0xFFDCFCE7)
                            : const Color(0xFFFEE2E2),
                        borderRadius: BorderRadius.circular(8)),
                    child: Text(
                      app.status == 'confirmed' ? 'مقبول' : 'مرفوض',
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: app.status == 'confirmed'
                              ? const Color(0xFF059669)
                              : const Color(0xFFDC2626)),
                    ),
                  ),
                ],
              ),
            )),
      ],
    );
  }

  void _showOpportunityApplications(BuildContext context, AppRiverpod provider,
      VolunteerOpportunity opp, List<VolunteerApplication> apps) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        constraints:
            BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.75),
        decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
                child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(10)))),
            const SizedBox(height: 16),
            Text(opp.title,
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1e293b))),
            Text('${apps.length} متطوع', style: const TextStyle(color: Color(0xFF64748b))),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: apps.length,
                itemBuilder: (_, i) {
                  final app = apps[i];
                  if (app.status == 'pending') {
                    return _buildApplicationCard(context, provider, app);
                  }
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12)),
                    child: Row(
                      children: [
                        Icon(
                          app.status == 'confirmed'
                              ? Icons.check_circle_rounded
                              : Icons.cancel_rounded,
                          color: app.status == 'confirmed'
                              ? const Color(0xFF10B981)
                              : const Color(0xFFEF4444),
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Text(app.volunteerName,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1e293b))),
                        const Spacer(),
                        Text(
                          app.status == 'confirmed' ? 'مقبول' : 'مرفوض',
                          style: TextStyle(
                              fontSize: 12,
                              color: app.status == 'confirmed'
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFFEF4444)),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _showEditOpportunitySheet(context, provider, opp);
                },
                child: const Text('تعديل الفرصة',
                    style: TextStyle(color: Color(0xFF0ea5e9))),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOpportunityCard(VolunteerOpportunity opp,
      [List<VolunteerApplication> apps = const []]) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
            border: Border.all(color: const Color(0xFFf1f5f9))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(opp.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0f172a))),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.edit_note_rounded,
                          size: 18, color: Color(0xFF64748b)),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                      color: opp.status == 'متاحة'
                          ? const Color(0xFFdcfce7)
                          : const Color(0xFFf1f5f9),
                      borderRadius: BorderRadius.circular(10)),
                  child: Text(opp.status,
                      style: TextStyle(
                          color: opp.status == 'متاحة'
                              ? const Color(0xFF15803d)
                              : const Color(0xFF64748b),
                          fontSize: 11,
                          fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(opp.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 13, height: 1.5, color: Color(0xFF475569))),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _infoChip(
                    Icons.person_search_rounded,
                    opp.targetResident.isEmpty
                        ? 'كل المقيمين'
                        : opp.targetResident),
                _infoChip(
                    Icons.groups_rounded,
                    opp.targetAudience.isEmpty
                        ? 'متطوع مناسب'
                        : opp.targetAudience),
                _infoChip(Icons.event_seat_rounded,
                    '${opp.filledSlots}/${opp.totalSlots} مقاعد'),
                _infoChip(Icons.schedule_rounded, '${opp.hours} ساعة'),
              ],
            ),
            if (opp.displaySkills.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: opp.displaySkills
                    .take(4)
                    .map((skill) => _skillChip(skill))
                    .toList(),
              ),
            ],
            // Applications summary for this opportunity
            if (apps.isNotEmpty) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.people_rounded,
                      size: 14, color: Color(0xFF0ea5e9)),
                  const SizedBox(width: 5),
                  Text('${apps.length} متطوع',
                      style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF0ea5e9),
                          fontWeight: FontWeight.w600)),
                  const SizedBox(width: 8),
                  if (apps.any((a) => a.status == 'pending')) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(6)),
                      child: Text(
                        '${apps.where((a) => a.status == 'pending').length} منتظر',
                        style: const TextStyle(
                            fontSize: 10,
                            color: Color(0xFFD97706),
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                  const Spacer(),
                  const Text('اضغط لعرض الطلبات',
                      style: TextStyle(
                          fontSize: 10, color: Color(0xFF94a3b8))),
                ],
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.star_rounded,
                    color: Color(0xFFf59e0b), size: 20),
                const SizedBox(width: 6),
                Text('${opp.points} نقطة مكافأة',
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0ea5e9))),
                const Spacer(),
                Text(opp.date,
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF94a3b8))),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _infoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: const Color(0xFF0284C7), size: 14),
          const SizedBox(width: 5),
          Text(text,
              style: const TextStyle(
                  color: Color(0xFF334155),
                  fontSize: 10,
                  fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _skillChip(String skill) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFBBF7D0)),
      ),
      child: Text(skill,
          style: const TextStyle(
              color: Color(0xFF15803D),
              fontSize: 10,
              fontWeight: FontWeight.bold)),
    );
  }

  void _showEditOpportunitySheet(
      BuildContext context, AppRiverpod provider, VolunteerOpportunity opp) {
    final titleController = TextEditingController(text: opp.title);
    final descController = TextEditingController(text: opp.description);
    final dateController = TextEditingController(text: opp.dateInfo);
    final hoursController = TextEditingController(text: opp.hours.toString());
    final slotsController =
        TextEditingController(text: opp.totalSlots.toString());
    final targetResidentController =
        TextEditingController(text: opp.targetResident);
    final targetAudienceController =
        TextEditingController(text: opp.targetAudience);
    final skillsController =
        TextEditingController(text: opp.displaySkills.join(', '));
    int selectedPoints = opp.points;

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, anim1, anim2) => const SizedBox(),
      transitionBuilder: (context, anim1, anim2, child) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: anim1, curve: Curves.elasticOut),
          child: AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
            contentPadding: EdgeInsets.zero,
            content: Directionality(
              textDirection: TextDirection.rtl,
              child: Container(
                width: MediaQuery.of(context).size.width * 0.9,
                padding: const EdgeInsets.all(24),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('تعديل الفرصة 📝',
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1e293b))),
                          IconButton(
                            onPressed: () {
                              // Delete logic
                              provider.volunteerOpportunities
                                  .removeWhere((o) => o.id == opp.id);
                              provider.refreshState();
                              Navigator.pop(context);
                            },
                            icon: const Icon(Icons.delete_outline_rounded,
                                color: Colors.red),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildField(titleController, 'عنوان الفرصة'),
                      const SizedBox(height: 12),
                      _buildField(descController, 'وصف المهمة', maxLines: 3),
                      const SizedBox(height: 12),
                      _buildField(
                          targetResidentController, 'لمن؟ اسم المقيم أو الفئة'),
                      const SizedBox(height: 12),
                      _buildField(targetAudienceController,
                          'نوع المتطوع المطلوب / الفئة المستهدفة'),
                      const SizedBox(height: 12),
                      _buildField(skillsController,
                          'المهارات المطلوبة، افصل بينها بفاصلة'),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                              child: _buildField(
                                  dateController, 'الموعد أو التكرار')),
                          const SizedBox(width: 10),
                          Expanded(
                              child: _buildField(hoursController, 'الساعات')),
                          const SizedBox(width: 10),
                          Expanded(
                              child: _buildField(slotsController, 'المقاعد')),
                        ],
                      ),
                      const SizedBox(height: 16),
                      StatefulBuilder(builder: (context, setModalState) {
                        return Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('النقاط',
                                    style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF334155))),
                                Text('$selectedPoints نقطة',
                                    style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF0ea5e9))),
                              ],
                            ),
                            Slider(
                              value: selectedPoints.toDouble(),
                              min: 10,
                              max: 200,
                              divisions: 19,
                              activeColor: const Color(0xFF0ea5e9),
                              onChanged: (val) => setModalState(
                                  () => selectedPoints = val.toInt()),
                            ),
                          ],
                        );
                      }),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () {
                            if (titleController.text.isNotEmpty &&
                                descController.text.isNotEmpty) {
                              final updatedOpp = VolunteerOpportunity(
                                id: opp.id,
                                title: titleController.text,
                                org: opp.org,
                                dateInfo: dateController.text.trim().isEmpty
                                    ? opp.dateInfo
                                    : dateController.text.trim(),
                                icon: opp.icon,
                                tags: _parseSkills(skillsController.text),
                                hours: int.tryParse(hoursController.text) ??
                                    opp.hours,
                                isNew: opp.isNew,
                                description: descController.text,
                                totalSlots:
                                    int.tryParse(slotsController.text) ??
                                        opp.totalSlots,
                                filledSlots: opp.filledSlots,
                                points: selectedPoints,
                                targetAudience:
                                    targetAudienceController.text.trim(),
                                targetResident:
                                    targetResidentController.text.trim(),
                                requiredSkills:
                                    _parseSkills(skillsController.text),
                              );
                              provider.updateVolunteerOpportunity(updatedOpp);
                              Navigator.pop(context);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0ea5e9),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                          child: const Text('حفظ التغييرات',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showAddOpportunitySheet(BuildContext context, AppRiverpod provider) {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    final dateController = TextEditingController(text: 'اليوم');
    final hoursController = TextEditingController(text: '1');
    final slotsController = TextEditingController(text: '5');
    final targetResidentController = TextEditingController();
    final targetAudienceController = TextEditingController();
    final skillsController = TextEditingController(text: 'التواصل، عام');
    int selectedPoints = 50;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            left: 24,
            right: 24,
            top: 24,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.84,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                      child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(10)))),
                  const SizedBox(height: 20),
                  const Text('نشر فرصة تطوعية جديدة ✨',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1e293b))),
                  const Text('ستظهر الفرصة فوراً لجميع المتطوعين المتاحين.',
                      style: TextStyle(fontSize: 13, color: Color(0xFF64748b))),
                  const SizedBox(height: 24),
                  _buildField(
                      titleController, 'عنوان الفرصة (مثال: مرافقة طبية)'),
                  const SizedBox(height: 12),
                  _buildField(descController, 'وصف المهمة المطلوبة',
                      maxLines: 3),
                  const SizedBox(height: 12),
                  _buildField(
                      targetResidentController, 'لمن؟ اسم المقيم أو الفئة'),
                  const SizedBox(height: 12),
                  _buildField(targetAudienceController,
                      'نوع المتطوع المطلوب / الفئة المستهدفة'),
                  const SizedBox(height: 12),
                  _buildField(
                      skillsController, 'المهارات المطلوبة، افصل بينها بفاصلة'),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _buildField(dateController, 'الموعد')),
                      const SizedBox(width: 10),
                      Expanded(child: _buildField(hoursController, 'الساعات')),
                      const SizedBox(width: 10),
                      Expanded(child: _buildField(slotsController, 'المقاعد')),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('النقاط الممنوحة',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF334155))),
                      Text('$selectedPoints نقطة',
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0ea5e9))),
                    ],
                  ),
                  Slider(
                    value: selectedPoints.toDouble(),
                    min: 10,
                    max: 200,
                    divisions: 19,
                    activeColor: const Color(0xFF0ea5e9),
                    onChanged: (val) =>
                        setModalState(() => selectedPoints = val.toInt()),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: () {
                        if (titleController.text.isNotEmpty &&
                            descController.text.isNotEmpty) {
                          final newOpp = VolunteerOpportunity(
                            id: 'opp${DateTime.now().millisecondsSinceEpoch}',
                            title: titleController.text,
                            org: 'الإدارة العامة',
                            dateInfo: dateController.text.trim().isEmpty
                                ? 'اليوم'
                                : dateController.text.trim(),
                            icon: '🌟',
                            tags: _parseSkills(skillsController.text),
                            hours: int.tryParse(hoursController.text) ?? 1,
                            isNew: true,
                            description: descController.text,
                            totalSlots: int.tryParse(slotsController.text) ?? 5,
                            filledSlots: 0,
                            points: selectedPoints,
                            targetAudience:
                                targetAudienceController.text.trim(),
                            targetResident:
                                targetResidentController.text.trim(),
                            requiredSkills: _parseSkills(skillsController.text),
                          );
                          provider.addVolunteerOpportunity(newOpp);
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('تم نشر الفرصة بنجاح! 🎉'),
                              backgroundColor: Color(0xFF0ea5e9),
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0ea5e9),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text('نشر الفرصة الآن',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController controller, String hint,
      {int maxLines = 1}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
          color: const Color(0xFFf8fafc),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFe2e8f0))),
      child: TextField(
        controller: controller,
        textAlign: TextAlign.right,
        maxLines: maxLines,
        decoration: InputDecoration(
            hintText: hint,
            border: InputBorder.none,
            hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94a3b8))),
      ),
    );
  }

  List<String> _parseSkills(String raw) {
    return raw
        .split(RegExp(r'[,،\n]'))
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toSet()
        .toList();
  }
}
