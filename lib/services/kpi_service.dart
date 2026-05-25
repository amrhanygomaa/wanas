import 'api_client.dart';

class KpiDashboard {
  final String generatedAt;
  final int periodDays;
  final double medicationAdherencePct;
  final int totalDoses;
  final int givenDoses;
  final int missedDoses;
  final int totalVisits;
  final int approvedVisits;
  final int completedVisits;
  final int totalMediaItems;
  final int criticalAlerts;
  final int openComplaints;
  final int closedComplaints;
  final Map<String, dynamic> raw;

  KpiDashboard({
    required this.generatedAt,
    required this.periodDays,
    required this.medicationAdherencePct,
    required this.totalDoses,
    required this.givenDoses,
    required this.missedDoses,
    required this.totalVisits,
    required this.approvedVisits,
    required this.completedVisits,
    required this.totalMediaItems,
    required this.criticalAlerts,
    required this.openComplaints,
    required this.closedComplaints,
    required this.raw,
  });

  factory KpiDashboard.fromJson(Map<String, dynamic> json) {
    final med = (json['medicationAdherence'] as Map?) ?? {};
    final fam = (json['familyEngagement'] as Map?) ?? {};
    final alerts = (json['criticalAlerts'] as Map?) ?? {};
    final comp = (json['complaints'] as Map?) ?? {};
    final period = (json['period'] as Map?) ?? {};
    return KpiDashboard(
      generatedAt: (json['generatedAt'] ?? '').toString(),
      periodDays: (period['days'] ?? 30) as int,
      medicationAdherencePct: (med['adherencePercentage'] ?? 0).toDouble(),
      totalDoses: (med['totalDoses'] ?? 0) as int,
      givenDoses: (med['givenDoses'] ?? 0) as int,
      missedDoses: (med['missedDoses'] ?? 0) as int,
      totalVisits: (fam['totalVisits'] ?? 0) as int,
      approvedVisits: (fam['approvedVisits'] ?? 0) as int,
      completedVisits: (fam['completedVisits'] ?? 0) as int,
      totalMediaItems: (fam['totalMediaItems'] ?? 0) as int,
      criticalAlerts: (alerts['count'] ?? alerts['total'] ?? 0) as int,
      openComplaints: (comp['open'] ?? 0) as int,
      closedComplaints: (comp['closed'] ?? 0) as int,
      raw: json,
    );
  }
}

class KpiService {
  KpiService._();
  static final KpiService instance = KpiService._();

  Future<KpiDashboard> getDashboard({int days = 30}) async {
    final res = await ApiClient.instance.get(
      '/kpi/dashboard',
      query: {'days': days},
    );
    return KpiDashboard.fromJson(res as Map<String, dynamic>);
  }
}
