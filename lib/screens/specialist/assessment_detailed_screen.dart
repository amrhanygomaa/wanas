// ignore_for_file: unused_element
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/app_riverpod.dart'; // مزود الحالة العام
import '../../models/app_models.dart'; // نماذج البيانات
import '../../services/pdf_service.dart'; // خدمة إنشاء ملفات PDF
import 'package:lottie/lottie.dart';

// شاشة التقييم الاجتماعي التفصيلي للمقيم - تسمح للأخصائي بإجراء التقييمات وحفظ النتائج
class AssessmentDetailedScreen extends ConsumerStatefulWidget {
  final SocialSpecialistAssessmentTool?
      tool; // أداة التقييم المختارة (نفسي، اجتماعي، إلخ)
  final SocialSpecialistResidentScore
      resident; // بيانات المقيم المستهدف بالتقييم
  final List<AssessmentQuestion>? initialQuestions; // الأسئلة المختارة مسبقاً
  const AssessmentDetailedScreen(
      {super.key, this.tool, required this.resident, this.initialQuestions});

  @override
  ConsumerState<AssessmentDetailedScreen> createState() =>
      _AssessmentDetailedScreenState();
}

class _AssessmentDetailedScreenState
    extends ConsumerState<AssessmentDetailedScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController; // متحكم حركات الظهور
  late AnimationController _ringController; // متحكم حركات الحلقات
  late AnimationController _shimmerController; // متحكم حركة اللمعان
  late List<Animation<double>> _fadeAnimations; // قائمة الحركات المتسلسلة
  int _currentToolIndex = 0; // الفهرس الحالي للأداة
  int _questionIndex = 0; // الفهرس الحالي للسؤال
  final Map<int, int> _selections = {}; // تخزين الإجابات المختارة
  final Map<int, int> _scales = {}; // تخزين إجابات المقاييس الرقمية
  final Set<String> _activeNotes = {}; // تخزين الملاحظات المفعلة
  late List<AssessmentQuestion> _questions; // قائمة الأسئلة الحالية
  final TextEditingController _notesController = TextEditingController(
      text: 'المقيم يُبدي علامات قلق متزايدة مؤخراً...'); // متحكم نص الملاحظات
  bool _isInterventionRequired = false; // حالة التدخل الاجتماعي

  @override
  void initState() {
    super.initState();

    // تحميل الأسئلة ديناميكياً بناءً على نوع التقييم أو استخدام الأسئلة الممررة
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.initialQuestions != null) {
        setState(() {
          _questions = widget.initialQuestions!;
        });
      } else {
        final provider = ref.read(appRiverpod);
        final rawQuestions =
            provider.getQuestionsForTool(widget.tool?.id ?? 't1');
        setState(() {
          _questions = rawQuestions.isEmpty
              ? [
                  AssessmentQuestion(
                      id: 'empty',
                      text: 'لا توجد أسئلة مهيأة لهذه الأداة حالياً',
                      type: 'text')
                ]
              : rawQuestions.asMap().entries.map((e) {
                  final i = e.key;
                  final q = e.value;
                  return AssessmentQuestion(
                    id: 'q$i',
                    text: q['text'],
                    type: q['type'],
                    options: q['options'] != null
                        ? List<String>.from(q['options'])
                        : null,
                  );
                }).toList();
        });
      }
    });

    // حالة افتراضية للأسئلة أثناء التحميل
    _questions = [
      AssessmentQuestion(id: 'ld', text: 'جاري تحميل الأسئلة...', type: 'text')
    ];

    // إعداد الـ Animations
    _fadeController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1000));
    _ringController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200));
    _shimmerController =
        AnimationController(vsync: this, duration: const Duration(seconds: 2))
          ..repeat();

    _fadeAnimations = List.generate(12, (index) {
      return Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
            parent: _fadeController,
            curve: Interval(index * 0.05, 1.0, curve: Curves.easeOut)),
      );
    });

    _fadeController.forward();
    _ringController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _ringController.dispose();
    _shimmerController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = ref.watch(appRiverpod);

    return Scaffold(
      backgroundColor: const Color(0xFFfff7ed),
      body: Column(
        children: [
          _buildHero(provider), // الواجهة العلوية (اسم المقيم)
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  _buildScoreOverview(), // ملخص الدرجات والتقدم
                  const SizedBox(height: 12),
                  _buildQuestionnaire(provider), // منطقة الأسئلة والتقرير
                  const SizedBox(height: 24),
                  _buildHistoryComparison(
                      provider), // مقارنة مع التقييمات السابقة
                  const SizedBox(height: 24),
                  _buildSpecialistNotes(), // حقل ملاحظات الأخصائي
                  const SizedBox(height: 24),
                  _buildInterventionToggle(), // تفعيل طلب التدخل
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
          _buildActionBar(), // شريط الأزرار السفلي (حفظ)
        ],
      ),
    );
  }

  // بناء الترويسة العلوية التي تظهر بيانات المقيم
  Widget _buildHero(AppRiverpod provider) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 40, 14, 14),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFc2410c), Color(0xFFea580c), Color(0xFFf97316)],
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('التقييم التفصيلي',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold)),
                    Text('أ. نور — الأخصائية الاجتماعية',
                        style: TextStyle(color: Colors.white70, fontSize: 10)),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle),
                  child: const Center(
                      child: Icon(Icons.arrow_forward_ios_rounded,
                          color: Colors.white, size: 14)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          FadeTransition(
            opacity: _fadeAnimations[1],
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(14)),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.28),
                        shape: BoxShape.circle),
                    child: Center(
                        child: Text(widget.resident.initials,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold))),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.resident.name,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.bold)),
                        Text('غرفة ${widget.resident.room} · آخر تقييم: ٣ أشهر',
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 10)),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                    decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8)),
                    child: const Text('يحتاج تجديد',
                        style: TextStyle(color: Colors.white, fontSize: 9)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // بناء تبويبات التبديل بين أنواع التقييمات
  Widget _buildToolTabs() {
    final tools = [
      {
        'label': 'نفسي',
        'icon': '🧠',
        'score': '٨/١٥',
        'col': const Color(0xFFf59e0b),
        'bg': const Color(0xFFfef3c7)
      },
      {
        'label': 'اجتماعي',
        'icon': '🤝',
        'score': '٥/٢٠',
        'col': const Color(0xFFef4444),
        'bg': const Color(0xFFfee2e2)
      },
      {
        'label': 'بدني',
        'icon': '🏃',
        'score': '٧٨/١٠٠',
        'col': const Color(0xFF10b981),
        'bg': const Color(0xFFd1fae5)
      },
      {
        'label': 'جودة الحياة',
        'icon': '❤️',
        'score': '٦٢/١٠٠',
        'col': const Color(0xFFf59e0b),
        'bg': const Color(0xFFfef3c7)
      },
    ];

    return Container(
      height: 44,
      color: Colors.white,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        reverse: true,
        child: Row(
          children: List.generate(tools.length, (index) {
            final isAct = _currentToolIndex == index;
            final tool = tools[index];
            return GestureDetector(
              onTap: () => setState(() => _currentToolIndex = index),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 11),
                decoration: BoxDecoration(
                    border: Border(
                        bottom: BorderSide(
                            color: isAct
                                ? const Color(0xFFea580c)
                                : Colors.transparent,
                            width: 2.5))),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                          color: tool['bg'] as Color,
                          borderRadius: BorderRadius.circular(6)),
                      child: Text(tool['score'] as String,
                          style: TextStyle(
                              color: tool['col'] as Color,
                              fontSize: 9,
                              fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 4),
                    Text('${tool['icon']} ${tool['label']}',
                        style: TextStyle(
                            color: isAct
                                ? const Color(0xFFea580c)
                                : const Color(0xFF94a3b8),
                            fontSize: 10,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  // بناء ملخص الدرجات الحالية والتقدم في التقييم
  Widget _buildScoreOverview() {
    return FadeTransition(
      opacity: _fadeAnimations[2],
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFfed7aa), width: 1.5)),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('تقييم الحالة النفسية GDS',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0f172a))),
                  const Text('مؤشر اكتئاب متوسط · يحتاج متابعة',
                      style: TextStyle(
                          fontSize: 10,
                          color: Color(0xFF334155),
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  _buildSubScoreBar('المزاج', 0.40, const Color(0xFFf59e0b)),
                  _buildSubScoreBar('الطاقة', 0.30, const Color(0xFFef4444)),
                  _buildSubScoreBar('الأمل', 0.65, const Color(0xFF10b981)),
                ],
              ),
            ),
            const SizedBox(width: 14),
            const SizedBox(
              width: 72,
              height: 72,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                      width: 72,
                      height: 72,
                      child: CircularProgressIndicator(
                          value: 0.53,
                          strokeWidth: 6,
                          backgroundColor: Color(0xFFfef3c7),
                          color: Color(0xFFf59e0b))),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('٨',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF92400e))),
                      Text('من ١٥',
                          style: TextStyle(
                              fontSize: 8,
                              color: Color(0xFF92400e),
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // بناء شريط التقدم الصغير للدرجات الفرعية
  Widget _buildSubScoreBar(String label, double val, Color col) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        children: [
          SizedBox(
              width: 44,
              child: Text(label,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                      fontSize: 9,
                      color: Color(0xFF334155),
                      fontWeight: FontWeight.w600))),
          const SizedBox(width: 6),
          Expanded(
            child: Container(
              height: 6,
              decoration: BoxDecoration(
                  color: const Color(0xFFf1f5f9),
                  borderRadius: BorderRadius.circular(4)),
              alignment: Alignment.centerRight,
              child: FractionallySizedBox(
                  widthFactor: val,
                  child: Container(
                      decoration: BoxDecoration(
                          color: col, borderRadius: BorderRadius.circular(4)))),
            ),
          ),
          const SizedBox(width: 6),
          Text('${(val * 100).toInt()}%',
              style: TextStyle(
                  fontSize: 9, fontWeight: FontWeight.bold, color: col)),
        ],
      ),
    );
  }

  // بناء الجزء الخاص بالأسئلة وتوليد التقارير
  // بناء منطقة الأسئلة (تتغير بناءً على التقدم في التقييم)
  Widget _buildQuestionnaire(AppRiverpod provider) {
    final tool = widget.tool ?? provider.socialAssessmentTools[0];
    return FadeTransition(
      opacity: _fadeAnimations[3],
      child: Container(
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFfed7aa), width: 1.5)),
        child: Column(
          children: [
            // الترويسة الداخلية للأسئلة
            Container(
              padding: const EdgeInsets.all(11),
              decoration: const BoxDecoration(
                  gradient: LinearGradient(
                      colors: [Color(0xFFea580c), Color(0xFFf97316)])),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(tool.name,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold)),
                  Text('${_questionIndex + 1} / ${_questions.length} سؤال',
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 10)),
                ],
              ),
            ),
            // شريط تقدم الأسئلة
            AnimatedBuilder(
              animation: _shimmerController,
              builder: (context, child) {
                return Container(
                  height: 3,
                  width: double.infinity,
                  color: Colors.white.withValues(alpha: 0.25),
                  child: FractionallySizedBox(
                      alignment: Alignment.centerRight,
                      widthFactor: (_questionIndex + 1) / _questions.length,
                      child: Container(
                          color: Colors.white.withValues(
                              alpha: 0.8 +
                                  0.2 *
                                      sin(_shimmerController.value * 2 * pi)))),
                );
              },
            ),
            // عرض السؤال الحالي
            Builder(builder: (context) {
              final q = _questions[_questionIndex];
              return _buildQuestionItem(
                  'السؤال ${_questionIndex + 1} من ${_questions.length}',
                  q.text,
                  type: q.type,
                  options: q.options,
                  selected: _selections[_questionIndex],
                  onSelected: (idx) =>
                      setState(() => _selections[_questionIndex] = idx),
                  selectedScale: _scales[_questionIndex],
                  onScaleSelected: (val) =>
                      setState(() => _scales[_questionIndex] = val));
            }),
            const SizedBox(height: 24),
            // زر توليد تقرير PDF
            ElevatedButton.icon(
              onPressed: () async {
                await PdfService.generateAssessmentReport(
                    widget.resident, tool, _selections, _questions);
              },
              icon: const Icon(Icons.picture_as_pdf_rounded, size: 20),
              label: const Text('تحميل التقرير كـ PDF',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0f172a),
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12))),
            ),
            const SizedBox(height: 32),
            _buildQuestionNav(), // أزرار التنقل (التالي/السابق)
          ],
        ),
      ),
    );
  }

  // بناء عنصر السؤال الفردي (اختيارات، مقياس، أو نص)
  Widget _buildQuestionItem(String num, String text,
      {required String type,
      List<String>? options,
      int? selected,
      int? selectedScale,
      Function(int)? onSelected,
      Function(int)? onScaleSelected}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFFfff7ed)))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(num,
              style: const TextStyle(
                  fontSize: 10,
                  color: Color(0xFF475569),
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(text,
              textAlign: TextAlign.right,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0f172a),
                  height: 1.5)),
          const SizedBox(height: 16),
          // عرض الخيارات المتعددة
          if (type == 'choice' && options != null)
            Column(
              children: List.generate(options.length, (index) {
                final isSel = selected == index;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: GestureDetector(
                    onTap: () => onSelected?.call(index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: isSel
                            ? const Color(0xFFea580c).withValues(alpha: 0.1)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: isSel
                                ? const Color(0xFFea580c)
                                : const Color(0xFFe2e8f0),
                            width: 1.5),
                        boxShadow: isSel
                            ? [
                                BoxShadow(
                                    color: const Color(0xFFea580c)
                                        .withValues(alpha: 0.05),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2))
                              ]
                            : null,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSel
                                    ? const Color(0xFFea580c)
                                    : const Color(0xFFcbd5e1),
                                width: 2,
                              ),
                              color: isSel
                                  ? const Color(0xFFea580c)
                                  : Colors.transparent,
                            ),
                            child: isSel
                                ? const Icon(Icons.check,
                                    color: Colors.white, size: 12)
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(options[index],
                                style: TextStyle(
                                    color: isSel
                                        ? const Color(0xFFea580c)
                                        : const Color(0xFF0f172a),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800)),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          // عرض المقياس الرقمي (1-5)
          if (type == 'scale')
            Row(
              children: [
                const Text('ممتاز',
                    style: TextStyle(fontSize: 9, color: Color(0xFF94a3b8))),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(5, (index) {
                      final i = 5 - index;
                      final isSel = selectedScale == i;
                      return GestureDetector(
                        onTap: () => onScaleSelected?.call(i),
                        child: Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                              color: isSel ? null : const Color(0xFFf8fafc),
                              gradient: isSel
                                  ? const LinearGradient(colors: [
                                      Color(0xFFea580c),
                                      Color(0xFFf97316)
                                    ])
                                  : null,
                              shape: BoxShape.circle,
                              border: isSel
                                  ? null
                                  : Border.all(
                                      color: const Color(0xFFe2e8f0),
                                      width: 1.5)),
                          child: Center(
                              child: Text('$i',
                                  style: TextStyle(
                                      color: isSel
                                          ? Colors.white
                                          : const Color(0xFF94a3b8),
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold))),
                        ),
                      );
                    }),
                  ),
                ),
                const Text('سيء جداً',
                    style: TextStyle(fontSize: 9, color: Color(0xFF94a3b8))),
              ],
            ),
          // عرض رد نصي افتراضي
          if (type == 'text')
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: const Color(0xFFf8fafc),
                  border: Border.all(color: const Color(0xFFe2e8f0)),
                  borderRadius: BorderRadius.circular(10)),
              child: const Text(
                  'المقيم ذكر شعوره بالعجز في بعض المواقف اليومية البسيطة...',
                  style: TextStyle(
                      fontSize: 11, color: Color(0xFF0f172a), height: 1.4)),
            ),
        ],
      ),
    );
  }

  // بناء أزرار التنقل بين الأسئلة
  Widget _buildQuestionNav() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: const BoxDecoration(color: Color(0xFFf8fafc)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => setState(() {
              if (_questionIndex > 0) _questionIndex--;
            }),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                  color: const Color(0xFFfff7ed),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFfed7aa))),
              child: const Text('→ السابق',
                  style: TextStyle(
                      color: Color(0xFF9a3412),
                      fontSize: 11,
                      fontWeight: FontWeight.bold)),
            ),
          ),
          Text('${_questionIndex + 1} من ${_questions.length}',
              style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF334155),
                  fontWeight: FontWeight.w600)),
          GestureDetector(
            onTap: () => setState(() {
              if (_questionIndex < _questions.length - 1) _questionIndex++;
            }),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                  color: const Color(0xFFfff7ed),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFfed7aa))),
              child: const Text('التالي ←',
                  style: TextStyle(
                      color: Color(0xFF9a3412),
                      fontSize: 11,
                      fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  // بناء مقارنة التقييمات التاريخية
  Widget _buildHistoryComparison(AppRiverpod provider) {
    return FadeTransition(
      opacity: _fadeAnimations[4],
      child: Column(
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.start, children: [
            Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                    color: Color(0xFF6366f1), shape: BoxShape.circle)),
            const SizedBox(width: 8),
            const Text('مقارنة التقييمات السابقة',
                style: TextStyle(
                    color: Color(0xFF9a3412),
                    fontSize: 11,
                    fontWeight: FontWeight.bold))
          ]),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFfed7aa), width: 1.5)),
            child: Column(
                children: provider.assessmentHistory
                    .map((h) => _buildCompareRow(h))
                    .toList()),
          ),
        ],
      ),
    );
  }

  // بناء صف المقارنة الفردي
  Widget _buildCompareRow(AssessmentHistoricalEntry h) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          _buildTrendArrow(h.trend), // سهم الاتجاه (تحسن/تراجع)
          const SizedBox(width: 6),
          Text('${h.score.toInt()}/${h.total}',
              style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFf59e0b))),
          const SizedBox(width: 8),
          Expanded(
              child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                      color: const Color(0xFFf1f5f9),
                      borderRadius: BorderRadius.circular(4)),
                  alignment: Alignment.centerRight,
                  child: FractionallySizedBox(
                      widthFactor: h.score / (double.tryParse(h.total) ?? 15.0),
                      child: Container(
                          decoration: BoxDecoration(
                              color: const Color(0xFFf59e0b),
                              borderRadius: BorderRadius.circular(4)))))),
          const SizedBox(width: 8),
          SizedBox(
              width: 72,
              child: Text(h.date,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF334155),
                      fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }

  Widget _buildTrendArrow(String trend) {
    if (trend == 'up') {
      return const Text('↑',
          style:
              TextStyle(color: Color(0xFF10b981), fontWeight: FontWeight.bold));
    }
    if (trend == 'down') {
      return const Text('↓',
          style:
              TextStyle(color: Color(0xFFef4444), fontWeight: FontWeight.bold));
    }
    return const Text('—',
        style:
            TextStyle(color: Color(0xFF94a3b8), fontWeight: FontWeight.bold));
  }

  // بناء منطقة ملاحظات الأخصائي مع الكلمات الدلالية (Tags)
  Widget _buildSpecialistNotes() {
    final tags = [
      'متابعة شهرية',
      'جلسة أسبوعية',
      'تنسيق مع الأسرة',
      'يحتاج دعم نفسي'
    ];
    return FadeTransition(
      opacity: _fadeAnimations[5],
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFfed7aa), width: 1.5)),
        child: Column(
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.start, children: [
              Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                      color: Color(0xFFf97316), shape: BoxShape.circle)),
              const SizedBox(width: 8),
              const Text('ملاحظات الأخصائية',
                  style: TextStyle(
                      color: Color(0xFF9a3412),
                      fontSize: 11,
                      fontWeight: FontWeight.bold))
            ]),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                  color: const Color(0xFFfff7ed),
                  border: Border.all(color: const Color(0xFFfed7aa)),
                  borderRadius: BorderRadius.circular(12)),
              child: TextField(
                  controller: _notesController,
                  maxLines: 3,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                      fontSize: 11, color: Color(0xFF0f172a), height: 1.6),
                  decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: 'اكتب ملاحظاتك هنا...',
                      hintStyle: TextStyle(color: Color(0xFF94a3b8)))),
            ),
            const SizedBox(height: 8),
            Wrap(
                spacing: 6,
                runSpacing: 4,
                alignment: WrapAlignment.start,
                children: tags
                    .map((t) => GestureDetector(
                        onTap: () => setState(() {
                              if (_activeNotes.contains(t)) {
                                _activeNotes.remove(t);
                              } else {
                                _activeNotes.add(t);
                              }
                            }),
                        child: _NoteChip('+ $t',
                            isSelected: _activeNotes.contains(t))))
                    .toList()),
          ],
        ),
      ),
    );
  }

  // بناء خيار تفعيل التدخل الاجتماعي العاجل
  Widget _buildInterventionToggle() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _isInterventionRequired ? const Color(0xFFfee2e2) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
            color: _isInterventionRequired
                ? const Color(0xFFef4444)
                : const Color(0xFFfed7aa),
            width: 1.5),
      ),
      child: Row(
        children: [
          const Icon(Icons.report_problem_rounded, color: Color(0xFFef4444)),
          const SizedBox(width: 12),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('تفعيل طلب تدخل عاجل',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF991b1b))),
              Text('سيتم إخطار الإدارة والزملاء فوراً',
                  style: TextStyle(fontSize: 10, color: Color(0xFFb91c1c))),
            ],
          ),
          const Spacer(),
          Switch(
            value: _isInterventionRequired,
            onChanged: (v) => setState(() => _isInterventionRequired = v),
            activeThumbColor: const Color(0xFFef4444),
          ),
        ],
      ),
    );
  }

  // بناء شريط الإجراءات السفلي مع منطق الحفظ الفعلي
  Widget _buildActionBar() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFfed7aa)))),
      child: Row(
        children: [
          Expanded(
              child: ElevatedButton(
                  onPressed: () {
                    if (_questions.isEmpty || _questions.first.id == 'empty') {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('لا توجد أسئلة متاحة لحفظ التقييم')),
                      );
                      return;
                    }
                    // حساب الدرجة التقريبية بناءً على عدد الإجابات المختارة
                    final Map<String, double> newScores = {};
                    if (widget.tool != null) {
                      newScores[widget.tool!.name] =
                          (_selections.length / _questions.length)
                              .clamp(0.1, 1.0);
                    }

                    // استدعاء دالة الحفظ في الـ Provider لتحديث بيانات المقيم في النظام
                    ref.read(appRiverpod).saveSocialAssessment(
                          residentId: widget.resident.id,
                          newScores: newScores,
                          needsIntervention: _isInterventionRequired,
                          notes: _notesController.text,
                        );

                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (dialogContext) => AlertDialog(
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18)),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Lottie.asset('assets/animations/Done.json',
                                width: 120, height: 120, repeat: false),
                            const SizedBox(height: 16),
                            const Text('تم حفظ التقييم بنجاح',
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0f172a))),
                            const SizedBox(height: 8),
                            const Text('تم تحديث حالة المقيم في النظام',
                                style: TextStyle(
                                    fontSize: 12, color: Color(0xFF64748b))),
                            const SizedBox(height: 20),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.pop(dialogContext); // Close dialog
                                Navigator.pop(context); // Close screen
                              },
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFea580c),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10))),
                              child: const Text('موافق'),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFea580c),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 0),
                  child: const Text('حفظ التقييم وإرساله للإدارة',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14)))),
        ],
      ),
    );
  }
}

// عنصر الـ Chip الخاص بالملاحظات السريعة
class _NoteChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  const _NoteChip(this.label, {this.isSelected = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFea580c) : const Color(0xFFfff7ed),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color:
                  isSelected ? Colors.transparent : const Color(0xFFfed7aa))),
      child: Text(label,
          style: TextStyle(
              color: isSelected ? Colors.white : const Color(0xFF9a3412),
              fontSize: 9,
              fontWeight: FontWeight.bold)),
    );
  }
}
