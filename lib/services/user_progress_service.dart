import 'api_client.dart';

class BackendUserProgress {
  final String id;
  final String userId;
  final int points;
  final int streakDays;
  final int completedActivities;
  final String? lastActivityAt;

  BackendUserProgress({
    required this.id,
    required this.userId,
    required this.points,
    required this.streakDays,
    required this.completedActivities,
    this.lastActivityAt,
  });

  factory BackendUserProgress.fromJson(Map<String, dynamic> json) {
    return BackendUserProgress(
      id: (json['id'] ?? '').toString(),
      userId: (json['userId'] ?? json['user_id'] ?? '').toString(),
      points: ((json['points'] ?? 0) as num).toInt(),
      streakDays:
          ((json['streakDays'] ?? json['streak_days'] ?? 0) as num).toInt(),
      completedActivities: ((json['completedActivities'] ??
              json['completed_activities'] ??
              0) as num)
          .toInt(),
      lastActivityAt:
          (json['lastActivityAt'] ?? json['last_activity_at'])?.toString(),
    );
  }
}

class UserProgressService {
  UserProgressService._();
  static final UserProgressService instance = UserProgressService._();

  Future<BackendUserProgress> getMe() async {
    final res = await ApiClient.instance.get('/user-progress/me');
    return BackendUserProgress.fromJson(res as Map<String, dynamic>);
  }

  Future<BackendUserProgress> addPoints({
    required int points,
    int completedActivitiesDelta = 1,
    int? streakDays,
  }) async {
    final res = await ApiClient.instance.post('/user-progress/points', body: {
      'points': points,
      'completedActivitiesDelta': completedActivitiesDelta,
      if (streakDays != null) 'streakDays': streakDays,
    });
    return BackendUserProgress.fromJson(res as Map<String, dynamic>);
  }
}
