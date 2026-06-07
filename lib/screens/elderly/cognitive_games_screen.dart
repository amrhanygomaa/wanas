import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/app_riverpod.dart';
import '../../models/app_models.dart';

/// شاشة الألعاب الذهنية والمعرفية للمسن
class CognitiveGamesScreen extends ConsumerStatefulWidget {
  const CognitiveGamesScreen({super.key});

  @override
  ConsumerState<CognitiveGamesScreen> createState() =>
      _CognitiveGamesScreenState();
}

class _CognitiveGamesScreenState extends ConsumerState<CognitiveGamesScreen> {
  int _selectedGame = -1; // -1 = list view, 0/1/2 = game index

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF3B82F6),
        foregroundColor: Colors.white,
        title: Text(
          _selectedGame == -1
              ? 'ألعاب وتدريبات ذهنية 🧠'
              : _gameTitle(_selectedGame),
          style: const TextStyle(
              fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 17),
        ),
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () {
            if (_selectedGame != -1) {
              setState(() => _selectedGame = -1);
            } else {
              Navigator.pop(context);
            }
          },
        ),
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(20))),
      ),
      body: _selectedGame == -1 ? _buildGamesList() : _buildGame(_selectedGame),
    );
  }

  String _gameTitle(int index) {
    switch (index) {
      case 0:
        return 'لعبة تطابق الأرقام 🔢';
      case 1:
        return 'سؤال التركيز 🎯';
      case 2:
        return 'تذكر الكلمات 📝';
      case 3:
        return 'لعبة التذكر 🃏';
      case 4:
        return 'أكمل الجملة ✍️';
      case 5:
        return 'الكلمات المتقاطعة 🔤';
      default:
        return 'لعبة ذهنية';
    }
  }

  // ── قائمة الألعاب ─────────────────────────────────────────────────
  Widget _buildGamesList() {
    final provider = ref.watch(appRiverpod);
    final lastResult = provider.cognitiveGameResult;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // نتيجة آخر جلسة
          if (lastResult != null)
            Container(
              margin: const EdgeInsets.only(bottom: 20),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: Row(
                children: [
                  const Text('🏆', style: TextStyle(fontSize: 28)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('آخر نتيجة',
                            style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF3B82F6),
                                fontWeight: FontWeight.bold)),
                        Text('${lastResult.score}/10 نقاط',
                            style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E3A8A))),
                        Text(lastResult.feedback,
                            style: const TextStyle(
                                fontSize: 12, color: Color(0xFF64748B))),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          const Text('اختر لعبة',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1e293b))),
          const SizedBox(height: 16),

          _buildGameCard(
            index: 0,
            emoji: '🔢',
            title: 'تطابق الأرقام',
            description: 'تذكّر تسلسل الأرقام وأعد ترتيبها بالشكل الصحيح',
            color: const Color(0xFF3B82F6),
          ),
          const SizedBox(height: 14),
          _buildGameCard(
            index: 1,
            emoji: '🎯',
            title: 'سؤال التركيز',
            description: 'أسئلة بسيطة لاختبار التركيز والانتباه',
            color: const Color(0xFF8B5CF6),
          ),
          const SizedBox(height: 14),
          _buildGameCard(
            index: 2,
            emoji: '📝',
            title: 'تذكر الكلمات',
            description: 'احفظ قائمة الكلمات ثم أجب عن الأسئلة',
            color: const Color(0xFF059669),
          ),
          const SizedBox(height: 14),
          _buildGameCard(
            index: 3,
            emoji: '🃏',
            title: 'لعبة التذكر',
            description: 'اقلب البطاقات وابحث عن الأزواج المتطابقة',
            color: const Color(0xFFD97706),
          ),
          const SizedBox(height: 14),
          _buildGameCard(
            index: 4,
            emoji: '✍️',
            title: 'أكمل الجملة',
            description: 'اختر الكلمة الصحيحة لإكمال الجملة',
            color: const Color(0xFFDB2777),
          ),
          const SizedBox(height: 14),
          _buildGameCard(
            index: 5,
            emoji: '🔤',
            title: 'الكلمات المتقاطعة',
            description: 'اقرأ التلميح وأكمل الكلمة حرفاً بحرف',
            color: const Color(0xFF0EA5E9),
          ),
          const SizedBox(height: 28),
          _buildLeaderboard(provider),
        ],
      ),
    );
  }

  Widget _buildLeaderboard(AppRiverpod provider) {
    final residents = provider.residentFiles;
    final myId = provider.backendResidentId ?? '';
    final myScore = provider.cognitiveGameResult?.score ?? 0;

    // Build sorted entries: current user gets their real score; others get 0.
    final entries = residents.map((r) {
      final isMe = r.id == myId;
      return _LeaderboardEntry(
        name: r.name,
        score: isMe ? myScore : 0,
        isMe: isMe,
      );
    }).toList()
      ..sort((a, b) => b.score.compareTo(a.score));

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFDE68A), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text('🏆', style: TextStyle(fontSize: 22)),
              SizedBox(width: 8),
              Text('قائمة الصدارة',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF92400E))),
            ],
          ),
          const SizedBox(height: 14),
          if (entries.isEmpty)
            const Text('لا يوجد مقيمون حالياً',
                style: TextStyle(fontSize: 13, color: Color(0xFF78716C)))
          else
            ...entries.asMap().entries.map((entry) {
              final i = entry.key;
              final e = entry.value;
              final medalColors = [
                const Color(0xFFF59E0B),
                const Color(0xFF9CA3AF),
                const Color(0xFFCD7F32),
              ];
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: e.isMe ? const Color(0xFFFEF3C7) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: e.isMe
                          ? const Color(0xFFF59E0B)
                          : const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: i < 3 ? medalColors[i] : const Color(0xFFE2E8F0),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text('${i + 1}',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: i < 3
                                    ? Colors.white
                                    : const Color(0xFF64748B))),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        e.name + (e.isMe ? ' (أنت)' : ''),
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight:
                                e.isMe ? FontWeight.bold : FontWeight.normal,
                            color: const Color(0xFF1e293b)),
                      ),
                    ),
                    Text('${e.score} نقطة',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: e.isMe
                                ? const Color(0xFFD97706)
                                : const Color(0xFF94a3b8))),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildGameCard({
    required int index,
    required String emoji,
    required String title,
    required String description,
    required Color color,
  }) {
    return GestureDetector(
      onTap: () => setState(() => _selectedGame = index),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
          boxShadow: [
            BoxShadow(
                color: color.withValues(alpha: 0.1),
                blurRadius: 12,
                offset: const Offset(0, 4))
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                  child: Text(emoji, style: const TextStyle(fontSize: 28))),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: color)),
                  const SizedBox(height: 4),
                  Text(description,
                      style: const TextStyle(
                          fontSize: 13, color: Color(0xFF64748B))),
                ],
              ),
            ),
            Icon(Icons.play_circle_fill_rounded, color: color, size: 36),
          ],
        ),
      ),
    );
  }

  Widget _buildGame(int index) {
    switch (index) {
      case 0:
        return _NumberMemoryGame(onComplete: _onGameComplete);
      case 1:
        return _FocusQuestionGame(onComplete: _onGameComplete);
      case 2:
        return _WordRecallGame(onComplete: _onGameComplete);
      case 3:
        return _MemoryMatchGame(onComplete: _onGameComplete);
      case 4:
        return _WordCompleteGame(onComplete: _onGameComplete);
      case 5:
        return _CrosswordGame(onComplete: _onGameComplete);
      default:
        return const SizedBox.shrink();
    }
  }

  void _onGameComplete(int score, String feedback) {
    final provider = ref.read(appRiverpod);
    provider.saveCognitiveGameResult(CognitiveGameResult(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      residentId: provider.backendResidentId ?? 'resident',
      score: score,
      feedback: feedback,
      date: DateTime.now(),
    ));
    provider.addPoints(score);
    setState(() => _selectedGame = -1);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('أحسنت! حصلت على $score نقاط 🎉',
          textAlign: TextAlign.center,
          style: const TextStyle(fontFamily: 'Cairo')),
      backgroundColor: const Color(0xFF059669),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }
}

