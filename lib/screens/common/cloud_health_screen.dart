import 'package:flutter/material.dart';
import '../../config/api_config.dart';
import '../../services/api_client.dart';
import '../../services/auth_service.dart';
import '../../services/residents_service.dart';
import '../../services/kpi_service.dart';
import '../../services/complaints_service.dart';
import '../../services/family_bridge_service.dart';
import '../../services/ai_service.dart';

// شاشة "صحة السحابة" — تختبر كل الـ services حية
// تُستخدم في الدفاع لإثبات أن كل التكاملات شغّالة
class CloudHealthScreen extends StatefulWidget {
  const CloudHealthScreen({super.key});

  @override
  State<CloudHealthScreen> createState() => _CloudHealthScreenState();
}

class _ServiceCheck {
  final String name;
  final String description;
  final IconData icon;
  final Color color;
  final Future<String> Function() check;

  _ServiceCheck({
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
    required this.check,
  });
}

enum _Status { idle, running, ok, fail }

class _CheckState {
  _Status status = _Status.idle;
  String? result;
  Duration? duration;
}

class _CloudHealthScreenState extends State<CloudHealthScreen> {
  late final List<_ServiceCheck> _services;
  late final List<_CheckState> _states;

  @override
  void initState() {
    super.initState();
    _services = [
      _ServiceCheck(
        name: 'Backend Health',
        description: 'EC2 · NestJS · /health',
        icon: Icons.dns_rounded,
        color: const Color(0xFFFF9900),
        check: () async {
          final r = await ApiClient.instance.get('/health', auth: false);
          return 'status: ${r['status']}';
        },
      ),
      _ServiceCheck(
        name: 'السيرفر',
        description: 'JWT validation · ${ApiConfig.cognitoUserPoolId}',
        icon: Icons.verified_user_rounded,
        color: const Color(0xFF7B1FA2),
        check: () async {
          final r = await ApiClient.instance.get('/auth/me');
          return '${r['email']} · ${(r['roles'] as List).join(",")}';
        },
      ),
      _ServiceCheck(
        name: 'السيرفر (PostgreSQL)',
        description: 'Residents table · facility-scoped',
        icon: Icons.storage_rounded,
        color: const Color(0xFF3B82F6),
        check: () async {
          final residents = await ResidentsService.instance.getAll();
          return '${residents.length} resident(s) loaded';
        },
      ),
      _ServiceCheck(
        name: 'KPI Aggregator',
        description: 'GET /kpi/dashboard',
        icon: Icons.analytics_rounded,
        color: const Color(0xFF10B981),
        check: () async {
          final k = await KpiService.instance.getDashboard();
          return 'adherence: ${k.medicationAdherencePct}% · visits: ${k.totalVisits}';
        },
      ),
      _ServiceCheck(
        name: 'Complaints API',
        description: 'GET /complaints',
        icon: Icons.feedback_rounded,
        color: const Color(0xFFF59E0B),
        check: () async {
          final c = await ComplaintsService.instance.getAll();
          final open = c
              .where((x) => x.status == 'open' || x.status == 'in_progress')
              .length;
          return '${c.length} total · $open open';
        },
      ),
      _ServiceCheck(
        name: 'Family Bridge',
        description: 'GET /family-bridge/visits',
        icon: Icons.family_restroom_rounded,
        color: const Color(0xFFEC4899),
        check: () async {
          final v = await FamilyBridgeService.instance.getVisits();
          return '${v.length} visit(s) · ${v.where((x) => x.status == "pending").length} pending';
        },
      ),
      _ServiceCheck(
        name: 'السيرفر Bedrock (AI)',
        description: 'POST /ai/chat · Claude Haiku',
        icon: Icons.smart_toy_rounded,
        color: const Color(0xFF6366F1),
        check: () async {
          final r = await AiService.instance.sendChat(
            message: 'health check ping',
            residentName: 'System',
            language: 'ar-eg',
          );
          return 'mode=${r.mode} · ${r.bedrockEnabled ? "Bedrock active" : "Bedrock inactive"}';
        },
      ),
      _ServiceCheck(
        name: 'AI Recommendations',
        description: 'GET /ai/recommendations/:id',
        icon: Icons.psychology_rounded,
        color: const Color(0xFF8B5CF6),
        check: () async {
          final residents = await ResidentsService.instance.getAll();
          if (residents.isEmpty) {
            throw StateError('No resident found in السيرفر');
          }
          final r =
              await AiService.instance.getRecommendations(residents.first.id);
          return 'flag=${r.flag} · ${r.summary.substring(0, r.summary.length > 40 ? 40 : r.summary.length)}...';
        },
      ),
    ];
    _states = List.generate(_services.length, (_) => _CheckState());
  }

