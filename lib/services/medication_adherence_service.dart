import 'api_client.dart';

class MedicationAdherenceSummary {
  final int totalDoses;
  final int givenDoses;
  final double percentage;

  MedicationAdherenceSummary({
    required this.totalDoses,
    required this.givenDoses,
    required this.percentage,
  });

  factory MedicationAdherenceSummary.fromJson(Map<String, dynamic> j) {
    return MedicationAdherenceSummary(
      totalDoses: (j['totalDoses'] as num?)?.toInt() ?? 0,
      givenDoses: (j['givenDoses'] as num?)?.toInt() ?? 0,
      percentage: (j['percentage'] as num?)?.toDouble() ?? 0,
    );
  }
}

class ResidentMedicationAdherence extends MedicationAdherenceSummary {
  final String residentId;
  final String residentName;
  final String roomNumber;

  ResidentMedicationAdherence({
    required this.residentId,
    required this.residentName,
    required this.roomNumber,
    required super.totalDoses,
    required super.givenDoses,
    required super.percentage,
  });

  factory ResidentMedicationAdherence.fromJson(Map<String, dynamic> j) {
    return ResidentMedicationAdherence(
      residentId: (j['residentId'] ?? '').toString(),
      residentName:
          '${j['residentFirstName'] ?? ''} ${j['residentLastName'] ?? ''}'
              .trim(),
      roomNumber: (j['roomNumber'] ?? '').toString(),
      totalDoses: (j['totalDoses'] as num?)?.toInt() ?? 0,
      givenDoses: (j['givenDoses'] as num?)?.toInt() ?? 0,
      percentage: (j['percentage'] as num?)?.toDouble() ?? 0,
    );
  }
}

class MedicationAdherenceReport {
  final String period;
  final String from;
  final String to;
  final MedicationAdherenceSummary facilityAdherence;
  final List<ResidentMedicationAdherence> residents;

  MedicationAdherenceReport({
    required this.period,
    required this.from,
    required this.to,
    required this.facilityAdherence,
    required this.residents,
  });

  factory MedicationAdherenceReport.fromJson(Map<String, dynamic> j) {
    return MedicationAdherenceReport(
      period: (j['period'] ?? '').toString(),
      from: (j['from'] ?? '').toString(),
      to: (j['to'] ?? '').toString(),
      facilityAdherence: MedicationAdherenceSummary.fromJson(
        Map<String, dynamic>.from(
          (j['facilityAdherence'] as Map?) ?? const <String, dynamic>{},
        ),
      ),
      residents: ((j['residents'] as List?) ?? const [])
          .whereType<Map>()
          .map((e) => ResidentMedicationAdherence.fromJson(
                Map<String, dynamic>.from(e),
              ))
          .toList(),
    );
  }
}

class MedicationAdherenceService {
  MedicationAdherenceService._();
  static final MedicationAdherenceService instance =
      MedicationAdherenceService._();

  Future<MedicationAdherenceReport> report({
    String period = 'weekly',
    String? residentId,
  }) async {
    final res = await ApiClient.instance.get('/medications/adherence', query: {
      'period': period,
      if (residentId != null && residentId.isNotEmpty) 'residentId': residentId,
    });
    return MedicationAdherenceReport.fromJson(
      Map<String, dynamic>.from(res as Map),
    );
  }
}
