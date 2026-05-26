import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/app_riverpod.dart';

class AdminReportsView extends ConsumerWidget {
  final List<Animation<double>> fadeAnimations;

  const AdminReportsView({super.key, required this.fadeAnimations});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = ref.watch(appRiverpod);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              _buildFinancialReportCard(context, provider),
              const SizedBox(height: 20),
              _buildSafetyReportCard(provider),
              const SizedBox(height: 20),
              _buildExportSection(context, provider),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    final now = DateTime.now();
    final timeStr = "${now.hour}:${now.minute.toString().padLeft(2, '0')}";
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('تقارير الأداء المركزية',
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0f172a))),
        const SizedBox(height: 4),
        Text('محدث بتاريخ اليوم الساعة $timeStr',
            style: TextStyle(
                fontSize: 12,
                color: const Color(0xFF64748b).withValues(alpha: 0.8))),
      ],
    );
  }

  Widget _buildFinancialReportCard(BuildContext context, AppRiverpod provider) {
    final compliance = (provider.medicationComplianceRate * 100).toInt();
    return GestureDetector(
      onTap: () => _showDetailedFinancialReport(context, provider),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFf1f5f9))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('الأداء التشغيلي والمالي',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1e293b))),
                // Icon(Icons.more_horiz, color: Color(0xFF94a3b8)), // Removed as requested
              ],
            ),
            const SizedBox(height: 24),
            _buildChartMockup(Colors.blue),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _statMini('$compliance%', 'التزام دوائي'),
                _statMini(
                    '${(provider.occupancyRate * 100).toInt()}%', 'نسبة الإشغال'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showDetailedFinancialReport(BuildContext context, AppRiverpod provider) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, anim1, anim2) => const SizedBox(),
      transitionBuilder: (context, anim1, anim2, child) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: anim1, curve: Curves.elasticOut),
          child: AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            content: Directionality(
              textDirection: TextDirection.rtl,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.1),
                        shape: BoxShape.circle),
                    child: const Icon(Icons.analytics_rounded,
                        color: Colors.blue, size: 40),
                  ),
                  const SizedBox(height: 20),
                  const Text('تفاصيل الأداء المالي والتشغيلي',
                      textAlign: TextAlign.center,
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  _detailRow('صافي الإيرادات', '٤٥,٠٠٠ ج.م', Colors.green),
                  _detailRow('مصروفات التشغيل', '١٢,٥٠٠ ج.م', Colors.red),
                  _detailRow('الأرباح المتوقعة', '٣٢,٥٠٠ ج.م', Colors.blue),
                  const Divider(height: 32),
                  const Text(
                    'ملاحظة: هذا التقرير مبني على البيانات المسجلة خلال الشهر الحالي فقط.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11, color: Color(0xFF64748b)),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('إغلاق',
                          style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _detailRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Color(0xFF64748b))),
          Text(value,
              style: TextStyle(
                  color: color, fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildSafetyReportCard(AppRiverpod provider) {
    final unresolved = provider.unresolvedComplaintsCount;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: const Color(0xFFfef2f2), borderRadius: BorderRadius.circular(24), border: Border.all(color: const Color(0xFFfee2e2))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('تقرير جودة الرعاية',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF991b1b))),
              Icon(Icons.warning_amber_rounded,
                  color: Color(0xFFef4444), size: 18),
            ],
          ),
          const SizedBox(height: 16),
          _buildSafetyRow('شكاوى قيد المتابعة', unresolved.toString().padLeft(2, '٠'), Colors.red),
          _buildSafetyRow('إجمالي المقيمين', provider.residentFiles.length.toString().padLeft(2, '٠'), Colors.green),
          _buildSafetyRow('أعضاء الطاقم النشط', provider.activeStaffCount.toString().padLeft(2, '٠'), Colors.blue),
        ],
      ),
    );
  }

  Widget _buildSafetyRow(String label, String val, Color c) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Text(label,
              style: const TextStyle(fontSize: 12, color: Color(0xFF7f1d1d))),
          const Spacer(),
          Text(val,
              style: TextStyle(
                  color: c, fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildChartMockup(Color color) {
    return Column(
      children: [
        const SizedBox(height: 10),
        Container(
          height: 160, // Increased height to accommodate labels
          width: double.infinity,
          padding: const EdgeInsets.only(left: 30, right: 30, bottom: 40, top: 10),
          child: CustomPaint(
            painter: LineChartPainter(color),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.trending_up_rounded, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              'مؤشر النمو التشغيلي (آخر ٦ أشهر)',
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
      ],
    );
  }

  static Widget _statMini(String val, String label) {
    return Column(
      children: [
        Text(val, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1e293b))),
        Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF64748b))),
      ],
    );
  }

  Widget _buildExportSection(BuildContext context, AppRiverpod provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('تصدير البيانات والتحاليل', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1e293b))),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _exportBtn(context, 'Excel', 'Excel', Icons.table_chart_outlined, Colors.green, provider)),
            const SizedBox(width: 12),
            Expanded(child: _exportBtn(context, 'PDF', 'PDF Report', Icons.picture_as_pdf_outlined, Colors.red, provider)),
          ],
        ),
      ],
    );
  }

  Widget _exportBtn(BuildContext context, String format, String label, IconData icon, Color c, AppRiverpod provider) {
    return InkWell(
      onTap: () => _showExportDialog(context, provider, format),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: c.withValues(alpha: 0.2))),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: c, size: 18),
            const SizedBox(width: 8),
            Text(label,
                style: TextStyle(
                    color: c, fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  void _showExportDialog(
      BuildContext context, AppRiverpod provider, String format) {
    final summary = provider.generatePerformanceSummary();
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      transitionDuration: const Duration(milliseconds: 500),
      pageBuilder: (context, anim1, anim2) => const SizedBox(),
      transitionBuilder: (context, anim1, anim2, child) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: anim1, curve: Curves.elasticOut),
          child: AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text('تصدير تقرير $format',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                Icon(
                    format == 'Excel'
                        ? Icons.table_chart_rounded
                        : Icons.picture_as_pdf_rounded,
                    color: format == 'Excel' ? Colors.green : Colors.red),
              ],
            ),
            content: Directionality(
              textDirection: TextDirection.rtl,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                        color: const Color(0xFFf8fafc),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFe2e8f0))),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('معاينة البيانات:',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF64748b))),
                        const SizedBox(height: 8),
                        Text(summary,
                            style: const TextStyle(
                                fontSize: 11, height: 1.6, color: Color(0xFF1e293b))),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text('سيتم إنشاء الملف بتصميم احترافي يشمل شعار المنشأة.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0369a1))),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('إلغاء',
                    style: TextStyle(color: Color(0xFF64748b))),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Row(
                          children: [
                            const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white)),
                            const SizedBox(width: 12),
                            Text('جاري تجهيز تقرير $format...'),
                          ],
                        ),
                        backgroundColor: const Color(0xFF0369a1)),
                  );

                  final fileName = await provider.exportReport(
                      format.toLowerCase() == 'excel' ? 'csv' : 'pdf');

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('تم تصدير الملف بنجاح: $fileName'),
                        backgroundColor: Colors.green,
                        duration: const Duration(seconds: 4),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0369a1),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12))),
                child: const Text('تأكيد وتحميل',
                    style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );
      },
    );
  }
}