  Future<void> _runOne(int i) async {
    setState(() {
      _states[i].status = _Status.running;
      _states[i].result = null;
    });
    final sw = Stopwatch()..start();
    try {
      final result = await _services[i].check();
      sw.stop();
      if (!mounted) return;
      setState(() {
        _states[i].status = _Status.ok;
        _states[i].result = result;
        _states[i].duration = sw.elapsed;
      });
    } catch (e) {
      sw.stop();
      if (!mounted) return;
      setState(() {
        _states[i].status = _Status.fail;
        _states[i].result = e.toString();
        _states[i].duration = sw.elapsed;
      });
    }
  }

  Future<void> _runAll() async {
    for (int i = 0; i < _services.length; i++) {
      await _runOne(i);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService.instance.currentUser;
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'صحة السحابة',
          style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
        ),
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          _buildHeader(user),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _services.length,
              itemBuilder: (_, i) => _buildServiceCard(i),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _runAll,
                  icon: const Icon(Icons.cloud_sync_rounded),
                  label: const Text(
                    'تشغيل كل الفحوصات',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Cairo',
                      fontSize: 15,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF9900),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(CognitoUserInfo? user) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.cloud_done_rounded,
                  color: Color(0xFFFF9900), size: 28),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'مراقبة التكامل المباشر',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Cairo',
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF9900), Color(0xFFFFB14E)],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'السيرفر',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'Cairo',
                    fontSize: 12,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            ApiConfig.baseUrl,
            style: TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 11,
              fontFamily: 'monospace',
            ),
          ),
          if (user != null) ...[
            const SizedBox(height: 4),
            Text(
              'الجلسة: ${user.email} · ${user.roles.join(",")} · ${user.facilityId}',
              style: const TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 11,
                fontFamily: 'Cairo',
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildServiceCard(int i) {
    final s = _services[i];
    final state = _states[i];

    Color statusColor;
    IconData statusIcon;
    String statusLabel;
    switch (state.status) {
      case _Status.idle:
        statusColor = const Color(0xFF94A3B8);
        statusIcon = Icons.circle_outlined;
        statusLabel = 'لم يُختبر';
        break;
      case _Status.running:
        statusColor = const Color(0xFFFF9900);
        statusIcon = Icons.sync_rounded;
        statusLabel = 'يفحص...';
        break;
      case _Status.ok:
        statusColor = const Color(0xFF10B981);
        statusIcon = Icons.check_circle_rounded;
        statusLabel = 'يعمل ✓';
        break;
      case _Status.fail:
        statusColor = const Color(0xFFEF4444);
        statusIcon = Icons.cancel_rounded;
        statusLabel = 'فشل';
        break;
    }

    return InkWell(
      onTap: () => _runOne(i),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: statusColor.withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(
              color: statusColor.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: s.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(s.icon, color: s.color, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Cairo',
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        s.description,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF64748B),
                          fontFamily: 'Cairo',
                        ),
                      ),
                    ],
                  ),
                ),
                if (state.status == _Status.running)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFFFF9900),
                    ),
                  )
                else
                  Icon(statusIcon, color: statusColor, size: 22),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Cairo',
                      color: statusColor,
                    ),
                  ),
                ),
                if (state.duration != null) ...[
                  const SizedBox(width: 6),
                  Text(
                    '${state.duration!.inMilliseconds}ms',
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFF94A3B8),
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
                const Spacer(),
                if (state.status == _Status.idle)
                  const Text(
                    'انقر للفحص',
                    style: TextStyle(
                      fontSize: 10,
                      color: Color(0xFF94A3B8),
                      fontFamily: 'Cairo',
                    ),
                  ),
              ],
            ),
            if (state.result != null) ...[
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  state.result!,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF334155),
                    fontFamily: 'monospace',
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
