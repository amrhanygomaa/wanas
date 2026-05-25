import 'dart:async';

import 'package:flutter/material.dart';
import '../services/medications_service.dart';
import '../services/api_client.dart';
import '../services/realtime_service.dart';

class _Dose {
  final String id;
  final String scheduledTime;
  final String status;
  final String? medicationName;
  final String? residentName;
  _Dose({
    required this.id,
    required this.scheduledTime,
    required this.status,
    this.medicationName,
    this.residentName,
  });

  factory _Dose.fromJson(Map<String, dynamic> j) => _Dose(
        id: (j['id'] ?? '').toString(),
        scheduledTime: (j['scheduledTime'] ?? '').toString(),
        status: (j['status'] ?? 'pending').toString(),
        medicationName: j['medicationName']?.toString() ??
            j['drugName']?.toString() ??
            j['schedule']?['medicationName']?.toString(),
        residentName: j['residentName']?.toString(),
      );
}

class LiveMedicationsBanner extends StatefulWidget {
  const LiveMedicationsBanner({super.key});

  @override
  State<LiveMedicationsBanner> createState() => _LiveMedicationsBannerState();
}

class _LiveMedicationsBannerState extends State<LiveMedicationsBanner> {
  Future<_MedData>? _future;
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
        RealtimeService.instance.liveEventsFor({'medications'}).listen((_) {
      if (!mounted || !_isAuthenticated) return;
      _refresh();
    });
  }

  Future<_MedData> _load() async {
    final schedules =
        await MedicationsService.instance.getSchedules(active: true);
    final overdueRaw = await MedicationsService.instance.getOverdue();
    final overdue = overdueRaw
        .map((e) => _Dose.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    return _MedData(schedules: schedules, overdue: overdue);
  }

  Future<void> _markDose(_Dose d, String status) async {
    try {
      await MedicationsService.instance.updateDose(
        doseId: d.id,
        status: status,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF10B981),
          content: Text(
            '✓ تم تحديث الجرعة → ${status == "given" ? "تم تناولها" : "تم تخطيها"} (PATCH على RDS)',
            style: const TextStyle(fontFamily: 'Cairo'),
          ),
        ),
      );
      _refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: Colors.redAccent,
        content: Text('فشل: $e', style: const TextStyle(fontFamily: 'Cairo')),
      ));
    }
  }

  void _refresh() => setState(() => _future = _load());

  @override
  void dispose() {
    _realtimeSub?.cancel();
    super.dispose();
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
              'سجّل دخولك لرؤية جداول الأدوية الحية',
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

    return FutureBuilder<_MedData>(
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
                'جلب الجداول الدوائية من AWS RDS...',
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
                  '${snap.error}',
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

        final d = snap.data!;
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
                    'الجداول الدوائية · ${d.schedules.length} نشطة · ${d.overdue.length} متأخرة',
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
                  onTap: _refresh,
                  child: const Icon(Icons.refresh_rounded,
                      size: 18, color: Color(0xFF4338CA)),
                ),
              ],
            ),
            if (d.schedules.isNotEmpty) ...[
              const SizedBox(height: 10),
              ...d.schedules.take(3).map((s) => _scheduleRow(s)),
            ],
            if (d.overdue.isNotEmpty) ...[
              const SizedBox(height: 10),
              const Text(
                'جرعات متأخرة (تحتاج تأكيد):',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Cairo',
                  color: Color(0xFFEF4444),
                ),
              ),
              ...d.overdue.take(3).map((dose) => _overdueRow(dose)),
            ],
          ],
        ));
      },
    );
  }

  Widget _overdueRow(_Dose d) {
    final time = d.scheduledTime.length > 16
        ? d.scheduledTime.substring(11, 16)
        : d.scheduledTime;
    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Row(
        children: [
          const Icon(Icons.access_time_filled_rounded,
              size: 16, color: Color(0xFFEF4444)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  d.medicationName ?? 'جرعة',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Cairo',
                    color: Color(0xFF7F1D1D),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'موعدها: $time',
                  style: const TextStyle(
                    fontSize: 9,
                    color: Color(0xFFB91C1C),
                    fontFamily: 'Cairo',
                  ),
                ),
              ],
            ),
          ),
          InkWell(
            onTap: () => _markDose(d, 'skipped'),
            borderRadius: BorderRadius.circular(6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF94A3B8).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text('تخطي',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Cairo',
                    color: Color(0xFF475569),
                  )),
            ),
          ),
          const SizedBox(width: 6),
          InkWell(
            onTap: () => _markDose(d, 'given'),
            borderRadius: BorderRadius.circular(6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_rounded, size: 12, color: Colors.white),
                  SizedBox(width: 3),
                  Text('تأكيد',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Cairo',
                        color: Colors.white,
                      )),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _scheduleRow(BackendMedicationSchedule s) {
    final routeColor = switch (s.route) {
      'oral' => const Color(0xFF6366F1),
      'iv' => const Color(0xFFEF4444),
      'im' => const Color(0xFFF59E0B),
      _ => const Color(0xFF94A3B8),
    };
    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: routeColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.medication_rounded, size: 18, color: routeColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.medicationName,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Cairo',
                    color: Color(0xFF1E293B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${s.dosage} · ${s.arabicFrequency}'
                  '${s.scheduledTimes.isNotEmpty ? " · ${s.scheduledTimes.join(", ")}" : ""}',
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF64748B),
                    fontFamily: 'Cairo',
                  ),
                ),
              ],
            ),
          ),
          if (s.prescriber != null && s.prescriber!.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFEEF2FF),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                s.prescriber!,
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Cairo',
                  color: Color(0xFF4338CA),
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

class _MedData {
  final List<BackendMedicationSchedule> schedules;
  final List<_Dose> overdue;
  _MedData({required this.schedules, required this.overdue});
}
