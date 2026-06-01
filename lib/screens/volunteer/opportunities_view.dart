import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/app_riverpod.dart';
import '../../models/app_models.dart';
import 'widgets/volunteer_background.dart';

class VolunteerOpportunitiesView extends ConsumerStatefulWidget {
  final List<Animation<double>> fadeAnimations;
  final AnimationController floatController;
  final AnimationController shimmerController;

  const VolunteerOpportunitiesView({
    super.key,
    required this.fadeAnimations,
    required this.floatController,
    required this.shimmerController,
  });

  @override
  ConsumerState<VolunteerOpportunitiesView> createState() =>
      _VolunteerOpportunitiesViewState();
}

class _VolunteerOpportunitiesViewState
    extends ConsumerState<VolunteerOpportunitiesView> {
  String _selectedSkill = 'الكل (٨)';
  String _selectedSort = 'مطابقة';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<VolunteerOpportunity> _getFilteredOpportunities(
      List<VolunteerOpportunity> all) {
    List<VolunteerOpportunity> filtered = all.where((o) {
      final matchesSearch = o.title.contains(_searchQuery) ||
          o.org.contains(_searchQuery) ||
          o.tags.any((t) => t.contains(_searchQuery));

      if (_selectedSkill == 'الكل (٨)') return matchesSearch;

      final skillName =
          _selectedSkill.split(' ')[1]; // Extract name from "📚 Name (Count)"
      final matchesSkill = o.tags.any((t) => t.contains(skillName));

      return matchesSearch && matchesSkill;
    }).toList();

    if (_selectedSort == 'الأقرب') {
      filtered.sort((a, b) => a.dateInfo.compareTo(b.dateInfo));
    } else if (_selectedSort == 'الساعات') {
      filtered.sort((a, b) => b.hours.compareTo(a.hours));
    } else if (_selectedSort == 'الجديد') {
      filtered.sort((a, b) => b.isNew.toString().compareTo(a.isNew.toString()));
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final provider = ref.watch(appRiverpod);
    final allOpp = provider.volunteerOpportunities;
    final filteredOpp = _getFilteredOpportunities(allOpp);
    final featured = filteredOpp.isNotEmpty ? filteredOpp.first : null;
    final others = filteredOpp.length > 1 ? filteredOpp.skip(1).toList() : [];

    return VolunteerAnimatedBackground(
      child: Column(
        children: [
          _buildSearchFilter(),
          _buildSkillFilters(),
          _buildSortRow(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (featured != null) ...[
                  _buildSectionLabel(
                      'مثالي لمهاراتك ✨', const Color(0xFF10b981), 0),
                  const SizedBox(height: 12),
                  _buildFeaturedOpportunity(featured),
                  const SizedBox(height: 24),
                ],
                if (others.isNotEmpty) ...[
                  _buildSectionLabel(
                      'فرص مناسبة لك', const Color(0xFF6366f1), 1),
                  const SizedBox(height: 12),
                  ...others.map((o) => _buildOpportunityCard(o, provider)),
                  const SizedBox(height: 24),
                ],
                if (filteredOpp.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Column(
                        children: [
                          const Text('🔍', style: TextStyle(fontSize: 40)),
                          const SizedBox(height: 12),
                          Text('لم يتم العثور على فرص تطابق بحثك',
                              style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontFamily: 'Cairo')),
                        ],
                      ),
                    ),
                  ),
                _buildSectionLabel('فرص أخرى', const Color(0xFF94a3b8), 2),
                const SizedBox(height: 12),
                _buildOtherOpportunity(provider),
                const SizedBox(height: 24),
                _buildImpactTracker(provider.volunteerImpact),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchFilter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFd1fae5))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 42,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFf0fdf4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFa7f3d0)),
              ),
              child: Row(
                children: [
                  if (_searchQuery.isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                      child: const Icon(Icons.clear,
                          color: Color(0xFF94a3b8), size: 16),
                    ),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: (val) => setState(() => _searchQuery = val),
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                          fontSize: 13, color: Color(0xFF065f46)),
                      decoration: const InputDecoration(
                        hintText: 'ابحث عن نشاط أو مهارة...',
                        hintStyle:
                            TextStyle(color: Color(0xFF94a3b8), fontSize: 13),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.search, color: Color(0xFF94a3b8), size: 18),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
                color: const Color(0xFFd1fae5),
                borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.filter_list,
                color: Color(0xFF059669), size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildSkillFilters() {
    final skills = [
      'الكل (٨)',
      '📚 قراءة (٢)',
      '🧠 دعم نفسي (٢)',
      '🎮 ترفيه (٢)',
      '💻 رقمي (١)',
      '💊 تمريض (١)'
    ];
    return Container(
      height: 50,
      color: const Color(0xFFf8fafc),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: skills.length,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemBuilder: (context, index) {
          final isSelected = _selectedSkill == skills[index];
          return GestureDetector(
            onTap: () => setState(() => _selectedSkill = skills[index]),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? const LinearGradient(
                        colors: [Color(0xFF059669), Color(0xFF10b981)])
                    : null,
                color: isSelected ? null : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: isSelected
                        ? Colors.transparent
                        : const Color(0xFFd1fae5)),
              ),
              child: Center(
                child: Text(skills[index],
                    style: TextStyle(
                      color:
                          isSelected ? Colors.white : const Color(0xFF065f46),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    )),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSortRow() {
    final sorts = ['مطابقة', 'الأقرب', 'الساعات', 'الجديد'];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: Color(0xFFf0fdf4),
        border: Border(bottom: BorderSide(color: Color(0xFFd1fae5))),
      ),
      child: Wrap(
        alignment: WrapAlignment.start,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 8,
        runSpacing: 8,
        children: [
          const Text(':ترتيب',
              style: TextStyle(
                  color: Color(0xFF065f46),
                  fontSize: 11,
                  fontWeight: FontWeight.bold)),
          ...sorts.map((s) {
            final isSelected = _selectedSort == s;
            return GestureDetector(
              onTap: () => setState(() => _selectedSort = s),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF059669) : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFd1fae5)),
                ),
                child: Text(s,
                    style: TextStyle(
                      color:
                          isSelected ? Colors.white : const Color(0xFF065f46),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    )),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label, Color color, int index) {
    return FadeTransition(
      opacity: widget.fadeAnimations[min(index, 11)],
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

  Widget _buildFeaturedOpportunity(VolunteerOpportunity opp) {
    return AnimatedBuilder(
      animation: widget.floatController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, -5 * widget.floatController.value),
          child: child,
        );
      },
      child: GestureDetector(
        onTap: () => _showOpportunityDetails(context, opp),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF059669), Color(0xFF10b981)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                  color: const Color(0xFF10b981).withValues(alpha: 0.3),
                  blurRadius: 15,
                  spreadRadius: 2),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildGlowButton('احجز الآن'),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                        color: const Color(0xFFfbbf24),
                        borderRadius: BorderRadius.circular(10)),
                    child: const Text('🆕 جديدة اليوم',
                        style: TextStyle(
                            color: Color(0xFF78350f),
                            fontSize: 10,
                            fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(opp.title,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(opp.org,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 13)),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            _buildAvatarsStack(),
                            const SizedBox(width: 8),
                            const Flexible(
                              child: Text('مكان واحد متبقي!',
                                  textAlign: TextAlign.right,
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text('${opp.filledSlots}/${opp.totalSlots} سُجّل',
                            style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.7),
                                fontSize: 10)),
                      ],
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

  Widget _buildAvatarsStack() {
    return SizedBox(
      width: 45,
      height: 24,
      child: Stack(
        children: [
          Positioned(
              left: 0, child: _buildAvatar(const Color(0xFF6366f1), 'س')),
          Positioned(
              left: 14, child: _buildAvatar(const Color(0xFFf59e0b), 'م')),
        ],
      ),
    );
  }

  Widget _buildAvatar(Color color, String text) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFF10b981), width: 1.5)),
      child: Center(
          child: Text(text,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 8,
                  fontWeight: FontWeight.bold))),
    );
  }

  Widget _buildGlowButton(String label) {
    return AnimatedBuilder(
      animation: widget.shimmerController,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.4),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Text(label,
              style: const TextStyle(
                  color: Color(0xFF059669),
                  fontSize: 12,
                  fontWeight: FontWeight.bold)),
        );
      },
    );
  }

  Widget _buildOpportunityCard(VolunteerOpportunity opp, AppRiverpod provider) {
    bool isMatched =
        opp.tags.any((t) => t.contains('دعم نفسي') || t.contains('قراءة'));
    return GestureDetector(
      onTap: () => _showOpportunityDetails(context, opp),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color:
                  isMatched ? const Color(0xFF10b981) : const Color(0xFFd1fae5),
              width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (isMatched) ...[
              Wrap(
                alignment: WrapAlignment.start,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                        color: const Color(0xFFd1fae5),
                        borderRadius: BorderRadius.circular(8)),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.circle, color: Color(0xFF10b981), size: 6),
                        SizedBox(width: 4),
                        Text('مطابق',
                            style: TextStyle(
                                color: Color(0xFF065f46),
                                fontSize: 8,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                      color: const Color(0xFFf0fdf4),
                      borderRadius: BorderRadius.circular(14)),
                  child: Center(
                      child:
                          Text(opp.icon, style: const TextStyle(fontSize: 22))),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(opp.title,
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0f172a))),
                      Text(opp.org,
                          style: const TextStyle(
                              color: Color(0xFF475569),
                              fontSize: 11,
                              fontWeight: FontWeight.w500)),
                      const SizedBox(height: 6),
                      Text(opp.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: Color(0xFF334155),
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              height: 1.5),
                          textAlign: TextAlign.right),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 6,
              children: opp.tags
                  .map((t) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                            color: const Color(0xFFf1f5f9),
                            borderRadius: BorderRadius.circular(8)),
                        child: Text(t,
                            style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF475569))),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 12),
            _buildSlotsProgressBar(opp.filledSlots / opp.totalSlots),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () {
                    if (opp.id != 'vo2') {
                      provider.joinOpportunity(opp.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('تم حجز "${opp.title}" بنجاح! 🎉',
                              style: const TextStyle(fontFamily: 'Cairo')),
                          backgroundColor: const Color(0xFF059669),
                        ),
                      );
                    }
                  },
                  child: _buildSmallActionBtn(
                      opp.id == 'vo2' ? '✓ محجوزة' : 'احجز',
                      isBooked: opp.id == 'vo2'),
                ),
                Row(
                  children: [
                    Text('⏱ ${opp.hours} س',
                        style: const TextStyle(
                            color: Color(0xFF64748b), fontSize: 10)),
                    const SizedBox(width: 10),
                    Text('+${opp.points} نقطة',
                        style: const TextStyle(
                            color: Color(0xFF64748b), fontSize: 10)),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlotsProgressBar(double progress) {
    return Container(
      height: 5,
      width: double.infinity,
      decoration: BoxDecoration(
          color: const Color(0xFFf0fdf4),
          borderRadius: BorderRadius.circular(3)),
      alignment: Alignment.centerRight,
      child: LayoutBuilder(builder: (context, constraints) {
        return Container(
          width: constraints.maxWidth * progress,
          decoration: BoxDecoration(
              color: const Color(0xFF10b981),
              borderRadius: BorderRadius.circular(3)),
        );
      }),
    );
  }

  Widget _buildSmallActionBtn(String label, {bool isBooked = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        gradient: isBooked
            ? null
            : const LinearGradient(
                colors: [Color(0xFF059669), Color(0xFF10b981)]),
        color: isBooked ? const Color(0xFFd1fae5) : null,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(label,
          style: TextStyle(
              color: isBooked ? const Color(0xFF065f46) : Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildOtherOpportunity(AppRiverpod provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFffe4e6), width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
                color: const Color(0xFFffe4e6),
                borderRadius: BorderRadius.circular(12)),
            child:
                const Center(child: Text('💊', style: TextStyle(fontSize: 20))),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('مساعدة تمريض أساسية',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0f172a))),
                Text('دار الرعاية النيل · الجمعة ٨:٠٠ ص',
                    style: TextStyle(color: Color(0xFF64748b), fontSize: 10)),
                SizedBox(height: 4),
                Text('⚠️ لا تتطابق مهاراتك',
                    style: TextStyle(
                        color: Color(0xFFef4444),
                        fontSize: 9,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                      'عذراً، هذه الفرصة تتطلب مهارات تمريض متقدمة غير متوفرة في ملفك حالياً.',
                      style: TextStyle(fontFamily: 'Cairo')),
                  backgroundColor: Color(0xFFef4444),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                  color: const Color(0xFFfecaca),
                  borderRadius: BorderRadius.circular(10)),
              child: const Text('عرض',
                  style: TextStyle(
                      color: Color(0xFFb91c1c),
                      fontSize: 10,
                      fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImpactTracker(VolunteerImpact impact) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFd1fae5), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSectionLabel('أثرك التطوعي 💚', const Color(0xFF059669), 3),
          const SizedBox(height: 12),
          _buildImpactRow('👴', 'مقيمون استفادوا منك', 'منذ بداية تطوعك',
              '${impact.residentsServed} مقيم'),
          _buildImpactRow('😊', 'تقييمات إيجابية تلقيتها',
              'من المقيمين والإدارة', '${impact.positiveRatings} ⭐'),
          _buildImpactRow('⏱', 'إجمالي ساعاتك التطوعية', 'منذ مارس ٢٠٢٤',
              '${impact.totalHours} ساعة'),
        ],
      ),
    );
  }

  Widget _buildImpactRow(String icon, String title, String sub, String val) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFFf0fdf4)))),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0f172a))),
                Text(sub,
                    textAlign: TextAlign.right,
                    style:
                        const TextStyle(fontSize: 9, color: Color(0xFF94a3b8))),
              ],
            ),
          ),
          const Spacer(),
          Flexible(
            child: Text(val,
                style: const TextStyle(
                    color: Color(0xFF059669),
                    fontSize: 13,
                    fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showOpportunityDetails(BuildContext context, VolunteerOpportunity opp) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
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
                        if (opp.isNew) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                                color: const Color(0xFF10b981),
                                borderRadius: BorderRadius.circular(8)),
                            child: const Text('فرصة جديدة',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(width: 12),
                        ],
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                              color: const Color(0xFFf0fdf4),
                              borderRadius: BorderRadius.circular(12)),
                          child: Text(opp.icon,
                              style: const TextStyle(fontSize: 24)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(opp.title,
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF065f46))),
                    Text(opp.org,
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF059669),
                            fontWeight: FontWeight.w500)),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        _buildDetailChip(
                            '${opp.hours} ساعة', Icons.timer_outlined),
                        const SizedBox(width: 12),
                        _buildDetailChip(
                            '${opp.points} نقطة', Icons.stars_rounded),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      children: [
                        _buildDetailChip(
                            opp.dateInfo, 'assets/icons/calendar.png'),
                        _buildDetailChip(
                            'المقاعد: ${opp.filledSlots}/${opp.totalSlots}',
                            Icons.people_outline),
                      ],
                    ),
                    const SizedBox(height: 32),
                    const Text('وصف الفرصة التطوعية',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1e293b))),
                    const SizedBox(height: 12),
                    Text(opp.description,
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF475569),
                            height: 1.8)),
                    const SizedBox(height: 32),
                    const Text('المهارات المطلوبة',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1e293b))),
                    const SizedBox(height: 12),
                    Wrap(
                      alignment: WrapAlignment.end,
                      spacing: 8,
                      runSpacing: 8,
                      children: opp.tags
                          .map((t) => Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                    color: const Color(0xFFf8fafc),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                        color: const Color(0xFFe2e8f0))),
                                child: Text(t,
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF64748b))),
                              ))
                          .toList(),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content:
                                  Text('تم إرسال طلبك للانضمام بنجاح! 🚀')),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF059669),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: const Text('تأكيد التطوع',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        side: const BorderSide(color: Color(0xFFe2e8f0)),
                      ),
                      child: const Text('إغلاق',
                          style: TextStyle(
                              color: Color(0xFF475569),
                              fontWeight: FontWeight.bold)),
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

  Widget _buildDetailChip(String label, dynamic icon) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 260),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
          color: const Color(0xFFf8fafc),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFe2e8f0))),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF475569))),
          ),
          const SizedBox(width: 8),
          if (icon is IconData)
            Icon(icon, size: 16, color: const Color(0xFF059669))
          else if (icon is String)
            Image.asset(icon,
                width: 16, height: 16, color: const Color(0xFF059669)),
        ],
      ),
    );
  }
}
