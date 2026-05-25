import 'api_client.dart';

class BackendVital {
  final String id;
  final String residentId;
  final String recordedAt;
  final int? heartRate;
  final int? bpSystolic;
  final int? bpDiastolic;
  final double? temperature;
  final int? respiratoryRate;
  final int? oxygenSaturation;
  final String? notes;

  BackendVital({
    required this.id,
    required this.residentId,
    required this.recordedAt,
    this.heartRate,
    this.bpSystolic,
    this.bpDiastolic,
    this.temperature,
    this.respiratoryRate,
    this.oxygenSaturation,
    this.notes,
  });

  factory BackendVital.fromJson(Map<String, dynamic> j) => BackendVital(
        id: (j['id'] ?? '').toString(),
        residentId: (j['residentId'] ?? '').toString(),
        recordedAt: (j['recordedAt'] ?? '').toString(),
        heartRate: j['heartRate'] as int?,
        bpSystolic: j['bloodPressureSystolic'] as int?,
        bpDiastolic: j['bloodPressureDiastolic'] as int?,
        temperature: (j['temperature'] as num?)?.toDouble(),
        respiratoryRate: j['respiratoryRate'] as int?,
        oxygenSaturation: j['oxygenSaturation'] as int?,
        notes: j['notes']?.toString(),
      );
}

class BackendHealthAlert {
  final String id;
  final String residentId;
  final String vitalType;
  final num? recordedValue;
  final num? thresholdMin;
  final num? thresholdMax;
  final String severity; // info | warning | critical
  final String status; // active | acknowledged | resolved

  BackendHealthAlert({
    required this.id,
    required this.residentId,
    required this.vitalType,
    this.recordedValue,
    this.thresholdMin,
    this.thresholdMax,
    required this.severity,
    required this.status,
  });

  factory BackendHealthAlert.fromJson(Map<String, dynamic> j) =>
      BackendHealthAlert(
        id: (j['id'] ?? '').toString(),
        residentId: (j['residentId'] ?? '').toString(),
        vitalType: (j['vitalType'] ?? '').toString(),
        recordedValue: j['recordedValue'] as num?,
        thresholdMin: j['thresholdMin'] as num?,
        thresholdMax: j['thresholdMax'] as num?,
        severity: (j['severity'] ?? 'info').toString(),
        status: (j['status'] ?? 'active').toString(),
      );

  String get arabicVitalType => switch (vitalType) {
        'heart_rate' => 'النبض',
        'blood_pressure' => 'الضغط',
        'temperature' => 'الحرارة',
        'oxygen_saturation' => 'الأكسجين',
        'respiratory_rate' => 'التنفس',
        _ => vitalType,
      };

  String get arabicSeverity => switch (severity) {
        'critical' => 'حرج',
        'warning' => 'تحذير',
        'info' => 'معلومة',
        _ => severity,
      };
}

class BackendHealthThreshold {
  final String id;
  final String vitalType;
  final num? minValue;
  final num? maxValue;
  final String? unit;

  BackendHealthThreshold({
    required this.id,
    required this.vitalType,
    this.minValue,
    this.maxValue,
    this.unit,
  });

  factory BackendHealthThreshold.fromJson(Map<String, dynamic> j) {
    return BackendHealthThreshold(
      id: (j['id'] ?? '').toString(),
      vitalType: (j['vitalType'] ?? j['vital_type'] ?? '').toString(),
      minValue: j['minValue'] as num? ?? j['min_value'] as num?,
      maxValue: j['maxValue'] as num? ?? j['max_value'] as num?,
      unit: (j['unit'])?.toString(),
    );
  }
}

class HealthService {
  HealthService._();
  static final HealthService instance = HealthService._();

  Future<BackendVital> recordVitals({
    required String residentId,
    int? heartRate,
    int? bloodPressureSystolic,
    int? bloodPressureDiastolic,
    double? temperature,
    int? respiratoryRate,
    int? oxygenSaturation,
    int? bloodGlucose,
    double? weight,
    String? notes,
  }) async {
    final body = <String, dynamic>{'residentId': residentId};
    if (heartRate != null) body['heartRate'] = heartRate;
    if (bloodPressureSystolic != null) {
      body['bloodPressureSystolic'] = bloodPressureSystolic;
    }
    if (bloodPressureDiastolic != null) {
      body['bloodPressureDiastolic'] = bloodPressureDiastolic;
    }
    if (temperature != null) body['temperature'] = temperature;
    if (respiratoryRate != null) body['respiratoryRate'] = respiratoryRate;
    if (oxygenSaturation != null) body['oxygenSaturation'] = oxygenSaturation;
    if (bloodGlucose != null) body['bloodGlucose'] = bloodGlucose;
    if (weight != null) body['weight'] = weight;
    if (notes != null && notes.isNotEmpty) body['notes'] = notes;

    final res = await ApiClient.instance.post('/health/vitals', body: body);
    // الـ response: { vitalSign: {...}, alerts: [...] }
    final vital = res is Map ? (res['vitalSign'] ?? res['vital'] ?? res) : res;
    return BackendVital.fromJson(vital as Map<String, dynamic>);
  }

  Future<List<BackendVital>> getVitals({String? residentId}) async {
    final res = await ApiClient.instance.get(
      '/health/vitals',
      query: {if (residentId != null) 'residentId': residentId},
    );
    if (res is! List) return [];
    return res
        .map((e) => BackendVital.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<BackendHealthAlert>> getAlerts({
    String? residentId,
    String? status,
  }) async {
    final res = await ApiClient.instance.get(
      '/health/alerts',
      query: {
        if (residentId != null) 'residentId': residentId,
        if (status != null) 'status': status,
      },
    );
    if (res is! List) return [];
    return res
        .map((e) => BackendHealthAlert.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<BackendHealthAlert> acknowledgeAlert(String id,
      {String? notes}) async {
    final res = await ApiClient.instance.patch('/health/alerts/$id', body: {
      'status': 'acknowledged',
      if (notes != null && notes.isNotEmpty) 'notes': notes,
    });
    return BackendHealthAlert.fromJson(Map<String, dynamic>.from(res as Map));
  }

  Future<BackendHealthAlert> resolveAlert(String id, {String? notes}) async {
    final res = await ApiClient.instance.patch('/health/alerts/$id', body: {
      'status': 'resolved',
      if (notes != null && notes.isNotEmpty) 'notes': notes,
    });
    return BackendHealthAlert.fromJson(Map<String, dynamic>.from(res as Map));
  }

  Future<List<BackendHealthThreshold>> getThresholds() async {
    final res = await ApiClient.instance.get('/health/thresholds');
    if (res is! List) return [];
    return res
        .map((e) => BackendHealthThreshold.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<BackendHealthThreshold> upsertThreshold({
    required String vitalType,
    num? minValue,
    num? maxValue,
    String? unit,
  }) async {
    final res = await ApiClient.instance.put('/health/thresholds', body: {
      'vitalType': vitalType,
      if (minValue != null) 'minValue': minValue,
      if (maxValue != null) 'maxValue': maxValue,
      if (unit != null && unit.isNotEmpty) 'unit': unit,
    });
    return BackendHealthThreshold.fromJson(
        Map<String, dynamic>.from(res as Map));
  }
}