class _LeaderboardEntry {
  final String name;
  final int score;
  final bool isMe;
  _LeaderboardEntry(
      {required this.name, required this.score, required this.isMe});
}

// ══════════════════════════════════════════════════════════════════════
// لعبة 1 — تطابق الأرقام (تذكر تسلسل)
// ══════════════════════════════════════════════════════════════════════
class _NumberMemoryGame extends StatefulWidget {
  final void Function(int score, String feedback) onComplete;
  const _NumberMemoryGame({required this.onComplete});

  @override
  State<_NumberMemoryGame> createState() => _NumberMemoryGameState();
}

class _NumberMemoryGameState extends State<_NumberMemoryGame> {
  final _rng = Random();
  List<int> _sequence = [];
  List<int> _userInput = [];
  bool _showing = true;
  int _round = 1;
  int _score = 0;

  @override
  void initState() {
    super.initState();
    _newRound();
  }

  void _newRound() {
    final length = 3 + _round;
    _sequence = List.generate(length, (_) => _rng.nextInt(9) + 1);
    _userInput = [];
    _showing = true;
    setState(() {});
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _showing = false);
    });
  }

  void _tap(int n) {
    _userInput.add(n);
    if (_userInput.length == _sequence.length) {
      final correct =
          _sequence.asMap().entries.every((e) => _userInput[e.key] == e.value);
      if (correct) {
        _score += 2;
        if (_round >= 5) {
          widget.onComplete(
              _score.clamp(0, 10), 'ذاكرة ممتازة! تذكرت جميع الأرقام بدقة.');
        } else {
          setState(() => _round++);
          Future.delayed(const Duration(milliseconds: 500), _newRound);
        }
      } else {
        widget.onComplete(
            _score.clamp(0, 10), 'جيد! استمر في تمرين ذاكرتك يومياً.');
      }
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Text('الجولة $_round من 5',
              style: const TextStyle(fontSize: 14, color: Color(0xFF64748B))),
          const SizedBox(height: 24),
          if (_showing) ...[
            const Text('احفظ هذه الأرقام',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1e293b))),
            const SizedBox(height: 24),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: _sequence
                  .map((n) => Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: const Color(0xFF3B82F6),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Center(
                          child: Text('$n',
                              style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white)),
                        ),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 24),
            const Text('ستختفي بعد 3 ثوانٍ...',
                style: TextStyle(fontSize: 13, color: Color(0xFF94a3b8))),
          ] else ...[
            const Text('الآن أدخل الأرقام بالترتيب',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1e293b))),
            const SizedBox(height: 12),
            Text('${_userInput.length} / ${_sequence.length}',
                style: const TextStyle(color: Color(0xFF64748B))),
            const SizedBox(height: 24),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              children: List.generate(9, (i) {
                final n = i + 1;
                return GestureDetector(
                  onTap: () => _tap(n),
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFF3B82F6)),
                    ),
                    child: Center(
                      child: Text('$n',
                          style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1D4ED8))),
                    ),
                  ),
                );
              }),
            ),
          ],
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════
// لعبة 2 — سؤال التركيز
// ══════════════════════════════════════════════════════════════════════
class _FocusQuestionGame extends StatefulWidget {
  final void Function(int score, String feedback) onComplete;
  const _FocusQuestionGame({required this.onComplete});

