import 'package:flutter/material.dart';
import '../../services/messages_service.dart';
import 'specialist_chat_detail_screen.dart';

class SpecialistChatsListScreen extends StatefulWidget {
  const SpecialistChatsListScreen({super.key});

  @override
  State<SpecialistChatsListScreen> createState() =>
      _SpecialistChatsListScreenState();
}

class _SpecialistChatsListScreenState extends State<SpecialistChatsListScreen> {
  late Future<List<BackendMessageThreadSummary>> _threadsFuture;

  @override
  void initState() {
    super.initState();
    _threadsFuture = MessagesService.instance.inbox();
  }

  Future<void> _refresh() async {
    setState(() {
      _threadsFuture = MessagesService.instance.inbox();
    });
    await _threadsFuture;
  }

  String _formatTime(String iso) {
    final dt = DateTime.tryParse(iso);
    if (dt == null) return '';
    final now = DateTime.now();
    final isSameDay =
        dt.year == now.year && dt.month == now.month && dt.day == now.day;
    if (isSameDay) {
      final h = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
      final m = dt.minute.toString().padLeft(2, '0');
      final period = dt.hour >= 12 ? 'م' : 'ص';
      return '$h:$m $period';
    }
    final yesterday = now.subtract(const Duration(days: 1));
    if (dt.year == yesterday.year &&
        dt.month == yesterday.month &&
        dt.day == yesterday.day) {
      return 'الأمس';
    }
    return '${dt.day}/${dt.month}';
  }

  String _initials(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '؟';
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length == 1) {
      return parts.first.characters.take(2).toString();
    }
    return parts.take(2).map((p) => p.characters.first).join();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F1F6),
      appBar: AppBar(
        backgroundColor: const Color(0xFFea580c),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'الرسائل',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: FutureBuilder<List<BackendMessageThreadSummary>>(
            future: _threadsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: Color(0xFFea580c)),
                );
              }
              if (snapshot.hasError) {
                return _buildError(snapshot.error.toString());
              }
              final threads = snapshot.data ?? const [];
              if (threads.isEmpty) {
                return _buildEmpty();
              }
              return ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(vertical: 12),
                itemCount: threads.length,
                itemBuilder: (context, index) =>
                    _buildThreadTile(threads[index]),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildThreadTile(BackendMessageThreadSummary thread) {
    final hasUnread = thread.unreadCount > 0;
    final displayName =
        thread.otherUserName.isNotEmpty ? thread.otherUserName : 'مستخدم';
    return InkWell(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SpecialistChatDetailScreen(
              otherUserId: thread.otherUserId,
              otherUserName: displayName,
              otherUserRole: thread.otherUserRole,
            ),
          ),
        );
        // Refresh after returning from chat (read state may have changed)
        if (mounted) _refresh();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            bottom: BorderSide(color: Colors.grey.withValues(alpha: 0.1)),
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: const Color(0xFFfed7aa),
              child: Text(
                _initials(displayName),
                style: const TextStyle(
                  color: Color(0xFFc2410c),
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: hasUnread
                                ? FontWeight.w900
                                : FontWeight.w700,
                            fontSize: 16,
                            color: const Color(0xFF1E293B),
                          ),
                        ),
                      ),
                      Text(
                        _formatTime(thread.lastMessage.createdAt),
                        style: TextStyle(
                          fontSize: 12,
                          color: hasUnread
                              ? const Color(0xFFea580c)
                              : const Color(0xFF64748B),
                          fontWeight:
                              hasUnread ? FontWeight.bold : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          thread.lastMessage.body,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            color: hasUnread
                                ? const Color(0xFF1E293B)
                                : const Color(0xFF64748B),
                            fontWeight:
                                hasUnread ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                      ),
                      if (hasUnread) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFea580c),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            thread.unreadCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 120),
        Icon(
          Icons.forum_outlined,
          size: 80,
          color: const Color(0xFFea580c).withValues(alpha: 0.4),
        ),
        const SizedBox(height: 16),
        const Center(
          child: Text(
            'لا توجد رسائل بعد',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF334155),
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Center(
          child: Text(
            'ستظهر هنا المحادثات مع العائلات والطاقم',
            style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
          ),
        ),
      ],
    );
  }

  Widget _buildError(String error) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 120),
        const Icon(Icons.error_outline, size: 64, color: Color(0xFFef4444)),
        const SizedBox(height: 12),
        const Center(
          child: Text(
            'تعذّر تحميل الرسائل',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF334155),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: ElevatedButton.icon(
            onPressed: _refresh,
            icon: const Icon(Icons.refresh),
            label: const Text('إعادة المحاولة'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFea580c),
              foregroundColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}
