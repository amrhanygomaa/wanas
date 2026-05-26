import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_riverpod.dart';

class TaptabaBell extends ConsumerStatefulWidget {
  const TaptabaBell({super.key});

  @override
  ConsumerState<TaptabaBell> createState() => _TaptabaBellState();
}

class _TaptabaBellState extends ConsumerState<TaptabaBell>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));

    _animation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -0.2), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -0.2, end: 0.2), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 0.2, end: -0.2), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -0.2, end: 0.2), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 0.2, end: 0.0), weight: 1),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    // Shake once on start to show off
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) _controller.forward(from: 0);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = ref.watch(appRiverpod);
    final filteredNotifs = provider.filteredNotifications;
    final unreadCount = filteredNotifs.where((n) => !n.isRead).length;
    final hasNotification = unreadCount > 0;

    // Trigger animation when unreadCount increases for the current role
    ref.listen(appRiverpod, (previous, next) {
      final prevUnread = previous?.filteredNotifications.where((n) => !n.isRead).length ?? 0;
      final nextUnread = next.filteredNotifications.where((n) => !n.isRead).length;
      if (nextUnread > prevUnread) {
        _controller.forward(from: 0);
      }
    });

    return Stack(
      alignment: Alignment.center,
      children: [
        AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            return Transform.rotate(
              angle: _animation.value,
              child: child,
            );
          },
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF64748b).withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(
                hasNotification
                    ? Icons.notifications_active_rounded
                    : Icons.notifications_none_rounded,
                color: const Color(0xFF64748b),
                size: 26,
              ),
              onPressed: () {
                // Show Notifications bottom sheet or screen
                provider.markAllFilteredNotificationsAsRead();
                _showNotifications(context, provider);
              },
            ),
          ),
        ),
        if (hasNotification)
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Text(
                unreadCount > 9 ? '9+' : '$unreadCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }

  void _showNotifications(BuildContext context, AppRiverpod provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 10),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('الإشعارات',
                        style: TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold)),
                    if (provider.filteredNotifications.isNotEmpty)
                      TextButton(
                        onPressed: () => provider.clearNotifications(),
                        child: const Text('مسح الكل',
                            style: TextStyle(color: Color(0xFFEF4444))),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: provider.filteredNotifications.isEmpty
                    ? const Center(
                        child: Text('لا توجد إشعارات حالياً',
                            style: TextStyle(color: Colors.grey)),
                      )
                    : ListView.builder(
                        controller: controller,
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        itemCount: provider.filteredNotifications.length,
                        itemBuilder: (context, index) {
                          final notif = provider.filteredNotifications[index];
                          return Dismissible(
                            key: Key(notif.id),
                            direction: DismissDirection.horizontal,
                            onDismissed: (direction) {
                              provider.deleteNotification(notif.id);
                            },
                            background: Container(
                              margin: const EdgeInsets.only(bottom: 15),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEF4444),
                                borderRadius: BorderRadius.circular(18),
                              ),
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              child: const Icon(Icons.delete_outline, color: Colors.white),
                            ),
                            secondaryBackground: Container(
                              margin: const EdgeInsets.only(bottom: 15),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEF4444),
                                borderRadius: BorderRadius.circular(18),
                              ),
                              alignment: Alignment.centerLeft,
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              child: const Icon(Icons.delete_outline, color: Colors.white),
                            ),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 15),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: notif.isRead
                                  ? Colors.grey[50]
                                  : const Color(0xFF6C63FF).withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: notif.isRead
                                    ? Colors.transparent
                                    : const Color(0xFF6C63FF).withValues(alpha: 0.1),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: _getNotifColor(notif.type)
                                        .withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(_getNotifIcon(notif.type),
                                      color: _getNotifColor(notif.type),
                                      size: 20),
                                ),
                                const SizedBox(width: 15),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(notif.title,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15)),
                                      Text(notif.body,
                                          style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 13)),
                                      const SizedBox(height: 5),
                                      Text(notif.time,
                                          style: TextStyle(
                                              color: Colors.grey[400],
                                              fontSize: 11)),
                                    ],
                                  ),
                                ),
                                if (!notif.isRead)
                                  IconButton(
                                    icon: const Icon(Icons.check_circle_outline,
                                        size: 20, color: Color(0xFF6C63FF)),
                                    onPressed: () => provider
                                        .markNotificationAsRead(notif.id),
                                  ),
                              ],
                            ),
                          ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getNotifColor(String type) {
    switch (type) {
      case 'medical': return Colors.red;
      case 'visit': return Colors.orange;
      case 'activity': return Colors.green;
      case 'social': return Colors.purple;
      default: return Colors.blue;
    }
  }

  IconData _getNotifIcon(String type) {
    switch (type) {
      case 'medical': return Icons.medical_services_rounded;
      case 'visit': return Icons.people_rounded;
      case 'activity': return Icons.event_rounded;
      case 'social': return Icons.volunteer_activism_rounded;
      default: return Icons.info_rounded;
    }
  }
}