  @override
  State<_FocusQuestionGame> createState() => _FocusQuestionGameState();
}

class _FocusQuestionGameState extends State<_FocusQuestionGame> {
  static const _questions = [
    {
      'q': 'ما هو عدد أيام الأسبوع؟',
      'options': ['5', '6', '7', '8'],
      'answer': '7',
    },
    {
      'q': 'ما هو الشهر الثالث في السنة؟',
      'options': ['فبراير', 'مارس', 'أبريل', 'يناير'],
      'answer': 'مارس',
    },
    {
      'q': 'كم يساوي ٥ × ٤؟',
      'options': ['١٦', '٢٠', '٢٤', '١٨'],
      'answer': '٢٠',
    },
    {
      'q': 'أي من هذه الفواكه لونها أصفر؟',
      'options': ['الفراولة', 'العنب', 'الموز', 'التفاح'],
      'answer': 'الموز',
    },
    {
      'q': 'ما هو العاصمة العربية الأولى أبجدياً؟',
      'options': ['عمّان', 'أبوظبي', 'بغداد', 'القاهرة'],
      'answer': 'أبوظبي',
    },
  ];

  int _current = 0;
  int _score = 0;
  String? _selected;
  bool _answered = false;

  void _answer(String option) {
    if (_answered) return;
    final correct = _questions[_current]['answer'] as String;
    setState(() {
      _selected = option;
      _answered = true;
      if (option == correct) _score += 2;
    });
    Future.delayed(const Duration(milliseconds: 900), () {
      if (_current + 1 >= _questions.length) {
        widget.onComplete(
            _score.clamp(0, 10),
            _score >= 8
                ? 'تركيز رائع! ذهنك نشيط.'
                : _score >= 4
                    ? 'جيد! تمرين منتظم سيحسّن تركيزك.'
                    : 'لا بأس، استمر في التمرين اليومي.');
      } else {
        setState(() {
          _current++;
          _selected = null;
          _answered = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final q = _questions[_current];
    final correct = q['answer'] as String;
    final options = q['options'] as List<String>;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LinearProgressIndicator(
            value: (_current + 1) / _questions.length,
            backgroundColor: const Color(0xFFE2E8F0),
            color: const Color(0xFF8B5CF6),
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 6),
          Text('السؤال ${_current + 1} من ${_questions.length}',
              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
          const SizedBox(height: 28),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFF3E8FF),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(q['q'] as String,
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF5B21B6),
                    height: 1.4)),
          ),
          const SizedBox(height: 28),
          ...options.map((opt) {
            Color bg = Colors.white;
            Color border = const Color(0xFFE2E8F0);
            if (_answered) {
              if (opt == correct) {
                bg = const Color(0xFFDCFCE7);
                border = const Color(0xFF059669);
              } else if (opt == _selected) {
                bg = const Color(0xFFFEE2E2);
                border = const Color(0xFFDC2626);
              }
            }
            return GestureDetector(
              onTap: () => _answer(opt),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: border, width: 1.5),
                ),
                child: Text(opt,
                    style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1e293b))),
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════
// لعبة 3 — تذكر الكلمات
// ══════════════════════════════════════════════════════════════════════
class _WordRecallGame extends StatefulWidget {
  final void Function(int score, String feedback) onComplete;
  const _WordRecallGame({required this.onComplete});

  @override
  State<_WordRecallGame> createState() => _WordRecallGameState();
}

class _WordRecallGameState extends State<_WordRecallGame> {
  static const _wordLists = [
    ['شمس', 'قمر', 'نجمة', 'سماء', 'غيم'],
    ['تفاح', 'موز', 'برتقال', 'عنب', 'خوخ'],
    ['بيت', 'شارع', 'حديقة', 'مدرسة', 'مسجد'],
  ];

  final _rng = Random();
  late List<String> _words;
  bool _showingWords = true;
  final List<String> _answers = [];

  @override
  void initState() {
    super.initState();
    _words = List.from(_wordLists[_rng.nextInt(_wordLists.length)])
      ..shuffle(_rng);
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) setState(() => _showingWords = false);
    });
  }

