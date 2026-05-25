import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/app_riverpod.dart';
import '../../../models/app_models.dart';
import '../../../widgets/live_kpi_banner.dart';

class SpecialistKPIView extends ConsumerWidget {
  final List<Animation<double>> fadeAnimations;
  final AnimationController floatController;
  final AnimationController shimmerController;
  final AnimationController popController;
  final void Function(int) onNavigate;

  const SpecialistKPIView({
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

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        const SliverToBoxAdapter(child: LiveKpiBanner()),
        SliverPadding(
          padding: const EdgeInsets.all(14),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _buildSectionLabel(
                  'مؤشرات الأداء الاجتماعي', const Color(0xFF10b981), 0),
              const SizedBox(height: 12),
            ]),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 0.95,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final kpi = provider.socialKPIs[index];
                return _buildKPICard(context, provider, kpi, index);
              },
              childCount: provider.socialKPIs.length,
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 40)),
      ],
    );
  }

  Widget _buildSectionLabel(String label, Color color, int index) {
    return FadeTransition(
      opacity: fadeAnimations[min(index, 11)],
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Text(label,
              style: const TextStyle(
                  color: Color(0xFF9a3412),
                  fontSize: 11,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildKPICard(BuildContext context, AppRiverpod provider,
      SocialSpecialistKPI kpi, int index) {
    return FadeTransition(
      opacity: fadeAnimations[min(index + 1, 11)],
      child: ScaleTransition(
        scale: popController,
        child: GestureDetector(
          onTap: () => _showKPIDetails(context, provider, kpi),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFfed7aa), width: 1.5),
              boxShadow: [
                BoxShadow(
                    color: const Color(0xFFea580c).withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4))
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: kpi.isPositive
                        ? const Color(0xFFd1fae5)
                        : const Color(0xFFfee2e2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    kpi.isPositive
                        ? Icons.trending_up_rounded
                        : Icons.trending_down_rounded,
                    size: 16,
                    color: kpi.isPositive
                        ? const Color(0xFF059669)
                        : const Color(0xFFdc2626),
                  ),
                ),
                const SizedBox(height: 12),
                Text(kpi.value,
                    style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: kpi.isPositive
                            ? const Color(0xFF059669)
                            : const Color(0xFFdc2626))),
                const SizedBox(height: 4),
                Text(kpi.label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1e293b))),
                const SizedBox(height: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: kpi.isPositive
                        ? const Color(0xFFd1fae5).withValues(alpha: 0.5)
                        : const Color(0xFFfee2e2).withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(kpi.trend,
                      style: TextStyle(
                          color: kpi.isPositive
                              ? const Color(0xFF065f46)
                              : const Color(0xFF7f1d1d),
                          fontSize: 9,
                          fontWeight: FontWeight.w900)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showKPIDetails(
      BuildContext context, AppRiverpod provider, SocialSpecialistKPI kpi) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
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
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFfff7ed),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: const Icon(Icons.analytics_outlined,
                              color: Color(0xFFea580c), size: 30),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(kpi.label,
                                style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF1e293b))),
                            const Text('تحليل الأداء للفترة الحالية',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF334155),
                                    fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    _buildDetailMetricRow(
                        'القيمة الحالية',
                        kpi.value,
                        kpi.isPositive
                            ? const Color(0xFF059669)
                            : const Color(0xFFdc2626)),
                    const Divider(height: 32),
                    _buildDetailMetricRow(
                        'معدل التغير',
                        kpi.trend,
                        kpi.isPositive
                            ? const Color(0xFF059669)
                            : const Color(0xFFdc2626)),
                    const SizedBox(height: 32),
                    const Text('مخطط النمو الزمني',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1e293b))),
                    const SizedBox(height: 16),
                    _buildChart(provider, kpi),
                    const SizedBox(height: 32),
                    const Text('توصيات الأداء',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1e293b))),
                    const SizedBox(height: 12),
                    _buildRecommendationCard(
                        'استمر في متابعة المقيمين بشكل دوري لضمان استقرار هذا المؤشر.',
                        Icons.lightbulb_outline_rounded),
                    const SizedBox(height: 40),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFea580c),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15)),
                        ),
                        child: const Text('فهمت',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailMetricRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF334155),
                fontWeight: FontWeight.w600)),
        Text(value,
            style: TextStyle(
                fontSize: 22, fontWeight: FontWeight.w900, color: color)),
      ],
    );
  }

  Widget _buildChart(AppRiverpod provider, SocialSpecialistKPI kpi) {
    final values = _liveChartValues(provider, kpi);
    final labels = List.generate(values.length, (i) => '${i + 1}');

    return Container(
      height: 160,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFf1f5f9)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(
            values.length,
            (i) => Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text('${values[i]}%',
                        style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0f172a))),
                    const SizedBox(height: 4),
                    Container(
                      width: 14,
                      height: 20 + (values[i].toDouble().clamp(0, 100) * 0.9),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [Color(0xFFea580c), Color(0xFFfb923c)],
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(labels[i],
                        style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF64748b))),
                  ],
                )),
      ),
    );
  }

  List<int> _liveChartValues(AppRiverpod provider, SocialSpecialistKPI kpi) {
    List<int> values;
    if (kpi.id == 'k1') {
      values = provider.socialResidentScores
          .map((resident) {
            if (resident.scores.isEmpty) return 0;
            final sum = resident.scores.values
                .fold<double>(0, (total, score) => total + score);
            return ((sum / resident.scores.length) * 100).round();
          })
          .where((value) => value > 0)
          .toList();
    } else if (kpi.id == 'k2') {
      var done = 0;
      values = provider.activities.asMap().entries.map((entry) {
        if (entry.value.status == 'done') done++;
        return ((done / (entry.key + 1)) * 100).round();
      }).toList();
    } else if (kpi.id == 'k3') {
      values = provider.socialResidentScores
          .map((resident) => resident.healthStatus == 'critical' ? 100 : 20)
          .toList();
    } else {
      values = provider.socialComplaints
          .map((complaint) => complaint.status == 'open' ? 100 : 30)
          .toList();
    }

    if (values.isEmpty) {
      final parsed = int.tryParse(kpi.value.replaceAll(RegExp(r'[^0-9]'), ''));
      values = [parsed ?? 0];
    }
    if (values.length > 7) {
      values = values.sublist(values.length - 7);
    }
    return values.map((value) => value.clamp(0, 100)).toList();
  }

  Widget _buildRecommendationCard(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFfff7ed),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFffedd5)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(text,
                textAlign: TextAlign.right,
                style: const TextStyle(fontSize: 12, color: Color(0xFF9a3412))),
          ),
          const SizedBox(width: 12),
          Icon(icon, color: const Color(0xFFea580c), size: 20),
        ],
      ),
    );
  }
}
