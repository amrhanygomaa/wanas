import 'api_client.dart';

class BackendVisit {
  final String id;
  final String residentId;
  final String visitorName;
  final String visitorRelationship;
  final String visitDate;
  final String? visitTimeStart;
  final String? visitTimeEnd;
  final String status; // pending | approved | rejected | completed | cancelled
  final String? notes;

  BackendVisit({
    required this.id,
    required this.residentId,
    required this.visitorName,
    required this.visitorRelationship,
    required this.visitDate,
    this.visitTimeStart,
    this.visitTimeEnd,
    required this.status,
    this.notes,
  });

  factory BackendVisit.fromJson(Map<String, dynamic> j) => BackendVisit(
        id: (j['id'] ?? '').toString(),
        residentId: (j['residentId'] ?? '').toString(),
        visitorName: (j['visitorName'] ?? '').toString(),
        visitorRelationship: (j['visitorRelationship'] ?? '').toString(),
        visitDate: (j['visitDate'] ?? '').toString(),
        visitTimeStart: j['visitTimeStart']?.toString(),
        visitTimeEnd: j['visitTimeEnd']?.toString(),
        status: (j['status'] ?? 'pending').toString(),
        notes: j['notes']?.toString(),
      );

  String get arabicStatus => switch (status) {
        'pending' => 'بانتظار الموافقة',
        'approved' => 'موافق عليها',
        'rejected' => 'مرفوضة',
        'completed' => 'مكتملة',
        'cancelled' => 'ملغاة',
        _ => status,
      };

  String get arabicRelationship => switch (visitorRelationship) {
        'son' => 'ابن',
        'daughter' => 'ابنة',
        'spouse' => 'زوج/ة',
        'brother' => 'أخ',
        'sister' => 'أخت',
        'friend' => 'صديق',
        'other' => 'آخر',
        _ => visitorRelationship,
      };
}

class FamilyBridgeService {
  FamilyBridgeService._();
  static final FamilyBridgeService instance = FamilyBridgeService._();

  // تحديث حالة الزيارة (موافقة/رفض/إكمال/إلغاء)
  Future<BackendVisit> updateVisitStatus(String id, String status) async {
    final res = await ApiClient.instance.patch(
      '/family-bridge/visits/$id/status',
      body: {'status': status},
    );
    return BackendVisit.fromJson(res as Map<String, dynamic>);
  }

  Future<List<BackendVisit>> getVisits({
    String? residentId,
    String? status,
  }) async {
    final res = await ApiClient.instance.get(
      '/family-bridge/visits',
      query: {
        if (residentId != null) 'residentId': residentId,
        if (status != null) 'status': status,
      },
    );
    if (res is! List) return [];
    return res
        .map((e) => BackendVisit.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
