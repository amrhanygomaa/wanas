import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/app_riverpod.dart';
import '../../../models/app_models.dart';

/// صفحة توصيات وتحذيرات الذكاء الاصطناعي للمدير
class AIWarningsView extends ConsumerStatefulWidget {
  const AIWarningsView({super.key});

  @override
  ConsumerState<AIWarningsView> createState() => _AIWarningsViewState();
}

class _AIWarningsViewState extends ConsumerState<AIWarningsView> {
  String _selectedFilter = 'الكل';

  static const _filters = ['الكل', 'حرجة', 'تحذير', 'توصية', 'تم الحل'];

  @override
  Widget build(BuildContext context) {
    final provider = ref.watch(appRiverpod);
    final insights = _applyFilter(provider.aiInsights);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1e293b),
        foregroundColor: Colors.white,
        title: const Text(
          'توصيات وتحذيرات الذكاء الاصطناعي',
          style: TextStyle(
              fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 16),
        ),
        centerTitle: true,
        elevation: 0,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(20))),
      ),
      body: Column(
        children: [
          _buildFilterBar(),
          Expanded(
            child: insights.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: insights.length,
                    itemBuilder: (_, i) =>
                        _buildInsightCard(insights[i], provider),
                  ),
          ),
        ],
      ),
    );
  }

  // ── شريط الفلاتر ─────────────────────────────────────────────────
  Widget _buildFilterBar() {
    return Container(
      height: 48,
      color: Colors.white,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: _filters.length,
        itemBuilder: (_, i) {
          final f = _filters[i];
          final isSelected = _selectedFilter == f;
          return GestureDetector(
            onTap: () => setState(() => _selectedFilter = f),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(left: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF1e293b)
                    : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                f,
                style: TextStyle(
                  color: isSelected ? Colors.white : const Color(0xFF64748b),
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 13,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ── بطاقة التوصية / التحذير ───────────────────────────────────────
  Widget _buildInsightCard(AIInsight insight, AppRiverpod provider) {
    final isCritical = insight.type == 'predictive_alert';
    final isResolved = insight.type == 'resolved';
    final color = isResolved
        ? const Color(0xFF059669)
        : isCritical
            ? const Color(0xFFDC2626)
            : const Color(0xFF6366F1);

    final label = isResolved
        ? 'تم الحل'
        : isCritical
            ? 'تحذير حرج'
            : 'توصية';

    final safeSummary = stripUuids(insight.summary);
    final safeRationale = stripUuids(insight.rationale);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.25), width: 1.5),
        boxShadow: [
          BoxShadow(
              color: color.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 3)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // رأس البطاقة
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(label,
                      style: TextStyle(
                          color: color,
                          fontSize: 11,
                          fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(insight.residentLabel,
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1e293b))),
                ),
                Text(
                  _formatDate(insight.generationDate),
                  style:
                      const TextStyle(fontSize: 11, color: Color(0xFF94a3b8)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(safeSummary,
                style: const TextStyle(
                    fontSize: 14, color: Color(0xFF374151), height: 1.5)),
            if (safeRationale.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(safeRationale,
                  style: const TextStyle(
                      fontSize: 12, color: Color(0xFF64748b), height: 1.4)),
            ],
            const SizedBox(height: 12),
            // زر تحديد كـ "تم الحل"
            if (!isResolved)
              SizedBox(
                width: double.infinity,
                height: 38,
                child: OutlinedButton.icon(
                  onPressed: () => _markResolved(insight, provider),
                  icon: Icon(Icons.check_circle_outline_rounded,
                      size: 16, color: color),
                  label: Text('تحديد كـ: تم الحل',
                      style: TextStyle(
                          fontSize: 13,
                          color: color,
                          fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: color.withValues(alpha: 0.4)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── حالة فارغة ────────────────────────────────────────────────────
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.auto_awesome_rounded,
                  color: Color(0xFF6366F1), size: 36),
            ),
            const SizedBox(height: 20),
            const Text(
              'لا توجد توصيات أو تحذيرات حالياً',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF64748b)),
            ),
            const SizedBox(height: 8),
            const Text(
              'سيعرض الذكاء الاصطناعي توصياته هنا بناءً على بيانات المقيمين',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Color(0xFF94a3b8)),
            ),
          ],
        ),
      ),
    );
  }

  // ── فلترة ──────────────────────────────────────────────────────────
  List<AIInsight> _applyFilter(List<AIInsight> all) {
    switch (_selectedFilter) {
      case 'حرجة':
        return all.where((i) => i.type == 'predictive_alert').toList();
      case 'تحذير':
        return all.where((i) => i.type == 'warning').toList();
      case 'توصية':
        return all.where((i) => i.type == 'recommendation').toList();
      case 'تم الحل':
        return all.where((i) => i.type == 'resolved').toList();
      default:
        return all;
    }
  }

  void _markResolved(AIInsight insight, AppRiverpod provider) {
    final idx = provider.aiInsights.indexWhere((i) => i.id == insight.id);
    if (idx == -1) return;
    provider.aiInsights[idx] = AIInsight(
      id: insight.id,
      residentName: insight.residentName,
      summary: insight.summary,
      rationale: insight.rationale,
      generationDate: insight.generationDate,
      confidenceScore: insight.confidenceScore,
      type: 'resolved',
    );
    provider.refreshState();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('تم تحديده كـ: تم الحل',
          textAlign: TextAlign.center, style: TextStyle(fontFamily: 'Cairo')),
      backgroundColor: Color(0xFF059669),
      behavior: SnackBarBehavior.floating,
    ));
  }

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