  void _submit() {
    final correct =
        _answers.where((a) => _words.any((w) => w.trim() == a.trim())).length;
    final score = (correct * 2).clamp(0, 10);
    widget.onComplete(
        score,
        correct >= 4
            ? 'ذاكرة قوية! تذكرت $correct كلمات من أصل ${_words.length}.'
            : 'تذكرت $correct كلمات. الممارسة المنتظمة تقوي الذاكرة.');
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_showingWords) ...[
            const Text('احفظ هذه الكلمات الخمس',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1e293b))),
            const SizedBox(height: 8),
            const Text('لديك 5 ثوانٍ',
                style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
            const SizedBox(height: 24),
            ...List.generate(_words.length, (i) {
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: const Color(0xFF059669).withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Text('${i + 1}.',
                        style: const TextStyle(
                            color: Color(0xFF059669),
                            fontWeight: FontWeight.bold)),
                    const SizedBox(width: 12),
                    Text(_words[i],
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF064E3B))),
                  ],
                ),
              );
            }),
          ] else ...[
            const Text('الآن اكتب الكلمات التي تتذكرها',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1e293b))),
            const SizedBox(height: 6),
            const Text('اكتب أي كلمة تتذكرها واضغط إضافة',
                style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
            const SizedBox(height: 20),
            _WordInputField(
              onAdd: (word) {
                if (word.trim().isNotEmpty && !_answers.contains(word.trim())) {
                  setState(() => _answers.add(word.trim()));
                }
              },
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _answers
                  .map((w) => Chip(
                        label: Text(w,
                            style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF059669),
                                fontWeight: FontWeight.bold)),
                        backgroundColor: const Color(0xFFECFDF5),
                        deleteIconColor: const Color(0xFF059669),
                        onDeleted: () => setState(() => _answers.remove(w)),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 24),
            if (_answers.isNotEmpty)
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF059669),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('تحقق من إجاباتي',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _WordInputField extends StatefulWidget {
  final void Function(String) onAdd;
  const _WordInputField({required this.onAdd});

  @override
  State<_WordInputField> createState() => _WordInputFieldState();
}

class _WordInputFieldState extends State<_WordInputField> {
  final _ctrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _ctrl,
            textAlign: TextAlign.right,
            decoration: InputDecoration(
              hintText: 'اكتب كلمة...',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: Color(0xFF059669), width: 2)),
            ),
          ),
        ),
        const SizedBox(width: 10),
        ElevatedButton(
          onPressed: () {
            widget.onAdd(_ctrl.text);
            _ctrl.clear();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF059669),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          ),
          child: const Text('إضافة',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }
}

