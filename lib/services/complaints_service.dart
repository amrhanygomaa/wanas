import 'api_client.dart';

class BackendComplaint {
  final String id;
  final String residentId;
  final String submittedBy;
  final String category;
  final String subject;
  final String description;
  final String status; // open | in_progress | resolved | closed
  final String priority; // low | medium | high | critical
  final String? resolvedBy;
  final String? resolvedAt;
  final String? resolutionNotes;
  final String createdAt;

  BackendComplaint({
    required this.id,
    required this.residentId,
    required this.submittedBy,
    required this.category,
    required this.subject,
    required this.description,
    required this.status,
    required this.priority,
    this.resolvedBy,
    this.resolvedAt,
    this.resolutionNotes,
    required this.createdAt,
  });

  factory BackendComplaint.fromJson(Map<String, dynamic> j) => BackendComplaint(
        id: (j['id'] ?? '').toString(),
        residentId: (j['residentId'] ?? '').toString(),
        submittedBy: (j['submittedBy'] ?? '').toString(),
        category: (j['category'] ?? '').toString(),
        subject: (j['subject'] ?? '').toString(),
        description: (j['description'] ?? '').toString(),
        status: (j['status'] ?? 'open').toString(),
        priority: (j['priority'] ?? 'medium').toString(),
        resolvedBy: j['resolvedBy']?.toString(),
        resolvedAt: j['resolvedAt']?.toString(),
        resolutionNotes: j['resolutionNotes']?.toString(),
        createdAt: (j['createdAt'] ?? '').toString(),
      );

  String get arabicCategory => switch (category) {
        'food' => 'الطعام',
        'communication' => 'التواصل',
        'service' => 'الخدمة',
        'maintenance' => 'الصيانة',
        'psych' => 'نفسي',
        _ => category,
      };

  String get arabicStatus => switch (status) {
        'open' => 'مفتوحة',
        'in_progress' => 'قيد المعالجة',
        'resolved' => 'تم الحل',
        'closed' => 'مغلقة',
        _ => status,
      };

  String get arabicPriority => switch (priority) {
        'low' => 'منخفضة',
        'medium' => 'متوسطة',
        'high' => 'عالية',
        'critical' => 'حرجة',
        _ => priority,
      };
}

class ComplaintsService {
  ComplaintsService._();
  static final ComplaintsService instance = ComplaintsService._();

  // الـ categories المسموحة: care_quality | staff_behavior | facility | food | communication | general | other
  // الـ priorities: low | medium | high | critical
  Future<BackendComplaint> create({
    required String category,
    required String subject,
    String? description,
    String? priority,
    String? residentId,
  }) async {
    final res = await ApiClient.instance.post('/complaints', body: {
      'category': category,
      'subject': subject,
      if (description != null && description.isNotEmpty)
        'description': description,
      if (priority != null) 'priority': priority,
      if (residentId != null && residentId.isNotEmpty) 'residentId': residentId,
    });
    return BackendComplaint.fromJson(res as Map<String, dynamic>);
  }

  // تغيير حالة الشكوى: open → in_progress → resolved → closed
  Future<BackendComplaint> updateStatus({
    required String id,
    required String status,
    String? resolutionNotes,
  }) async {
    final res = await ApiClient.instance.patch(
      '/complaints/$id/status',
      body: {
        'status': status,
        if (resolutionNotes != null && resolutionNotes.isNotEmpty)
          'resolutionNotes': resolutionNotes,
      },
    );
    return BackendComplaint.fromJson(res as Map<String, dynamic>);
  }

  Future<List<BackendComplaint>> getAll({
    String? status,
    String? priority,
  }) async {
    final res = await ApiClient.instance.get(
      '/complaints',
      query: {
        if (status != null) 'status': status,
        if (priority != null) 'priority': priority,
      },
    );
    if (res is! List) return [];
    return res
        .map((e) => BackendComplaint.fromJson(e as Map<String, dynamic>))
        .toList();
  }

}
