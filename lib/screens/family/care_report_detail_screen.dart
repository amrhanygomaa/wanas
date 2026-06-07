import 'package:flutter/material.dart';
import '../../models/app_models.dart';
import 'chat_with_specialist_screen.dart';

class CareReportDetailScreen extends StatefulWidget {
  final CareReport report;

  const CareReportDetailScreen({super.key, required this.report});

  @override
  State<CareReportDetailScreen> createState() => _CareReportDetailScreenState();
}

class _CareReportDetailScreenState extends State<CareReportDetailScreen>
    with TickerProviderStateMixin {
  late AnimationController _floatController;
  late AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _floatController =
        AnimationController(vsync: this, duration: const Duration(seconds: 3))
          ..repeat(reverse: true);
    _rotationController =
        AnimationController(vsync: this, duration: const Duration(seconds: 25))
          ..repeat();
  }

  @override
  void dispose() {
    _floatController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F1F6),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildMainCard(),
                  const SizedBox(height: 32),
                  _buildSectionHeader('الملخص المهني'),
                  const SizedBox(height: 12),
                  _buildContentCard(widget.report.summary),
                  const SizedBox(height: 24),
                  _buildMetricsRow(),
                  const SizedBox(height: 32),
                  _buildSectionHeader('الملاحظات الاجتماعية'),
                  const SizedBox(height: 12),
                  _buildContentCard(widget.report.socialNotes),
                  const SizedBox(height: 32),
                  _buildSectionHeader('المؤشرات'),
                  const SizedBox(height: 12),
                  _buildMetricsCard(widget.report.recommendations),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
          _buildBottomAction(context),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFea580c),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
        child: Stack(
          children: [
            Positioned.fill(child: _buildAnimatedBackground()),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: Colors.white, size: 22),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Text('تفاصيل التقرير',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(width: 48),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedBackground() {
    return AnimatedBuilder(
      animation: Listenable.merge([_floatController, _rotationController]),
      builder: (context, child) {
        return Stack(
          children: [
            Positioned(
              top: -50 + (30 * _floatController.value),
              right: -40 + (20 * _floatController.value),
              child: _buildRealisticOrb(180, [
                const Color(0xFFfb923c).withValues(alpha: 0.35),
                const Color(0xFFea580c).withValues(alpha: 0.15),
                Colors.transparent,
              ]),
            ),
            Positioned(
              bottom: -30 + (40 * (1 - _floatController.value)),
              left: -40 + (25 * _floatController.value),
              child: _buildRealisticOrb(160, [
                const Color(0xFFfdba74).withValues(alpha: 0.3),
                const Color(0xFFf97316).withValues(alpha: 0.1),
                Colors.transparent,
              ]),
            ),
            Positioned(
              top: 40,
              left: 100,
              child: _buildRealisticOrb(70, [
                const Color(0xFFfb923c).withValues(alpha: 0.1),
                Colors.transparent,
              ]),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRealisticOrb(double size, List<Color> baseColors) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(shape: BoxShape.circle),
      child: ClipOval(
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: baseColors,
                  stops: const [0.0, 0.6, 1.0],
                ),
              ),
            ),
            RotationTransition(
              turns: _rotationController,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: SweepGradient(
                    colors: [
                      Colors.transparent,
                      Colors.white.withValues(alpha: 0.15),
                      Colors.transparent,
                      Colors.white.withValues(alpha: 0.08),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
                  ),
                ),
              ),
            ),
            Positioned(
              top: size * 0.1,
              left: size * 0.15,
              child: Container(
                width: size * 0.4,
                height: size * 0.2,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.1),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String get _reportTypeLabel {
    switch (widget.report.id) {
      case 'weekly':
        return 'تقرير أسبوعي';
      case 'critical':
        return 'تنبيه حرج';
      case 'medications':
        return 'تقرير أدوية';
      default:
        return 'تقرير يومي';
    }
  }

  Widget _buildMainCard() {
    final initial = widget.report.authorName.isNotEmpty
        ? widget.report.authorName.substring(0, 1)
        : 'ن';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 20,
              offset: const Offset(0, 10))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_reportTypeLabel,
                  style: const TextStyle(
                      color: Color(0xFFea580c),
                      fontSize: 12,
                      fontWeight: FontWeight.bold)),
              Text(widget.report.date,
                  style:
                      const TextStyle(color: Color(0xFF94a3b8), fontSize: 14)),
            ],
          ),
          const SizedBox(height: 20),
          Text(widget.report.title,
              textAlign: TextAlign.right,
              style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1e293b),
                  height: 1.3)),
          const SizedBox(height: 24),
          const Divider(color: Color(0xFFf1f5f9), thickness: 1.5),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(widget.report.authorName,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Color(0xFF1e293b))),
                  Text(widget.report.authorRole,
                      style: const TextStyle(
                          color: Color(0xFF64748b), fontSize: 13)),
                ],
              ),
              const SizedBox(width: 16),
              Container(
                width: 50,
                height: 50,
                decoration: const BoxDecoration(
                    color: Color(0xFFfee2e2), shape: BoxShape.circle),
                child: Center(
                    child: Text(initial,
                        style: const TextStyle(
                            color: Color(0xFFef4444),
                            fontSize: 20,
                            fontWeight: FontWeight.bold))),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Container(
            width: 4,
            height: 18,
            decoration: BoxDecoration(
                color: const Color(0xFFea580c),
                borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 10),
        Text(title,
            style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFFea580c))),
      ],
    );
  }

  Widget _buildContentCard(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 15,
              offset: const Offset(0, 5))
        ],
      ),
      child: Text(text,
          textAlign: TextAlign.right,
          style: const TextStyle(
              color: Color(0xFF4b5563),
              fontSize: 15,
              height: 1.7,
              fontWeight: FontWeight.w500)),
    );
  }

  Widget _buildMetricsRow() {
    return Row(
      children: [
        Expanded(
            child: _buildMetricBox('التفاعل', widget.report.interactionLevel,
                const Color(0xFFf0fdf4), const Color(0xFF16a34a))),
        const SizedBox(width: 16),
        Expanded(
            child: _buildMetricBox('المزاج', widget.report.moodStatus,
                const Color(0xFFeff6ff), const Color(0xFF2563eb))),
      ],
    );
  }

  Widget _buildMetricBox(String label, String value, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(24)),
      child: Column(
        children: [
          Text(label,
              style: TextStyle(
                  color: fg, fontSize: 13, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  color: fg, fontSize: 20, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildMetricsCard(String text) {
    if (text.isEmpty) return _buildContentCard('لا توجد مؤشرات متاحة');

    final lines = text
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 15,
              offset: const Offset(0, 5))
        ],
      ),
      child: Column(
        children: List.generate(lines.length, (i) {
          final parts = lines[i].split(':');
          final label = parts.first.trim();
          final value =
              parts.length > 1 ? parts.sublist(1).join(':').trim() : '';
          final isLast = i == lines.length - 1;

          final isHighValue = value.contains('%') &&
              (int.tryParse(value.replaceAll('%', '').trim()) ?? 0) >= 80;
          final isCritical = label.contains('حرج') && value != '0';

          return Column(
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // القيمة على اليسار
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: isCritical
                            ? const Color(0xFFfee2e2)
                            : isHighValue
                                ? const Color(0xFFdcfce7)
                                : const Color(0xFFf1f5f9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        value.isEmpty ? '—' : value,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: isCritical
                              ? const Color(0xFFdc2626)
                              : isHighValue
                                  ? const Color(0xFF16a34a)
                                  : const Color(0xFF1e293b),
                        ),
                      ),
                    ),
                    // التسمية على اليمين
                    Text(
                      label,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF64748b),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isLast)
                const Divider(
                    height: 1,
                    thickness: 1,
                    color: Color(0xFFf8fafc),
                    indent: 20,
                    endIndent: 20),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildBottomAction(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChatWithSpecialistScreen(report: widget.report),
              ),
            );
          },
          borderRadius: BorderRadius.circular(20),
          child: Container(
            width: double.infinity,
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFF1e293b),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                    color: const Color(0xFF1e293b).withValues(alpha: 0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8))
              ],
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.chat_bubble_outline_rounded,
                    color: Colors.white, size: 24),
                SizedBox(width: 12),
                Text('تواصل مع الأخصائي',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
