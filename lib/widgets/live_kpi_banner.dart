import 'dart:async';

import 'package:flutter/material.dart';
import '../services/kpi_service.dart';
import '../services/api_client.dart';
import '../services/realtime_service.dart';

// بانر مؤشرات الأداء المباشرة من /kpi/dashboard
// يُعرض في شاشة الإدارة لإثبات التكامل الحي مع AWS RDS
class LiveKpiBanner extends StatefulWidget {
  const LiveKpiBanner({super.key});

  @override
  State<LiveKpiBanner> createState() => _LiveKpiBannerState();
}

class _LiveKpiBannerState extends State<LiveKpiBanner> {
  Future<KpiDashboard>? _future;
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
      if (_isAuthenticated) _future = KpiService.instance.getDashboard();
    });
    if (_isAuthenticated) _startRealtime();
  }

  void _startRealtime() {
    _realtimeSub ??= RealtimeService.instance.liveEventsFor({
      'kpi',
      'medications',
      'family_visits',
      'family_media',
      'complaints',
      'health',
    }).listen((_) {
      if (!mounted || !_isAuthenticated) return;
      _refresh();
    });
  }

  void _refresh() => setState(() {
        _future = KpiService.instance.getDashboard();
      });

  @override
  void dispose() {
    _realtimeSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAuthenticated) {
      return _shell(
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Icon(Icons.cloud_off_rounded, color: Color(0xFF94A3B8), size: 18),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'مؤشرات السحابة غير متاحة — سجّل دخول Cognito أولاً',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                    fontFamily: 'Cairo',
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return FutureBuilder<KpiDashboard>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return _shell(
            const Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    color: Color(0xFFFF9900),
                    strokeWidth: 2,
                  ),
                ),
                SizedBox(width: 10),
                Text(
                  'جاري قراءة مؤشرات الأداء من AWS RDS...',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Cairo',
                    color: Color(0xFFB45309),
                  ),
                ),
              ],
            ),
          );
        }
        if (snap.hasError) {
          return _shell(Row(
            children: [
              const Icon(Icons.error_outline_rounded,
                  color: Color(0xFFEF4444), size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'فشل جلب KPI: ${snap.error}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFFEF4444),
                    fontFamily: 'Cairo',
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ));
        }

        final k = snap.data!;
        return _shell(
          Column(
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
                        Text(
                          'Live KPI',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Cairo',
                            color: Color(0xFF065F46),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'AWS RDS · آخر ${k.periodDays} يوم',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Cairo',
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF9900), Color(0xFFFFB14E)],
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'AWS',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'Cairo',
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                reverse: true,
                child: Row(
                  children: [
                    _kpiTile(
                        'الالتزام الدوائي',
                        '${k.medicationAdherencePct.toStringAsFixed(0)}%',
                        const Color(0xFF10B981),
                        Icons.medication_outlined),
                    _kpiTile(
                        'الزيارات',
                        '${k.completedVisits}/${k.totalVisits}',
                        const Color(0xFF6366F1),
                        Icons.calendar_today_rounded),
                    _kpiTile('وسائط العائلة', '${k.totalMediaItems}',
                        const Color(0xFFEC4899), Icons.photo_library_outlined),
                    _kpiTile('الشكاوى المفتوحة', '${k.openComplaints}',
                        const Color(0xFFF59E0B), Icons.feedback_outlined),
                    _kpiTile('تنبيهات حرجة', '${k.criticalAlerts}',
                        const Color(0xFFEF4444), Icons.warning_amber_rounded),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _kpiTile(String label, String value, Color color, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(left: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      width: 110,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              fontFamily: 'Cairo',
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              fontFamily: 'Cairo',
              color: Color(0xFF64748B),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
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
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF9900).withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}