// ══════════════════════════════════════════════════════════════════════
// لعبة 4 — التذكر (بطاقات متطابقة)
// ══════════════════════════════════════════════════════════════════════
class _MemoryMatchGame extends StatefulWidget {
  final void Function(int score, String feedback) onComplete;
  const _MemoryMatchGame({required this.onComplete});

  @override
  State<_MemoryMatchGame> createState() => _MemoryMatchGameState();
}

class _MemoryMatchGameState extends State<_MemoryMatchGame> {
  static const _emojis = ['🌹', '🌸', '🌺', '🌻', '🌼', '🌷', '🍀', '🌿'];

  late List<String> _cards;
  late List<bool> _flipped;
  late List<bool> _matched;
  final List<int> _selected = [];
  bool _checking = false;
  int _attempts = 0;

  @override
  void initState() {
    super.initState();
    final pairs = [..._emojis, ..._emojis];
    pairs.shuffle(Random());
    _cards = pairs;
    _flipped = List.filled(16, false);
    _matched = List.filled(16, false);
  }

  void _onTap(int i) {
    if (_checking) return;
    if (_flipped[i] || _matched[i]) return;
    if (_selected.length == 2) return;

    setState(() {
      _flipped[i] = true;
      _selected.add(i);
    });

    if (_selected.length == 2) {
      _attempts++;
      _checking = true;
      Future.delayed(const Duration(milliseconds: 800), _checkMatch);
    }
  }

