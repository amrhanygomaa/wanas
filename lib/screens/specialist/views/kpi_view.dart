import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/app_riverpod.dart';
import '../../../models/app_models.dart';

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
        SliverPadding(
          padding: const EdgeInsets.all(14),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _buildSectionLabel('مؤشرات الأداء الاجتماعي', const Color(0xFF10b981), 0),
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
                return _buildKPICard(context, kpi, index);
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
          Container(width: 7, height: 7, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(color: Color(0xFF9a3412), fontSize: 11, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildKPICard(BuildContext context, SocialSpecialistKPI kpi, int index) {
    return FadeTransition(
      opacity: fadeAnimations[min(index + 1, 11)],
      child: ScaleTransition(
        scale: popController,
        child: GestureDetector(
          onTap: () => _showKPIDetails(context, kpi),
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
                    color: kpi.isPositive ? const Color(0xFFd1fae5) : const Color(0xFFfee2e2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    kpi.isPositive ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                    size: 16,
                    color: kpi.isPositive ? const Color(0xFF059669) : const Color(0xFFdc2626),
                  ),
                ),
                const SizedBox(height: 12),
                Text(kpi.value,
                    style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: kpi.isPositive ? const Color(0xFF059669) : const Color(0xFFdc2626))),
                const SizedBox(height: 4),
                Text(kpi.label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1e293b))),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: kpi.isPositive
                        ? const Color(0xFFd1fae5).withValues(alpha: 0.5)
                        : const Color(0xFFfee2e2).withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(kpi.trend,
                      style: TextStyle(
                          color: kpi.isPositive ? const Color(0xFF065f46) : const Color(0xFF7f1d1d),
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

  void _showKPIDetails(BuildContext context, SocialSpecialistKPI kpi) {
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
                  color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
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
                            Text('تحليل الأداء للفترة الحالية',
                                style: const TextStyle(fontSize: 12, color: Color(0xFF334155), fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    _buildDetailMetricRow('القيمة الحالية', kpi.value,
                        kpi.isPositive ? const Color(0xFF059669) : const Color(0xFFdc2626)),
                    const Divider(height: 32),
                    _buildDetailMetricRow('معدل التغير', kpi.trend,
                        kpi.isPositive ? const Color(0xFF059669) : const Color(0xFFdc2626)),
                    const SizedBox(height: 32),
                    const Text('مخطط النمو الزمني',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1e293b))),
                    const SizedBox(height: 16),
                    _buildMockChart(),
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
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
        Text(label, style: const TextStyle(fontSize: 14, color: Color(0xFF334155), fontWeight: FontWeight.w600)),
        Text(value,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: color)),
      ],
    );
  }

  Widget _buildMockChart() {
    final days = ['السبت', 'الأحد', 'الإثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة'];
    final values = [45, 60, 55, 75, 80, 70, 90];

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
            7,
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
                      height: values[i].toDouble(),
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
                    Text(days[i],
                        style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF64748b))),
                  ],
                )),
      ),
    );
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
