import 'package:flutter/material.dart';
import 'specialist_chat_detail_screen.dart';

class SpecialistChatsListScreen extends StatelessWidget {
  const SpecialistChatsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // قائمة تجريبية للمحادثات مع العائلات
    final List<Map<String, String>> chats = [
      {'name': 'عائلة الحاج محمود سالم', 'resident': 'غرفة ١٠٣', 'lastMsg': 'شكراً جزيلاً أستاذة نور، طمنتينا عليه', 'time': '١٠:٣٠ ص', 'unread': '٢', 'av': 'عا'},
      {'name': 'ابن الحاجة فاطمة', 'resident': 'غرفة ٢١٠', 'lastMsg': 'هل يمكننا زيارتها غداً؟', 'time': 'الأمس', 'unread': '٠', 'av': 'اب'},
      {'name': 'زوجة السيد أحمد سعيد', 'resident': 'غرفة ١٠٥', 'lastMsg': 'حسناً، سأحضر له الدواء المطلوب', 'time': 'الأمس', 'unread': '٠', 'av': 'زو'},
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF1F1F6),
      appBar: AppBar(
        backgroundColor: const Color(0xFFea580c),
        elevation: 0,
        centerTitle: true,
        title: const Text('الرسائل', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 12),
          itemCount: chats.length,
          itemBuilder: (context, index) {
            final chat = chats[index];
            final bool hasUnread = chat['unread'] != '٠';
            
            return InkWell(
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => SpecialistChatDetailScreen(
                  familyName: chat['name']!,
                  residentName: chat['resident']!,
                )));
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(bottom: BorderSide(color: Colors.grey.withOpacity(0.1))),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: const Color(0xFFfed7aa),
                      child: Text(chat['av']!, style: const TextStyle(color: Color(0xFFc2410c), fontWeight: FontWeight.bold, fontSize: 18)),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(chat['name']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E293B))),
                              Text(chat['time']!, style: TextStyle(fontSize: 12, color: hasUnread ? const Color(0xFFea580c) : Colors.grey, fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(chat['lastMsg']!, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 14, color: hasUnread ? const Color(0xFF1E293B) : Colors.grey, fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal)),
                              ),
                              if (hasUnread)
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: const BoxDecoration(color: Color(0xFFea580c), shape: BoxShape.circle),
                                  child: Text(chat['unread']!, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
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