class LineChartPainter extends CustomPainter {
  final Color color;
  LineChartPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF94a3b8).withValues(alpha: 0.8)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    final arrowSize = 7.0;

    // Draw Y Axis
    canvas.drawLine(Offset(0, size.height), const Offset(0, 0), paint);
    // Y Arrow
    final yArrowPath = Path()
      ..moveTo(-arrowSize, arrowSize)
      ..lineTo(0, 0)
      ..lineTo(arrowSize, arrowSize);
    canvas.drawPath(yArrowPath, paint);

    // Draw X Axis
    canvas.drawLine(
        Offset(0, size.height), Offset(size.width, size.height), paint);
    // X Arrow
    final xArrowPath = Path()
      ..moveTo(size.width - arrowSize, size.height - arrowSize)
      ..lineTo(size.width, size.height)
      ..lineTo(size.width - arrowSize, size.height + arrowSize);
    canvas.drawPath(xArrowPath, paint);

    // Labels X
    final textPainter = TextPainter(textDirection: TextDirection.rtl);
    final months = ['يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو'];
    final segmentWidth = size.width / (months.length - 1);
    
    for (int i = 0; i < months.length; i++) {
      textPainter.text = TextSpan(
        text: months[i],
        style: const TextStyle(
            color: Color(0xFF64748b),
            fontSize: 9,
            fontWeight: FontWeight.bold),
      );
      textPainter.layout();
      // Center the text under the point
      textPainter.paint(
          canvas, Offset((segmentWidth * i) - (textPainter.width / 2), size.height + 12));
    }

    // Draw Shadow Line (Glow)
    final shadowPaint = Paint()
      ..color = color.withValues(alpha: 0.2)
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    final path = Path();
    final points = [
      Offset(0, size.height * 0.8),
      Offset(size.width * 0.2, size.height * 0.7),
      Offset(size.width * 0.4, size.height * 0.75),
      Offset(size.width * 0.6, size.height * 0.4),
      Offset(size.width * 0.8, size.height * 0.3),
      Offset(size.width, size.height * 0.2),
    ];

    path.moveTo(points[0].dx, points[0].dy);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }

    canvas.drawPath(path, shadowPaint);

    // Draw Data Line (Bolder)
    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 4.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawPath(path, linePaint);

    // Draw dots
    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    for (var p in points) {
      canvas.drawCircle(p, 4, dotPaint);
      canvas.drawCircle(
          p,
          6,
          Paint()
            ..color = color.withValues(alpha: 0.2)
            ..style = PaintingStyle.fill);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
