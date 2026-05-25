import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/app_riverpod.dart';
import '../../models/app_models.dart';
import 'package:lottie/lottie.dart';

class MedicationScreen extends ConsumerStatefulWidget {
  const MedicationScreen({super.key});

  @override
  ConsumerState<MedicationScreen> createState() => _MedicationScreenState();
}

class _MedicationScreenState extends ConsumerState<MedicationScreen>
    with TickerProviderStateMixin {
  bool _showSuccessAnimation = false;
  late AnimationController _bgController;
  late AnimationController _pillController;
  late AnimationController _ringController;
  late AnimationController _glowController;
  late AnimationController _missController;

  int remainingSeconds = 22 * 60;
  Timer? _timer;
  int selectedDay = 1;
  final List<String> tabs = ['أمس', 'اليوم', 'غداً', 'الأسبوع'];

  @override
  void initState() {
    super.initState();

    _bgController =
        AnimationController(vsync: this, duration: const Duration(seconds: 10))
          ..repeat();
    _pillController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2800))
      ..repeat(reverse: true);
    _ringController =
        AnimationController(vsync: this, duration: const Duration(seconds: 2))
          ..repeat();
    _glowController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2500))
      ..repeat(reverse: true);
    _missController =
        AnimationController(vsync: this, duration: const Duration(seconds: 1))
          ..repeat();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (remainingSeconds > 0) setState(() => remainingSeconds--);
    });
  }

  @override
  void dispose() {
    _bgController.dispose();
    _pillController.dispose();
    _ringController.dispose();
    _glowController.dispose();
    _missController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  String formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return m > 0 ? '$m دقيقة' : '$s ثانية';
  }

  @override
  Widget build(BuildContext context) {
    final provider = ref.watch(appRiverpod);
    return Stack(
      children: [
        SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              _buildHero(provider),
              _buildDayTabs(),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 34),
                child: Column(
                  children: [
                    _buildMissBanner(),
                    const SizedBox(height: 12),
                    ..._buildDynamicSections(provider, selectedDay),
                    const SizedBox(height: 12),
                    _buildAppointmentsSection(provider),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (_showSuccessAnimation) _buildCentralSuccessAnimation(),
      ],
    );
  }

  Widget _buildCentralSuccessAnimation() {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 700),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Container(
          color: Colors.black.withValues(alpha: 0.5 * value),
          child: Center(
            child: Transform.scale(
              scale: value,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Lottie Animation: Done.json (Transparent Background)
                  SizedBox(
                    width: 320,
                    height: 320,
                    child: Lottie.asset(
                      'assets/animations/Done.json',
                      repeat: false,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 30),
                  const Text(
                    'تم أخذ الدواء بنجاح ✨',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          color: Colors.black26,
                          offset: Offset(0, 4),
                          blurRadius: 10,
                        )
                      ],
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

  Widget _buildHero(AppRiverpod provider) {
    return AnimatedBuilder(
      animation: _bgController,
      builder: (context, child) {
        return Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF1a0533),
                Color(0xFF3730a3),
                Color(0xFF0f3460),
                Color(0xFF6C63FF)
              ],
            ),
          ),
          child: Stack(
            children: [
              _buildBlob(180, const Color(0xFF6C63FF), -50, -50, 7),
              _buildBlob(130, const Color(0xFFf472b6), -35, 30, 9),
              _buildBlob(80, const Color(0xFF0ea5e9), 80, -10, 6),
              SafeArea(
                bottom: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(left: 16.0, top: 16.0),
                    ),
                    const Padding(
                      padding: EdgeInsets.only(right: 28, top: 8, bottom: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text('جدول الأدوية',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold)),
                          ),
                          SizedBox(height: 4),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(
                          left: 16, right: 16, top: 8, bottom: 24),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildHeroChip(
                              '${provider.getMedicationsForDay(selectedDay).where((m) => m.isTaken).length}',
                              'تم',
                              0),
                          const SizedBox(width: 8),
                          _buildHeroChip(
                              '${provider.getMedicationsForDay(selectedDay).where((m) => !m.isTaken).length}',
                              'باقي',
                              1),
                          const SizedBox(width: 8),
                          _buildHeroChip('٠', 'لاحقاً', 2),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBlob(
      double size, Color color, double right, double top, double duration) {
    return AnimatedBuilder(
      animation: _bgController,
      builder: (context, child) {
        final t = _bgController.value * 2 * pi;
        final x = sin(t * (duration / 7)) * 10;
        final y = cos(t * (duration / 7)) * 12;
        return Positioned(
          left: right + x,
          top: top + y,
          child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                  shape: BoxShape.circle, color: color.withValues(alpha: 0.4))),
        );
      },
    );
  }

  Widget _buildHeroChip(String value, String label, int index) {
    Color chipColor;
    Color borderColor;

    switch (index) {
      case 0: // تم
        chipColor =
            const Color(0xFF6C63FF).withValues(alpha: 0.15); // بنفسجي أساسي
        borderColor = const Color(0xFF6C63FF).withValues(alpha: 0.3);
        break;
      case 1: // باقي
        chipColor =
            const Color(0xFF8B5CF6).withValues(alpha: 0.15); // بنفسجي فاتح
        borderColor = const Color(0xFF8B5CF6).withValues(alpha: 0.3);
        break;
      case 2: // لاحقاً
        chipColor = const Color(0xFF3B82F6).withValues(alpha: 0.15); // أزرق
        borderColor = const Color(0xFF3B82F6).withValues(alpha: 0.3);
        break;
      default:
        chipColor = Colors.white.withValues(alpha: 0.14);
        borderColor = Colors.white.withValues(alpha: 0.12);
    }

    return Expanded(
      child: TweenAnimationBuilder(
        tween: Tween<double>(begin: 0.6, end: 1),
        duration: Duration(milliseconds: 450 + (index * 110)),
        curve: Curves.elasticOut,
        builder: (context, scale, child) =>
            Transform.scale(scale: scale, child: child!),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 4),
          decoration: BoxDecoration(
            color: chipColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: borderColor.withValues(alpha: 0.2),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(value,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(label,
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 12,
                      fontWeight: FontWeight.w500)),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildDayTabs() {
    bool hc = ref.watch(appRiverpod).isHighContrast;
    return Container(
      color: hc ? const Color(0xFF1E1E1E) : Colors.white,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(tabs.length, (index) {
            final isActive = selectedDay == index;
            return GestureDetector(
              onTap: () => setState(() => selectedDay = index),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 34, vertical: 9),
                decoration: BoxDecoration(
                  border: Border(
                      bottom: BorderSide(
                          color: isActive
                              ? (hc
                                  ? const Color(0xFF9FA8DA)
                                  : const Color(0xFF6C63FF))
                              : Colors.transparent,
                          width: 2.5)),
                ),
                child: Text(tabs[index],
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isActive
                            ? (hc
                                ? const Color(0xFF9FA8DA)
                                : const Color(0xFF6C63FF))
                            : (hc ? Colors.white38 : const Color(0xFF94a3b8)))),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildMissBanner() {
    bool hc = ref.watch(appRiverpod).isHighContrast;
    return AnimatedBuilder(
      animation: _missController,
      builder: (context, child) {
        final shake = sin(_missController.value * pi * 2) * 3;
        return Transform.translate(
          offset: Offset(shake, 0),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
                color: hc ? const Color(0xFF421515) : const Color(0xFFfff5f5),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color:
                        hc ? const Color(0xFFef4444) : const Color(0xFFfca5a5),
                    width: 1.5)),
            child: Row(
              children: [
                Expanded(
                    child: Text(
                        'جرعة الأمس المسائية لم تُؤخذ — تم إشعار الممرضة 👩‍⚕️',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: hc ? Colors.white : const Color(0xFF7f1d1d),
                            height: 1.5))),
                const SizedBox(width: 10),
                Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                        shape: BoxShape.circle, color: Color(0xFFef4444))),
              ],
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildDynamicSections(AppRiverpod provider, int currentDay) {
    Map<String, List<Medication>> grouped = {
      'الصباح': [],
      'الظهر': [],
      'المساء': [],
    };
    for (var m in provider.getMedicationsForDay(currentDay)) {
      if (grouped.containsKey(m.timeOfDay)) {
        grouped[m.timeOfDay]!.add(m);
      } else {
        grouped[m.timeOfDay] = [m];
      }
    }

    final nextMed = provider.nextMedication;
    List<Widget> sections = [];
    grouped.forEach((time, meds) {
      if (meds.isEmpty) return;

      Color color = time == 'الصباح'
          ? const Color(0xFFfbbf24)
          : (time == 'الظهر'
              ? const Color(0xFF6C63FF)
              : const Color(0xFF818cf8));

      sections.add(_buildSectionLabel(time, color));
      sections.add(const SizedBox(height: 8));

      for (int i = 0; i < meds.length; i++) {
        var m = meds[i];
        // If confirmed by elderly but not yet final isTaken, it's pending nurse
        bool isPendingNurse = m.isElderlyConfirmed && !m.isTaken;

        if (m == nextMed && !isPendingNurse) {
          sections.add(_buildActiveMedCard(provider, m));
          sections.add(const SizedBox(height: 10));
          sections.add(_buildConfirmButton(provider, m));
        } else {
          sections.add(_buildMedCard(m.name, m.dosage, m.timeDescription,
              m.isTaken, false, false, i, m.isElderlyConfirmed));
        }
        sections.add(const SizedBox(height: 8));
      }
      sections.add(const SizedBox(height: 12));
    });

    return sections;
  }

  Widget _buildSectionLabel(String text, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Container(
            width: 4,
            height: 16,
            decoration: BoxDecoration(
                color: color, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 7),
        Text(text,
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF6C63FF))),
      ],
    );
  }

  Widget _buildMedCard(String name, String dose, String time, bool isDone,
      bool isMissed, bool isLater, int delayIndex,
      [bool isElderlyConfirmed = false]) {
    bool hc = ref.watch(appRiverpod).isHighContrast;

    bool isPendingNurse = isElderlyConfirmed && !isDone;

    final bgColor = isDone
        ? const Color(0xFFd1fae5)
        : (isPendingNurse
            ? const Color(0xFFfef3c7)
            : (isMissed
                ? const Color(0xFFfee2e2)
                : (isLater ? const Color(0xFFf1f5f9) : Colors.white)));

    final borderColor = isDone
        ? const Color(0xFFd1fae5)
        : (isPendingNurse
            ? const Color(0xFFfde68a)
            : (isMissed
                ? const Color(0xFFfca5a5)
                : (isLater
                    ? const Color(0xFFede9fe)
                    : const Color(0xFFede9fe))));

    final badgeText = isDone
        ? '✓ تم'
        : (isPendingNurse
            ? '⏳ في الانتظار'
            : (isMissed ? 'فائتة' : (isLater ? 'لاحقاً' : '')));

    final badgeColor = isDone
        ? const Color(0xFFd1fae5)
        : (isPendingNurse
            ? const Color(0xFFfef3c7)
            : (isMissed
                ? const Color(0xFFfee2e2)
                : (isLater ? const Color(0xFFf1f5f9) : Colors.white)));

    final badgeTextColor = isDone
        ? const Color(0xFF065f46)
        : (isPendingNurse
            ? const Color(0xFF92400e)
            : (isMissed
                ? const Color(0xFF7f1d1d)
                : (isLater ? const Color(0xFF9ca3af) : Colors.white)));

    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOut,
      builder: (context, value, child) => Transform.translate(
          offset: Offset(14 * (1 - value), 0),
          child: Opacity(opacity: value, child: child)),
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
            color: hc ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: hc ? const Color(0xFF333333) : borderColor, width: 1.5),
            boxShadow: [
              BoxShadow(
                  color: const Color(0xFF6C63FF)
                      .withValues(alpha: hc ? 0.25 : 0.15),
                  blurRadius: 10,
                  offset: const Offset(0, 4))
            ]),
        child: Row(
          textDirection: TextDirection.rtl,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Right Side: Text Info (First in RTL)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color:
                                hc ? Colors.white : const Color(0xFF0f172a))),
                  ),
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(dose,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 14, color: Color(0xFF64748b))),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text(time,
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: isLater
                                  ? const Color(0xFF475569)
                                  : const Color(0xFF475569))),
                      const SizedBox(width: 6),
                      Icon(Icons.access_time,
                          size: 14,
                          color: isLater
                              ? const Color(0xFF94a3b8)
                              : const Color(0xFF94a3b8)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Middle/Left: Actions & Status
            IconButton(
              icon: const Icon(Icons.volume_up_rounded,
                  color: Color(0xFF6C63FF), size: 24),
              onPressed: () => ref
                  .read(appRiverpod)
                  .startReading('دواء $name، الجرعة $dose، الموعد $time'),
            ),
            const SizedBox(width: 8),
            // Left Side: Status Column
            Column(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                      color: bgColor, borderRadius: BorderRadius.circular(16)),
                  child: Center(
                      child:
                          _buildPillIcon(isDone, isLater, isElderlyConfirmed)),
                ),
                const SizedBox(height: 8),
                if (badgeText.isNotEmpty)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                        color: badgeColor,
                        borderRadius: BorderRadius.circular(8)),
                    child: Text(badgeText,
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: badgeTextColor)),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveMedCard(AppRiverpod provider, Medication med) {
    return AnimatedBuilder(
      animation: _glowController,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF6C63FF), Color(0xFFA78BFA)]),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                  color: const Color(0xFF6C63FF)
                      .withValues(alpha: 0.35 + (_glowController.value * 0.25)),
                  blurRadius: 24,
                  offset: const Offset(0, 6))
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(13),
            child: Row(
              textDirection: TextDirection.rtl,
              children: [
                // Right: Text info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(med.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white)),
                      ),
                      const SizedBox(height: 4),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(med.dosage,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: 16,
                                color: Colors.white.withValues(alpha: 0.85))),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Text('باقي ${formatTime(remainingSeconds)}',
                              style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white)),
                          const SizedBox(width: 8),
                          AnimatedBuilder(
                            animation: _ringController,
                            builder: (context, child) => Transform.scale(
                                scale: 1 +
                                    (sin(_ringController.value * pi * 2) *
                                        0.06),
                                child: const Icon(Icons.timer_outlined,
                                    size: 20, color: Colors.white)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Left: Interactive Icon
                GestureDetector(
                  onTap: () {
                    provider.elderlyConfirmMedication(med.id);

                    // Show central animation instead of SnackBar
                    setState(() => _showSuccessAnimation = true);

                    // Hide it after 3 seconds
                    Future.delayed(const Duration(seconds: 3), () {
                      if (mounted) {
                        setState(() => _showSuccessAnimation = false);
                      }
                    });
                  },
                  child: SizedBox(
                    width: 56,
                    height: 56,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        AnimatedBuilder(
                          animation: _ringController,
                          builder: (context, child) => Transform.scale(
                            scale: 1 + (_ringController.value * 0.32),
                            child: Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: Colors.white.withValues(
                                            alpha: 0.55 -
                                                (_ringController.value * 0.55)),
                                        width: 2))),
                          ),
                        ),
                        AnimatedBuilder(
                          animation: _pillController,
                          builder: (context, child) => Transform.translate(
                            offset: Offset(0, -6 * _pillController.value),
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          Colors.black.withValues(alpha: 0.15),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    )
                                  ]),
                              child: const Icon(Icons.touch_app,
                                  color: Color(0xFF7c3aed), size: 26),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.volume_up_rounded,
                      color: Colors.white, size: 28),
                  onPressed: () => provider.startReading(
                      'دواء ${med.name}، الجرعة ${med.dosage}، الآن'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildConfirmButton(AppRiverpod provider, Medication med) {
    return AnimatedBuilder(
      animation: _glowController,
      builder: (context, child) {
        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF6C63FF), Color(0xFFA78BFA)]),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                  color: const Color(0xFF6C63FF)
                      .withValues(alpha: 0.4 + (_glowController.value * 0.2)),
                  blurRadius: 24,
                  offset: const Offset(0, 6))
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                provider.elderlyConfirmMedication(med.id);

                // Show central animation
                setState(() => _showSuccessAnimation = true);

                // Hide it after 3 seconds
                Future.delayed(const Duration(seconds: 3), () {
                  if (mounted) {
                    setState(() => _showSuccessAnimation = false);
                  }
                });
              },
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 15),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.25)),
                      child: const Icon(Icons.check,
                          color: Colors.white, size: 14),
                    ),
                    const SizedBox(width: 9),
                    const Text('أخذت الدواء ✓',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAppointmentsSection(AppRiverpod provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
                width: 4,
                height: 16,
                decoration: BoxDecoration(
                    color: const Color(0xFFf472b6),
                    borderRadius: BorderRadius.circular(3))),
            const SizedBox(width: 7),
            const Text('مواعيد وجلسات قادمة',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF6C63FF))),
            const SizedBox(width: 6),
            Image.asset('assets/icons/calendar.png', width: 22, height: 22),
          ],
        ),
        const SizedBox(height: 12),
        if (provider.medicalSessions.isEmpty)
          const Center(
              child: Text('لا توجد مواعيد مسجلة حالياً',
                  style: TextStyle(color: Colors.white70, fontSize: 13)))
        else
          ...provider.medicalSessions.map((s) {
            final dt = s.date == 'اليوم'
                ? DateTime.now()
                : s.date == 'غد'
                    ? DateTime.now().add(const Duration(days: 1))
                    : DateTime.tryParse(s.date) ?? DateTime.now();
            const months = ['يناير','فبراير','مارس','أبريل','مايو','يونيو','يوليو','أغسطس','سبتمبر','أكتوبر','نوفمبر','ديسمبر'];
            final dayAr = dt.day.toString().replaceAllMapped(RegExp(r'\d'), (m) => ['٠','١','٢','٣','٤','٥','٦','٧','٨','٩'][int.parse(m[0]!)]);
            return _buildAppointmentCard(
              dayAr,
              months[dt.month - 1],
              s.specialistName,
              '${s.type == 'doctor' ? 'كشف طبي' : 'جلسة علاج'} · ${s.time}',
              s.type == 'doctor',
              0,
            );
          }),
      ],
    );
  }

  Widget _buildAppointmentCard(String day, String month, String title,
      String detail, bool isPurple, int delay) {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOut,
      builder: (context, value, child) => Transform.translate(
          offset: Offset(14 * (1 - value), 0),
          child: Opacity(opacity: value, child: child)),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFede9fe), width: 1.5),
            boxShadow: [
              BoxShadow(
                  color: const Color(0xFF6C63FF).withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 2))
            ]),
        child: Row(
          children: [
            // Right: Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF1e293b))),
                  const SizedBox(height: 4),
                  Text(detail,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 16,
                          color: Color(0xFF64748b),
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            const SizedBox(width: 16),
            // Left: Date Box
            Container(
              width: 70,
              height: 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isPurple
                        ? const [Color(0xFF6C63FF), Color(0xFF818CF8)]
                        : const [Color(0xFF4F46E5), Color(0xFF6366F1)]),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: (isPurple
                            ? const Color(0xFF6C63FF)
                            : const Color(0xFF4F46E5))
                        .withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(day,
                      style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          height: 1.1)),
                  Text(month,
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          height: 1.1)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPillIcon(bool isDone, bool isLater,
      [bool isElderlyConfirmed = false]) {
    // Icon continues to animate if it's pending nurse confirmation (isElderlyConfirmed and not yet isDone)
    bool shouldAnimate = !isDone || (isElderlyConfirmed && !isDone);

    return Opacity(
      opacity: isLater ? 0.5 : 1.0,
      child: Lottie.asset(
        'assets/animations/pickups.json',
        width: 45,
        height: 45,
        fit: BoxFit.contain,
        repeat: shouldAnimate,
        animate: true,
      ),
    );
  }
}
