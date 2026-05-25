import 'dart:async';

import 'package:flutter/material.dart';
import '../services/complaints_service.dart';
import '../services/api_client.dart';
import '../services/realtime_service.dart';
import 'sheets/submit_complaint_sheet.dart';

class LiveComplaintsBanner extends StatefulWidget {
  const LiveComplaintsBanner({super.key});

  @override
  State<LiveComplaintsBanner> createState() => _LiveComplaintsBannerState();
}

class _LiveComplaintsBannerState extends State<LiveComplaintsBanner> {
  Future<List<BackendComplaint>>? _future;
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
      if (_isAuthenticated) _future = ComplaintsService.instance.getAll();
    });
    if (_isAuthenticated) _startRealtime();
  }

  void _startRealtime() {
    _realtimeSub ??=
        RealtimeService.instance.liveEventsFor({'complaints'}).listen((_) {
      if (!mounted || !_isAuthenticated) return;
      _refresh();
    });
  }

  void _refresh() => setState(() {
        _future = ComplaintsService.instance.getAll();
      });

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
              'سجّل دخولك لرؤية الشكاوى الحية من السحابة',
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

    return FutureBuilder<List<BackendComplaint>>(
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
                'جاري جلب الشكاوى من AWS RDS...',
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
                  'تعذّر التحميل: ${snap.error}',
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

        final complaints = snap.data ?? [];
        final open = complaints
            .where((c) => c.status == 'open' || c.status == 'in_progress')
            .length;
        final resolved = complaints.length - open;

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
                    'الشكاوى · ${complaints.length} إجمالي · $open مفتوحة · $resolved معالجة',
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
                      SubmitComplaintSheet.show(context, onSubmitted: _refresh),
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
                        Icon(Icons.add_comment_rounded,
                            size: 12, color: Color(0xFF065F46)),
                        SizedBox(width: 4),
                        Text('تقديم',
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
            if (complaints.isNotEmpty) ...[
              const SizedBox(height: 10),
              ...complaints.take(3).map((c) => _complaintRow(c)),
            ],
          ],
        ));
      },
    );
  }

  Widget _complaintRow(BackendComplaint c) {
    final priorityColor = switch (c.priority) {
      'critical' => const Color(0xFFEF4444),
      'high' => const Color(0xFFF59E0B),
      'medium' => const Color(0xFF6366F1),
      _ => const Color(0xFF94A3B8),
    };
    final statusColor = c.status == 'resolved' || c.status == 'closed'
        ? const Color(0xFF10B981)
        : const Color(0xFFF59E0B);

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
            width: 4,
            height: 32,
            decoration: BoxDecoration(
              color: priorityColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  c.subject,
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
                  '${c.arabicCategory} · ${c.arabicPriority}',
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
              c.arabicStatus,
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
