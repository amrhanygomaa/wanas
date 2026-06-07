import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/services.dart';
import '../../providers/app_riverpod.dart';
import '../../models/app_models.dart';
import 'widgets/volunteer_background.dart';

class VolunteerCertificatesView extends ConsumerStatefulWidget {
  final List<Animation<double>> fadeAnimations;
  final AnimationController floatController;
  final AnimationController shimmerController;
  final AnimationController popController;

  const VolunteerCertificatesView({
    super.key,
    required this.fadeAnimations,
    required this.floatController,
    required this.shimmerController,
    required this.popController,
  });

  @override
  ConsumerState<VolunteerCertificatesView> createState() =>
      _VolunteerCertificatesViewState();
}

class _VolunteerCertificatesViewState
    extends ConsumerState<VolunteerCertificatesView> {
  int _selectedCertIndex = 0;

  @override
  Widget build(BuildContext context) {
    final provider = ref.watch(appRiverpod);
    final earnedCerts =
        provider.volunteerCertificates.where((c) => !c.isLocked).toList();

    if (earnedCerts.isEmpty) {
      return VolunteerAnimatedBackground(child: _buildEmptyState());
    }

    // Clamp index in case the list shrank after data refresh.
    if (_selectedCertIndex >= earnedCerts.length) {
      _selectedCertIndex = 0;
    }
    final activeCert = earnedCerts[_selectedCertIndex];

    return VolunteerAnimatedBackground(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildCertificateDocument(activeCert, provider),
                const SizedBox(height: 20),
                _buildActionGrid(activeCert, provider),
                const SizedBox(height: 24),
                _buildSectionLabel(
                    'شهاداتي الأخرى', const Color(0xFF059669), 0),
                const SizedBox(height: 12),
                _buildMiniCertsRow(provider.volunteerCertificates),
                const SizedBox(height: 24),
                _buildSectionLabel(
                    'توزيع ساعاتك التطوعية', const Color(0xFF059669), 1),
                const SizedBox(height: 12),
                _buildHoursDistribution(provider),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: const Color(0xFF059669).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.workspace_premium_rounded,
                  color: Color(0xFF059669), size: 40),
            ),
            const SizedBox(height: 24),
            const Text(
              'لا توجد شهادات حتى الآن',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0f172a)),
            ),
            const SizedBox(height: 10),
            const Text(
              'أكمل جلسات التطوع لتحصل على شهادات تقدير رقمية',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 13, color: Color(0xFF64748b), height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCertificateDocument(
      VolunteerCertificate cert, AppRiverpod provider) {
    return ScaleTransition(
      scale: widget.popController,
      child: AnimatedBuilder(
        animation: widget.floatController,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, -5 * widget.floatController.value),
            child: child,
          );
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF059669).withValues(alpha: 0.15),
                blurRadius: 30,
                offset: const Offset(0, 15),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Stack(
              children: [
                // Background Pattern/Gradient
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFd1fae5), Color(0xFFf0fdf4)],
                    ),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(26),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildVerifiedBadge(),
                            const SizedBox(width: 24),
                          ],
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'شهادة تقدير وتطوع',
                          style: TextStyle(
                            color: Color(0xFF059669),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'تمنح هذه الشهادة تقديراً لجهود',
                          style: TextStyle(
                              color: Color(0xFF475569),
                              fontSize: 11,
                              fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          provider.volunteerProfile.name.isEmpty
                              ? 'المتطوع'
                              : provider.volunteerProfile.name,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Color(0xFF065f46),
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            fontFamily: 'Cairo',
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          width: 60,
                          height: 2,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [
                              Colors.transparent,
                              Color(0xFF059669),
                              Colors.transparent
                            ]),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          child: Text(
                            'لمساهمته الاستثنائية وتفانيه في خدمة المجتمع من خلال برنامج "تابتيبا" للتطوع الرقمي والاجتماعي.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Color(0xFF334155),
                              fontSize: 12,
                              height: 1.6,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        _buildMainAwardBanner(cert),
                        const SizedBox(height: 24),
                        _buildCertStats(provider),
                        const SizedBox(height: 30),
                        _buildSignaturesSection(),
                      ],
                    ),
                  ),
                ),
                // Decorative Elements
                Positioned(
                  top: -20,
                  right: -20,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: const Color(0xFFd1fae5).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMainAwardBanner(VolunteerCertificate cert) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF065f46), Color(0xFF059669)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF065f46).withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                cert.awardTitle,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'صدرت في ${cert.date}',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 9,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSignaturesSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildSingleSignature('أ. نور الهدى', 'المديرة التنفيذية'),
        const Text('●',
            style: TextStyle(color: Color(0xFFd1fae5), fontSize: 8)),
        _buildSingleSignature('أ. سمر الرشيد', 'منسقة التطوع'),
      ],
    );
  }

  Widget _buildSingleSignature(String name, String role) {
    return Column(
      children: [
        Text(
          name,
          style: const TextStyle(
            color: Color(0xFF065f46),
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          role,
          style: const TextStyle(color: Color(0xFF94a3b8), fontSize: 9),
        ),
      ],
    );
  }

  Widget _buildVerifiedBadge() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
            color: const Color(0xFFd1fae5),
            borderRadius: BorderRadius.circular(20)),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('موثّقة رقمياً',
                style: TextStyle(
                    color: Color(0xFF065f46),
                    fontSize: 9,
                    fontWeight: FontWeight.bold)),
            SizedBox(width: 4),
            Icon(Icons.verified, color: Color(0xFF10b981), size: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildCertStats(AppRiverpod provider) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Color(0xFFd1fae5)))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Expanded(
              child: _buildStatColumn(
                  '${provider.volunteerHours}', 'ساعة تطوعية',
                  isShimmer: true)),
          Expanded(
              child: _buildStatColumn(
                  '${provider.volunteerBookings.where((b) => b.status == 'done').length}',
                  'جلسة مكتملة')),
          Expanded(
              child: _buildStatColumn(
                  provider.averageRating.toStringAsFixed(1), 'متوسط التقييم')),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String val, String label, {bool isShimmer = false}) {
    return Column(
      children: [
        if (isShimmer)
          AnimatedBuilder(
            animation: widget.shimmerController,
            builder: (context, child) {
              return ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [
                    Color(0xFF059669),
                    Color(0xFF10b981),
                    Color(0xFF059669)
                  ],
                  stops: [0.0, 0.5, 1.0],
                ).createShader(bounds),
                child: Text(val,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold)),
              );
            },
          )
        else
          Text(val,
              style: const TextStyle(
                  color: Color(0xFF065f46),
                  fontSize: 14,
                  fontWeight: FontWeight.bold)),
        Text(label,
            style: const TextStyle(color: Color(0xFF94a3b8), fontSize: 8)),
      ],
    );
  }

  Widget _buildActionGrid(VolunteerCertificate cert, AppRiverpod provider) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 2.2,
      children: [
        _buildActionBtn(
            '📄 تحميل PDF', [const Color(0xFF059669), const Color(0xFF10b981)],
            onTap: () => _generateAndDownloadPDF(cert, provider)),
        _buildActionBtn(
            '🔗 نسخ الرابط', [const Color(0xFF059669), const Color(0xFF10b981)],
            onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('تم نسخ رابط التوثيق الرقمي بنجاح! 🔗'),
            backgroundColor: Color(0xFF059669),
          ));
        }),
        _buildActionBtn(
            '💬 واتساب', [const Color(0xFF25D366), const Color(0xFF2ecc71)],
            onTap: () async {
          final text =
              'لقد حصلت على شهادة ${cert.name} من برنامج تابتيبا للتطوع! 🏆';
          final url = Uri.parse('whatsapp://send?text=$text');
          final canLaunch = await canLaunchUrl(url);
          if (!mounted) return;
          if (canLaunch) {
            await launchUrl(url);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('تعذر فتح واتساب، يرجى التأكد من تثبيت التطبيق 💬'),
              backgroundColor: Color(0xFFef4444),
            ));
          }
        }),
        _buildActionBtn('📧 بريد إلكتروني', [
          const Color(0xFF059669),
          const Color(0xFF10b981)
        ], onTap: () async {
          final subject = 'شهادة تطوع: ${cert.name}';
          final body =
              'يسعدني مشاركة حصولي على شهادة ${cert.name} من برنامج تابتيبا للتطوع.\nالتاريخ: ${cert.date}';
          final url = Uri.parse(
              'mailto:?subject=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(body)}');
          final canLaunch = await canLaunchUrl(url);
          if (!mounted) return;
          if (canLaunch) {
            await launchUrl(url);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('تعذر فتح تطبيق البريد الإلكتروني 📧'),
              backgroundColor: Color(0xFFef4444),
            ));
          }
        }),
      ],
    );
  }

  Widget _buildActionBtn(String label, List<Color> colors,
      {required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: colors),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Text(label,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold)),
        ),
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

  Widget _buildMiniCertsRow(List<VolunteerCertificate> certs) {
    return _CertificatesTicker(
      certificates: certs,
      popController: widget.popController,
      onSelected: (index) {
        setState(() => _selectedCertIndex = index);
      },
    );
  }

  Widget _buildHoursDistribution(AppRiverpod provider) {
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('توزيع ساعاتك التطوعية',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0f172a))),
                const SizedBox(height: 10),
                _buildDistBar('قراءة', 15, const Color(0xFF10b981), 0.6),
                _buildDistBar('دعم نفسي', 12, const Color(0xFF10b981), 0.48),
                _buildDistBar('ترفيه', 11, const Color(0xFF10b981), 0.44),
              ],
            ),
          ),
          const SizedBox(width: 16),
          _buildRingSummary(),
        ],
      ),
    );
  }

  Widget _buildDistBar(String label, int val, Color color, double width) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Flexible(
            flex: 2,
            child: Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 10, color: Color(0xFF64748b)),
                textAlign: TextAlign.right),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 3,
            child: Container(
              height: 6,
              decoration: BoxDecoration(
                  color: const Color(0xFFd1fae5),
                  borderRadius: BorderRadius.circular(4)),
              alignment: Alignment.centerRight,
              child: FractionallySizedBox(
                  widthFactor: width,
                  child: Container(
                      decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(4)))),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text('$val س',
                style: TextStyle(
                    color: color, fontSize: 10, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildRingSummary() {
    return const SizedBox(
      width: 70,
      height: 70,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
              value: 0.76,
              strokeWidth: 6,
              backgroundColor: Color(0xFFd1fae5),
              color: Color(0xFF059669)),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('٧٦٪',
                  style: TextStyle(
                      color: Color(0xFF059669),
                      fontSize: 14,
                      fontWeight: FontWeight.bold)),
              Text('الهدف',
                  style: TextStyle(color: Color(0xFF059669), fontSize: 8)),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildPdfStatItem(
      pw.Font boldFont, pw.Font regularFont, String value, String label) {
    return pw.Column(
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        pw.Text(
          value,
          textDirection: pw.TextDirection.rtl,
          style: pw.TextStyle(
            font: boldFont,
            fontSize: 11,
            color: PdfColor.fromHex('#0c1b33'),
          ),
        ),
        pw.Text(
          label,
          textDirection: pw.TextDirection.rtl,
          style: pw.TextStyle(
            font: regularFont,
            fontSize: 8,
            color: PdfColor.fromHex('#8a95a5'),
          ),
        ),
      ],
    );
  }

  Future<void> _generateAndDownloadPDF(
      VolunteerCertificate cert, AppRiverpod provider) async {
    final pdf = pw.Document();

    // Load fonts for Arabic support
    final regularFontData =
        await rootBundle.load("assets/fonts/Cairo-Regular.ttf");
    final boldFontData = await rootBundle.load("assets/fonts/Cairo-Bold.ttf");
    final ttfRegular = pw.Font.ttf(regularFontData);
    final ttfBold = pw.Font.ttf(boldFontData);

    final theme = pw.ThemeData.withFont(
      base: ttfRegular,
      bold: ttfBold,
    );

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(20),
        theme: theme,
        build: (pw.Context context) {
          return pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: pw.Container(
              decoration: pw.BoxDecoration(
                color: PdfColor.fromHex('#fcfbfa'), // Soft background cream
                border: pw.Border.all(
                  color: PdfColor.fromHex('#c5a880'), // Gold outer border
                  width: 2,
                ),
              ),
              padding: const pw.EdgeInsets.all(4),
              child: pw.Container(
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(
                    color:
                        PdfColor.fromHex('#0c1b33'), // Thick inner navy frame
                    width: 8,
                  ),
                ),
                padding: const pw.EdgeInsets.all(6),
                child: pw.Container(
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(
                      color:
                          PdfColor.fromHex('#c5a880'), // Thin inner gold line
                      width: 1.5,
                    ),
                  ),
                  padding: const pw.EdgeInsets.symmetric(
                      horizontal: 40, vertical: 12),
                  child: pw.Column(
                    mainAxisAlignment: pw.MainAxisAlignment.center,
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      // 1. Header Row (Emblem + Organization Names - Arranged for natural RTL flow)
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: pw.CrossAxisAlignment.center,
                        children: [
                          // Right-aligned organization details (appears on the right in RTL)
                          pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(
                                'برنامج ونس الوطني للرعاية',
                                style: pw.TextStyle(
                                  fontWeight: pw.FontWeight.bold,
                                  fontSize: 9,
                                  color: PdfColor.fromHex('#0c1b33'),
                                  height: 1.3,
                                ),
                              ),
                              pw.Text(
                                'منصة التمكين والعمل التطوعي',
                                style: const pw.TextStyle(
                                  fontSize: 8,
                                  color: PdfColors.grey600,
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),

                          // Center crest
                          pw.Container(
                            width: 36,
                            height: 36,
                            decoration: pw.BoxDecoration(
                              shape: pw.BoxShape.circle,
                              border: pw.Border.all(
                                color: PdfColor.fromHex('#c5a880'),
                                width: 1.5,
                              ),
                            ),
                            padding: const pw.EdgeInsets.all(2),
                            child: pw.Container(
                              decoration: pw.BoxDecoration(
                                shape: pw.BoxShape.circle,
                                color: PdfColor.fromHex('#0c1b33'),
                              ),
                              child: pw.Center(
                                child: pw.Text(
                                  '★',
                                  style: pw.TextStyle(
                                    color: PdfColor.fromHex('#c5a880'),
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                          ),

                          // Left-aligned verification details (appears on the left in RTL)
                          pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.end,
                            children: [
                              pw.Text(
                                'الرقم المرجعي: TBT-${DateTime.now().year}-${1000 + Random().nextInt(9000)}',
                                style: const pw.TextStyle(
                                  fontSize: 8,
                                  color: PdfColors.grey600,
                                  height: 1.3,
                                ),
                              ),
                              pw.Text(
                                'التحقق الرقمي: موثقة ونشطة',
                                style: const pw.TextStyle(
                                  fontSize: 8,
                                  color: PdfColors.grey600,
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      pw.SizedBox(height: 10),

                      // 2. Main Title Block
                      pw.Text(
                        'شهادة تقدير وتميز تطوعي',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 22,
                          color: PdfColor.fromHex('#0c1b33'),
                          height: 1.3,
                        ),
                      ),
                      pw.SizedBox(height: 3),
                      pw.Container(
                        width: 140,
                        height: 1.5,
                        color: PdfColor.fromHex('#c5a880'),
                      ),

                      pw.SizedBox(height: 8),

                      // 3. Recipient Block
                      pw.Text(
                        'تمنح هذه الشهادة بكل فخر واعتزاز إلى المتطوع المبادر',
                        style: const pw.TextStyle(
                          fontSize: 11,
                          color: PdfColors.grey800,
                          height: 1.3,
                        ),
                      ),
                      pw.SizedBox(height: 6),
                      pw.Text(
                        provider.volunteerProfile.name.isEmpty
                            ? 'المتطوع'
                            : provider.volunteerProfile.name,
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 28,
                          color: PdfColor.fromHex('#0c1b33'),
                          height: 1.3,
                        ),
                      ),

                      pw.SizedBox(height: 8),

                      // 4. Appreciation Text Block
                      pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 60),
                        child: pw.Text(
                          'تقديراً لمساهمته الاستثنائية وتفانيه في تقديم الدعم والتمكين الرقمي والاجتماعي لكبار السن من خلال برنامج "ونس" للتطوع الرقمي. لقد أثبت نموذجاً متميزاً يُحتذى به في المسؤولية المجتمعية والنبل الإنساني، وأحدث أثراً إيجابياً وملموساً في حياة المستفيدين.',
                          textAlign: pw.TextAlign.center,
                          style: const pw.TextStyle(
                            fontSize: 10,
                            color: PdfColors.grey900,
                            height: 1.4,
                            lineSpacing: 3,
                          ),
                        ),
                      ),

                      pw.SizedBox(height: 10),

                      // 5. Impact Metrics block
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(
                            horizontal: 20, vertical: 6),
                        decoration: pw.BoxDecoration(
                          color: PdfColor.fromHex('#fbf9f4'),
                          borderRadius:
                              const pw.BorderRadius.all(pw.Radius.circular(8)),
                          border: pw.Border.all(
                            color: PdfColor.fromHex('#e8e2d5'),
                            width: 1,
                          ),
                        ),
                        child: pw.Row(
                          mainAxisSize: pw.MainAxisSize.min,
                          mainAxisAlignment: pw.MainAxisAlignment.center,
                          children: [
                            _buildPdfStatItem(
                                ttfBold,
                                ttfRegular,
                                '${provider.volunteerHours} ساعة',
                                'العطاء الزمني'),
                            pw.SizedBox(width: 16),
                            pw.Container(
                                width: 1,
                                height: 18,
                                color: PdfColor.fromHex('#e8e2d5')),
                            pw.SizedBox(width: 16),
                            _buildPdfStatItem(
                                ttfBold,
                                ttfRegular,
                                '${provider.volunteerBookings.where((b) => b.status == 'done').length} جلسة',
                                'الرعاية المكتملة'),
                            pw.SizedBox(width: 16),
                            pw.Container(
                                width: 1,
                                height: 18,
                                color: PdfColor.fromHex('#e8e2d5')),
                            pw.SizedBox(width: 16),
                            _buildPdfStatItem(
                                ttfBold,
                                ttfRegular,
                                '${provider.averageRating.toStringAsFixed(1)} / ٥.٠',
                                'تقييم الأثر'),
                          ],
                        ),
                      ),

                      pw.SizedBox(height: 12),

                      // 6. Signatures & Seal Section
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                        crossAxisAlignment: pw.CrossAxisAlignment.center,
                        children: [
                          // Right signature (appears on the right in RTL)
                          pw.Column(
                            children: [
                              pw.SizedBox(height: 14),
                              pw.Container(
                                width: 100,
                                height: 1,
                                color: PdfColor.fromHex('#c5a880'),
                              ),
                              pw.SizedBox(height: 4),
                              pw.Text(
                                'أ. نور الهدى',
                                style: pw.TextStyle(
                                  fontWeight: pw.FontWeight.bold,
                                  fontSize: 11,
                                  color: PdfColor.fromHex('#0c1b33'),
                                  height: 1.3,
                                ),
                              ),
                              pw.SizedBox(height: 2),
                              pw.Text(
                                'المديرة التنفيذية لبرنامج ونس',
                                style: const pw.TextStyle(
                                  fontSize: 7.5,
                                  color: PdfColors.grey700,
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                          // Golden Medal Seal in middle
                          pw.Container(
                            width: 30,
                            height: 30,
                            decoration: pw.BoxDecoration(
                              shape: pw.BoxShape.circle,
                              color: PdfColor.fromHex('#c5a880'),
                            ),
                            child: pw.Center(
                              child: pw.Container(
                                width: 24,
                                height: 24,
                                decoration: pw.BoxDecoration(
                                  shape: pw.BoxShape.circle,
                                  border: pw.Border.all(
                                    color: PdfColors.white,
                                    width: 1,
                                  ),
                                ),
                                child: pw.Center(
                                  child: pw.Text(
                                    '✓',
                                    style: pw.TextStyle(
                                      fontWeight: pw.FontWeight.bold,
                                      color: PdfColors.white,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          // Left signature (appears on the left in RTL)
                          pw.Column(
                            children: [
                              pw.SizedBox(height: 14),
                              pw.Container(
                                width: 100,
                                height: 1,
                                color: PdfColor.fromHex('#c5a880'),
                              ),
                              pw.SizedBox(height: 4),
                              pw.Text(
                                'أ. سمر الرشيد',
                                style: pw.TextStyle(
                                  fontWeight: pw.FontWeight.bold,
                                  fontSize: 11,
                                  color: PdfColor.fromHex('#0c1b33'),
                                  height: 1.3,
                                ),
                              ),
                              pw.SizedBox(height: 2),
                              pw.Text(
                                'منسقة شؤون المتطوعين',
                                style: const pw.TextStyle(
                                  fontSize: 7.5,
                                  color: PdfColors.grey700,
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      pw.SizedBox(height: 8),

                      // 7. Footer text
                      pw.Text(
                        'هذه الشهادة معتمدة وموثقة رقمياً من قبل برنامج ونس الوطني للرعاية الاجتماعية ويمكن التحقق من صحتها عبر الرمز المرجعي المدرج.',
                        style: const pw.TextStyle(
                          fontSize: 6.5,
                          color: PdfColors.grey500,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: 'شهادة_تطوع_${cert.name}.pdf');
  }
}

// --- Certificates Ticker Widget ---

class _CertificatesTicker extends StatefulWidget {
  final List<VolunteerCertificate> certificates;
  final AnimationController popController;
  final Function(int) onSelected;

  const _CertificatesTicker({
    required this.certificates,
    required this.popController,
    required this.onSelected,
  });

  @override
  State<_CertificatesTicker> createState() => _CertificatesTickerState();
}

class _CertificatesTickerState extends State<_CertificatesTicker> {
  late ScrollController _scrollController;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startTimer();
    });
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(milliseconds: 30), (timer) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.offset + 0.5);
        if (_scrollController.offset >=
            _scrollController.position.maxScrollExtent) {
          _scrollController.jumpTo(0);
        }
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.certificates.isEmpty) {
      return const SizedBox(height: 110);
    }

    final infiniteItems = [
      ...widget.certificates,
      ...widget.certificates,
      ...widget.certificates,
    ];

    return SizedBox(
      height: 110,
      child: ListView.builder(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        itemCount: infiniteItems.length,
        itemBuilder: (context, index) {
          final cert = infiniteItems[index];
          final isEarned = !cert.isLocked;

          return GestureDetector(
            onTap: isEarned
                ? () {
                    final earnedIndex = widget.certificates
                        .where((c) => !c.isLocked)
                        .toList()
                        .indexOf(cert);
                    if (earnedIndex != -1) {
                      widget.onSelected(earnedIndex);
                    }
                  }
                : null,
            child: Container(
              width: 95,
              margin: const EdgeInsets.only(left: 12),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
              decoration: BoxDecoration(
                gradient: cert.isLocked
                    ? LinearGradient(
                        colors: [
                          Colors.white.withValues(alpha: 0.4),
                          Colors.grey.shade50.withValues(alpha: 0.2)
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : const LinearGradient(
                        colors: [Colors.white, Color(0xFFf0fdf4)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: cert.isLocked
                      ? const Color(0xFFcbd5e1).withValues(alpha: 0.4)
                      : const Color(0xFF34d399).withValues(alpha: 0.6),
                  width: cert.isLocked ? 1 : 1.5,
                ),
                boxShadow: cert.isLocked
                    ? null
                    : [
                        BoxShadow(
                          color:
                              const Color(0xFF059669).withValues(alpha: 0.06),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
              ),
              child: Opacity(
                opacity: cert.isLocked ? 0.5 : 1.0,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Top Accent Symbol/Ornament (Minimalist Gold Star)
                    Text(
                      '★',
                      style: TextStyle(
                        color: cert.isLocked
                            ? const Color(0xFF94a3b8).withValues(alpha: 0.5)
                            : const Color(0xFFfbbf24),
                        fontSize: 12,
                      ),
                    ),

                    // Certificate Title
                    Expanded(
                      child: Center(
                        child: Text(
                          cert.name,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: cert.isLocked
                                ? const Color(0xFF64748b)
                                : const Color(0xFF059669),
                            height: 1.2,
                          ),
                        ),
                      ),
                    ),

                    // Mini Decorative Gold/Green Divider
                    Container(
                      width: 16,
                      height: 1.5,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        color: cert.isLocked
                            ? const Color(0xFFcbd5e1)
                            : const Color(0xFF059669),
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),

                    // Bottom Block (Subtitle and optional Progress Bar)
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          cert.isLocked ? cert.date : cert.date,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF64748b),
                          ),
                        ),
                        if (cert.isLocked) ...[
                          const SizedBox(height: 6),
                          Container(
                            height: 3,
                            decoration: BoxDecoration(
                                color: const Color(0xFFd1fae5),
                                borderRadius: BorderRadius.circular(3)),
                            alignment: Alignment.centerRight,
                            child: FractionallySizedBox(
                                widthFactor: cert.progress,
                                child: Container(
                                    decoration: BoxDecoration(
                                        color: const Color(0xFF059669),
                                        borderRadius:
                                            BorderRadius.circular(3)))),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
