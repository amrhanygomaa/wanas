import 'package:flutter/material.dart';
import 'widgets/healing_particles.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/app_riverpod.dart';
import '../../models/app_models.dart';
import '../../services/medication_adherence_service.dart';
import '../../services/nursing_reports_service.dart';

class NurseReportsScreen extends ConsumerStatefulWidget {
  const NurseReportsScreen({super.key});

  @override
  ConsumerState<NurseReportsScreen> createState() => _NurseReportsScreenState();
}

class _NurseReportsScreenState extends ConsumerState<NurseReportsScreen>
    with TickerProviderStateMixin {
  late AnimationController _blinkController;
  late AnimationController _pulseController;
  late AnimationController _floatController;
  String _selectedType = 'تقرير يومي';
  final Map<String, bool> _activeRecipients = {
    'د. أحمد': true,
    'الإدارة': true,
    'الأخصائي': true,
    'الأسر': false,
  };

  String _dailyTime = '٠٨:٠٠ ص';
  String _weeklyDay = 'الجمعة';
  bool _isCriticalAlertOn = true;
  bool _isMissedMedAlertOn = true;
  bool _isLoadingBackendReports = false;
  List<NursingReportCompletenessItem> _reportCompleteness = [];
  MedicationAdherenceReport? _adherenceReport;

  String _getShiftName() {
    int hour = DateTime.now().hour;
    if (hour >= 6 && hour < 14) return 'الوردية الصباحية (٦ ص - ٢ ظ)';
    if (hour >= 14 && hour < 22) return 'الوردية المسائية (٢ ظ - ١٠ م)';
    return 'الوردية الليلية (١٠ م - ٦ ص)';
  }

  @override
  void initState() {
    super.initState();

    _blinkController =
        AnimationController(vsync: this, duration: const Duration(seconds: 1))
          ..repeat(reverse: true);

    _pulseController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1400))
      ..repeat(reverse: true);

    _floatController =
        AnimationController(vsync: this, duration: const Duration(seconds: 3))
          ..repeat(reverse: true);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadBackendReportData();
    });
  }

  @override
  void dispose() {
    _blinkController.dispose();
    _pulseController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  Future<void> _loadBackendReportData() async {
    setState(() => _isLoadingBackendReports = true);
    try {
      final settings = await NursingReportsService.instance.settings();
      final completeness = await NursingReportsService.instance.completeness();
      final adherence =
          await MedicationAdherenceService.instance.report(period: 'weekly');
      if (!mounted) return;
      setState(() {
        _dailyTime = settings.dailyTime;
        _weeklyDay = settings.weeklyDay;
        _isCriticalAlertOn = settings.criticalAlertEnabled;
        _isMissedMedAlertOn = settings.missedMedicationAlertEnabled;
        if (settings.recipients.isNotEmpty) {
          for (final key in _activeRecipients.keys.toList()) {
            _activeRecipients[key] = settings.recipients.contains(key);
          }
        }
        _reportCompleteness = completeness;
        _adherenceReport = adherence;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تعذر تحميل إعدادات التقارير من AWS: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoadingBackendReports = false);
    }
  }

  Future<void> _saveBackendReportSettings() async {
    try {
      final settings = await NursingReportsService.instance.updateSettings(
        dailyTime: _dailyTime,
        weeklyDay: _weeklyDay,
        criticalAlertEnabled: _isCriticalAlertOn,
        missedMedicationAlertEnabled: _isMissedMedAlertOn,
        recipients: _activeRecipients.entries
            .where((entry) => entry.value)
            .map((entry) => entry.key)
            .toList(),
      );
      if (!mounted) return;
      setState(() {
        _dailyTime = settings.dailyTime;
        _weeklyDay = settings.weeklyDay;
        _isCriticalAlertOn = settings.criticalAlertEnabled;
        _isMissedMedAlertOn = settings.missedMedicationAlertEnabled;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تعذر حفظ إعدادات التقارير: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _sendReport(String reportType) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Container(
          padding: const EdgeInsets.all(30),
          decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(24)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(
                  color: Color(0xFF0EA5E9), strokeWidth: 3),
              const SizedBox(height: 24),
              Text('جاري إرسال $reportType...',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      fontFamily: 'Cairo',
                      decoration: TextDecoration.none,
                      color: isDark ? Colors.white : const Color(0xFF0F172A))),
              const SizedBox(height: 8),
              Text('يتم الآن تشفير البيانات وإرسالها للجهات المعنية',
                  style: TextStyle(
                      fontSize: 10,
                      color: isDark ? Colors.white38 : const Color(0xFF64748B),
                      decoration: TextDecoration.none,
                      fontFamily: 'Cairo')),
            ],
          ),
        ),
      ),
    );
    final provider = ref.read(appRiverpod);
    String icon = '📋';
    if (reportType == 'تقرير أسبوعي') icon = '📊';
    if (reportType == 'تنبيه حرج') icon = '🚨';
    if (reportType == 'تقرير أدوية') icon = '💊';

    await provider.addSentReport(SentReport(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      icon: icon,
      title: '$reportType — ${DateTime.now().day} مايو',
      meta: 'أُرسل يدوياً · ${DateTime.now().hour}:${DateTime.now().minute}',
      status: 'أُرسل',
      date: DateTime.now().toIso8601String(),
    ));

    if (!mounted) return;
    Navigator.pop(context);
    final error = provider.backendSyncError;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(error ?? 'تم إرسال $reportType بنجاح'),
      backgroundColor:
          error == null ? const Color(0xFF10B981) : Colors.redAccent,
    ));
  }

  Future<void> _generatePDF(String reportType) async {
    try {
      final exported = await NursingReportsService.instance.export(
        reportType: reportType,
        format: 'pdf',
      );
      await _printBackendReport(exported);
      return;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تعذر تصدير تقرير AWS، سيتم إنشاء نسخة محلية: $e'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }

    final provider = ref.read(appRiverpod);
    final residentCount = provider.residentFiles.length;
    final openComplaints = provider.unresolvedComplaintsCount;
    final completedTasks =
        provider.careTasks.where((task) => task.isCompleted).length;
    final totalTasks = provider.careTasks.length;
    final taskCompletion =
        totalTasks == 0 ? 0 : ((completedTasks / totalTasks) * 100).round();
    final medicationTotal = provider.medications.length;
    final medicationTaken =
        provider.medications.where((med) => med.isTaken).length;
    final medicationRate = medicationTotal == 0
        ? 0
        : ((medicationTaken / medicationTotal) * 100).round();
    final criticalComplaints = provider.socialComplaints
        .where((complaint) =>
            complaint.priority == 'critical' || complaint.priority == 'high')
        .toList();
    final criticalResident = criticalComplaints.isEmpty
        ? null
        : criticalComplaints.first.residentName;
    final fontData = await rootBundle.load('assets/fonts/Cairo-Regular.ttf');
    final ttf = pw.Font.ttf(fontData);
    final fontBoldData = await rootBundle.load('assets/fonts/Cairo-Bold.ttf');
    final ttfBold = pw.Font.ttf(fontBoldData);

    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: pw.Container(
              padding: const pw.EdgeInsets.all(30),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Header
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('تطبيق طبطبة',
                          style: pw.TextStyle(
                              font: ttfBold,
                              fontSize: 18,
                              color: PdfColors.blue600)),
                      pw.Text(
                          provider.facilityName.isNotEmpty
                              ? provider.facilityName
                              : 'اسم المنشأة غير مهيأ',
                          style: pw.TextStyle(
                              font: ttf,
                              fontSize: 12,
                              color: PdfColors.grey700)),
                    ],
                  ),
                  pw.SizedBox(height: 5),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                          'الممرض: ${provider.currentAccount?.name ?? 'الممرض'}',
                          style: pw.TextStyle(
                              font: ttf,
                              fontSize: 12,
                              color: PdfColors.grey700)),
                      pw.Text(
                          'التاريخ: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}  الوقت: ${DateTime.now().hour}:${DateTime.now().minute}',
                          style: pw.TextStyle(
                              font: ttf,
                              fontSize: 12,
                              color: PdfColors.grey700)),
                    ],
                  ),
                  pw.SizedBox(height: 10),
                  pw.Divider(color: PdfColors.blue200, thickness: 2),
                  pw.SizedBox(height: 20),

                  // Title
                  pw.Center(
                    child: pw.Text('تقرير: $reportType',
                        style: pw.TextStyle(
                            font: ttfBold,
                            fontSize: 20,
                            color: PdfColors.grey900)),
                  ),
                  pw.SizedBox(height: 30),

                  pw.Text('تفاصيل التقرير:',
                      style: pw.TextStyle(
                          font: ttfBold,
                          fontSize: 16,
                          color: PdfColors.grey800)),
                  pw.SizedBox(height: 15),

                  if (reportType == 'تقرير أسبوعي') ...[
                    _pdfRow(
                        ttf, ttfBold, 'عدد المقيمين من AWS', '$residentCount'),
                    _pdfRow(
                        ttf, ttfBold, 'الشكاوى المفتوحة', '$openComplaints'),
                    _pdfRow(ttf, ttfBold, 'متوسط الالتزام الدوائي',
                        '$medicationRate٪'),
                  ] else if (reportType == 'تنبيه حرج') ...[
                    _pdfRow(ttf, ttfBold, 'المقيم',
                        criticalResident ?? 'لا توجد حالة حرجة مسجلة'),
                    _pdfRow(ttf, ttfBold, 'الحالة',
                        criticalResident == null ? 'مستقرة' : 'حرجة'),
                    _pdfRow(ttf, ttfBold, 'مصدر البيانات', 'AWS RDS'),
                  ] else ...[
                    _pdfRow(ttf, ttfBold, 'حالة الوردية',
                        openComplaints == 0 ? 'مستقرة' : 'تحتاج متابعة'),
                    _pdfRow(ttf, ttfBold, 'عدد المقيمين المتابعين',
                        '$residentCount'),
                    _pdfRow(
                        ttf, ttfBold, 'نسبة اكتمال المهام', '$taskCompletion٪'),
                  ],

                  pw.Spacer(),

                  // Signature
                  pw.Align(
                    alignment: pw.Alignment.centerLeft,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        pw.Container(
                            width: 120,
                            child: pw.Divider(
                                color: PdfColors.grey400, thickness: 1)),
                        pw.SizedBox(height: 4),
                        pw.Text('توقيع الممرض',
                            style: pw.TextStyle(
                                font: ttfBold,
                                fontSize: 12,
                                color: PdfColors.grey800)),
                        pw.Text(provider.currentAccount?.name ?? 'الممرض',
                            style: pw.TextStyle(
                                font: ttf,
                                fontSize: 11,
                                color: PdfColors.grey600)),
                      ],
                    ),
                  ),
                  pw.SizedBox(height: 20),

                  // Footer
                  pw.Divider(color: PdfColors.grey300),
                  pw.SizedBox(height: 10),
                  pw.Center(
                    child: pw.Text(
                        'تم إنشاء هذا التقرير تلقائياً عبر تطبيق طبطبة',
                        style: pw.TextStyle(
                            font: ttf, fontSize: 10, color: PdfColors.grey600)),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: '$reportType.pdf',
    );
  }

  Future<void> _printBackendReport(NursingReportExport report) async {
    final fontData = await rootBundle.load('assets/fonts/Cairo-Regular.ttf');
    final ttf = pw.Font.ttf(fontData);
    final fontBoldData = await rootBundle.load('assets/fonts/Cairo-Bold.ttf');
    final ttfBold = pw.Font.ttf(fontBoldData);
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        theme: pw.ThemeData.withFont(base: ttf, bold: ttfBold),
        textDirection: pw.TextDirection.rtl,
        build: (pw.Context context) => [
          pw.Text(
            report.title,
            style: pw.TextStyle(font: ttfBold, fontSize: 20),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            report.summary,
            style: pw.TextStyle(font: ttf, fontSize: 12),
          ),
          pw.SizedBox(height: 18),
          ...report.metrics.map(
            (metric) => _pdfRow(ttf, ttfBold, metric.label, metric.value),
          ),
          pw.SizedBox(height: 18),
          pw.Text(
            'ملاحظات',
            style: pw.TextStyle(font: ttfBold, fontSize: 14),
          ),
          ...report.notes.map(
            (note) => pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 3),
              child: pw.Text(note, style: pw.TextStyle(font: ttf)),
            ),
          ),
          pw.SizedBox(height: 18),
          pw.Text(
            'اكتمال التقرير',
            style: pw.TextStyle(font: ttfBold, fontSize: 14),
          ),
          ...report.completeness.map(
            (item) => _pdfRow(ttf, ttfBold, item.title, item.value),
          ),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: report.filename,
    );
  }

  pw.Widget _pdfRow(pw.Font ttf, pw.Font ttfBold, String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 8),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label,
              style: pw.TextStyle(
                  font: ttfBold, fontSize: 12, color: PdfColors.grey700)),
          pw.Text(value,
              style: pw.TextStyle(
                  font: ttf, fontSize: 12, color: PdfColors.grey900)),
        ],
      ),
    );
  }

  Future<void> _showPreviewDialog(String type) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const CircularProgressIndicator(color: Color(0xFF0EA5E9)),
        ),
      ),
    );

    NursingReportPreview preview;
    try {
      preview = await NursingReportsService.instance.preview(reportType: type);
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تعذر تحميل معاينة التقرير من AWS: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          preview.summary,
          textAlign: TextAlign.right,
          style: TextStyle(
            fontSize: 12,
            height: 1.5,
            color: isDark ? Colors.white70 : const Color(0xFF475569),
          ),
        ),
        Divider(height: 24, color: isDark ? Colors.white10 : Colors.black12),
        ...preview.metrics.map((metric) => _previewRow(
              metric.label,
              metric.value,
            )),
        if (preview.notes.isNotEmpty) ...[
          Divider(height: 24, color: isDark ? Colors.white10 : Colors.black12),
          Text(
            'ملاحظات AWS:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 6),
          ...preview.notes.map(
            (note) => Text(
              note,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 11,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
          ),
        ],
      ],
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(preview.title,
            textAlign: TextAlign.center,
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontFamily: 'Cairo',
                color: isDark ? Colors.white : Colors.black87)),
        content: SingleChildScrollView(child: content),
        actions: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _sendReport(type);
                  },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: type == 'تنبيه حرج'
                          ? const Color(0xFFEF4444)
                          : const Color(0xFF0EA5E9),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12))),
                  child: const Text('إرسال الآن',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Cairo')),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _generatePDF(type);
                  },
                  style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF0EA5E9)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12))),
                  child: const Text('تحميل PDF',
                      style: TextStyle(
                          color: Color(0xFF0EA5E9),
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Cairo')),
                ),
                const SizedBox(height: 4),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('إلغاء',
                      style: TextStyle(
                          color:
                              isDark ? Colors.white38 : const Color(0xFF64748B),
                          fontFamily: 'Cairo')),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _previewRow(String label, String value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(value,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isDark
                      ? const Color(0xFF38BDF8)
                      : const Color(0xFF0EA5E9))),
          Text(label,
              style: TextStyle(
                  color: isDark ? Colors.white60 : const Color(0xFF64748B))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                _buildHero(),
                const SizedBox(height: 10),
                _buildQuickSendCard(),
                const SizedBox(height: 10),
                _buildCriticalNotif(),
                const SizedBox(height: 10),
                _buildReportTypes(),
                const SizedBox(height: 10),
                _buildRecipients(),
                const SizedBox(height: 10),
                _buildScheduleSettings(),
                const SizedBox(height: 10),
                _buildReportCompleteness(),
                const SizedBox(height: 10),
                _buildMedicationAdherence(),
                const SizedBox(height: 10),
                _buildSentHistory(),
                const SizedBox(height: 20),
                const SizedBox(height: 100), // Space for parent's bottom nav
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHero() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0369A1), Color(0xFF0EA5E9), Color(0xFF06B6D4)],
        ),
      ),
      child: Stack(
        children: [
          const HealingParticles(), // الأنيميشن الموحد
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '📤 التقارير والإرسال',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${ref.read(appRiverpod).currentAccount?.name ?? 'الممرض'} — ${_getShiftName()}',
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 11, vertical: 4),
                      decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(20)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          FadeTransition(
                            opacity: Tween<double>(begin: 0.15, end: 1.0)
                                .animate(_blinkController),
                            child: Container(
                              width: 7,
                              height: 7,
                              decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Color(0xFF4ADE80)),
                            ),
                          ),
                          const SizedBox(width: 5),
                          const Text('إرسال تلقائي يومي ٨:٠٠ ص — مفعّل',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickSendCard() {
    return AnimatedBuilder(
      animation: _floatController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, -3 * _floatController.value),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0369A1), Color(0xFF0EA5E9)],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Stack(
                children: [
                  Positioned(
                    right: -34,
                    top: -34,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('التقرير اليومي جاهز',
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white.withValues(alpha: 0.8))),
                          AnimatedBuilder(
                            animation: _pulseController,
                            builder: (context, child) {
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 9, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF10B981).withValues(
                                          alpha: 0.4 * _pulseController.value),
                                      blurRadius: 7 * _pulseController.value,
                                      spreadRadius: 2 * _pulseController.value,
                                    )
                                  ],
                                ),
                                child: const Row(
                                  children: [
                                    Text('✓',
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold)),
                                    SizedBox(width: 4),
                                    Text('آخر إرسال ٨:٠٠ ص',
                                        style: TextStyle(
                                            color: Colors.white, fontSize: 12)),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      const Text('تقرير الوردية الصباحية',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                      const SizedBox(height: 2),
                      Builder(builder: (context) {
                        final p = ref.read(appRiverpod);
                        final totalMeds = p.medications.length;
                        final takenMeds =
                            p.medications.where((m) => m.isTaken).length;
                        final adherencePct = totalMeds > 0
                            ? (takenMeds * 100 ~/ totalMeds)
                            : 0;
                        final criticalCount = p.residentFiles
                            .where((r) => r.status == 'critical')
                            .length;
                        return Text(
                          '${p.residentFiles.length} مقيم · $criticalCount حالة حرجة · $adherencePct٪ التزام بالأدوية',
                          style: TextStyle(
                              fontSize: 13,
                              color: Colors.white.withValues(alpha: 0.9)),
                        );
                      }),
                      const SizedBox(height: 11),
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => _showPreviewDialog('التقرير اليومي'),
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.remove_red_eye_outlined,
                                        color: Color(0xFF0369A1), size: 14),
                                    SizedBox(width: 5),
                                    Text('معاينة',
                                        style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF0369A1))),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => _sendReport('التقرير اليومي'),
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.send_rounded,
                                        color: Colors.white, size: 13),
                                    SizedBox(width: 5),
                                    Text('إرسال الآن',
                                        style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white)),
                                  ],
                                ),
                              ),
                            ),
                          )
                        ],
                      )
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCriticalNotif() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
              colors: [Color(0xFFEF4444), Color(0xFFF87171)]),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            FadeTransition(
              opacity: Tween<double>(begin: 0.15, end: 1.0)
                  .animate(_blinkController),
              child: const Text('🚨', style: TextStyle(fontSize: 20)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Builder(builder: (_) {
                final provider = ref.read(appRiverpod);
                final critical = provider.residentFiles
                    .where((f) => f.status == 'critical')
                    .toList();
                final name = critical.isNotEmpty
                    ? critical.first.name
                    : 'مقيم بحالة حرجة';
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('إرسال تنبيه حرج — $name',
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
                    const SizedBox(height: 1),
                    const Text('تنبيه فوري للطبيب والإدارة',
                        style: TextStyle(fontSize: 12, color: Colors.white)),
                  ],
                );
              }),
            ),
            GestureDetector(
              onTap: () => _sendReport('التنبيه الحرج'),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('إرسال',
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, Color dotColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(title,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFF38BDF8)
                      : const Color(0xFF0369A1))),
        ],
      ),
    );
  }

  Widget _buildReportTypes() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        children: [
          _sectionHeader('نوع التقرير', const Color(0xFF0EA5E9)),
          Row(
            children: [
              Expanded(
                  child: _rTypeCard('📋', 'تقرير يومي', 'ملخص كامل للوردية',
                      _selectedType == 'تقرير يومي', () {
                setState(() => _selectedType = 'تقرير يومي');
                _showPreviewDialog('تقرير يومي');
              })),
              const SizedBox(width: 8),
              Expanded(
                  child: _rTypeCard('📊', 'تقرير أسبوعي', 'اتجاهات ومقارنات',
                      _selectedType == 'تقرير أسبوعي', () {
                setState(() => _selectedType = 'تقرير أسبوعي');
                _showPreviewDialog('تقرير أسبوعي');
              })),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                  child: _rTypeCard('🚨', 'تنبيه حرج', 'إرسال فوري للحالات',
                      _selectedType == 'تنبيه حرج', () {
                setState(() => _selectedType = 'تنبيه حرج');
                _showPreviewDialog('تنبيه حرج');
              })),
              const SizedBox(width: 8),
              Expanded(
                  child: _rTypeCard('💊', 'تقرير أدوية', 'الالتزام والجرعات',
                      _selectedType == 'تقرير أدوية', () {
                setState(() => _selectedType = 'تقرير أدوية');
                _showPreviewDialog('تقرير أدوية');
              })),
            ],
          )
        ],
      ),
    );
  }

  Widget _rTypeCard(
      String icon, String title, String desc, bool active, VoidCallback onTap) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          gradient: active
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF0EA5E9), Color(0xFF0284C7)],
                )
              : null,
          boxShadow: [
            BoxShadow(
              color: active
                  ? const Color(0xFF0EA5E9).withValues(alpha: 0.3)
                  : Colors.black.withValues(alpha: 0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
              color: active
                  ? Colors.transparent
                  : (isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
              width: 1.5),
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: active
                        ? Colors.white.withValues(alpha: 0.2)
                        : (isDark ? Colors.white10 : const Color(0xFFF0F9FF)),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(icon, style: const TextStyle(fontSize: 20)),
                ),
                const SizedBox(height: 12),
                Text(title,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: active
                            ? Colors.white
                            : (isDark
                                ? Colors.white
                                : const Color(0xFF0F172A)))),
                const SizedBox(height: 4),
                Text(desc,
                    style: TextStyle(
                        fontSize: 11,
                        color: active
                            ? Colors.white.withValues(alpha: 0.8)
                            : (isDark
                                ? Colors.white70
                                : const Color(0xFF475569)))),
              ],
            ),
            if (active)
              Positioned(
                left: 0,
                top: 0,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                      child: Icon(Icons.check,
                          size: 12, color: Color(0xFF0EA5E9))),
                ),
              )
          ],
        ),
      ),
    );
  }

  Widget _buildRecipients() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
              color: isDark ? Colors.white12 : const Color(0xFFE0F2FE),
              width: 1.5),
        ),
        child: Column(
          children: [
            _sectionHeader('المستلمون', const Color(0xFF7C3AED)),
            _recRow('د.أ', const Color(0xFFDBEAFE), const Color(0xFF1E40AF),
                'د. أحمد — الطبيب المشرف', 'يستلم: الحرجة + اليومي', 'د. أحمد'),
            Divider(
                color: isDark ? Colors.white10 : const Color(0xFFF0F9FF),
                height: 12),
            _recRow('إد', const Color(0xFFEDE9FE), const Color(0xFF4C1D95),
                'الإدارة العامة', 'يستلم: الأسبوعي فقط', 'الإدارة'),
            Divider(
                color: isDark ? Colors.white10 : const Color(0xFFF0F9FF),
                height: 12),
            _recRow('أس', const Color(0xFFD1FAE5), const Color(0xFF065F46),
                'الأخصائي الاجتماعي', 'يستلم: الحرجة النفسية', 'الأخصائي'),
            Divider(
                color: isDark ? Colors.white10 : const Color(0xFFF0F9FF),
                height: 12),
            _recRow('أس', const Color(0xFFFEF3C7), const Color(0xFF92400E),
                'أسر المقيمين', 'يستلمون: التقرير الأسبوعي', 'الأسر'),
          ],
        ),
      ),
    );
  }

  Widget _recRow(
      String av, Color bg, Color fg, String n, String r, String key) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    bool isOn = _activeRecipients[key] ?? false;
    return Row(
      children: [
        CircleAvatar(
          radius: 17,
          backgroundColor: isDark ? bg.withValues(alpha: 0.2) : bg,
          child: Text(av,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isDark ? fg.withValues(alpha: 0.8) : fg)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(n,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF0F172A))),
              const SizedBox(height: 1),
              Text(r,
                  style: TextStyle(
                      fontSize: 12,
                      color:
                          isDark ? Colors.white70 : const Color(0xFF475569))),
            ],
          ),
        ),
        _toggle(isOn, () {
          setState(() {
            _activeRecipients[key] = !isOn;
          });
          _saveBackendReportSettings();
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(isOn
                ? 'تم إيقاف الإرسال لـ $key 🛑'
                : 'تم تفعيل الإرسال لـ $key'),
            duration: const Duration(seconds: 1),
          ));
        }),
      ],
    );
  }

  Widget _toggle(bool on, VoidCallback onTap) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 20,
        decoration: BoxDecoration(
          color: on
              ? const Color(0xFF0EA5E9)
              : (isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Stack(
          children: [
            AnimatedPositioned(
              duration: const Duration(milliseconds: 200),
              curve: Curves.ease,
              top: 2,
              left: on ? 18 : 2,
              child: Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                    color: isDark
                        ? (on ? Colors.white : Colors.white38)
                        : Colors.white,
                    shape: BoxShape.circle),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleSettings() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
              color: isDark ? Colors.white12 : const Color(0xFFE0F2FE),
              width: 1.5),
        ),
        child: Column(
          children: [
            _sectionHeader('إعدادات الجدول التلقائي', const Color(0xFF10B981)),
            _schRowVal(
                'التقرير اليومي', 'يُرسل تلقائياً نهاية الوردية', _dailyTime,
                () async {
              final picked = await showTimePicker(
                  context: context, initialTime: TimeOfDay.now());
              if (picked != null) {
                setState(() {
                  _dailyTime =
                      '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
                });
                await _saveBackendReportSettings();
              }
            }),
            Divider(
                color: isDark ? Colors.white10 : const Color(0xFFF0F9FF),
                height: 14),
            _schRowVal('التقرير الأسبوعي', 'كل جمعة تلقائياً', _weeklyDay, () {
              _showDayPicker();
            }),
            Divider(
                color: isDark ? Colors.white10 : const Color(0xFFF0F9FF),
                height: 14),
            _schRowTog('تنبيه القراءات الحرجة', 'إرسال فوري عند تجاوز الحد',
                _isCriticalAlertOn, (val) {
              setState(() => _isCriticalAlertOn = val);
              _saveBackendReportSettings();
            }),
            Divider(
                color: isDark ? Colors.white10 : const Color(0xFFF0F9FF),
                height: 14),
            _schRowTog('تنبيه الدواء الفائت', 'بعد ٣٠ دقيقة من الموعد',
                _isMissedMedAlertOn, (val) {
              setState(() => _isMissedMedAlertOn = val);
              _saveBackendReportSettings();
            }),
          ],
        ),
      ),
    );
  }

  void _showDayPicker() {
    final days = [
      'السبت',
      'الأحد',
      'الاثنين',
      'الثلاثاء',
      'الأربعاء',
      'الخميس',
      'الجمعة'
    ];
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('اختر يوم التقرير الأسبوعي',
            style: TextStyle(fontFamily: 'Cairo', fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: days
              .map((d) => ListTile(
                    title: Text(d,
                        textAlign: TextAlign.right,
                        style: const TextStyle(fontFamily: 'Cairo')),
                    onTap: () {
                      setState(() => _weeklyDay = d);
                      Navigator.pop(context);
                      _saveBackendReportSettings();
                    },
                  ))
              .toList(),
        ),
      ),
    );
  }

  Widget _schRowVal(String lbl, String sub, String val, VoidCallback onTap) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(lbl,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF0F172A))),
              const SizedBox(height: 1),
              Text(sub,
                  style:
                      const TextStyle(fontSize: 12, color: Color(0xFF475569))),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : const Color(0xFFF0F9FF),
                borderRadius: BorderRadius.circular(8)),
            child: Text(val,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0369A1))),
          )
        ],
      ),
    );
  }

  Widget _schRowTog(String lbl, String sub, bool on, Function(bool) onChanged) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(lbl,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF0F172A))),
            const SizedBox(height: 1),
            Text(sub,
                style: const TextStyle(fontSize: 12, color: Color(0xFF475569))),
          ],
        ),
        Row(
          children: [
            GestureDetector(
              onTap: () => onChanged(!on),
              child: Container(
                width: 32,
                height: 18,
                decoration: BoxDecoration(
                    color: on
                        ? const Color(0xFF0EA5E9)
                        : (isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
                    borderRadius: BorderRadius.circular(9)),
                child: Stack(
                  children: [
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 200),
                      top: 2,
                      left: on ? 14 : 2,
                      child: Container(
                          width: 14,
                          height: 14,
                          decoration: const BoxDecoration(
                              shape: BoxShape.circle, color: Colors.white)),
                    )
                  ],
                ),
              ),
            ),
            const SizedBox(width: 6),
            Text(on ? 'مفعّل' : 'معطّل',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: on
                        ? (isDark
                            ? const Color(0xFF38BDF8)
                            : const Color(0xFF0369A1))
                        : (isDark ? Colors.white38 : const Color(0xFF64748B)))),
          ],
        )
      ],
    );
  }

  Widget _buildReportCompleteness() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final items = _reportCompleteness;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
              color: isDark ? Colors.white12 : const Color(0xFFE0F2FE),
              width: 1.5),
        ),
        child: Column(
          children: [
            _sectionHeader('اكتمال التقرير اليومي', const Color(0xFF0EA5E9)),
            const SizedBox(height: 4),
            if (_isLoadingBackendReports && items.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: CircularProgressIndicator(
                  color: Color(0xFF0EA5E9),
                  strokeWidth: 2,
                ),
              )
            else if (items.isEmpty) ...[
              _progRow(
                  'القراءات الحيوية', '٠٪', 0, const Color(0xFF0EA5E9), 900),
              const SizedBox(height: 9),
              _progRow('تأكيد الأدوية', '٠٪', 0, const Color(0xFF10B981), 1500),
              const SizedBox(height: 9),
              _progRow(
                  'ملاحظات الممرضة', '٠٪', 0, const Color(0xFFF59E0B), 1600),
            ] else
              ...items.asMap().entries.expand((entry) {
                final colors = [
                  const Color(0xFF0EA5E9),
                  const Color(0xFF10B981),
                  const Color(0xFFF59E0B),
                ];
                final item = entry.value;
                return [
                  _progRow(
                    item.title,
                    item.value,
                    item.percentage.clamp(0.0, 1.0).toDouble(),
                    colors[entry.key % colors.length],
                    900 + (entry.key * 250),
                  ),
                  const SizedBox(height: 9),
                ];
              }),
            const SizedBox(height: 7),
            const Text('أكمل الملاحظات الناقصة قبل إرسال التقرير',
                style: TextStyle(fontSize: 12, color: Color(0xFF475569))),
          ],
        ),
      ),
    );
  }

  Widget _progRow(String title, String val, double pct, Color c, int delay) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF0F172A))),
            Text(val,
                style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.bold, color: c)),
          ],
        ),
        const SizedBox(height: 5),
        Container(
          height: 7,
          decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(6)),
          child: Align(
            alignment: Alignment.centerRight,
            child: TweenAnimationBuilder(
              duration: const Duration(seconds: 1),
              tween: Tween<double>(begin: 0, end: pct),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return FractionallySizedBox(
                  widthFactor: value,
                  child: Container(
                    decoration: BoxDecoration(
                      color: c,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                );
              },
            ),
          ),
        )
      ],
    );
  }

  Widget _buildMedicationAdherence() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final report = _adherenceReport;
    final pct = ((report?.facilityAdherence.percentage ?? 0) / 100)
        .clamp(0.0, 1.0)
        .toDouble();
    final residents = (report?.residents ?? const [])
        .where((resident) => resident.totalDoses > 0)
        .take(3)
        .toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
              color: isDark ? Colors.white12 : const Color(0xFFE0F2FE),
              width: 1.5),
        ),
        child: Column(
          children: [
            _sectionHeader('تقرير الالتزام الدوائي', const Color(0xFF10B981)),
            if (_isLoadingBackendReports && report == null)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: CircularProgressIndicator(
                  color: Color(0xFF10B981),
                  strokeWidth: 2,
                ),
              )
            else ...[
              _progRow(
                'التزام المنشأة',
                '${(report?.facilityAdherence.percentage ?? 0).toStringAsFixed(0)}٪',
                pct,
                const Color(0xFF10B981),
                1200,
              ),
              const SizedBox(height: 10),
              if (residents.isEmpty)
                const Text(
                  'لا توجد جرعات مسجلة في فترة التقرير بعد',
                  style: TextStyle(fontSize: 12, color: Color(0xFF475569)),
                )
              else
                ...residents.map((resident) {
                  final name = resident.residentName.isEmpty
                      ? 'مقيم ${resident.roomNumber}'
                      : resident.residentName;
                  return Padding(
                    padding: const EdgeInsets.only(top: 7),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${resident.givenDoses}/${resident.totalDoses} جرعات',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF475569),
                          ),
                        ),
                        Text(
                          '$name · ${resident.percentage.toStringAsFixed(0)}٪',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color:
                                isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSentHistory() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = ref.watch(appRiverpod);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        children: [
          _sectionHeader('سجل الإرسال', const Color(0xFF10B981)),
          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                  color: isDark ? Colors.white12 : const Color(0xFFE0F2FE),
                  width: 1.5),
            ),
            child: Column(
              children: provider.sentReports.map((report) {
                Color bg = isDark
                    ? const Color(0xFF065F46).withValues(alpha: 0.2)
                    : const Color(0xFFD1FAE5);
                Color fg = const Color(0xFF10B981);

                if (report.status == 'مجدول') {
                  bg = isDark
                      ? const Color(0xFF78350F).withValues(alpha: 0.2)
                      : const Color(0xFFFEF3C7);
                  fg = const Color(0xFFF59E0B);
                }

                return Column(
                  children: [
                    _histRow(report.icon, bg, report.title, report.meta,
                        report.status, bg, fg),
                    if (report != provider.sentReports.last)
                      Divider(
                          color:
                              isDark ? Colors.white10 : const Color(0xFFF0F9FF),
                          height: 1),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _histRow(String icon, Color iconBg, String title, String meta,
      String stLabel, Color stBg, Color stFg) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
                color: iconBg, borderRadius: BorderRadius.circular(10)),
            child:
                Center(child: Text(icon, style: const TextStyle(fontSize: 15))),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color:
                            isDark ? Colors.white : const Color(0xFF0F172A))),
                const SizedBox(height: 2),
                Text(meta,
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFF475569))),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
                color: stBg, borderRadius: BorderRadius.circular(8)),
            child: Text(stLabel,
                style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.bold, color: stFg)),
          )
        ],
      ),
    );
  }
}
