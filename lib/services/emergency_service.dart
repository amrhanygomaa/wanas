import 'api_client.dart';

class BackendEmergency {
  final String id;
  final String? residentId;
  final String triggeredBy;
  final String sourceRole;
  final String type;
  final String message;
  final String? location;
  final String status;
  final String createdAt;

  BackendEmergency({
    required this.id,
    this.residentId,
    required this.triggeredBy,
    required this.sourceRole,
    required this.type,
    required this.message,
    this.location,
    required this.status,
    required this.createdAt,
  });

  factory BackendEmergency.fromJson(Map<String, dynamic> j) {
    return BackendEmergency(
      id: (j['id'] ?? '').toString(),
      residentId: (j['residentId'] ?? j['resident_id'])?.toString(),
      triggeredBy: (j['triggeredBy'] ?? j['triggered_by'] ?? '').toString(),
      sourceRole:
          (j['sourceRole'] ?? j['source_role'] ?? 'Resident').toString(),
      type:
          (j['type'] ?? j['alertType'] ?? j['alert_type'] ?? 'sos').toString(),
      message: (j['message'] ?? j['notes'] ?? 'نداء طوارئ').toString(),
      location: (j['location'])?.toString(),
      status: (j['status'] ?? 'active').toString(),
      createdAt: (j['createdAt'] ?? j['created_at'] ?? '').toString(),
    );
  }
}

class EmergencyService {
  EmergencyService._();
  static final EmergencyService instance = EmergencyService._();

  Future<BackendEmergency> triggerSos({
    required String triggeredBy,
    String? residentId,
    String? notes,
    String? location,
  }) async {
    final res = await ApiClient.instance.post('/emergency/sos', body: {
      'triggeredBy': triggeredBy,
      if (residentId != null && residentId.isNotEmpty) 'residentId': residentId,
      if (location != null && location.isNotEmpty) 'location': location,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
    });
    return BackendEmergency.fromJson(Map<String, dynamic>.from(res as Map));
  }

  Future<List<BackendEmergency>> active() async {
    final res = await ApiClient.instance.get('/emergency/active');
    if (res is! List) return [];
    return res
        .whereType<Map>()
        .map((e) => BackendEmergency.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<BackendEmergency> resolve(String id, {String? notes}) async {
    final res = await ApiClient.instance.patch('/emergency/$id/resolve', body: {
      if (notes != null && notes.isNotEmpty) 'notes': notes,
    });
    return BackendEmergency.fromJson(Map<String, dynamic>.from(res as Map));
  }
}
