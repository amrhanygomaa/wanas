import 'api_client.dart';

class BackendUserSummary {
  final String id;
  final String name;
  final String email;
  final String role;

  BackendUserSummary({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
  });

  factory BackendUserSummary.fromJson(Map<String, dynamic> j) {
    final id =
        (j['cognitoSub'] ?? j['cognito_sub'] ?? j['userId'] ?? j['id'] ?? '')
            .toString();
    final name =
        (j['fullName'] ?? j['full_name'] ?? j['name'] ?? '').toString().trim();
    final email = (j['email'] ?? '').toString();
    return BackendUserSummary(
      id: id,
      name: name.isEmpty ? email.split('@').first : name,
      email: email,
      role: (j['role'] ?? '').toString(),
    );
  }
}

class BackendRoleMessage {
  final String id;
  final String senderId;
  final String recipientId;
  final String body;
  final String? mediaUrl;
  final String? mediaType;
  final String? readAt;
  final String createdAt;

  BackendRoleMessage({
    required this.id,
    required this.senderId,
    required this.recipientId,
    required this.body,
    this.mediaUrl,
    this.mediaType,
    this.readAt,
    required this.createdAt,
  });

  factory BackendRoleMessage.fromJson(Map<String, dynamic> j) {
    return BackendRoleMessage(
      id: (j['id'] ?? '').toString(),
      senderId: (j['senderId'] ?? j['sender_id'] ?? '').toString(),
      recipientId: (j['recipientId'] ?? j['recipient_id'] ?? '').toString(),
      body: (j['body'] ?? j['text'] ?? '').toString(),
      mediaUrl: (j['mediaUrl'] ?? j['media_url'])?.toString(),
      mediaType: (j['mediaType'] ?? j['media_type'])?.toString(),
      readAt: (j['readAt'] ?? j['read_at'])?.toString(),
      createdAt: (j['createdAt'] ?? j['created_at'] ?? '').toString(),
    );
  }
}

class BackendMessageThreadSummary {
  final String otherUserId;
  final String otherUserName;
  final String otherUserRole;
  final BackendRoleMessage lastMessage;
  final int unreadCount;

  BackendMessageThreadSummary({
    required this.otherUserId,
    required this.otherUserName,
    required this.otherUserRole,
    required this.lastMessage,
    required this.unreadCount,
  });

  factory BackendMessageThreadSummary.fromJson(Map<String, dynamic> j) {
    return BackendMessageThreadSummary(
      otherUserId: (j['otherUserId'] ?? j['other_user_id'] ?? '').toString(),
      otherUserName:
          (j['otherUserName'] ?? j['other_user_name'] ?? '').toString(),
      otherUserRole:
          (j['otherUserRole'] ?? j['other_user_role'] ?? '').toString(),
      lastMessage: BackendRoleMessage.fromJson(
        Map<String, dynamic>.from(j['lastMessage'] as Map),
      ),
      unreadCount: (j['unreadCount'] as num?)?.toInt() ?? 0,
    );
  }
}

class MessagesService {
  MessagesService._();
  static final MessagesService instance = MessagesService._();

  Future<List<BackendUserSummary>> clinicalUsers() async {
    final res = await ApiClient.instance.get('/users/clinical');
    if (res is! List) return [];
    return res
        .whereType<Map>()
        .map((e) => BackendUserSummary.fromJson(Map<String, dynamic>.from(e)))
        .where((u) => u.id.isNotEmpty)
        .toList();
  }

  Future<List<BackendMessageThreadSummary>> inbox() async {
    final res = await ApiClient.instance.get('/messages/inbox');
    if (res is! List) return [];
    return res
        .whereType<Map>()
        .map((e) => BackendMessageThreadSummary.fromJson(
              Map<String, dynamic>.from(e),
            ))
        .where((t) => t.otherUserId.isNotEmpty)
        .toList();
  }

  Future<List<BackendRoleMessage>> thread(String otherUserId) async {
    final res = await ApiClient.instance.get('/messages/thread/$otherUserId');
    if (res is! List) return [];
    return res
        .whereType<Map>()
        .map((e) => BackendRoleMessage.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<BackendRoleMessage> send({
    required String recipientId,
    required String body,
  }) async {
    final res = await ApiClient.instance.post('/messages', body: {
      'recipientId': recipientId,
      'body': body,
    });
    return BackendRoleMessage.fromJson(Map<String, dynamic>.from(res as Map));
  }

  Future<void> markThreadRead(String otherUserId) async {
    await ApiClient.instance.post('/messages/thread/$otherUserId/read');
  }

  // عدد الرسائل غير المقروءة للمستخدم الحالي — يُستخدم في badge الجرس
  Future<int> unreadCount() async {
    try {
      final res = await ApiClient.instance.get('/messages/unread-count');
      if (res is Map) {
        final c = res['count'] ?? res['unread'] ?? res['unreadCount'];
        if (c is num) return c.toInt();
      }
      if (res is num) return res.toInt();
      return 0;
    } catch (_) {
      return 0;
    }
  }
}
