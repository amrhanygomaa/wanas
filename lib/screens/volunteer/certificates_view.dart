// ignore_for_file: unused_element
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
                        const Text(
                          'عمر أحمد الشريف',
                          textAlign: TextAlign.center,
                          style: TextStyle(
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
                Positioned(
                  bottom: 20,
                  left: 20,
                  child: _buildQRCode(),
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
          Expanded(child: _buildStatColumn('١٢', 'جلسة مكتملة')),
          Expanded(child: _buildStatColumn('٤.٧', 'متوسط التقييم')),
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

  Widget _buildQRCode() {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
          color: const Color(0xFFf8fafc),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFe2e8f0))),
      child: const Icon(Icons.qr_code_2, color: Color(0xFF059669), size: 30),
    );
  }

  Widget _buildConfettiOverlay() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      height: 80,
      child: IgnorePointer(
        child: Stack(
          children: List.generate(10, (index) {
            return _buildConfettiDot(index);
          }),
        ),
      ),
    );
  }

  Widget _buildConfettiDot(int index) {
    final colors = [
      Colors.amber,
      Colors.green,
      Colors.blue,
      Colors.pink,
      Colors.red
    ];
    return AnimatedBuilder(
      animation: widget.floatController,
      builder: (context, child) {
        final pos = (index * 0.1);
        return Positioned(
          left: (pos * 300) + (10 * sin(widget.floatController.value * 6)),
          top: (widget.floatController.value * 100) % 80,
          child: Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
                color: colors[index % colors.length],
                shape: index.isEven ? BoxShape.circle : BoxShape.rectangle),
          ),
        );
      },
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
          if (await canLaunchUrl(url)) {
            await launchUrl(url);
          } else {
            if (!mounted) return;
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
          if (await canLaunchUrl(url)) {
            await launchUrl(url);
          } else {
            if (!mounted) return;
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
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(label,
              style: TextStyle(
                  color: color, fontSize: 13, fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
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

  Future<void> _generateAndDownloadPDF(
      VolunteerCertificate cert, AppRiverpod provider) async {
    final pdf = pw.Document();

    // Load font for Arabic support
    final fontData = await rootBundle.load("assets/fonts/Cairo-Bold.ttf");
    final ttf = pw.Font.ttf(fontData);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4.landscape,
        build: (pw.Context context) {
          return pw.FullPage(
            ignoreMargins: true,
            child: pw.Container(
              decoration: pw.BoxDecoration(
                border: pw.Border.all(
                    color: PdfColor.fromHex('#d97706'), width: 12),
              ),
              child: pw.Container(
                margin: const pw.EdgeInsets.all(5),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(
                      color: PdfColor.fromHex('#fef3c7'), width: 2),
                ),
                padding: const pw.EdgeInsets.all(40),
                child: pw.Column(
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Text(
                      'شهادة تقدير وتطوع',
                      textDirection: pw.TextDirection.rtl,
                      style: pw.TextStyle(
                        font: ttf,
                        fontSize: 14,
                        color: PdfColor.fromHex('#92400e'),
                      ),
                    ),
                    pw.SizedBox(height: 25),
                    pw.Text(
                      'تمنح دار رعاية النيل هذه الشهادة لـ',
                      textDirection: pw.TextDirection.rtl,
                      style: pw.TextStyle(font: ttf, fontSize: 16),
                    ),
                    pw.SizedBox(height: 15),
                    pw.Text(
                      'عمر أحمد الشريف',
                      textDirection: pw.TextDirection.rtl,
                      style: pw.TextStyle(
                        font: ttf,
                        fontSize: 42,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColor.fromHex('#78350f'),
                      ),
                    ),
                    pw.SizedBox(height: 25),
                    pw.Container(
                      width: 200,
                      height: 2,
                      color: PdfColor.fromHex('#d97706'),
                    ),
                    pw.SizedBox(height: 25),
                    pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 80),
                      child: pw.Text(
                        'تقديراً لجهوده الاستثنائية وتفانيه في خدمة المجتمع من خلال مشاركته المتميزة في برنامج "تابتيبا" للتطوع الرقمي، حيث أتم مهامه بكل إخلاص واحترافية أسهمت في تحسين جودة حياة المقيمين.',
                        textAlign: pw.TextAlign.center,
                        textDirection: pw.TextDirection.rtl,
                        style: pw.TextStyle(
                            font: ttf, fontSize: 13, lineSpacing: 5),
                      ),
                    ),
                    pw.SizedBox(height: 35),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      decoration: pw.BoxDecoration(
                        color: PdfColor.fromHex('#78350f'),
                        borderRadius: pw.BorderRadius.circular(8),
                      ),
                      child: pw.Text(
                        cert.awardTitle,
                        textDirection: pw.TextDirection.rtl,
                        style: pw.TextStyle(
                          font: ttf,
                          fontSize: 20,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColor.fromHex('#ffffff'),
                        ),
                      ),
                    ),
                    pw.SizedBox(height: 15),
                    pw.Text(
                      'صدرت في ${cert.date}',
                      textDirection: pw.TextDirection.rtl,
                      style: pw.TextStyle(
                          font: ttf,
                          fontSize: 11,
                          color: PdfColor.fromHex('#64748b')),
                    ),
                    pw.SizedBox(height: 60),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                      children: [
                        pw.Column(children: [
                          pw.Container(
                              width: 140,
                              height: 1,
                              color: PdfColor.fromHex('#d97706')),
                          pw.SizedBox(height: 8),
                          pw.Text('أ. نور الهدى',
                              textDirection: pw.TextDirection.rtl,
                              style: pw.TextStyle(
                                  font: ttf,
                                  fontSize: 14,
                                  fontWeight: pw.FontWeight.bold)),
                          pw.Text('المديرة التنفيذية',
                              textDirection: pw.TextDirection.rtl,
                              style: pw.TextStyle(
                                  font: ttf,
                                  fontSize: 10,
                                  color: PdfColor.fromHex('#64748b'))),
                        ]),
                        pw.Column(children: [
                          pw.Container(
                              width: 140,
                              height: 1,
                              color: PdfColor.fromHex('#d97706')),
                          pw.SizedBox(height: 8),
                          pw.Text('أ. سمر الرشيد',
                              textDirection: pw.TextDirection.rtl,
                              style: pw.TextStyle(
                                  font: ttf,
                                  fontSize: 14,
                                  fontWeight: pw.FontWeight.bold)),
                          pw.Text('منسقة التطوع',
                              textDirection: pw.TextDirection.rtl,
                              style: pw.TextStyle(
                                  font: ttf,
                                  fontSize: 10,
                                  color: PdfColor.fromHex('#64748b'))),
                        ]),
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
    final infiniteItems = [
      ...widget.certificates,
      ...widget.certificates,
      ...widget.certificates,
    ];

    return SizedBox(
      height: 95,
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
              width: 90,
              margin: const EdgeInsets.only(left: 10),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: cert.isLocked
                        ? const Color(0xFFd1fae5).withValues(alpha: 0.5)
                        : const Color(0xFFd1fae5),
                    width: cert.isLocked ? 1 : 2),
              ),
              child: Opacity(
                opacity: cert.isLocked ? 0.5 : 1.0,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(cert.icon, style: const TextStyle(fontSize: 22)),
                    const SizedBox(height: 4),
                    Text(cert.name,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF059669))),
                    Text(cert.isLocked ? cert.date : cert.date,
                        style: const TextStyle(
                            fontSize: 8, color: Color(0xFF94a3b8))),
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
                                    borderRadius: BorderRadius.circular(3)))),
                      ),
                    ],
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
