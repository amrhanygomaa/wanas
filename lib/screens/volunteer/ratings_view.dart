import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/app_riverpod.dart';
import '../../models/app_models.dart';
import 'widgets/volunteer_background.dart';

class VolunteerRatingsView extends ConsumerStatefulWidget {
  final List<Animation<double>> fadeAnimations;
  final AnimationController floatController;
  final AnimationController shimmerController;
  final AnimationController popController;

  const VolunteerRatingsView({
    super.key,
    required this.fadeAnimations,
    required this.floatController,
    required this.shimmerController,
    required this.popController,
  });

  @override
  ConsumerState<VolunteerRatingsView> createState() =>
      _VolunteerRatingsViewState();
}

class _VolunteerRatingsViewState extends ConsumerState<VolunteerRatingsView> {
  int _activeTabIndex = 0; // 0: Rate, 1: My Ratings, 2: Summary
  final Map<String, int> _pendingRatings = {}; // review.id -> main score
  final Map<String, Map<String, int>> _pendingCriteria =
      {}; // review.id -> {label -> score}

  @override
  Widget build(BuildContext context) {
    final provider = ref.watch(appRiverpod);

    return VolunteerAnimatedBackground(
      child: Column(
        children: [
          _buildTabSelector(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_activeTabIndex == 0) ..._buildRateSection(provider),
                if (_activeTabIndex == 1) ..._buildMyRatingsSection(provider),
                if (_activeTabIndex == 2) ..._buildPerformanceSummary(provider),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSummary(AppRiverpod provider) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF064e3b), Color(0xFF059669), Color(0xFF10b981)],
        ),
      ),
      child: Column(
        children: [
          ScaleTransition(
            scale: widget.popController,
            child: Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Text('${provider.averageRating}',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold)),
                            const SizedBox(width: 4),
                            const Text('/ ٥',
                                style: TextStyle(
                                    color: Colors.white60, fontSize: 12)),
                          ],
                        ),
                        _buildFloatingStars(provider.averageRating),
                        const SizedBox(height: 4),
                        Text(
                            'من ${provider.totalReviews} تقييم من المقيمين والإدارة',
                            style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.75),
                                fontSize: 10)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  _buildCircularScore(provider.averageRating),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCircularScore(double score) {
    return SizedBox(
      width: 64,
      height: 64,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: score / 5,
            strokeWidth: 5,
            backgroundColor: Colors.white.withValues(alpha: 0.2),
            color: Colors.white,
          ),
          Text('${(score / 5 * 100).toInt()}%',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildFloatingStars(double score) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: List.generate(5, (index) {
        final isLast = index == score.floor();
        return Padding(
          padding: const EdgeInsets.only(right: 3),
          child: AnimatedBuilder(
            animation: widget.floatController,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0,
                    isLast ? sin(widget.floatController.value * 6.28) * 3 : 0),
                child: child,
              );
            },
            child: Text('⭐',
                style: TextStyle(fontSize: index < score.floor() ? 18 : 14)),
          ),
        );
      }),
    );
  }

  Widget _buildTabSelector() {
    final tabs = ['أقيّم (١)', 'تقييماتي (١٢)', 'ملخص أدائي'];
    return Container(
      height: 45,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFd1fae5))),
      ),
      child: Row(
        children: List.generate(tabs.length, (index) {
          final isAct = _activeTabIndex == index;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _activeTabIndex = index),
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  border: Border(
                      bottom: BorderSide(
                          color: isAct
                              ? const Color(0xFF10b981)
                              : Colors.transparent,
                          width: 2.5)),
                ),
                child: Text(tabs[index],
                    style: TextStyle(
                        color: isAct
                            ? const Color(0xFF059669)
                            : const Color(0xFF94a3b8),
                        fontSize: 11,
                        fontWeight: FontWeight.bold)),
              ),
            ),
          );
        }),
      ),
    );
  }

  List<Widget> _buildRateSection(AppRiverpod provider) {
    final pending =
        provider.volunteerReviews.where((r) => r.isPending).toList();
    return [
      _buildSectionLabel('تقييمات بانتظار الإرسال', const Color(0xFF10b981), 0),
      const SizedBox(height: 12),
      ...pending.map((r) => _buildInteractiveRatingCard(r)),
      const SizedBox(height: 24),
      _buildSectionLabel('تاريخ تقييماتي للمقيمين', const Color(0xFF10b981), 1),
      const SizedBox(height: 12),
      _buildRatingsHistory(
          provider.volunteerReviews.where((r) => !r.isPending).toList()),
    ];
  }

  Widget _buildInteractiveRatingCard(VolunteerReview review) {
    final currentScore = _pendingRatings[review.id] ?? 4;
    final criteria = _pendingCriteria[review.id] ??
        {
          'مستوى التفاعل': 5,
          'مزاج المقيم': 4,
          'النشاط البدني': 3,
        };

    return AnimatedBuilder(
      animation: widget.floatController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, sin(widget.floatController.value * 6.28) * 3),
          child: child,
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
              colors: [Color(0xFF059669), Color(0xFF10b981)]),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: const Color(0xFF10b981).withValues(alpha: 0.3),
                blurRadius: 10,
                spreadRadius: 1)
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      shape: BoxShape.circle),
                  child: Center(
                      child: Text(review.icon,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold))),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('قيّم الجلسة مع',
                          textAlign: TextAlign.right,
                          style:
                              TextStyle(color: Colors.white70, fontSize: 10)),
                      Text(review.toName,
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.bold)),
                      Text('${review.session} · ${review.date}',
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 10)),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8)),
                    child: const Text('⏰ منذ يوم',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text('التقييم العام للجلسة',
                style: TextStyle(color: Colors.white, fontSize: 11)),
            const SizedBox(height: 8),
            _buildInteractiveStars(currentScore, onChanged: (val) {
              setState(() {
                _pendingRatings[review.id] = val;
              });
            }),
            const SizedBox(height: 20),
            ...criteria.keys.map((label) => _buildCriteriaRatingRow(
                    label, criteria[label] ?? 0, onChanged: (val) {
                  setState(() {
                    if (_pendingCriteria[review.id] == null) {
                      _pendingCriteria[review.id] = Map.from(criteria);
                    }
                    _pendingCriteria[review.id]![label] = val;
                  });
                })),
            const SizedBox(height: 16),
            TextField(
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'أضف ملاحظة للأخصائي الاجتماعي...',
                hintStyle: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5), fontSize: 11),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.15),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.all(12),
              ),
              style: const TextStyle(color: Colors.white, fontSize: 11),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('تم إرسال تقييمك لـ ${review.toName} بنجاح! ⭐'),
                  backgroundColor: const Color(0xFF059669),
                ));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF059669),
                minimumSize: const Size(double.infinity, 45),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline, size: 16),
                  SizedBox(width: 8),
                  Text('إرسال التقييم',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInteractiveStars(int score, {required Function(int) onChanged}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        return GestureDetector(
          onTap: () => onChanged(index + 1),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(index < score ? '★' : '☆',
                style: TextStyle(
                    color: index < score
                        ? const Color(0xFFfbbf24)
                        : Colors.white24,
                    fontSize: 32)),
          ),
        );
      }),
    );
  }

  Widget _buildCriteriaRatingRow(String label, int score,
      {required Function(int) onChanged}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(label,
              style: const TextStyle(color: Colors.white, fontSize: 11)),
          const Spacer(),
          Row(
            children: List.generate(5, (index) {
              return GestureDetector(
                onTap: () => onChanged(index + 1),
                child: Text(index < score ? '★' : '☆',
                    style: TextStyle(
                        color: index < score
                            ? const Color(0xFFfbbf24)
                            : Colors.white24,
                        fontSize: 14)),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingsHistory(List<VolunteerReview> history) {
    return Container(
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFd1fae5))),
      child: Column(
        children: history.map((r) => _buildHistoryRow(r)).toList(),
      ),
    );
  }

  Widget _buildHistoryRow(VolunteerReview r) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFFf0fdf4)))),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
                color: Color(0xFFf0fdf4), shape: BoxShape.circle),
            child: Center(
                child: Text(r.icon,
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF059669)))),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(r.toName,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.bold)),
                Text('${r.session} · ${r.date}',
                    textAlign: TextAlign.right,
                    style:
                        const TextStyle(color: Color(0xFF94a3b8), fontSize: 9)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            flex: 2,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(
                  5,
                  (index) => Text(index < r.score ? '★' : '☆',
                      style: TextStyle(
                          color: index < r.score
                              ? const Color(0xFFfbbf24)
                              : const Color(0xFFe5e7eb),
                          fontSize: 12))),
            ),
          ),
          const Spacer(),
          const Flexible(
            child: Text('تم ✓',
                style: TextStyle(
                    color: Color(0xFF10b981),
                    fontSize: 10,
                    fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildMyRatingsSection(AppRiverpod provider) {
    return [
      _buildSectionLabel(
          'تفصيل تقييمات المقيمين لي', const Color(0xFFfbbf24), 0),
      const SizedBox(height: 12),
      _buildDetailedBreakdown(provider),
      const SizedBox(height: 24),
      _buildSectionLabel(
          'آخر ما قاله عنك المقيمون', const Color(0xFF10b981), 1),
      const SizedBox(height: 12),
      ...provider.volunteerRatings.map((r) => _buildReviewCard(r)),
    ];
  }

  Widget _buildDetailedBreakdown(AppRiverpod provider) {
    final criteria = [
      {
        'label': 'التعامل والاحترام',
        'score': 5.0,
        'color': const Color(0xFF10b981)
      },
      {
        'label': 'الالتزام بالمواعيد',
        'score': 5.0,
        'color': const Color(0xFF10b981)
      },
      {'label': 'جودة التحضير', 'score': 4.0, 'color': const Color(0xFF10b981)},
      {
        'label': 'الإبداع في الجلسة',
        'score': 4.7,
        'color': const Color(0xFF10b981)
      },
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFa7f3d0), width: 1.5)),
      child: Column(
        children: criteria
            .map((c) => _buildBreakdownRow(c['label'] as String,
                c['score'] as double, c['color'] as Color))
            .toList(),
      ),
    );
  }

  Widget _buildBreakdownRow(String label, double score, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Flexible(
            flex: 3,
            child: Text(label,
                textAlign: TextAlign.right,
                style: const TextStyle(color: Color(0xFF374151), fontSize: 11)),
          ),
          const SizedBox(width: 12),
          Flexible(
            flex: 2,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(
                  5,
                  (index) => Text(index < score.floor() ? '★' : '☆',
                      style: TextStyle(
                          color: index < score.floor()
                              ? const Color(0xFFfbbf24)
                              : const Color(0xFFe5e7eb),
                          fontSize: 12))),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: Container(
              height: 6,
              decoration: BoxDecoration(
                  color: const Color(0xFFf0fdf4),
                  borderRadius: BorderRadius.circular(4)),
              alignment: Alignment.centerRight,
              child: FractionallySizedBox(
                  widthFactor: score / 5,
                  child: Container(
                      decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(4)))),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text('$score',
                style: TextStyle(
                    color: color, fontSize: 11, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard(VolunteerRating rating) {
    return GestureDetector(
      onTap: () => _showReviewDetails(context, rating),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFd1fae5))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                        color: Color(0xFFf0fdf4), shape: BoxShape.circle),
                    child: Center(
                        child: Text(rating.icon,
                            style: const TextStyle(fontSize: 20)))),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(rating.fromName,
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.bold)),
                    Text(rating.date,
                        style: const TextStyle(
                            color: Color(0xFF64748b), fontSize: 11, fontWeight: FontWeight.w500)),
                  ],
                ),
                const Spacer(),
                Row(
                  children: List.generate(
                      5,
                      (index) => Text(index < rating.score.floor() ? '★' : '☆',
                          style: TextStyle(
                              color: index < rating.score.floor()
                                  ? const Color(0xFFfbbf24)
                                  : const Color(0xFFe5e7eb),
                              fontSize: 14))),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: const Color(0xFFf0fdf4),
                  borderRadius: BorderRadius.circular(12)),
              child: Text(rating.comment,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                      color: Color(0xFF334155), fontSize: 12, fontWeight: FontWeight.w500, height: 1.6)),
            ),
            if (rating.chips.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                alignment: WrapAlignment.end,
                children: rating.chips
                    .map((chip) => Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                              color: const Color(0xFFd1fae5),
                              borderRadius: BorderRadius.circular(8)),
                          child: Text(chip,
                              style: const TextStyle(
                                  color: Color(0xFF065f46),
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold)),
                        ))
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  List<Widget> _buildPerformanceSummary(AppRiverpod provider) {
    return [
      _buildSectionLabel('خلاصة الأداء العام', const Color(0xFF065f46), 0),
      const SizedBox(height: 12),
      _buildStatsCard(provider),
    ];
  }

  Widget _buildStatsCard(AppRiverpod provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFd1fae5), width: 1.5)),
      child: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                _buildStatTextRow(
                    'إجمالي التقييمات', '${provider.totalReviews} تقييم'),
                _buildStatTextRow('أعلى نقطة', provider.topSkill,
                    isShimmer: true),
                _buildStatTextRow('يحتاج تحسين', provider.skillNeedsImprovement,
                    valColor: const Color(0xFF10b981)),
                _buildStatTextRow('معلّقة للإرسال', '١ تقييم',
                    valColor: Colors.red),
              ],
            ),
          ),
          const SizedBox(width: 20),
          _buildPerformanceRing(),
        ],
      ),
    );
  }

  Widget _buildPerformanceRing() {
    return const SizedBox(
      width: 65,
      height: 65,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
              value: 0.85,
              strokeWidth: 6,
              backgroundColor: Color(0xFFd1fae5),
              color: Color(0xFF10b981)),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('٨٥٪',
                  style: TextStyle(
                      color: Color(0xFF065f46),
                      fontSize: 14,
                      fontWeight: FontWeight.bold)),
              Text('أداء',
                  style: TextStyle(color: Color(0xFF64748b), fontSize: 8)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatTextRow(String lbl, String val,
      {bool isShimmer = false, Color? valColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(lbl,
                textAlign: TextAlign.right,
                style: const TextStyle(color: Color(0xFF64748b), fontSize: 10)),
          ),
          const SizedBox(width: 12),
          if (isShimmer)
            Flexible(
              child: AnimatedBuilder(
                animation: widget.shimmerController,
                builder: (context, child) => ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(colors: [
                    Color(0xFFd97706),
                    Color(0xFFfbbf24),
                    Color(0xFFd97706)
                  ], stops: [
                    0.0,
                    0.5,
                    1.0
                  ]).createShader(bounds),
                  child: Text(val,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold)),
                ),
              ),
            )
          else
            Flexible(
              child: Text(val,
                  style: TextStyle(
                      color: valColor ?? const Color(0xFF0f172a),
                      fontSize: 11,
                      fontWeight: FontWeight.bold)),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label, Color color, int index) {
    return FadeTransition(
      opacity:
          widget.fadeAnimations[min(index, widget.fadeAnimations.length - 1)],
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Text(label,
              style: TextStyle(
                  color: color, fontSize: 13, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  void _showRatingSubmission(BuildContext context, VolunteerReview review) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2))),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                        color: const Color(0xFFd1fae5),
                        borderRadius: BorderRadius.circular(12)),
                    child:
                        Text(review.icon, style: const TextStyle(fontSize: 24)),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('تقييم التجربة',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF064e3b))),
                      Text(review.toName,
                          style: const TextStyle(
                              fontSize: 12, color: Color(0xFF10b981))),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('كيف كانت تجربتك مع المقيم؟',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1e293b))),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                          5, (index) => _buildRatingStar(index < 4)),
                    ),
                    const SizedBox(height: 32),
                    const Text('أضف تعليقاً (اختياري)',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1e293b))),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                          color: const Color(0xFFf8fafc),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFe2e8f0))),
                      child: const TextField(
                        maxLines: 4,
                        textAlign: TextAlign.right,
                        decoration: InputDecoration(
                            hintText: 'اكتب رأيك هنا...',
                            hintStyle: TextStyle(fontSize: 12),
                            border: InputBorder.none),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text('السمات الإيجابية',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1e293b))),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.end,
                      children: [
                        _buildDetailChip('متعاون'),
                        _buildDetailChip('شرح وافٍ'),
                        _buildDetailChip('لطيف'),
                        _buildDetailChip('منظم'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content:
                        Text('تم إرسال تقييمك لـ ${review.toName} بنجاح! ⭐'),
                    backgroundColor: const Color(0xFF059669),
                  ));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF059669),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 54),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: const Text('إرسال التقييم',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showReviewDetails(BuildContext context, VolunteerRating rating) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2))),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                        color: Color(0xFFf0fdf4), shape: BoxShape.circle),
                    child: Center(
                        child: Text(rating.icon,
                            style: const TextStyle(fontSize: 24))),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(rating.fromName,
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1e293b))),
                      Text(rating.date,
                          style: const TextStyle(
                              fontSize: 12, color: Color(0xFF94a3b8))),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: List.generate(
                          5,
                          (index) => Icon(
                              index < rating.score.floor()
                                  ? Icons.star_rounded
                                  : Icons.star_outline_rounded,
                              color: const Color(0xFFfbbf24),
                              size: 24)),
                    ),
                    const SizedBox(height: 24),
                    const Text('رأي المقيم',
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1e293b))),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      width: double.infinity,
                      decoration: BoxDecoration(
                          color: const Color(0xFFf0fdf4),
                          borderRadius: BorderRadius.circular(16)),
                      child: Text(rating.comment,
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF334155),
                              height: 1.6)),
                    ),
                    const SizedBox(height: 24),
                    const Text('المهارات الملحوظة',
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1e293b))),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.end,
                      children: rating.chips
                          .map((chip) => _buildDetailChip(chip))
                          .toList(),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  side: const BorderSide(color: Color(0xFFe2e8f0)),
                ),
                child: const Text('إغلاق',
                    style: TextStyle(
                        color: Color(0xFF64748b), fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingStar(bool filled) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Icon(filled ? Icons.star_rounded : Icons.star_outline_rounded,
          color: const Color(0xFFfbbf24), size: 40),
    );
  }

  Widget _buildDetailChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
          color: const Color(0xFFd1fae5),
          borderRadius: BorderRadius.circular(10)),
      child: Text(label,
          style: const TextStyle(
              color: Color(0xFF065f46),
              fontSize: 11,
              fontWeight: FontWeight.bold)),
    );
  }
}
