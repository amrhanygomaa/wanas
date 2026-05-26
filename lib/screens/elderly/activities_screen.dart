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
    _bgController = AnimationController(
        vsync: this, duration: const Duration(seconds: 15))
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
                    Text(act.time,
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
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('أحسنت! تم إنجاز ${act.name} 🌟',
                style: const TextStyle(fontSize: 20)),
            backgroundColor: const Color(0xFF10B981),
            duration: const Duration(seconds: 3),
          ));
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
    final badges = [
      {
        'icon': Icons.stars_rounded,
        'label': 'وسام الحكمة',
        'color': const Color(0xFFFBBF24),
        'locked': false
      },
      {
        'icon': Icons.favorite_rounded,
        'label': 'صديق الجميع',
        'color': const Color(0xFFEC4899),
        'locked': false
      },
      {
        'icon': Icons.lock_outline_rounded,
        'label': 'بطل النشاط',
        'color': const Color(0xFF94A3B8),
        'locked': true
      },
      {
        'icon': Icons.lock_outline_rounded,
        'label': 'خبير السعادة',
        'color': const Color(0xFF94A3B8),
        'locked': true
      },
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      reverse: true,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: badges.map((b) {
          final locked = b['locked'] as bool;
          final color = b['color'] as Color;
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
                    : [
                        color.withValues(alpha: 0.05),
                        Colors.white,
                      ],
              ),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: locked
                    ? const Color(0xFFE2E8F0)
                    : color.withValues(alpha: 0.3),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: locked
                      ? Colors.transparent
                      : color.withValues(alpha: 0.15),
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
                          color: color.withValues(alpha: 0.1),
                        ),
                      ),
                    Icon(
                      locked ? Icons.lock_rounded : b['icon'] as IconData,
                      color: locked ? const Color(0xFFCBD5E1) : color,
                      size: 40,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  b['label'] as String,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: locked ? const Color(0xFF94A3B8) : const Color(0xFF1E293B),
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: locked
                        ? Colors.transparent
                        : color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    locked ? 'بانتظارك ✨' : 'مكتسب بفخر 🏆',
                    style: TextStyle(
                      fontSize: 12,
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

    final rows = residents.isNotEmpty
        ? residents.take(3).toList().asMap().entries.map((entry) {
            final i = entry.key;
            final r = entry.value;
            final isMe = r.name == currentName;
            return {
              'rank': toArabicDigit(i + 1),
              'ini': r.initials,
              'name': r.name,
              'pts': isMe
                  ? toArabicDigit(provider.currentUser.points)
                  : toArabicDigit(max(310, 370 - (i * 30)).toInt()),
              'me': isMe,
            };
          }).toList()
        : [
            {
              'rank': toArabicDigit(1),
              'ini': 'مح',
              'name': currentName.trim().isEmpty ? 'الحاج محمود' : currentName,
              'pts': toArabicDigit(max(provider.currentUser.points, 370).toInt()),
              'me': true,
            },
            {
              'rank': toArabicDigit(2),
              'ini': 'فا',
              'name': 'الحاجة فاطمة',
              'pts': toArabicDigit(340),
              'me': false,
            },
            {
              'rank': toArabicDigit(3),
              'ini': 'أح',
              'name': 'الحاج أحمد',
              'pts': toArabicDigit(310),
              'me': false,
            },
          ];
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
            final color = rankColors[e.key];
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