  void _checkMatch() {
    final a = _selected[0];
    final b = _selected[1];
    if (_cards[a] == _cards[b]) {
      setState(() {
        _matched[a] = true;
        _matched[b] = true;
        _selected.clear();
        _checking = false;
      });
      if (_matched.every((m) => m)) {
        final score = (_attempts <= 10
                ? 10
                : _attempts <= 14
                    ? 8
                    : _attempts <= 18
                        ? 6
                        : 4)
            .clamp(0, 10);
        widget.onComplete(
          score,
          score >= 8
              ? 'ذاكرة ممتازة! أتممت اللعبة في $_attempts محاولة.'
              : 'أحسنت! أتممت اللعبة في $_attempts محاولة.',
        );
      }
    } else {
      setState(() {
        _flipped[a] = false;
        _flipped[b] = false;
        _selected.clear();
        _checking = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final matched = _matched.where((m) => m).length ~/ 2;
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('أزواج مكتملة: $matched / 8',
                  style:
                      const TextStyle(fontSize: 14, color: Color(0xFF64748B))),
              Text('محاولات: $_attempts',
                  style:
                      const TextStyle(fontSize: 14, color: Color(0xFF64748B))),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: 16,
              itemBuilder: (_, i) {
                final isRevealed = _flipped[i] || _matched[i];
                return GestureDetector(
                  onTap: () => _onTap(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    decoration: BoxDecoration(
                      color: _matched[i]
                          ? const Color(0xFFDCFCE7)
                          : isRevealed
                              ? const Color(0xFFEFF6FF)
                              : const Color(0xFFD97706),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: _matched[i]
                            ? const Color(0xFF059669)
                            : isRevealed
                                ? const Color(0xFF3B82F6)
                                : const Color(0xFFB45309),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: isRevealed
                          ? Text(_cards[i],
                              style: const TextStyle(fontSize: 28))
                          : const Text('?',
                              style: TextStyle(
                                  fontSize: 22,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════
// لعبة 5 — أكمل الجملة
// ══════════════════════════════════════════════════════════════════════
class _WordCompleteGame extends StatefulWidget {
  final void Function(int score, String feedback) onComplete;
  const _WordCompleteGame({required this.onComplete});

  @override
  State<_WordCompleteGame> createState() => _WordCompleteGameState();
}

class _WordCompleteGameState extends State<_WordCompleteGame> {
  static const _questions = [
    {
      'sentence': 'الشمس تشرق من جهة ___',
      'options': ['الغرب', 'الجنوب', 'الشرق', 'الشمال'],
      'answer': 'الشرق',
    },
    {
      'sentence': 'رمضان هو الشهر ___ في التقويم الهجري',
      'options': ['التاسع', 'العاشر', 'الثامن', 'السابع'],
      'answer': 'التاسع',
    },
    {
      'sentence': 'الماء يغلي عند درجة حرارة ___ مئوية',
      'options': ['٨٠', '٩٠', '١٠٠', '١١٠'],
      'answer': '١٠٠',
    },
    {
      'sentence': 'عاصمة المملكة العربية السعودية هي ___',
      'options': ['جدة', 'الرياض', 'مكة', 'المدينة'],
      'answer': 'الرياض',
    },
    {
      'sentence': 'عدد أيام السنة الميلادية ___',
      'options': ['٣٦٠', '٣٦٥', '٣٧٠', '٣٥٥'],
      'answer': '٣٦٥',
    },
  ];

  int _current = 0;
  int _score = 0;
  String? _selected;
  bool _answered = false;

  void _answer(String option) {
    if (_answered) return;
    final correct = _questions[_current]['answer'] as String;
    setState(() {
      _selected = option;
      _answered = true;
      if (option == correct) _score += 2;
    });
    Future.delayed(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      if (_current + 1 >= _questions.length) {
        widget.onComplete(
          _score.clamp(0, 10),
          _score >= 8
              ? 'ممتاز! ذهنك حاضر ومعلوماتك راسخة.'
              : _score >= 4
                  ? 'جيد جداً! التمرين المنتظم يزيد المعلومات.'
                  : 'لا بأس، استمر في التعلم اليومي.',
        );
      } else {
        setState(() {
          _current++;
          _selected = null;
          _answered = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final q = _questions[_current];
    final correct = q['answer'] as String;
    final options = q['options'] as List<String>;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LinearProgressIndicator(
            value: (_current + 1) / _questions.length,
            backgroundColor: const Color(0xFFE2E8F0),
            color: const Color(0xFFDB2777),
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 6),
          Text('السؤال ${_current + 1} من ${_questions.length}',
              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
          const SizedBox(height: 28),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFFCE7F3),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(q['sentence'] as String,
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF831843),
                    height: 1.5)),
          ),
          const SizedBox(height: 28),
          ...options.map((opt) {
            Color bg = Colors.white;
            Color border = const Color(0xFFE2E8F0);
            if (_answered) {
              if (opt == correct) {
                bg = const Color(0xFFDCFCE7);
                border = const Color(0xFF059669);
              } else if (opt == _selected) {
                bg = const Color(0xFFFEE2E2);
                border = const Color(0xFFDC2626);
              }
            }
            return GestureDetector(
              onTap: () => _answer(opt),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: border, width: 1.5),
                ),
                child: Text(opt,
                    style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1e293b))),
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════
// لعبة 6 — الكلمات المتقاطعة
// ══════════════════════════════════════════════════════════════════════
class _CrosswordGame extends StatefulWidget {
  final void Function(int score, String feedback) onComplete;
  const _CrosswordGame({required this.onComplete});
  @override
  State<_CrosswordGame> createState() => _CrosswordGameState();
}

class _CrosswordGameState extends State<_CrosswordGame> {
  static const _puzzles = [
    _Puzzle(clue: 'عاصمة المملكة العربية السعودية', answer: 'الرياض'),
    _Puzzle(clue: 'أطول نهر في العالم', answer: 'النيل'),
    _Puzzle(clue: 'كوكبنا الذي نعيش عليه', answer: 'الأرض'),
    _Puzzle(clue: 'الشهر التاسع في التقويم الهجري', answer: 'رمضان'),
    _Puzzle(clue: 'لون السماء في الطقس الصافي', answer: 'أزرق'),
  ];

  int _current = 0;
  int _score = 0;
  final _ctrl = TextEditingController();
  String? _feedback;
  bool _answered = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _check() {
    final answer = _ctrl.text.trim();
    if (answer.isEmpty) return;
    final correct = answer == _puzzles[_current].answer;
    setState(() {
      _answered = true;
      _score += correct ? 2 : 0;
      _feedback =
          correct ? 'صحيح! ' : 'الإجابة الصحيحة: ${_puzzles[_current].answer}';
    });
  }

  void _next() {
    if (_current >= _puzzles.length - 1) {
      widget.onComplete(
        _score.clamp(0, 10),
        _score >= 8
            ? 'ممتاز! معرفة واسعة وذاكرة قوية.'
            : _score >= 4
                ? 'جيد جداً! استمر في التدريب.'
                : 'حاول مرة أخرى لتحسين نتيجتك.',
      );
    } else {
      setState(() {
        _current++;
        _answered = false;
        _feedback = null;
        _ctrl.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final puzzle = _puzzles[_current];
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          LinearProgressIndicator(
            value: (_current + 1) / _puzzles.length,
            backgroundColor: const Color(0xFFBAE6FD),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF0EA5E9)),
            minHeight: 6,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 8),
          Text('السؤال ${_current + 1} من ${_puzzles.length}',
              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
          const SizedBox(height: 32),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [Color(0xFF0EA5E9), Color(0xFF38BDF8)]),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                const Text('التلميح',
                    style: TextStyle(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 8),
                Text(puzzle.clue,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        height: 1.4)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 8,
            children: List.generate(puzzle.answer.length, (i) {
              return Container(
                width: 36,
                height: 44,
                decoration: BoxDecoration(
                  color: _answered
                      ? const Color(0xFFDCFCE7)
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _answered
                        ? const Color(0xFF86EFAC)
                        : const Color(0xFFCBD5E1),
                  ),
                ),
                child: Center(
                  child: Text(
                    _answered ? puzzle.answer[i] : '_',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _answered
                          ? const Color(0xFF166534)
                          : const Color(0xFF94A3B8),
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 24),
          if (!_answered)
            TextField(
              controller: _ctrl,
              textAlign: TextAlign.center,
              autofocus: true,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                hintText: 'اكتب الإجابة هنا',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFF0EA5E9))),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide:
                        const BorderSide(color: Color(0xFF0EA5E9), width: 2)),
              ),
              onSubmitted: (_) => _check(),
            ),
          if (_feedback != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: (_feedback!.startsWith('صحيح'))
                    ? const Color(0xFFDCFCE7)
                    : const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(_feedback!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: (_feedback!.startsWith('صحيح'))
                          ? const Color(0xFF166534)
                          : const Color(0xFF991B1B))),
            ),
          ],
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _answered ? _next : _check,
              style: ElevatedButton.styleFrom(
                backgroundColor: _answered
                    ? const Color(0xFF059669)
                    : const Color(0xFF0EA5E9),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(
                _answered
                    ? (_current >= _puzzles.length - 1
                        ? 'عرض النتيجة'
                        : 'السؤال التالي')
                    : 'تحقق من الإجابة',
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Puzzle {
  final String clue;
  final String answer;
  const _Puzzle({required this.clue, required this.answer});
}
