import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/app_riverpod.dart';
import 'specialist_chat_detail_screen.dart';

class SpecialistChatsListScreen extends ConsumerWidget {
  const SpecialistChatsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = ref.watch(appRiverpod);
    final chats = [
      for (final resident in provider.residentFiles)
        for (final family in resident.familyMembers)
          {
            'name': family.name,
            'resident': 'غرفة ${resident.room}',
            'lastMsg': 'لا توجد رسائل حديثة من AWS',
            'time': '',
            'unread': '٠',
            'av': family.initials,
          },
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF1F1F6),
      appBar: AppBar(
        backgroundColor: const Color(0xFFea580c),
        elevation: 0,
        centerTitle: true,
        title: const Text('الرسائل',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon:
              const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: chats.isEmpty
            ? const Center(child: Text('لا توجد محادثات عائلية من AWS'))
            : ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 12),
                itemCount: chats.length,
                itemBuilder: (context, index) {
                  final chat = chats[index];
                  final bool hasUnread = chat['unread'] != '٠';

                  return InkWell(
                    onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => SpecialistChatDetailScreen(
                                    familyName: chat['name']!,
                                    residentName: chat['resident']!,
                                  )));
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border(
                            bottom: BorderSide(
                                color: Colors.grey.withValues(alpha: 0.1))),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 28,
                            backgroundColor: const Color(0xFFfed7aa),
                            child: Text(chat['av']!,
                                style: const TextStyle(
                                    color: Color(0xFFc2410c),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18)),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(chat['name']!,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: Color(0xFF1E293B))),
                                    Text(chat['time']!,
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: hasUnread
                                                ? const Color(0xFFea580c)
                                                : Colors.grey,
                                            fontWeight: hasUnread
                                                ? FontWeight.bold
                                                : FontWeight.normal)),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(chat['lastMsg']!,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                              fontSize: 14,
                                              color: hasUnread
                                                  ? const Color(0xFF1E293B)
                                                  : Colors.grey,
                                              fontWeight: hasUnread
                                                  ? FontWeight.bold
                                                  : FontWeight.normal)),
                                    ),
                                    if (hasUnread)
                                      Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: const BoxDecoration(
                                            color: Color(0xFFea580c),
                                            shape: BoxShape.circle),
                                        child: Text(chat['unread']!,
                                            style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold)),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
