import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/app_riverpod.dart';
import '../../../models/app_models.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../widgets/live_cloud_residents_banner.dart';

class SpecialistFilesView extends ConsumerWidget {
  final List<Animation<double>> fadeAnimations;
  final AnimationController floatController;
  final AnimationController shimmerController;
  final AnimationController popController;
  final void Function(int) onNavigate;

  const SpecialistFilesView({
    super.key,
    required this.fadeAnimations,
    required this.floatController,
    required this.shimmerController,
    required this.popController,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = ref.watch(appRiverpod);
    final files = provider.filteredResidentFiles;

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            children: [
              _buildSearchHeader(context, provider),
              const LiveCloudResidentsBanner(),
              _buildCategoryFilters(provider),
            ],
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                return FadeTransition(
                  opacity: fadeAnimations[index % 10],
                  child: _buildFileCard(context, files[index]),
                );
              },
              childCount: files.length,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchHeader(BuildContext context, AppRiverpod provider) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('ملفات المقيمين',
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFc2410c))),
          const Text('إدارة السجلات الاجتماعية والنفسية',
              style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF9a3412),
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 20),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 15,
                    offset: const Offset(0, 5))
              ],
            ),
            child: TextField(
              onChanged: (v) => provider.setResidentFilesSearchQuery(v),
              textAlign: TextAlign.right,
              decoration: const InputDecoration(
                hintText: 'بحث باسم المقيم أو رقم الغرفة...',
                hintStyle: TextStyle(fontSize: 13, color: Color(0xFF64748b)),
                suffixIcon: Icon(Icons.search, color: Color(0xFFea580c)),
                border: InputBorder.none,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilters(AppRiverpod provider) {
    final categories = ['الكل', 'اجتماعي', 'نفسي', 'طبي', 'إداري'];
    return SizedBox(
      height: 40,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        reverse: true,
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final cat = categories[index];
          final isAct = provider.selectedResidentFileCategory == cat;
          return GestureDetector(
            onTap: () => provider.setSelectedResidentFileCategory(cat),
            child: Container(
              margin: const EdgeInsets.only(left: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isAct ? const Color(0xFFea580c) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color:
                        isAct ? Colors.transparent : const Color(0xFFfed7aa)),
                boxShadow: isAct
                    ? [
                        BoxShadow(
                            color:
                                const Color(0xFFea580c).withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3))
                      ]
                    : null,
              ),
              child: Center(
                child: Text(
                  cat,
                  style: TextStyle(
                      color: isAct ? Colors.white : const Color(0xFF9a3412),
                      fontSize: 11,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFileCard(BuildContext context, SpecialistResidentFile file) {
    return GestureDetector(
      onTap: () => _showFileDetails(context, file),
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
              color: const Color(0xFFfed7aa).withValues(alpha: 0.5),
              width: 1.5),
          boxShadow: [
            BoxShadow(
                color: const Color(0xFFea580c).withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4))
          ],
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [Color(0xFFfff7ed), Color(0xFFffedd5)]),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: const Color(0xFFfed7aa)),
                    ),
                    child: Center(
                      child: Text(file.initials,
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFea580c))),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(file.name,
                          style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1f2937))),
                      Row(
                        children: [
                          Text('الغرفة ${file.room}',
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFFea580c),
                                  fontWeight: FontWeight.w600)),
                          const SizedBox(width: 8),
                          Text(file.lastUpdate,
                              style: const TextStyle(
                                  fontSize: 10,
                                  color: Color(0xFF334155),
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ],
                  ),
                  const Spacer(),
                  _buildStatusIcon(file.status),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFfff7ed)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => _showFileDetails(context, file),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                            colors: [Color(0xFFea580c), Color(0xFFf97316)]),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                              color: const Color(0xFFea580c)
                                  .withValues(alpha: 0.2),
                              blurRadius: 10)
                        ],
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.folder_open_rounded,
                              color: Colors.white, size: 14),
                          SizedBox(width: 8),
                          Text('فتح الملف الرقمي',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(),
                  _buildActionLabel(Icons.history_edu_rounded, 'سجل النشاط'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFileDetails(BuildContext context, SpecialistResidentFile file) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Color(0xFFf8fafc),
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2)),
            ),
            Expanded(
              child: Stack(
                children: [
                  const FilesCardDustAnimation(), // أنيميشن غبار النجوم في الخلفية
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildStatusBadge(file.status),
                            IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(Icons.close_rounded,
                                  color: Color(0xFF64748b)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(colors: [
                                  Color(0xFFfff7ed),
                                  Color(0xFFffedd5)
                                ]),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                    color: const Color(0xFFfed7aa), width: 2),
                              ),
                              child: Center(
                                child: Text(file.initials,
                                    style: const TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFFea580c))),
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(file.name,
                                      style: const TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF0f172a))),
                                  Text('غرفة ${file.room} · الطابق الأول',
                                      style: const TextStyle(
                                          fontSize: 14,
                                          color: Color(0xFFea580c))),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                        _buildDetailSectionTitle('الأقسام المفعلة'),
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            alignment: WrapAlignment.start,
                            children: file.categories.map((c) {
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: const Color(0xFFe2e8f0)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(_getCategoryIcon(c),
                                        size: 16,
                                        color: const Color(0xFFea580c)),
                                    const SizedBox(width: 8),
                                    Text(_getCategoryLabel(c),
                                        style: const TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF1e293b))),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(height: 32),
                        _buildDetailSectionTitle('آخر التحديثات'),
                        const SizedBox(height: 16),
                        _buildAuditTrailPanel(file.id),
                        const SizedBox(height: 40),
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFea580c),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16)),
                              elevation: 0,
                            ),
                            onPressed: () {
                              Navigator.pop(context);
                              _showPdfPreview(context, file);
                            },
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.download_rounded,
                                    color: Colors.white),
                                SizedBox(width: 12),
                                Text('تنزيل التقرير الشامل (PDF)',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAuditTrailPanel(String residentId) {
    return Consumer(
      builder: (ctx, ref, _) {
        final provider = ref.watch(appRiverpod);
        final trail = provider.residentAuditTrails[residentId];
        final isLoading =
            provider.loadingAuditTrailResidentIds.contains(residentId);

        if (trail == null && !isLoading) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ref.read(appRiverpod).loadAuditTrail(residentId);
          });
        }

        if (trail == null || isLoading) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        }

        if (trail.isEmpty) {
          return _auditEmptyState(ref, residentId);
        }

        final latest = trail.first;
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFe2e8f0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  _auditMetric('السجلات', '${trail.length}',
                      Icons.history_rounded, const Color(0xFF6366f1)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _auditMetric(
                      'آخر إجراء',
                      _auditActionLabel(latest),
                      Icons.update_rounded,
                      const Color(0xFFea580c),
                    ),
                  ),
                  IconButton(
                    tooltip: 'تحديث',
                    onPressed: () => ref
                        .read(appRiverpod)
                        .loadAuditTrail(residentId, force: true),
                    icon: const Icon(Icons.refresh_rounded,
                        color: Color(0xFF334155)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...trail.take(8).toList().asMap().entries.map((entry) {
                return _buildAuditTrailItem(
                  entry.value,
                  isLatest: entry.key == 0,
                  isLast: entry.key == trail.take(8).length - 1,
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _auditEmptyState(WidgetRef ref, String residentId) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFe2e8f0)),
      ),
      child: Row(
        children: [
          const Icon(Icons.history_toggle_off_rounded,
              color: Color(0xFF94a3b8), size: 22),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'لا توجد تحديثات مسجّلة',
              style: TextStyle(color: Color(0xFF64748b), fontSize: 13),
            ),
          ),
          IconButton(
            tooltip: 'تحديث',
            onPressed: () =>
                ref.read(appRiverpod).loadAuditTrail(residentId, force: true),
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF334155)),
          ),
        ],
      ),
    );
  }

  Widget _auditMetric(
      String label, String value, IconData icon, Color accentColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accentColor.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: accentColor),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFF64748b),
                        fontWeight: FontWeight.w700)),
                Text(value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 12,
                        color: accentColor,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuditTrailItem(Map<String, dynamic> item,
      {required bool isLatest, required bool isLast}) {
    final fields = _changedFieldLabels(item['changedFields'] ??
        item['changed_fields'] ??
        item['changed_fields_json']);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: isLatest ? const Color(0xFFea580c) : Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFea580c), width: 2),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(width: 2, color: const Color(0xFFe2e8f0)),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _auditActionLabel(item),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1e293b)),
                        ),
                      ),
                      if (isLatest)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFF10b981).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text('الأحدث',
                              style: TextStyle(
                                  fontSize: 10,
                                  color: Color(0xFF047857),
                                  fontWeight: FontWeight.bold)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_auditTime(item)} · بواسطة ${_auditActor(item)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF64748b),
                        fontWeight: FontWeight.w600),
                  ),
                  if (fields.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: fields.take(5).map((field) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFf8fafc),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFe2e8f0)),
                          ),
                          child: Text(field,
                              style: const TextStyle(
                                  fontSize: 10,
                                  color: Color(0xFF475569),
                                  fontWeight: FontWeight.w600)),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _auditActionLabel(Map<String, dynamic> item) {
    final raw = (item['action'] ?? item['title'] ?? 'updated').toString();
    return switch (raw) {
      'created' => 'إنشاء ملف المقيم',
      'updated' => 'تحديث بيانات المقيم',
      'medical_info_updated' => 'تحديث المعلومات الطبية',
      _ => raw.replaceAll('_', ' '),
    };
  }

  String _auditActor(Map<String, dynamic> item) {
    return (item['actorName'] ??
            item['actor_name'] ??
            item['staffName'] ??
            item['staff_name'] ??
            item['performedBy'] ??
            'موظف')
        .toString();
  }

  String _auditTime(Map<String, dynamic> item) {
    final raw = (item['at'] ?? item['createdAt'] ?? item['created_at'] ?? '')
        .toString();
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw.isEmpty ? 'بدون وقت' : raw;
    final local = parsed.toLocal();
    String two(int value) => value.toString().padLeft(2, '0');
    return '${local.year}-${two(local.month)}-${two(local.day)} ${two(local.hour)}:${two(local.minute)}';
  }

  List<String> _changedFieldLabels(dynamic value) {
    if (value is Map) {
      return value.keys
          .map((key) => key.toString().replaceAll('_', ' '))
          .where((key) => key.trim().isNotEmpty)
          .toList();
    }
    if (value is List) {
      return value
          .map((item) => item.toString().replaceAll('_', ' '))
          .where((item) => item.trim().isNotEmpty)
          .toList();
    }
    return const [];
  }

  Widget _buildDetailSectionTitle(String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Container(
            width: 4,
            height: 18,
            decoration: BoxDecoration(
                color: const Color(0xFFea580c),
                borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 12),
        Text(title,
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF334155))),
      ],
    );
  }

  Widget _buildStatusBadge(String status) {
    String label = 'محدّث';
    Color color = const Color(0xFF10b981);
    if (status == 'pending') {
      label = 'قيد المراجعة';
      color = const Color(0xFFf59e0b);
    }
    if (status == 'critical') {
      label = 'حالة حرجة';
      color = const Color(0xFFef4444);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }

  String _getCategoryLabel(String cat) {
    switch (cat) {
      case 'social':
        return 'اجتماعي';
      case 'medical':
        return 'طبي';
      case 'psychological':
        return 'نفسي';
      case 'admin':
        return 'إداري';
      default:
        return cat;
    }
  }

  IconData _getCategoryIcon(String cat) {
    switch (cat) {
      case 'social':
        return Icons.people_alt_rounded;
      case 'medical':
        return Icons.medical_services_rounded;
      case 'psychological':
        return Icons.psychology_rounded;
      case 'admin':
        return Icons.admin_panel_settings_rounded;
      default:
        return Icons.folder_rounded;
    }
  }

  Widget _buildStatusIcon(String status) {
    IconData icon = Icons.check_circle_rounded;
    Color color = const Color(0xFF10b981);
    if (status == 'pending') {
      icon = Icons.pending_actions_rounded;
      color = const Color(0xFFf59e0b);
    }
    if (status == 'critical') {
      icon = Icons.report_problem_rounded;
      color = const Color(0xFFef4444);
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
      child: Icon(icon, color: color, size: 20),
    );
  }

  Widget _buildActionLabel(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 14, color: const Color(0xFF94a3b8)),
        const SizedBox(width: 6),
        Text(label,
            style: const TextStyle(
                color: Color(0xFF334155),
                fontSize: 10,
                fontWeight: FontWeight.w600)),
      ],
    );
  }

  void _showPdfPreview(BuildContext context, SpecialistResidentFile file) {
    final psychController = TextEditingController(
      text:
          'يظهر المقيم تحسناً ملحوظاً في التفاعل مع الأنشطة الجماعية. يوصى بزيادة جلسات الدعم النفسي الفردية بمعدل جلسة أسبوعياً.',
    );
    final medicalController = TextEditingController(
      text:
          'متابعة قياس ضغط الدم يومياً. الالتزام بمواعيد الأدوية المحددة في النظام.',
    );

    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height * 0.85,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('مَضْبوط',
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFea580c))),
                  Text('التاريخ: ${DateTime.now().toString().substring(0, 10)}',
                      style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF334155),
                          fontWeight: FontWeight.w600)),
                ],
              ),
              const Divider(height: 30, color: Color(0xFFe2e8f0)),
              const Text('تعديل ومعاينة التقرير الشامل',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0f172a))),
              const SizedBox(height: 20),

              // Resident Info
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFf8fafc),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFe2e8f0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _buildPdfRow('اسم المقيم:', file.name),
                    _buildPdfRow('رقم الغرفة:', file.room),
                    _buildPdfRow('الحالة:',
                        file.status == 'critical' ? 'حرجة' : 'مستقرة'),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Editable Sections
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _buildEditableSection(
                        title: 'الحالة النفسية والاجتماعية',
                        controller: psychController,
                      ),
                      const SizedBox(height: 20),
                      _buildEditableSection(
                        title: 'التوصيات الطبية',
                        controller: medicalController,
                      ),
                      const SizedBox(height: 20),
                      _buildPdfSectionTitle('التحديثات الأخيرة'),
                      const SizedBox(height: 8),
                      const Text(
                        'لا توجد تحديثات مضافة في هذه المعاينة.',
                        textAlign: TextAlign.right,
                        style:
                            TextStyle(fontSize: 12, color: Color(0xFF64748b)),
                      ),
                    ],
                  ),
                ),
              ),

              const Divider(height: 30, color: Color(0xFFe2e8f0)),

              // Footer / Signatures
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    children: [
                      Text('توقيع الطبيب',
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.bold)),
                      SizedBox(height: 30),
                      Text('......................',
                          style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                  Column(
                    children: [
                      Text('توقيع الأخصائي',
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.bold)),
                      SizedBox(height: 30),
                      Text('......................',
                          style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text('إغلاق'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFea580c),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      onPressed: () async {
                        Navigator.pop(context);
                        await _generatePdfWithContent(
                            file, psychController.text, medicalController.text);
                      },
                      child: const Text('حفظ كـ PDF وتنزيل'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEditableSection(
      {required String title, required TextEditingController controller}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _buildPdfSectionTitle(title),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: null,
          textAlign: TextAlign.right,
          style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF0f172a),
              height: 1.5,
              fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFf8fafc),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFe2e8f0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFe2e8f0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFea580c)),
            ),
            contentPadding: const EdgeInsets.all(12),
          ),
        ),
      ],
    );
  }

  Future<void> _generatePdfWithContent(SpecialistResidentFile file,
      String psychContent, String medicalContent) async {
    final pdf = pw.Document();
    final font = await PdfGoogleFonts.amiriRegular();
    final boldFont = await PdfGoogleFonts.amiriBold();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header Bar
                pw.Container(
                  padding: const pw.EdgeInsets.all(16),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.orange700,
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('مَضْبوط - إدارة السجلات',
                          style: pw.TextStyle(
                              font: boldFont,
                              fontSize: 18,
                              color: PdfColors.white)),
                      pw.Text(DateTime.now().toString().substring(0, 10),
                          style: pw.TextStyle(
                              font: font,
                              fontSize: 12,
                              color: PdfColors.white)),
                    ],
                  ),
                ),
                pw.SizedBox(height: 30),

                // Title
                pw.Center(
                  child: pw.Text('تقرير شامل للمقيم',
                      style: pw.TextStyle(
                          font: boldFont,
                          fontSize: 22,
                          color: PdfColors.blueGrey800)),
                ),
                pw.SizedBox(height: 30),

                // Resident Info Card
                pw.Container(
                  padding: const pw.EdgeInsets.all(16),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.orange200, width: 2),
                    borderRadius: pw.BorderRadius.circular(8),
                    color: PdfColors.orange50,
                  ),
                  child: pw.Column(
                    children: [
                      _buildPdfDataRow(
                          font, boldFont, 'اسم المقيم:', file.name),
                      pw.Divider(color: PdfColors.orange200),
                      _buildPdfDataRow(
                          font, boldFont, 'رقم الغرفة:', file.room),
                      pw.Divider(color: PdfColors.orange200),
                      _buildPdfDataRow(font, boldFont, 'الحالة:',
                          file.status == 'critical' ? 'حرجة' : 'مستقرة'),
                    ],
                  ),
                ),
                pw.SizedBox(height: 30),

                // Content Sections
                _buildPdfSection(
                    font, boldFont, 'الحالة النفسية والاجتماعية', psychContent),
                pw.SizedBox(height: 20),

                _buildPdfSection(font, boldFont, 'التوصيات الطبية والملاحظات',
                    medicalContent),
                pw.SizedBox(height: 40),

                // Signatures
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      children: [
                        pw.Text('توقيع الطبيب المختص',
                            style: pw.TextStyle(
                                font: boldFont,
                                fontSize: 14,
                                color: PdfColors.blueGrey800)),
                        pw.SizedBox(height: 40),
                        pw.Text('---------------------------',
                            style:
                                const pw.TextStyle(color: PdfColors.grey500)),
                      ],
                    ),
                    pw.Column(
                      children: [
                        pw.Text('توقيع الأخصائي الاجتماعي',
                            style: pw.TextStyle(
                                font: boldFont,
                                fontSize: 14,
                                color: PdfColors.blueGrey800)),
                        pw.SizedBox(height: 40),
                        pw.Text('---------------------------',
                            style:
                                const pw.TextStyle(color: PdfColors.grey500)),
                      ],
                    ),
                  ],
                ),

                pw.Spacer(),
                // Footer
                pw.Center(
                  child: pw.Text(
                      'تم توليد هذا التقرير آلياً بواسطة تطبيق مضبوط',
                      style: pw.TextStyle(
                          font: font, fontSize: 10, color: PdfColors.grey600)),
                ),
              ],
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save());
  }

  pw.Widget _buildPdfDataRow(
      pw.Font font, pw.Font boldFont, String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label,
              style: pw.TextStyle(
                  font: boldFont, fontSize: 14, color: PdfColors.blueGrey700)),
          pw.Text(value,
              style: pw.TextStyle(
                  font: font, fontSize: 14, color: PdfColors.black)),
        ],
      ),
    );
  }

  pw.Widget _buildPdfSection(
      pw.Font font, pw.Font boldFont, String title, String content) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: const pw.BoxDecoration(
            border: pw.Border(
                right: pw.BorderSide(color: PdfColors.orange700, width: 4)),
          ),
          child: pw.Text(title,
              style: pw.TextStyle(
                  font: boldFont, fontSize: 16, color: PdfColors.orange700)),
        ),
        pw.SizedBox(height: 10),
        pw.Container(
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            color: PdfColors.grey50,
            borderRadius: pw.BorderRadius.circular(4),
          ),
          child: pw.Text(content,
              style: pw.TextStyle(
                  font: font, fontSize: 12, color: PdfColors.blueGrey800),
              textAlign: pw.TextAlign.justify),
        ),
      ],
    );
  }

  Widget _buildPdfRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF334155),
                  fontWeight: FontWeight.w600)),
          const SizedBox(width: 8),
          Text(value,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0f172a))),
        ],
      ),
    );
  }

  Widget _buildPdfSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Container(width: 4, height: 14, color: const Color(0xFFea580c)),
          const SizedBox(width: 8),
          Text(title,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFea580c))),
        ],
      ),
    );
  }
}

