import 'dart:async';

import 'package:flutter/material.dart';
import '../services/notifications_api_service.dart';
import '../services/auth_service.dart';
import '../services/api_client.dart';
import '../services/realtime_service.dart';

class LiveNotificationsBanner extends StatefulWidget {
  const LiveNotificationsBanner({super.key});

  @override
  State<LiveNotificationsBanner> createState() =>
      _LiveNotificationsBannerState();
}

class _LiveNotificationsBannerState extends State<LiveNotificationsBanner> {
  Future<List<BackendNotification>>? _future;
  bool _isAuthenticated = false;
  bool _isCreating = false;
  StreamSubscription<Map<String, dynamic>>? _realtimeSub;

  String? _resolveUserId() {
    final user = AuthService.instance.currentUser;
    return user?.userId;
  }

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
    });
    if (_isAuthenticated) {
      _refresh();
      _startRealtime();
    }
  }

  void _startRealtime() {
    _realtimeSub ??=
        RealtimeService.instance.liveEventsFor({'notifications'}).listen((_) {
      if (!mounted || !_isAuthenticated) return;
      _refresh();
    });
  }

  void _refresh() {
    final userId = _resolveUserId();
    if (userId == null || userId.isEmpty) return;
    setState(() {
      _future = NotificationsApiService.instance.listForUser(userId);
    });
  }

  @override
  void dispose() {
    _realtimeSub?.cancel();
    super.dispose();
  }

  Future<void> _markRead(BackendNotification n) async {
    try {
      await NotificationsApiService.instance.markAsRead(n.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFF10B981),
          content: Text(
            'تم تعليم الإشعار كمقروء (PATCH على RDS)',
            style: TextStyle(fontFamily: 'Cairo'),
          ),
        ),
      );
      _refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.redAccent,
          content: Text('فشل: $e', style: const TextStyle(fontFamily: 'Cairo')),
        ),
      );
    }
  }

  Future<void> _createTestNotification() async {
    setState(() => _isCreating = true);
    try {
      await NotificationsApiService.instance.create(
        userId: _resolveUserId()!,
        message:
            'إشعار من Flutter @ ${DateTime.now().toIso8601String().substring(11, 19)}',
        type: 'vital_alert',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFF6366F1),
          content: Text(
            'تم إنشاء إشعار جديد في السيرفر (POST /notifications)',
            style: TextStyle(fontFamily: 'Cairo'),
          ),
        ),
      );
      _refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.redAccent,
          content: Text('فشل: $e', style: const TextStyle(fontFamily: 'Cairo')),
        ),
      );
    } finally {
      if (mounted) setState(() => _isCreating = false);
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
              'سجّل دخولك لرؤية الإشعارات الحية',
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

    return FutureBuilder<List<BackendNotification>>(
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
              Text('جلب الإشعارات...',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Cairo',
                    color: Color(0xFFB45309),
                  )),
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
                ),
              ),
            ],
          ));
        }

        final notifs = snap.data ?? [];
        final unread = notifs.where((n) => !n.read).length;

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
                    'الإشعارات · ${notifs.length} · $unread غير مقروء',
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
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _isCreating ? null : _createTestNotification,
                icon: _isCreating
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.add_alert_rounded, size: 16),
                label: const Text(
                  'إنشاء إشعار في السيرفر',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Cairo',
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF6366F1),
                  side: const BorderSide(color: Color(0xFF6366F1)),
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  minimumSize: const Size(0, 32),
                ),
              ),
            ),
            if (notifs.isNotEmpty) ...[
              const SizedBox(height: 8),
              ...notifs.take(3).map((n) => _notifRow(n)),
            ],
          ],
        ));
      },
    );
  }

  Widget _notifRow(BackendNotification n) {
    final typeColor = switch (n.type) {
      'vital_alert' => const Color(0xFFEF4444),
      'medication_reminder' => const Color(0xFF6366F1),
      'complaint' => const Color(0xFFF59E0B),
      'visit_reminder' => const Color(0xFFEC4899),
      'ai_summary' => const Color(0xFF8B5CF6),
      _ => const Color(0xFF94A3B8),
    };
    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: n.read ? const Color(0xFFF8FAFC) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: n.read
              ? const Color(0xFFE2E8F0)
              : typeColor.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 32,
            decoration: BoxDecoration(
              color: typeColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  n.message,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: n.read ? FontWeight.w500 : FontWeight.bold,
                    fontFamily: 'Cairo',
                    color: n.read
                        ? const Color(0xFF64748B)
                        : const Color(0xFF1E293B),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  n.arabicType,
                  style: TextStyle(
                    fontSize: 10,
                    color: typeColor,
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (!n.read)
            InkWell(
              onTap: () => _markRead(n),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.done_rounded,
                        size: 12, color: Color(0xFF065F46)),
                    SizedBox(width: 3),
                    Text('قراءة',
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
