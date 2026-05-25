import 'package:flutter/material.dart';
import '../../services/notifications_api_service.dart';
import '../../services/auth_service.dart';
import '../../services/api_client.dart';

// شاشة إشعارات 100% AWS RDS — لا mock إطلاقاً
class RealNotificationsScreen extends StatefulWidget {
  const RealNotificationsScreen({super.key});

  @override
  State<RealNotificationsScreen> createState() =>
      _RealNotificationsScreenState();
}

class _RealNotificationsScreenState extends State<RealNotificationsScreen> {
  Future<List<BackendNotification>>? _future;
  bool _isAuthenticated = false;
  bool _isCreating = false;

  String? _resolveUserId() {
    final user = AuthService.instance.currentUser;
    return user?.userId;
  }

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final token = await ApiClient.instance.getToken();
    setState(() {
      _isAuthenticated = token != null;
      if (_isAuthenticated) _refresh();
    });
  }

  void _refresh() {
    final userId = _resolveUserId();
    if (userId == null || userId.isEmpty) return;
    setState(() {
      _future = NotificationsApiService.instance.listForUser(userId);
    });
  }

  Future<void> _markRead(BackendNotification n) async {
    try {
      await NotificationsApiService.instance.markAsRead(n.id);
      _refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: Colors.redAccent,
        content: Text('فشل: $e', style: const TextStyle(fontFamily: 'Cairo')),
      ));
    }
  }

  Future<void> _createOne(String type, String label) async {
    setState(() => _isCreating = true);
    try {
      await NotificationsApiService.instance.create(
        userId: _resolveUserId()!,
        message:
            '$label @ ${DateTime.now().toIso8601String().substring(11, 19)}',
        type: type,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: const Color(0xFF10B981),
        content: Text('✓ POST /notifications تم ($type)',
            style: const TextStyle(fontFamily: 'Cairo')),
      ));
      _refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: Colors.redAccent,
        content: Text('فشل: $e', style: const TextStyle(fontFamily: 'Cairo')),
      ));
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          title: const Text(
            'الإشعارات (AWS RDS)',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontWeight: FontWeight.bold,
              fontSize: 17,
            ),
          ),
          backgroundColor: const Color(0xFF0F172A),
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              onPressed: _refresh,
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
        ),
        body: !_isAuthenticated
            ? const Center(
                child: Text(
                  'سجّل دخولك أولاً',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 16,
                    color: Color(0xFF64748B),
                  ),
                ),
              )
            : Column(
                children: [
                  _buildHeader(),
                  _buildActionButtons(),
                  Expanded(child: _buildList()),
                ],
              ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: const Color(0xFF1E293B),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFF9900), Color(0xFFFFB14E)],
              ),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text(
              'Live · POST + PATCH',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 10,
                fontFamily: 'Cairo',
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'userId = ${_resolveUserId() ?? '-'}',
            style: const TextStyle(
              color: Color(0xFF94A3B8),
              fontFamily: 'monospace',
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    final actions = [
      (
        'vital_alert',
        'تنبيه حيوي',
        Icons.favorite_rounded,
        const Color(0xFFEF4444)
      ),
      (
        'medication_reminder',
        'تذكير دواء',
        Icons.medication_rounded,
        const Color(0xFF6366F1)
      ),
      ('complaint', 'شكوى', Icons.warning_rounded, const Color(0xFFF59E0B)),
      (
        'visit_reminder',
        'زيارة',
        Icons.calendar_today_rounded,
        const Color(0xFFEC4899)
      ),
    ];
    return Container(
      padding: const EdgeInsets.all(12),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _isCreating ? 'جاري الإنشاء...' : 'إنشاء إشعار في RDS:',
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: actions
                .map((a) => ActionChip(
                      avatar: Icon(a.$3, size: 16, color: a.$4),
                      label: Text(
                        a.$2,
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onPressed:
                          _isCreating ? null : () => _createOne(a.$1, a.$2),
                      backgroundColor: a.$4.withValues(alpha: 0.1),
                      side: BorderSide(color: a.$4.withValues(alpha: 0.3)),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildList() {
    return FutureBuilder<List<BackendNotification>>(
      future: _future,
      builder: (_, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text('فشل: ${snap.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontFamily: 'Cairo', color: Color(0xFFEF4444))),
            ),
          );
        }
        final notifs = snap.data ?? [];
        if (notifs.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off_outlined,
                      size: 60, color: Color(0xFF94A3B8)),
                  SizedBox(height: 16),
                  Text(
                    'لا توجد إشعارات',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'اضغط أحد الأزرار أعلاه لإنشاء إشعار في RDS',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 12,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: () async => _refresh(),
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            itemCount: notifs.length,
            itemBuilder: (_, i) => _notifCard(notifs[i]),
          ),
        );
      },
    );
  }

  Widget _notifCard(BackendNotification n) {
    final typeColor = switch (n.type) {
      'vital_alert' => const Color(0xFFEF4444),
      'medication_reminder' => const Color(0xFF6366F1),
      'complaint' => const Color(0xFFF59E0B),
      'visit_reminder' => const Color(0xFFEC4899),
      'ai_summary' => const Color(0xFF8B5CF6),
      _ => const Color(0xFF94A3B8),
    };
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: n.read ? const Color(0xFFF1F5F9) : Colors.white,
        borderRadius: BorderRadius.circular(12),
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
            height: 44,
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
                    fontFamily: 'Cairo',
                    fontWeight: n.read ? FontWeight.w500 : FontWeight.bold,
                    fontSize: 13,
                    color: n.read
                        ? const Color(0xFF64748B)
                        : const Color(0xFF1E293B),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: typeColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        n.arabicType,
                        style: TextStyle(
                          fontSize: 9,
                          color: typeColor,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Cairo',
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      n.createdAt.length > 16
                          ? n.createdAt.substring(0, 16).replaceAll('T', ' ')
                          : n.createdAt,
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFF94A3B8),
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (!n.read)
            IconButton(
              onPressed: () => _markRead(n),
              icon: const Icon(Icons.mark_email_read_rounded,
                  color: Color(0xFF10B981)),
              tooltip: 'تعليم كمقروء (PATCH)',
            ),
        ],
      ),
    );
  }
}
