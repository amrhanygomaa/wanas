import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/app_riverpod.dart';
import '../../models/app_models.dart';

class NotificationsCenterScreen extends ConsumerWidget {
  const NotificationsCenterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = ref.watch(appRiverpod);
    final notifs = provider.filteredNotifications;

    return Scaffold(
      backgroundColor: const Color(0xFFf8fafc),
      appBar: AppBar(
        title: const Text('مركز التنبيهات',
            style: TextStyle(
                color: Color(0xFF0f172a),
                fontWeight: FontWeight.bold,
                fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: Color(0xFF0f172a), size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (notifs.isNotEmpty)
            TextButton(
              onPressed: () {
                for (var n in notifs) {
                  provider.markNotificationAsRead(n.id);
                }
              },
              child: const Text('تحديد الكل كمقروء',
                  style: TextStyle(color: Color(0xFF6366f1), fontSize: 10)),
            ),
        ],
      ),
      body: notifs.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: notifs.length,
              itemBuilder: (context, index) {
                return _buildNotificationCard(context, provider, notifs[index]);
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Color(0xFFe2e8f0),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.notifications_off_outlined,
                size: 40, color: Color(0xFF94a3b8)),
          ),
          const SizedBox(height: 16),
          const Text('لا توجد تنبيهات حالياً',
              style: TextStyle(
                  color: Color(0xFF64748b),
                  fontSize: 14,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(
      BuildContext context, AppRiverpod provider, TaptabaNotification notif) {
    Color iconBg;
    IconData iconData;

    switch (notif.type) {
      case 'complaint':
        iconBg = const Color(0xFFfee2e2);
        iconData = Icons.warning_amber_rounded;
        break;
      case 'assessment':
        iconBg = const Color(0xFFfef3c7);
        iconData = Icons.assignment_late_outlined;
        break;
      case 'medical':
        iconBg = const Color(0xFFdcfce7);
        iconData = Icons.medical_services_outlined;
        break;
      default:
        iconBg = const Color(0xFFe0e7ff);
        iconData = Icons.notifications_active_outlined;
    }

    // Determine icon color based on background
    final iconColor = notif.type == 'complaint'
        ? const Color(0xFFef4444)
        : notif.type == 'assessment'
            ? const Color(0xFFd97706)
            : notif.type == 'medical'
                ? const Color(0xFF16a34a)
                : const Color(0xFF6366f1);

    return Dismissible(
      key: Key(notif.id),
      direction: DismissDirection.horizontal,
      onDismissed: (direction) {
        provider.deleteNotification(notif.id);
      },
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFef4444),
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      secondaryBackground: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFef4444),
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      child: GestureDetector(
        onTap: () => provider.markNotificationAsRead(notif.id),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: notif.isRead ? Colors.white : const Color(0xFFf0f9ff),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: notif.isRead
                ? const Color(0xFFe2e8f0)
                : const Color(0xFFbae6fd),
            width: 1,
          ),
          boxShadow: [
            if (!notif.isRead)
              BoxShadow(
                color: const Color(0xFF0369a1).withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(iconData, size: 20, color: iconColor),
                ),
                if (!notif.isRead)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Color(0xFF0ea5e9),
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(notif.title,
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0f172a))),
                  const SizedBox(height: 4),
                  Text(notif.body,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF64748b),
                          height: 1.4)),
                  const SizedBox(height: 8),
                  Text(notif.time,
                      style: const TextStyle(
                          fontSize: 9, color: Color(0xFF94a3b8))),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }
}
