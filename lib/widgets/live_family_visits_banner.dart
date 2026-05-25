import 'dart:async';

import 'package:flutter/material.dart';
import '../services/family_bridge_service.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../services/realtime_service.dart';

class LiveFamilyVisitsBanner extends StatefulWidget {
  // showActions=true يعرض أزرار الموافقة/الرفض (للإدارة فقط)
  final bool showActions;
  const LiveFamilyVisitsBanner({super.key, this.showActions = false});

  @override
  State<LiveFamilyVisitsBanner> createState() => _LiveFamilyVisitsBannerState();
}

class _LiveFamilyVisitsBannerState extends State<LiveFamilyVisitsBanner> {
  Future<List<BackendVisit>>? _future;
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
      if (_isAuthenticated) _future = FamilyBridgeService.instance.getVisits();
    });
    if (_isAuthenticated) _startRealtime();
  }

  void _startRealtime() {
    _realtimeSub ??=
        RealtimeService.instance.liveEventsFor({'family_visits'}).listen((_) {
      if (!mounted || !_isAuthenticated) return;
      _refresh();
    });
  }

  void _refresh() => setState(() {
        _future = FamilyBridgeService.instance.getVisits();
      });

  @override
  void dispose() {
    _realtimeSub?.cancel();
    super.dispose();
  }

  Future<void> _updateStatus(BackendVisit v, String newStatus) async {
    try {
      await FamilyBridgeService.instance.updateVisitStatus(v.id, newStatus);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF10B981),
          content: Text(
            'تم تحديث زيارة ${v.visitorName} → ${_arabicStatus(newStatus)} (PATCH على RDS)',
            style: const TextStyle(fontFamily: 'Cairo'),
          ),
        ),
      );
      _refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.redAccent,
          content: Text('فشل التحديث: $e',
              style: const TextStyle(fontFamily: 'Cairo')),
        ),
      );
    }
  }

  String _arabicStatus(String s) => switch (s) {
        'approved' => 'مقبولة',
        'rejected' => 'مرفوضة',
        'completed' => 'مكتملة',
        'cancelled' => 'ملغاة',
        _ => s,
      };

  @override
  Widget build(BuildContext context) {
    if (!_isAuthenticated) {
      return _shell(const Row(
        children: [
          Icon(Icons.cloud_off_rounded, color: Color(0xFF94A3B8), size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'سجّل دخولك لرؤية الزيارات الحية',
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

    return FutureBuilder<List<BackendVisit>>(
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
                'جاري جلب الزيارات...',
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

        final visits = snap.data ?? [];
        final pending = visits.where((v) => v.status == 'pending').length;
        final approved = visits.where((v) => v.status == 'approved').length;

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
                    'الزيارات · ${visits.length} · بانتظار $pending · مقبولة $approved',
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
            if (visits.isNotEmpty) ...[
              const SizedBox(height: 10),
              ...visits.take(3).map((v) => _visitRow(v)),
            ],
          ],
        ));
      },
    );
  }

  Widget _visitRow(BackendVisit v) {
    final statusColor = switch (v.status) {
      'approved' => const Color(0xFF10B981),
      'pending' => const Color(0xFFF59E0B),
      'rejected' => const Color(0xFFEF4444),
      'completed' => const Color(0xFF6366F1),
      _ => const Color(0xFF94A3B8),
    };
    final isAdmin = AuthService.instance.currentUser?.roles
            .any((r) => r.toLowerCase() == 'admin') ??
        false;
    final canActOnIt = widget.showActions && isAdmin && v.status == 'pending';

    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.calendar_today_rounded,
                    size: 18, color: statusColor),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${v.visitorName} (${v.arabicRelationship})',
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
                      '${v.visitDate} · ${v.visitTimeStart ?? ""}',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFF64748B),
                        fontFamily: 'Cairo',
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  v.arabicStatus,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Cairo',
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          if (canActOnIt) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _updateStatus(v, 'rejected'),
                    icon: const Icon(Icons.close_rounded, size: 14),
                    label: const Text(
                      'رفض',
                      style: TextStyle(
                        fontSize: 11,
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFEF4444),
                      side: const BorderSide(color: Color(0xFFEF4444)),
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      minimumSize: const Size(0, 30),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _updateStatus(v, 'approved'),
                    icon: const Icon(Icons.check_rounded, size: 14),
                    label: const Text(
                      'موافقة',
                      style: TextStyle(
                        fontSize: 11,
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      minimumSize: const Size(0, 30),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ],
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
