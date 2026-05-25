import 'dart:async';

import 'package:flutter/material.dart';
import '../services/health_service.dart';
import '../services/api_client.dart';
import '../services/realtime_service.dart';
import 'sheets/record_vitals_sheet.dart';

class LiveVitalsBanner extends StatefulWidget {
  const LiveVitalsBanner({super.key});

  @override
  State<LiveVitalsBanner> createState() => _LiveVitalsBannerState();
}

class _LiveVitalsBannerState extends State<LiveVitalsBanner> {
  Future<_VitalsData>? _future;
  bool _isAuthenticated = false;
  StreamSubscription<Map<String, dynamic>>? _realtimeSub;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final token = await ApiClient.instance.getToken();
    if (!mounted) return;
    setState(() {
      _isAuthenticated = token != null;
      if (_isAuthenticated) _future = _load();
    });
    if (_isAuthenticated) _startRealtime();
  }

  void _startRealtime() {
    _realtimeSub ??=
        RealtimeService.instance.liveEventsFor({'health'}).listen((_) {
      if (!mounted || !_isAuthenticated) return;
      _refresh();
    });
  }

  Future<_VitalsData> _load() async {
    final vitals = await HealthService.instance.getVitals();
    final alerts = await HealthService.instance.getAlerts(status: 'active');
    return _VitalsData(vitals: vitals, alerts: alerts);
  }

  void _refresh() => setState(() => _future = _load());

  @override
  void dispose() {
    _realtimeSub?.cancel();
    super.dispose();
  }

  Future<void> _acknowledgeAlert(BackendHealthAlert alert) async {
    try {
      await HealthService.instance.acknowledgeAlert(alert.id);
      _refresh();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر تأكيد التنبيه حالياً')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAuthenticated) {
      return _shell(const Row(
        children: [
          Icon(Icons.cloud_off_rounded, color: Color(0xFF94A3B8), size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'سجّل دخولك لرؤية القراءات الحيوية',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF64748B),
                fontFamily: 'Cairo',
              ),
            ),
          ),
        ],
      ));
    }

    return FutureBuilder<_VitalsData>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return _shell(const Row(
            children: [
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    color: Color(0xFFFF9900), strokeWidth: 2),
              ),
              SizedBox(width: 10),
              Text(
                'جلب القراءات الحيوية والتنبيهات...',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Cairo',
                  color: Color(0xFFB45309),
                ),
              ),
            ],
          ));
        }
        if (snap.hasError) {
          return _shell(Row(
            children: [
              const Icon(Icons.error_outline_rounded,
                  color: Color(0xFFEF4444), size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'فشل: ${snap.error}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFFEF4444),
                    fontFamily: 'Cairo',
                  ),
                ),
              ),
            ],
          ));
        }

        final d = snap.data!;
        final criticalCount = d.alerts
            .where((a) => a.severity == 'critical' || a.severity == 'warning')
            .length;
        final latestVital = d.vitals.isNotEmpty ? d.vitals.first : null;

        return _shell(Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.circle, size: 8, color: Color(0xFF10B981)),
                      SizedBox(width: 6),
                      Text('Live',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Cairo',
                            color: Color(0xFF065F46),
                          )),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'القراءات الحيوية · ${d.vitals.length} قراءة · $criticalCount تنبيه نشط',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Cairo',
                      color: Color(0xFF1E293B),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                InkWell(
                  onTap: () =>
                      RecordVitalsSheet.show(context, onRecorded: _refresh),
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add_chart_rounded,
                            size: 12, color: Color(0xFF065F46)),
                        SizedBox(width: 4),
                        Text('تسجيل',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Cairo',
                              color: Color(0xFF065F46),
                            )),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                InkWell(
                  onTap: _refresh,
                  child: const Icon(Icons.refresh_rounded,
                      size: 18, color: Color(0xFF4338CA)),
                ),
              ],
            ),
            if (latestVital != null) ...[
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                reverse: true,
                child: Row(
                  children: [
                    if (latestVital.heartRate != null)
                      _vitalChip(
                        Icons.favorite_rounded,
                        'النبض',
                        '${latestVital.heartRate}',
                        'bpm',
                        const Color(0xFFEF4444),
                      ),
                    if (latestVital.bpSystolic != null)
                      _vitalChip(
                        Icons.monitor_heart_rounded,
                        'الضغط',
                        '${latestVital.bpSystolic}/${latestVital.bpDiastolic}',
                        '',
                        const Color(0xFF6366F1),
                      ),
                    if (latestVital.temperature != null)
                      _vitalChip(
                        Icons.thermostat_rounded,
                        'الحرارة',
                        '${latestVital.temperature}',
                        '°',
                        const Color(0xFFF59E0B),
                      ),
                    if (latestVital.oxygenSaturation != null)
                      _vitalChip(
                        Icons.air_rounded,
                        'الأكسجين',
                        '${latestVital.oxygenSaturation}',
                        '%',
                        const Color(0xFF06B6D4),
                      ),
                  ],
                ),
              ),
            ],
            if (d.alerts.isNotEmpty) ...[
              const SizedBox(height: 8),
              ...d.alerts.take(2).map((a) => _alertRow(a)),
            ],
          ],
        ));
      },
    );
  }

  Widget _vitalChip(
      IconData icon, String label, String value, String unit, Color color) {
    return Container(
      margin: const EdgeInsets.only(left: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 9,
                  color: Color(0xFF64748B),
                  fontFamily: 'Cairo',
                ),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'Cairo',
                      color: color,
                    ),
                  ),
                  if (unit.isNotEmpty)
                    Text(
                      ' $unit',
                      style: const TextStyle(
                        fontSize: 9,
                        color: Color(0xFF94A3B8),
                        fontFamily: 'Cairo',
                      ),
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _alertRow(BackendHealthAlert a) {
    final color = a.severity == 'critical'
        ? const Color(0xFFEF4444)
        : const Color(0xFFF59E0B);
    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: color, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${a.arabicVitalType}: ${a.recordedValue} (الحد: ${a.thresholdMin ?? "-"} - ${a.thresholdMax ?? "-"})',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                fontFamily: 'Cairo',
                color: color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              a.arabicSeverity,
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w900,
                fontFamily: 'Cairo',
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: () => _acknowledgeAlert(a),
            style: TextButton.styleFrom(
              foregroundColor: color,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: const Size(0, 28),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              'تم',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                fontFamily: 'Cairo',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _shell(Widget child) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            const Color(0xFFFFF7ED).withValues(alpha: 0.6),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFFF9900).withValues(alpha: 0.3),
          width: 1.2,
        ),
      ),
      child: child,
    );
  }
}

class _VitalsData {
  final List<BackendVital> vitals;
  final List<BackendHealthAlert> alerts;
  _VitalsData({required this.vitals, required this.alerts});
}
