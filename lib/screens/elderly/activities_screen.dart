import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/app_riverpod.dart';
import '../../models/app_models.dart';

class ActivitiesScreen extends ConsumerStatefulWidget {
  const ActivitiesScreen({super.key});

  @override
  ConsumerState<ActivitiesScreen> createState() => _ActivitiesScreenState();
}

class _ActivitiesScreenState extends ConsumerState<ActivitiesScreen>
    with TickerProviderStateMixin {
  late AnimationController _ringController;
  late AnimationController _glowController;
  late AnimationController _shimmerController;
  late AnimationController _bgController;

  int selectedDay = 1;
  final days = ['أمس', 'اليوم', 'غداً', 'الأسبوع'];
  final int targetPoints = 600;

  @override
  void initState() {
    super.initState();
    _ringController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500))
      ..forward();
    _glowController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2000))
      ..repeat(reverse: true);
    _shimmerController =
        AnimationController(vsync: this, duration: const Duration(seconds: 2))
          ..repeat();
    _bgController =
        AnimationController(vsync: this, duration: const Duration(seconds: 15))
          ..repeat();
  }

  @override
  void dispose() {
    _ringController.dispose();
    _glowController.dispose();
    _shimmerController.dispose();
    _bgController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = ref.watch(appRiverpod);

    // اعرض احتفال الوسام عند فتح وسام جديد
    ref.listen<AppRiverpod>(appRiverpod, (prev, next) {
      if (next.newlyUnlockedBadge != null &&
          prev?.newlyUnlockedBadge != next.newlyUnlockedBadge) {
        final badge = next.newlyUnlockedBadge!;
        // نمسح الإشعار ونعرض الاحتفال خارج دورة البناء
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          ref.read(appRiverpod).clearBadgeNotification();
          _showBadgeCelebration(context, badge);
        });
      }
    });

    final int points = provider.currentUser.points;
    final double progress = (points / targetPoints).clamp(0.0, 1.0);

    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOut,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, 30 * (1 - value)),
          child: child,
        ),
      ),
      child: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(provider, points, progress),
            _buildDaySelector(),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildSectionTitle('جدول أنشطة اليوم'),
                  const SizedBox(height: 10),
                  _buildActivitiesList(provider),
                  const SizedBox(height: 20),
                  _buildPointsCard(points, progress),
                  const SizedBox(height: 20),
                  _buildSectionTitle('أوسمةُ فخرٍ بعطائك'),
                  const SizedBox(height: 10),
                  _buildBadgesSection(),
                  const SizedBox(height: 20),
                  _buildLeaderboard(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Converts "HH:MM" to "HH:MM ص" or "HH:MM م" for clear Arabic display.
  String _arabicTime(String time) {
    final parts = time.split(':');
    if (parts.length < 2) return time;
    final hour = int.tryParse(parts[0]);
    if (hour == null) return time;
    final suffix = hour < 12 ? 'ص' : 'م';
    return '$time $suffix';
  }

  // ─── Header ──────────────────────────────────────────────────────────
  Widget _buildHeader(AppRiverpod provider, int points, double progress) {
    return AnimatedBuilder(
      animation: _bgController,
      builder: (context, child) => Container(
        clipBehavior: Clip.antiAlias,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF312E81), Color(0xFF4F46E5), Color(0xFF6366F1)],
          ),
        ),
        child: Stack(
          children: [
            _buildBlob(180, const Color(0xFF6C63FF).withValues(alpha: 0.3), -40,
                -40, 0.8, _bgController),
            _buildBlob(140, const Color(0xFFF472B6).withValues(alpha: 0.2), 100,
                -20, 1.2, _bgController),
            _buildBlob(100, const Color(0xFF60A5FA).withValues(alpha: 0.2), -20,
                120, 0.9, _bgController),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 40, 28, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  const Text('🏆 أنشطتي ونقاطي',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  const Text('أنت في المركز الأول هذا الشهر 👑',
                      style: TextStyle(color: Colors.white70, fontSize: 17)),
                  const SizedBox(height: 20),
                  // Stats row
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            _statRow(
                                Icons.emoji_events_rounded,
                                const Color(0xFFfbbf24),
                                'المركز الأول 👑',
                                'هذا الشهر'),
                            const SizedBox(height: 10),
                            _statRow(
                                Icons.check_circle_rounded,
                                const Color(0xFF34d399),
                                '${provider.currentUser.completedActivities} نشاط',
                                'مكتمل'),
                            const SizedBox(height: 10),
                            _statRow(
                                Icons.local_fire_department_rounded,
                                const Color(0xFFf87171),
                                '${provider.currentUser.streakDays} يوم',
                                'متواصل 🔥'),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      AnimatedBuilder(
                        animation: _ringController,
                        builder: (context, _) => SizedBox(
                          width: 100,
                          height: 100,
                          child: CustomPaint(
                            painter: _RingPainter(
                                progress: _ringController.value * progress),
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text('$points',
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold)),
                                  const Text('نقطة',
                                      style: TextStyle(
                                          color: Colors.white70, fontSize: 13)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
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

  Widget _buildBlob(double size, Color color, double top, double left,
      double speed, AnimationController controller) {
    return Positioned(
      top: top + (sin(controller.value * 2 * pi * speed) * 30),
      left: left + (cos(controller.value * 2 * pi * speed) * 30),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
                color: color.withValues(alpha: 0.3),
                blurRadius: 40,
                spreadRadius: 10)
          ],
        ),
      ),
    );
  }

  Widget _statRow(IconData icon, Color color, String main, String sub) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(main,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold)),
              Text(sub,
                  style: const TextStyle(color: Colors.white60, fontSize: 13)),
            ],
          ),
        ),
      ],
    );
  }

  // ─── Day Selector ────────────────────────────────────────────────────
  Widget _buildDaySelector() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: List.generate(days.length, (i) {
          final isActive = selectedDay == i;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => selectedDay = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isActive
                      ? const Color(0xFF4F46E5)
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  days[i],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: isActive ? Colors.white : const Color(0xFF94a3b8),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ─── Section Title ───────────────────────────────────────────────────
  Widget _buildSectionTitle(String title) {
    return Text(title,
        style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1e293b)));
  }

  // ─── Activities ──────────────────────────────────────────────────────
  Widget _buildActivitiesList(AppRiverpod provider) {
    final list = provider.getActivitiesForDay(selectedDay);
    if (list.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFe2e8f0)),
        ),
        child: const Center(
          child: Column(children: [
            Text('📭', style: TextStyle(fontSize: 48)),
            SizedBox(height: 12),
            Text('لا توجد أنشطة في هذا اليوم',
                style: TextStyle(fontSize: 20, color: Colors.grey)),
          ]),
        ),
      );
    }
    return Column(
      children: list
          .map((act) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: act.status == 'active'
                    ? _buildActiveCard(provider, act)
                    : _buildCard(act),
              ))
          .toList(),
    );
  }

  Widget _buildCard(Activity act) {
    final isDone = act.status == 'done';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDone ? const Color(0xFFF0FDF4) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDone ? const Color(0xFF86EFAC) : const Color(0xFFE2E8F0),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
              color: const Color(0xFF6366F1).withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Row(
        children: [
          // Right: Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(act.name,
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: isDone
                            ? const Color(0xFF15803D)
                            : const Color(0xFF1e293b))),
                const SizedBox(height: 4),
                Text(act.location,
                    style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Icon(Icons.access_time_rounded,
                        size: 16, color: Colors.grey.shade500),
                    const SizedBox(width: 6),
                    Text(_arabicTime(act.time),
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade700)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Left: Emoji Box
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: isDone ? const Color(0xFFDCFCE7) : const Color(0xFFEDE9FE),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: (isDone
                          ? const Color(0xFF16A34A)
                          : const Color(0xFF6366F1))
                      .withValues(alpha: 0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                )
              ],
            ),
            child: Center(
              child: isDone
                  ? const Icon(Icons.check_circle_rounded,
                      color: Color(0xFF16A34A), size: 30)
                  : Text(act.emoji, style: const TextStyle(fontSize: 28)),
            ),
          ),
          const SizedBox(width: 12),
          // Far Left: Voice Button
          IconButton(
            icon: const Icon(Icons.volume_up_rounded,
                color: Color(0xFF6366F1), size: 28),
            onPressed: () => ref.read(appRiverpod).startReading(
                '${act.name}، ${act.location}، الساعة ${act.time}'),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveCard(AppRiverpod provider, Activity act) {
    return AnimatedBuilder(
      animation: _glowController,
      builder: (context, _) => GestureDetector(
        onTap: () {
          provider.completeActivity(act.id);
          _showPostSessionEvaluation(context, provider, act.name);
        },
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF4F46E5)
                    .withValues(alpha: 0.25 + _glowController.value * 0.2),
                blurRadius: 20 + _glowController.value * 10,
                spreadRadius: _glowController.value * 3,
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Text(act.emoji, style: const TextStyle(fontSize: 26)),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(act.name,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w900)),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3)),
                      ),
                      child: const Text(
                        '● جارٍ الآن  •  اضغط للإتمام',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Points Card ─────────────────────────────────────────────────────
  Widget _buildPointsCard(int points, double progress) {
    final remaining = (targetPoints - points).clamp(0, targetPoints);
    final pct = (progress * 100).round();
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFf1f5f9), width: 2),
        boxShadow: [
          BoxShadow(
              color: const Color(0xFF6366f1).withValues(alpha: 0.15),
              blurRadius: 10,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$points نقطة',
                      style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF1e293b),
                          letterSpacing: -1)),
                  const Text('إجمالي نقاطك هذا الشهر',
                      style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFF64748b),
                          fontWeight: FontWeight.w600)),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFeef2ff),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.emoji_events_rounded,
                    color: Color(0xFF4F46E5), size: 40),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 14,
              backgroundColor: const Color(0xFFf1f5f9),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              const Text('🎁', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  '$pct٪ من الهدف — باقي $remaining نقطة للجائزة',
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF64748b)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.end,
            children: [
              _chip('رياضة +٣٠', '🏃'),
              _chip('ذاكرة +٢٥', '🧠'),
              _chip('قراءة +٢٠', '📖'),
              _chip('حضور +١٠', '✅'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chip(String text, String emoji) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFf8fafc),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFf1f5f9)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(text,
              style: const TextStyle(
                  fontSize: 15,
                  color: Color(0xFF6366f1),
                  fontWeight: FontWeight.w700)),
          const SizedBox(width: 8),
          Text(emoji, style: const TextStyle(fontSize: 18)),
        ],
      ),
    );
  }

  // ─── Badges ──────────────────────────────────────────────────────────
  Widget _buildBadgesSection() {
    final earnedIds = ref.watch(appRiverpod).earnedBadgeIds;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      reverse: true,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: BadgeDefinition.all.map((badge) {
          final locked = !earnedIds.contains(badge.id);
          final color = locked ? const Color(0xFF94A3B8) : badge.color;
          return Container(
            width: 170,
            margin: const EdgeInsets.only(left: 14),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: locked
                    ? [const Color(0xFFF8FAFC), const Color(0xFFF1F5F9)]
                    : [badge.color.withValues(alpha: 0.05), Colors.white],
              ),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: locked
                    ? const Color(0xFFE2E8F0)
                    : badge.color.withValues(alpha: 0.3),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: locked
                      ? Colors.transparent
                      : badge.color.withValues(alpha: 0.15),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    if (!locked)
                      Container(
                        width: 65,
                        height: 65,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: badge.color.withValues(alpha: 0.1),
                        ),
                      ),
                    Icon(
                      locked ? Icons.lock_rounded : badge.icon,
                      color: locked ? const Color(0xFFCBD5E1) : badge.color,
                      size: 40,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  badge.name,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: locked
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF1E293B),
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: locked
                        ? const Color(0xFFF1F5F9)
                        : badge.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    locked ? badge.requirement : 'مكتسب بفخر 🏆',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: locked ? const Color(0xFFCBD5E1) : color,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  void _showBadgeCelebration(BuildContext context, BadgeDefinition badge) {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (_) => _BadgeCelebrationDialog(badge: badge),
    );
  }

  // ─── Leaderboard ─────────────────────────────────────────────────────
  Widget _buildLeaderboard() {
    final provider = ref.read(appRiverpod);
    final currentName = provider.currentUser.name;
    final residents = provider.residentFiles;
    String toArabicDigit(int n) {
      const map = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
      return n.toString().split('').map((c) {
        final i = int.tryParse(c);
        return i == null ? c : map[i];
      }).join();
    }

    // Build full list: current user gets real points, all others start at 0.
    // Sort descending by points so top scorers appear first.
    final allRows = residents.isNotEmpty
        ? (residents.map((r) {
            final isMe = r.name == currentName;
            return {
              'ini': r.initials,
              'name': r.name,
              'pts': isMe ? provider.currentUser.points : 0,
              'me': isMe,
            };
          }).toList()
          ..sort((a, b) => (b['pts'] as int).compareTo(a['pts'] as int)))
        : currentName.trim().isEmpty
            ? <Map<String, Object>>[]
            : [
                {
                  'ini': String.fromCharCode(currentName.runes.first),
                  'name': currentName,
                  'pts': provider.currentUser.points,
                  'me': true,
                },
              ];

    final rows = allRows.asMap().entries.map((e) {
      final r = e.value;
      return {
        'rank': toArabicDigit(e.key + 1),
        'ini': r['ini'],
        'name': r['name'],
        'pts': toArabicDigit(r['pts'] as int),
        'me': r['me'],
      };
    }).toList();

    final rankColors = [
      const Color(0xFFD97706),
      const Color(0xFF64748B),
      const Color(0xFFBE185D),
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFEDE9FE), width: 1.5),
        boxShadow: [
          BoxShadow(
              color: const Color(0xFF6366F1).withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('🌟 لوح الشرف',
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B))),
          const SizedBox(height: 16),
          ...rows.asMap().entries.map((e) {
            final r = e.value;
            final isMe = r['me'] as bool;
            final color = e.key < rankColors.length
                ? rankColors[e.key]
                : const Color(0xFF94A3B8);
            return Column(
              children: [
                if (e.key > 0) Divider(color: Colors.grey.shade100, height: 1),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(r['rank'] as String,
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: color)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: isMe
                              ? const Color(0xFF4F46E5)
                              : const Color(0xFFF1F5F9),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(r['ini'] as String,
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: isMe
                                      ? Colors.white
                                      : const Color(0xFF475569))),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(r['name'] as String,
                                style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF0F172A))),
                            if (isMe)
                              const Text('أنت 👑',
                                  style: TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF4F46E5),
                                      fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text('${r['pts']} ⭐',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: color)),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  // ── تقييم ما بعد النشاط ──────────────────────────────────────────────
  void _showPostSessionEvaluation(
      BuildContext context, AppRiverpod provider, String activityName) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                  width: 50,
                  height: 5,
                  decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(4))),
            ),
            const SizedBox(height: 20),
            const Text('أحسنت! 🌟',
                style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A))),
            const SizedBox(height: 8),
            Text('تم إنجاز $activityName بنجاح',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: Color(0xFF64748B))),
            const SizedBox(height: 28),
            _buildEvaluationCard(
              icon: Icons.volunteer_activism_rounded,
              iconBg: const Color(0xFF86EFAC),
              iconColor: const Color(0xFF15803D),
              bg: const Color(0xFFF0FDF4),
              border: const Color(0xFFBBF7D0),
              title: 'كيف كانت جلستك التطوعية؟',
              subtitle: 'أخبرنا برأيك في المتطوع الذي زارك',
              titleColor: const Color(0xFF166534),
              subtitleColor: const Color(0xFF15803D),
              onTap: () {
                Navigator.pop(ctx);
                _showVolunteerRatingSheet(context, provider, activityName);
              },
            ),
            const SizedBox(height: 12),
            _buildEvaluationCard(
              icon: Icons.star_rounded,
              iconBg: const Color(0xFF93C5FD),
              iconColor: const Color(0xFF1D4ED8),
              bg: const Color(0xFFEFF6FF),
              border: const Color(0xFFBFDBFE),
              title: 'تقييم جودة الخدمة',
              subtitle: 'رأيك يهمنا في الدار والممرض والأخصائي',
              titleColor: const Color(0xFF1E40AF),
              subtitleColor: const Color(0xFF1D4ED8),
              onTap: () {
                Navigator.pop(ctx);
                _showServiceRatingSheet(context, provider);
              },
            ),
            const SizedBox(height: 12),
            _buildEvaluationCard(
              icon: Icons.room_service_rounded,
              iconBg: const Color(0xFFFCA5A5),
              iconColor: const Color(0xFFB91C1C),
              bg: const Color(0xFFFEF2F2),
              border: const Color(0xFFFECACA),
              title: 'طلب مساعدة / شكوى',
              subtitle: 'هل تحتاج لشيء؟ نحن هنا لخدمتك',
              titleColor: const Color(0xFF991B1B),
              subtitleColor: const Color(0xFFB91C1C),
              onTap: () {
                Navigator.pop(ctx);
                _showComplaintSheet(context, provider);
              },
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('ربما لاحقاً',
                  style: TextStyle(fontSize: 16, color: Color(0xFF94A3B8))),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEvaluationCard({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required Color bg,
    required Color border,
    required String title,
    required String subtitle,
    required Color titleColor,
    required Color subtitleColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: border, width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
              child: Icon(icon, color: iconColor, size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: titleColor)),
                  Text(subtitle,
                      style: TextStyle(fontSize: 13, color: subtitleColor)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, color: titleColor, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingEmoji(String emoji, String label, int value,
      int selectedValue, VoidCallback onTap) {
    final isSelected = value == selectedValue;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFFDCFCE7)
                  : const Color(0xFFF1F5F9),
              shape: BoxShape.circle,
              border: Border.all(
                  color:
                      isSelected ? const Color(0xFF22C55E) : Colors.transparent,
                  width: 3),
            ),
            child:
                Text(emoji, style: TextStyle(fontSize: isSelected ? 48 : 36)),
          ),
          const SizedBox(height: 12),
          Text(label,
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected
                      ? const Color(0xFF166534)
                      : const Color(0xFF64748B))),
        ],
      ),
    );
  }

  void _showVolunteerRatingSheet(
      BuildContext context, AppRiverpod provider, String activityName) {
    int selectedRating = 0;
    final commentController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
              left: 20,
              right: 20,
              top: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                    width: 50,
                    height: 5,
                    decoration: BoxDecoration(
                        color: const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(4))),
              ),
              const SizedBox(height: 24),
              const Text('تقييم زيارة التطوع 🌟',
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A))),
              const SizedBox(height: 12),
              Text('كيف كان وقتك في $activityName؟',
                  style:
                      const TextStyle(fontSize: 18, color: Color(0xFF475569))),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildRatingEmoji('☹️', 'غير سعيد', 1, selectedRating,
                      () => setModalState(() => selectedRating = 1)),
                  _buildRatingEmoji('😐', 'عادي', 2, selectedRating,
                      () => setModalState(() => selectedRating = 2)),
                  _buildRatingEmoji('😊', 'سعيد', 3, selectedRating,
                      () => setModalState(() => selectedRating = 3)),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: commentController,
                maxLines: 2,
                style: const TextStyle(fontSize: 16),
                decoration: InputDecoration(
                  hintText: 'اكتب رأيك هنا (اختياري)...',
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed: selectedRating == 0
                      ? null
                      : () {
                          provider.rateVolunteerSession('v_123', selectedRating,
                              comment: commentController.text);
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('شكراً لتقييمك! 🌟',
                                  style: TextStyle(fontSize: 18)),
                              backgroundColor: Color(0xFF22C55E),
                              duration: Duration(seconds: 3),
                            ),
                          );
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF22C55E),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                    disabledBackgroundColor: const Color(0xFFE2E8F0),
                  ),
                  child: const Text('إرسال التقييم',
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  void _showServiceRatingSheet(BuildContext context, AppRiverpod provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                  width: 50,
                  height: 5,
                  decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(4))),
            ),
            const SizedBox(height: 24),
            const Text('ماذا تريد أن تقيم اليوم؟ ⭐',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A))),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                    child: _buildServiceButton('الأخصائي', () {
                  Navigator.pop(ctx);
                  _showServiceReviewDialog(context, provider, 'specialist');
                })),
                const SizedBox(width: 8),
                Expanded(
                    child: _buildServiceButton('الممرض', () {
                  Navigator.pop(ctx);
                  _showServiceReviewDialog(context, provider, 'nurse');
                })),
                const SizedBox(width: 8),
                Expanded(
                    child: _buildServiceButton('الدار', () {
                  Navigator.pop(ctx);
                  _showServiceReviewDialog(context, provider, 'home');
                })),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceButton(String label, VoidCallback onTap) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF3B82F6),
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 0,
      ),
      child: Text(label,
          style: const TextStyle(
              color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
    );
  }

  void _showServiceReviewDialog(
      BuildContext context, AppRiverpod provider, String toRole) {
    int selectedRating = 0;
    final commentController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          title: Text(
              'تقييم ${toRole == 'specialist' ? 'الأخصائي' : toRole == 'nurse' ? 'الممرض' : 'الدار'}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontFamily: 'Cairo')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildRatingEmoji('☹️', 'غير سعيد', 1, selectedRating,
                        () => setD(() => selectedRating = 1)),
                    _buildRatingEmoji('😐', 'عادي', 2, selectedRating,
                        () => setD(() => selectedRating = 2)),
                    _buildRatingEmoji('😊', 'سعيد', 3, selectedRating,
                        () => setD(() => selectedRating = 3)),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: commentController,
                maxLines: 2,
                style: const TextStyle(fontSize: 16),
                decoration: InputDecoration(
                  hintText: 'اكتب رأيك هنا (اختياري)...',
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('إلغاء')),
            ElevatedButton(
              onPressed: selectedRating == 0
                  ? null
                  : () {
                      provider.addReview(Review(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        fromRole: 'elderly',
                        fromName: provider.currentUser.name,
                        toRole: toRole,
                        rating: selectedRating.toDouble(),
                        comment: commentController.text,
                        date: DateTime.now().toString(),
                      ));
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('شكراً لتقييمك! 🌟',
                              style: TextStyle(fontSize: 18)),
                          backgroundColor: Color(0xFF22C55E),
                          duration: Duration(seconds: 3),
                        ),
                      );
                    },
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF22C55E)),
              child: const Text('إرسال', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _showComplaintSheet(BuildContext context, AppRiverpod provider) {
    String selectedType = 'جودة الطعام';
    final descController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
              left: 20,
              right: 20,
              top: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                    width: 50,
                    height: 5,
                    decoration: BoxDecoration(
                        color: const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(4))),
              ),
              const SizedBox(height: 24),
              const Text('أخبرنا بما يزعجك',
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A))),
              const SizedBox(height: 24),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  'جودة الطعام',
                  'صيانة الغرفة',
                  'مساعدة في التنظيف',
                  'أحتاج ممرض',
                  'أخرى'
                ].map((type) {
                  final isSelected = selectedType == type;
                  return GestureDetector(
                    onTap: () => setModalState(() => selectedType = type),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF6C63FF)
                            : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(type,
                          style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : const Color(0xFF475569),
                              fontSize: 18,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal)),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: descController,
                maxLines: 2,
                style: const TextStyle(fontSize: 18),
                decoration: InputDecoration(
                  hintText: 'اكتب تفاصيل إضافية إن أردت...',
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed: () {
                    provider.submitComplaint(
                        descController.text.isNotEmpty
                            ? descController.text
                            : 'طلب من المسن بخصوص $selectedType',
                        selectedType,
                        'مسن');
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('تم استلام طلبك، سنخدمك فوراً 🙏',
                            style: TextStyle(fontSize: 18)),
                        backgroundColor: Color(0xFF6C63FF),
                        duration: Duration(seconds: 3),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C63FF),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                  ),
                  child: const Text('إرسال الطلب',
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Ring Painter ─────────────────────────────────────────────────────
class _RingPainter extends CustomPainter {
  final double progress;
  _RingPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    const radius = 42.0;

    canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.2)
          ..strokeWidth = 7
          ..style = PaintingStyle.stroke);

    if (progress > 0) {
      canvas.drawArc(
          Rect.fromCircle(center: center, radius: radius),
          -pi / 2,
          2 * pi * progress,
          false,
          Paint()
            ..color = const Color(0xFFfbbf24)
            ..strokeWidth = 7
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round);
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) => old.progress != progress;
}

// ─── Badge Celebration Dialog ──────────────────────────────────────────
class _BadgeCelebrationDialog extends StatefulWidget {
  const _BadgeCelebrationDialog({required this.badge});
  final BadgeDefinition badge;

  @override
  State<_BadgeCelebrationDialog> createState() =>
      _BadgeCelebrationDialogState();
}

class _BadgeCelebrationDialogState extends State<_BadgeCelebrationDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _scale = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final badge = widget.badge;
    return FadeTransition(
      opacity: _fade,
      child: Dialog(
        backgroundColor: Colors.transparent,
        child: ScaleTransition(
          scale: _scale,
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: badge.color.withValues(alpha: 0.3),
                  blurRadius: 40,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: badge.color.withValues(alpha: 0.12),
                    border: Border.all(
                        color: badge.color.withValues(alpha: 0.4), width: 3),
                  ),
                  child: Icon(badge.icon, color: badge.color, size: 52),
                ),
                const SizedBox(height: 20),
                const Text(
                  '🎉 مبروك!',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'حصلت على وسام',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  badge.name,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: badge.color,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: badge.color,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: const Text(
                      'رائع! 🌟',
                      style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 18,
                          fontWeight: FontWeight.w800),
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
}