class _FilesCardDustParticle {
  Offset position;
  double speed;
  double radius;
  _FilesCardDustParticle(
      {required this.position, required this.speed, required this.radius});
}

class FilesCardDustAnimation extends StatefulWidget {
  const FilesCardDustAnimation({super.key});

  @override
  State<FilesCardDustAnimation> createState() => _FilesCardDustAnimationState();
}

class _FilesCardDustAnimationState extends State<FilesCardDustAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<_FilesCardDustParticle> _dust;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 15))
          ..repeat();

    final random = Random();
    _dust = List.generate(100, (index) {
      // استخدام 100 جزيء كما طلب المستخدم
      return _FilesCardDustParticle(
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
            painter: _FilesCardDustPainter(
                dust: _dust, animationValue: _controller.value),
          );
        },
      ),
    );
  }
}

class _FilesCardDustPainter extends CustomPainter {
  final List<_FilesCardDustParticle> dust;
  final double animationValue;

  _FilesCardDustPainter({required this.dust, required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFea580c).withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;

    for (var i = 0; i < dust.length; i++) {
      final p = dust[i];

      double dy = (p.position.dy + (animationValue * p.speed * 20)) % 1.0;
      dy *= size.height;

      double dx =
          p.position.dx * size.width + sin(animationValue * 2 * pi + i) * 5;

      final currentPos = Offset(dx, dy);

      double opacity = (sin(animationValue * 2 * pi * 2 + i) + 1) / 2;
      paint.color = const Color(0xFFea580c).withValues(alpha: opacity * 0.4);

      canvas.drawCircle(currentPos, p.radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _FilesCardDustPainter oldDelegate) {
    return true;
  }
}
