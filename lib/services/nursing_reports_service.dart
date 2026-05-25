import 'api_client.dart';

class NursingReportMetric {
  final String label;
  final String value;

  NursingReportMetric({required this.label, required this.value});

  factory NursingReportMetric.fromJson(Map<String, dynamic> j) {
    return NursingReportMetric(
      label: (j['label'] ?? '').toString(),
      value: (j['value'] ?? '').toString(),
    );
  }
}

class NursingReportCompletenessItem {
  final String title;
  final String value;
  final double percentage;

  NursingReportCompletenessItem({
    required this.title,
    required this.value,
    required this.percentage,
  });

  factory NursingReportCompletenessItem.fromJson(Map<String, dynamic> j) {
    return NursingReportCompletenessItem(
      title: (j['title'] ?? '').toString(),
      value: (j['value'] ?? '').toString(),
      percentage: (j['percentage'] as num?)?.toDouble() ?? 0,
    );
  }
}

class NursingReportPreview {
  final String reportType;
  final String generatedAt;
  final String title;
  final String summary;
  final List<NursingReportMetric> metrics;
  final List<String> notes;
  final List<NursingReportCompletenessItem> completeness;

  NursingReportPreview({
    required this.reportType,
    required this.generatedAt,
    required this.title,
    required this.summary,
    required this.metrics,
    required this.notes,
    required this.completeness,
  });

  factory NursingReportPreview.fromJson(Map<String, dynamic> j) {
    return NursingReportPreview(
      reportType: (j['reportType'] ?? '').toString(),
      generatedAt: (j['generatedAt'] ?? '').toString(),
      title: (j['title'] ?? '').toString(),
      summary: (j['summary'] ?? '').toString(),
      metrics: ((j['metrics'] as List?) ?? const [])
          .whereType<Map>()
          .map((e) => NursingReportMetric.fromJson(
                Map<String, dynamic>.from(e),
              ))
          .toList(),
      notes:
          ((j['notes'] as List?) ?? const []).map((e) => e.toString()).toList(),
      completeness: ((j['completeness'] as List?) ?? const [])
          .whereType<Map>()
          .map((e) => NursingReportCompletenessItem.fromJson(
                Map<String, dynamic>.from(e),
              ))
          .toList(),
    );
  }
}

class NursingReportExport extends NursingReportPreview {
  final String format;
  final String filename;
  final String content;

  NursingReportExport({
    required super.reportType,
    required super.generatedAt,
    required super.title,
    required super.summary,
    required super.metrics,
    required super.notes,
    required super.completeness,
    required this.format,
    required this.filename,
    required this.content,
  });

  factory NursingReportExport.fromJson(Map<String, dynamic> j) {
    final preview = NursingReportPreview.fromJson(j);
    return NursingReportExport(
      reportType: preview.reportType,
      generatedAt: preview.generatedAt,
      title: preview.title,
      summary: preview.summary,
      metrics: preview.metrics,
      notes: preview.notes,
      completeness: preview.completeness,
      format: (j['format'] ?? '').toString(),
      filename: (j['filename'] ?? 'nursing-report.txt').toString(),
      content: (j['content'] ?? '').toString(),
    );
  }
}

class NursingReportSettings {
  final String dailyTime;
  final String weeklyDay;
  final bool criticalAlertEnabled;
  final bool missedMedicationAlertEnabled;
  final List<String> recipients;

  NursingReportSettings({
    required this.dailyTime,
    required this.weeklyDay,
    required this.criticalAlertEnabled,
    required this.missedMedicationAlertEnabled,
    required this.recipients,
  });

  factory NursingReportSettings.fromJson(Map<String, dynamic> j) {
    return NursingReportSettings(
      dailyTime: (j['dailyTime'] ?? '08:00').toString(),
      weeklyDay: (j['weeklyDay'] ?? 'الجمعة').toString(),
      criticalAlertEnabled: j['criticalAlertEnabled'] != false,
      missedMedicationAlertEnabled: j['missedMedicationAlertEnabled'] != false,
      recipients: ((j['recipients'] as List?) ?? const [])
          .map((e) => e.toString())
          .toList(),
    );
  }
}

class NursingReportsService {
  NursingReportsService._();
  static final NursingReportsService instance = NursingReportsService._();

  Future<NursingReportPreview> preview({String? reportType}) async {
    final res =
        await ApiClient.instance.get('/reports/nursing/preview', query: {
      if (reportType != null && reportType.isNotEmpty) 'type': reportType,
    });
    return NursingReportPreview.fromJson(Map<String, dynamic>.from(res as Map));
  }

  Future<List<NursingReportCompletenessItem>> completeness() async {
    final res = await ApiClient.instance.get('/reports/nursing/completeness');
    if (res is! List) return [];
    return res
        .whereType<Map>()
        .map((e) => NursingReportCompletenessItem.fromJson(
              Map<String, dynamic>.from(e),
            ))
        .toList();
  }

  Future<NursingReportExport> export({
    String? reportType,
    String format = 'pdf',
  }) async {
    final res = await ApiClient.instance.get('/reports/nursing/export', query: {
      if (reportType != null && reportType.isNotEmpty) 'type': reportType,
      'format': format,
    });
    return NursingReportExport.fromJson(Map<String, dynamic>.from(res as Map));
  }

  Future<NursingReportSettings> settings() async {
    final res = await ApiClient.instance.get('/reports/nursing/settings');
    return NursingReportSettings.fromJson(
      Map<String, dynamic>.from(res as Map),
    );
  }

  Future<NursingReportSettings> updateSettings({
    String? dailyTime,
    String? weeklyDay,
    bool? criticalAlertEnabled,
    bool? missedMedicationAlertEnabled,
    List<String>? recipients,
  }) async {
    final res =
        await ApiClient.instance.patch('/reports/nursing/settings', body: {
      if (dailyTime != null) 'dailyTime': dailyTime,
      if (weeklyDay != null) 'weeklyDay': weeklyDay,
      if (criticalAlertEnabled != null)
        'criticalAlertEnabled': criticalAlertEnabled,
      if (missedMedicationAlertEnabled != null)
        'missedMedicationAlertEnabled': missedMedicationAlertEnabled,
      if (recipients != null) 'recipients': recipients,
    });
    return NursingReportSettings.fromJson(
      Map<String, dynamic>.from(res as Map),
    );
  }
}
