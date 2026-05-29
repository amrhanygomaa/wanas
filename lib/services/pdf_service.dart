import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw; // مكتبة تصميم صفحات PDF
import 'package:printing/printing.dart'; // مكتبة الطباعة ومعاينة الملفات
import '../models/app_models.dart'; // استيراد نماذج البيانات

class PdfService {
  // دالة لإنشاء تقرير التقييم وتحويله لملف PDF
  static Future<void> generateAssessmentReport(
    SocialSpecialistResidentScore resident, // بيانات المقيم
    SocialSpecialistAssessmentTool tool, // أداة التقييم المستخدمة
    Map<int, int> answers, // إجابات المستخدم
    List<AssessmentQuestion> questions, // قائمة الأسئلة
  ) async {
    final pdf = pw.Document(); // إنشاء مستند PDF جديد

    // تحميل الخط العربي (Cairo) لدعم اللغة العربية في الملف
    final font = await PdfGoogleFonts.cairoRegular();
    final boldFont = await PdfGoogleFonts.cairoBold();

    // إضافة صفحة جديدة للملف
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4, // قياس الصفحة A4
        theme:
            pw.ThemeData.withFont(base: font, bold: boldFont), // تعيين الخطوط
        build: (pw.Context context) {
          return pw.Directionality(
            textDirection:
                pw.TextDirection.rtl, // تحديد اتجاه النص من اليمين لليسار
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // ترويسة التقرير (Header)
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('طبـطبـة - نظام رعاية المسنين',
                        style: const pw.TextStyle(
                            fontSize: 10, color: PdfColors.grey700)),
                    pw.Text('تقرير تقييم دوري',
                        style: const pw.TextStyle(
                            fontSize: 10, color: PdfColors.grey700)),
                  ],
                ),
                pw.SizedBox(height: 20),
                pw.Divider(), // خط فاصل
                pw.SizedBox(height: 10),

                // بيانات المقيم (Resident Info)
                pw.Text('بيانات المقيم',
                    style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blue800)),
                pw.SizedBox(height: 10),
                pw.Row(
                  children: [
                    pw.Expanded(child: pw.Text('الاسم: ${resident.name}')),
                    pw.Expanded(child: pw.Text('الغرفة: ${resident.room}')),
                  ],
                ),
                pw.SizedBox(height: 5),
                pw.Text(
                    'تاريخ التقييم: ${DateTime.now().toString().split(' ')[0]}'),
                pw.SizedBox(height: 20),

                // نتائج التقييم (Assessment Results)
                pw.Text('نتائج التقييم: ${tool.name}',
                    style: pw.TextStyle(
                        fontSize: 16, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 10),

                // الملخص التنفيذي (Summary Box)
                pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  decoration: const pw.BoxDecoration(
                    color: PdfColors.grey100,
                    borderRadius: pw.BorderRadius.all(pw.Radius.circular(8)),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('الملخص التنفيذي:',
                          style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.blue800)),
                      pw.SizedBox(height: 8),
                      pw.Text(
                          'تم إجراء التقييم بنجاح. حالة المقيم الحالية: ${resident.healthStatus == 'critical' ? 'حرجة' : resident.healthStatus == 'monitoring' ? 'تحتاج متابعة' : 'مستقرة'}.',
                          style: const pw.TextStyle(fontSize: 11)),
                    ],
                  ),
                ),
                pw.SizedBox(height: 20),

                // تفاصيل الأسئلة والإجابات (Detailed Questions)
                pw.Text('التفاصيل:',
                    style: pw.TextStyle(
                        fontSize: 14, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 10),

                // عرض كل سؤال مع الإجابة المختارة
                ...questions.asMap().entries.map((entry) {
                  final idx = entry.key; // رقم السؤال
                  final q = entry.value; // بيانات السؤال
                  final answerIdx = answers[idx] ?? -1; // فهرس الإجابة
                  final answerText = (q.options != null &&
                          answerIdx != -1 &&
                          answerIdx < q.options!.length)
                      ? q.options![answerIdx]
                      : 'لم تتم الإجابة';

                  return pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 8),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('${idx + 1}. ${q.text}',
                            style: pw.TextStyle(
                                fontSize: 12,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.grey900)),
                        pw.Padding(
                          padding: const pw.EdgeInsets.only(right: 10, top: 4),
                          child: pw.Text('• الإجابة: $answerText',
                              style: const pw.TextStyle(
                                  fontSize: 10, color: PdfColors.grey700)),
                        ),
                      ],
                    ),
                  );
                }),

                pw.Spacer(), // مساحة فارغة لدفع التوقيع للأسفل
                pw.Divider(),
                // خانة التوقيع والختم
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('توقيع الأخصائي المسؤول: ________________'),
                    pw.Text('ختم الدار: ________________'),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );

    // فتح واجهة الطباعة أو معاينة الملف للمستخدم
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'تقرير_${resident.name}_${tool.name}.pdf', // اسم الملف عند الحفظ
    );
  }
}
