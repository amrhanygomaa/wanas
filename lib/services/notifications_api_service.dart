import 'api_client.dart';

class BackendNotification {
  final String id;
  final String userId;
  final String facilityId;
  final String message;
  final String type;
  final bool read;
  final String createdAt;

  BackendNotification({
    required this.id,
    required this.userId,
    required this.facilityId,
    required this.message,
    required this.type,
    required this.read,
    required this.createdAt,
  });

  factory BackendNotification.fromJson(Map<String, dynamic> j) {
    return BackendNotification(
      id: (j['id'] ?? '').toString(),
      userId: (j['userId'] ?? j['user_id'] ?? '').toString(),
      facilityId: (j['facilityId'] ?? '').toString(),
      message: (j['message'] ?? j['body'] ?? '').toString(),
      type: (j['type'] ?? 'info').toString(),
      read: (j['read'] ?? j['isRead'] ?? j['is_read'] ?? false) == true,
      createdAt: (j['createdAt'] ?? j['created_at'] ?? '').toString(),
    );
  }

  String get arabicType => switch (type) {
        'medication_reminder' => 'تذكير دواء',
        'vital_alert' => 'تنبيه حيوي',
        'complaint' => 'شكوى',
        'visit_reminder' => 'تذكير زيارة',
        'ai_summary' => 'ملخص ذكاء اصطناعي',
        _ => type,
      };
}

class NotificationsApiService {
  NotificationsApiService._();
  static final NotificationsApiService instance = NotificationsApiService._();

  Future<List<BackendNotification>> listForUser(String userId) async {
    final res = await ApiClient.instance.get('/notifications/$userId');
    if (res is! List) return [];
    return res
        .map((e) => BackendNotification.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // الأنواع المسموحة: medication_reminder | vital_alert | complaint | visit_reminder | ai_summary
  Future<BackendNotification> create({
    required String userId,
    required String message,
    String type = 'vital_alert',
  }) async {
    final res = await ApiClient.instance.post('/notifications', body: {
      'userId': userId,
      'message': message,
      'type': type,
    });
    return BackendNotification.fromJson(res as Map<String, dynamic>);
  }

  Future<BackendNotification> markAsRead(String id) async {
    final res = await ApiClient.instance.patch('/notifications/$id/read');
    return BackendNotification.fromJson(res as Map<String, dynamic>);
  }

  Future<void> deleteOne(String id) async {
    await ApiClient.instance.delete('/notifications/$id');
  }

  Future<void> clearForUser(String userId) async {
    await ApiClient.instance.delete('/notifications/user/$userId');
  }
}
