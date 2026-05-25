import 'dart:async';

import 'package:flutter/material.dart';
import '../services/api_client.dart';
import '../services/messages_service.dart';
import '../services/realtime_service.dart';

// أيقونة رسائل + badge عدّاد للرسائل غير المقروءة (GET /messages/unread-count)
// تتحدث تلقائياً عبر:
// - polling كل دقيقة
// - realtime event 'messages' من Socket.IO
class UnreadMessagesIcon extends StatefulWidget {
  const UnreadMessagesIcon({super.key});

  @override
  State<UnreadMessagesIcon> createState() => _UnreadMessagesIconState();
}

class _UnreadMessagesIconState extends State<UnreadMessagesIcon> {
  int _count = 0;
  bool _isAuthed = false;
  Timer? _poll;
  StreamSubscription<Map<String, dynamic>>? _realtimeSub;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final token = await ApiClient.instance.getToken();
    if (!mounted) return;
    _isAuthed = token != null;
    if (!_isAuthed) {
      setState(() {});
      return;
    }
    _refresh();
    _poll = Timer.periodic(const Duration(minutes: 1), (_) => _refresh());
    _realtimeSub =
        RealtimeService.instance.liveEventsFor({'messages'}).listen((_) {
      _refresh();
    });
  }

  Future<void> _refresh() async {
    final n = await MessagesService.instance.unreadCount();
    if (!mounted) return;
    setState(() => _count = n);
  }

  @override
  void dispose() {
    _poll?.cancel();
    _realtimeSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAuthed) return const SizedBox.shrink();
    final has = _count > 0;
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF64748B).withValues(alpha: 0.08),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: Icon(
              has
                  ? Icons.mark_chat_unread_rounded
                  : Icons.chat_bubble_outline_rounded,
              color: const Color(0xFF64748B),
              size: 24,
            ),
            onPressed: () {
              _refresh();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    _count == 0
                        ? 'لا توجد رسائل غير مقروءة'
                        : 'لديك $_count رسالة غير مقروءة — افتحها من شاشة المحادثات',
                    style: const TextStyle(fontFamily: 'Cairo'),
                  ),
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          ),
        ),
        if (has)
          Positioned(
            right: 6,
            top: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              alignment: Alignment.center,
              child: Text(
                _count > 99 ? '99+' : '$_count',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
