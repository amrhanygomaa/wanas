import 'api_client.dart';

int _scoreAverage(dynamic rawScores) {
  if (rawScores is! Map || rawScores.isEmpty) return 0;
  final scores = rawScores.values.whereType<num>().toList();
  if (scores.isEmpty) return 0;
  final sum = scores.fold<double>(0, (total, score) => total + score);
  return (sum / scores.length).round();
}

class SocialNeedModel {
  final String id;
  final String residentId;
  final String residentName;
  final String needType;
  final String description;
  final String priority;
  final String status;
  final String createdAt;

  SocialNeedModel({
    required this.id,
    required this.residentId,
    required this.residentName,
    required this.needType,
    required this.description,
    required this.priority,
    required this.status,
    required this.createdAt,
  });

  factory SocialNeedModel.fromJson(Map<String, dynamic> j) {
    return SocialNeedModel(
      id: j['id']?.toString() ?? '',
      residentId: (j['residentId'] ?? j['resident_id'])?.toString() ?? '',
      residentName: (j['residentName'] ?? j['resident_name'] ?? j['roomNumber'])
              ?.toString() ??
          '',
      needType:
          (j['needType'] ?? j['need_type'] ?? j['type'])?.toString() ?? '',
      description: (j['description'] ?? j['label'])?.toString() ?? '',
      priority: (j['priority'] ?? (j['isUrgent'] == true ? 'high' : 'medium'))
          .toString(),
      status: j['status']?.toString() ?? 'open',
      createdAt: (j['createdAt'] ?? j['created_at'])?.toString() ?? '',
    );
  }
}

class SocialAssessmentToolModel {
  final String id;
  final String name;
  final String category;
  final String description;
  final int totalQuestions;

  SocialAssessmentToolModel({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.totalQuestions,
  });

  factory SocialAssessmentToolModel.fromJson(Map<String, dynamic> j) {
    return SocialAssessmentToolModel(
      id: j['id']?.toString() ?? '',
      name: j['name']?.toString() ?? '',
      category: (j['category'] ?? j['icon'])?.toString() ?? '',
      description: (j['description'] ?? j['subtitle'])?.toString() ?? '',
      totalQuestions:
          ((j['totalQuestions'] ?? j['total_questions']) as num?)?.toInt() ?? 0,
    );
  }
}

class SocialResidentScoreModel {
  final String residentId;
  final String residentName;
  final int overallScore;
  final String riskLevel;
  final String lastAssessmentDate;

  SocialResidentScoreModel({
    required this.residentId,
    required this.residentName,
    required this.overallScore,
    required this.riskLevel,
    required this.lastAssessmentDate,
  });

  factory SocialResidentScoreModel.fromJson(Map<String, dynamic> j) {
    return SocialResidentScoreModel(
      residentId:
          (j['residentId'] ?? j['resident_id'] ?? j['id'])?.toString() ?? '',
      residentName:
          (j['residentName'] ?? j['resident_name'] ?? j['name'])?.toString() ??
              '',
      overallScore:
          ((j['overallScore'] ?? j['overall_score']) as num?)?.toInt() ??
              _scoreAverage(j['scores']),
      riskLevel:
          (j['riskLevel'] ?? j['risk_level'] ?? j['healthStatus'] ?? 'low')
              .toString(),
      lastAssessmentDate: (j['lastAssessmentDate'] ??
                  j['last_assessment_date'] ??
                  j['lastAssessment'])
              ?.toString() ??
          '',
    );
  }
}

class SocialKpiModel {
  final String label;
  final String value;
  final String trend;
  final bool isPositive;

  SocialKpiModel({
    required this.label,
    required this.value,
    required this.trend,
    required this.isPositive,
  });

  factory SocialKpiModel.fromJson(Map<String, dynamic> j) {
    return SocialKpiModel(
      label: j['label']?.toString() ?? '',
      value: j['value']?.toString() ?? '',
      trend: j['trend']?.toString() ?? '',
      isPositive: (j['isPositive'] ?? j['is_positive']) == true,
    );
  }
}

class SocialService {
  SocialService._();
  static final SocialService instance = SocialService._();

  final _api = ApiClient.instance;

  Future<List<SocialNeedModel>> getNeeds() async {
    try {
      final data = await _api.get('/social/needs');
      if (data is List) {
        return data
            .map((e) => SocialNeedModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<List<SocialAssessmentToolModel>> getAssessmentTools() async {
    try {
      final data = await _api.get('/social/assessment-tools');
      if (data is List) {
        return data
            .map((e) =>
                SocialAssessmentToolModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<List<SocialResidentScoreModel>> getResidentScores() async {
    try {
      final data = await _api.get('/social/resident-scores');
      if (data is List) {
        return data
            .map((e) =>
                SocialResidentScoreModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<List<SocialKpiModel>> getKpis() async {
    try {
      final data = await _api.get('/social/kpis');
      if (data is List) {
        return data
            .map((e) => SocialKpiModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<bool> createNeed(Map<String, dynamic> dto) async {
    try {
      await _api.post('/social/needs', body: dto);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> createAssessment(Map<String, dynamic> dto) async {
    try {
      await _api.post('/social/assessments', body: dto);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getGdsQuestions(
      {String scale = 'GDS'}) async {
    final data = await _api.get(
      '/social/gds-questions',
      query: {'scale': scale},
    );
    if (data is List) {
      return data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }
    return [];
  }

  Future<List<Map<String, dynamic>>> getToolQuestions(String toolId) async {
    final data = await _api.get('/social/assessment-tools/$toolId/questions');
    if (data is List) {
      return data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }
    return [];
  }
}
