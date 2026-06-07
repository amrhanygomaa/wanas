import 'api_client.dart';

class BackendMedicationSchedule {
  final String id;
  final String residentId;
  final String medicationName;
  final String dosage;
  final String route;
  final String frequency;
  final List<String> scheduledTimes;
  final String? startDate;
  final String? endDate;
  final bool isActive;
  final String? prescriber;
  final String? notes;

  BackendMedicationSchedule({
    required this.id,
    required this.residentId,
    required this.medicationName,
    required this.dosage,
    required this.route,
    required this.frequency,
    required this.scheduledTimes,
    this.startDate,
    this.endDate,
    required this.isActive,
    this.prescriber,
    this.notes,
  });

  factory BackendMedicationSchedule.fromJson(Map<String, dynamic> j) =>
      BackendMedicationSchedule(
        id: (j['id'] ?? '').toString(),
        residentId: (j['residentId'] ?? '').toString(),
        medicationName: (j['medicationName'] ?? '').toString(),
        dosage: (j['dosage'] ?? '').toString(),
        route: (j['route'] ?? 'oral').toString(),
        frequency: (j['frequency'] ?? 'daily').toString(),
        scheduledTimes: (j['scheduledTimes'] as List? ?? [])
            .map((e) => e.toString())
            .toList(),
        startDate: j['startDate']?.toString(),
        endDate: j['endDate']?.toString(),
        isActive: j['isActive'] == true,
        prescriber: j['prescriber']?.toString(),
        notes: j['notes']?.toString(),
      );

  String get arabicFrequency => switch (frequency) {
        'once' => 'مرة واحدة',
        'daily' => 'يومياً',
        'bid' => 'مرتين يومياً',
        'tid' => '3 مرات يومياً',
        'qid' => '4 مرات يومياً',
        'weekly' => 'أسبوعياً',
        'prn' => 'عند الحاجة',
        _ => frequency,
      };
}

class MedicationsService {
  MedicationsService._();
  static final MedicationsService instance = MedicationsService._();
  static const elderlyConfirmationNote = 'resident_confirmed_pending_nurse';

  Future<List<BackendMedicationSchedule>> getSchedules({
    String? residentId,
    bool? active,
  }) async {
    final res = await ApiClient.instance.get(
      '/medications/schedules',
      query: {
        if (residentId != null) 'residentId': residentId,
        if (active != null) 'active': active.toString(),
      },
    );
    if (res is! List) return [];
    return res
        .map((e) =>
            BackendMedicationSchedule.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<dynamic>> getOverdue() async {
    final res = await ApiClient.instance.get('/medications/overdue');
    if (res is List) return res;
    return [];
  }

  Future<Map<String, dynamic>?> logDose({
    required String scheduleId,
    required String residentId,
    required DateTime scheduledTime,
    required String status,
    String? notes,
  }) async {
    final res = await ApiClient.instance.post('/medications/doses', body: {
      'scheduleId': scheduleId,
      'residentId': residentId,
      'scheduledTime': scheduledTime.toIso8601String(),
      'status': status,
      if (status == 'given') 'administeredAt': DateTime.now().toIso8601String(),
      if (notes != null && notes.isNotEmpty) 'notes': notes,
    });
    return res is Map ? Map<String, dynamic>.from(res) : null;
  }

  Future<Map<String, dynamic>?> updateDose({
    required String doseId,
    required String status,
    String? notes,
  }) async {
    final res =
        await ApiClient.instance.patch('/medications/doses/$doseId', body: {
      'status': status,
      if (status == 'given') 'administeredAt': DateTime.now().toIso8601String(),
      if (notes != null && notes.isNotEmpty) 'notes': notes,
    });
    return res is Map ? Map<String, dynamic>.from(res) : null;
  }
}
