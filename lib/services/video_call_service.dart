import 'api_client.dart';

class BackendVideoCall {
  final String id;
  final String? residentId;
  final String callerId;
  final String? calleeId;
  final String? calleeName;
  final String provider;
  final String? joinUrl;
  final String callType;
  final String status;
  final String startedAt;

  BackendVideoCall({
    required this.id,
    this.residentId,
    required this.callerId,
    this.calleeId,
    this.calleeName,
    this.provider = 'zoom',
    this.joinUrl,
    required this.callType,
    required this.status,
    required this.startedAt,
  });

  factory BackendVideoCall.fromJson(Map<String, dynamic> json) {
    return BackendVideoCall(
      id: (json['id'] ?? '').toString(),
      residentId: (json['residentId'] ?? json['resident_id'])?.toString(),
      callerId: (json['callerId'] ?? json['caller_id'] ?? '').toString(),
      calleeId: (json['calleeId'] ?? json['callee_id'])?.toString(),
      calleeName: (json['calleeName'] ?? json['callee_name'])?.toString(),
      provider: (json['provider'] ?? 'zoom').toString(),
      joinUrl: (json['joinUrl'] ?? json['join_url'])?.toString(),
      callType:
          (json['callType'] ?? json['call_type'] ?? 'family_video').toString(),
      status: (json['status'] ?? 'ringing').toString(),
      startedAt: (json['startedAt'] ?? json['started_at'] ?? '').toString(),
    );
  }
}

class VideoCallService {
  VideoCallService._();
  static final VideoCallService instance = VideoCallService._();

  Future<BackendVideoCall> start({
    String? residentId,
    String? calleeId,
    String? calleeName,
    String callType = 'family_video',
    String provider = 'zoom',
    String? joinUrl,
  }) async {
    final res = await ApiClient.instance.post('/video-calls', body: {
      if (residentId != null && residentId.isNotEmpty) 'residentId': residentId,
      if (calleeId != null && calleeId.isNotEmpty) 'calleeId': calleeId,
      if (calleeName != null && calleeName.isNotEmpty) 'calleeName': calleeName,
      'callType': callType,
      'provider': provider,
      if (joinUrl != null && joinUrl.isNotEmpty) 'joinUrl': joinUrl,
    });
    return BackendVideoCall.fromJson(res as Map<String, dynamic>);
  }

  Future<List<BackendVideoCall>> active() async {
    final res = await ApiClient.instance.get('/video-calls/active');
    if (res is! List) return [];
    return res
        .map((item) => BackendVideoCall.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<BackendVideoCall> updateStatus(String id, String status) async {
    final res = await ApiClient.instance.patch(
      '/video-calls/$id/status',
      body: {'status': status},
    );
    return BackendVideoCall.fromJson(res as Map<String, dynamic>);
  }

  Future<List<BackendVideoCall>> history({String? userId}) async {
    try {
      final res = await ApiClient.instance.get(
        '/video-calls/history',
        query: {if (userId != null && userId.isNotEmpty) 'userId': userId},
      );
      if (res is! List) return [];
      return res
          .map((e) =>
              BackendVideoCall.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {
      return [];
    }
  }
}
