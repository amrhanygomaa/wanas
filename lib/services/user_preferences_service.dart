import 'api_client.dart';

class BackendUserPreferences {
  final Map<String, dynamic> preferences;

  BackendUserPreferences({required this.preferences});

  factory BackendUserPreferences.fromJson(Map<String, dynamic> json) {
    return BackendUserPreferences(
      preferences: Map<String, dynamic>.from(
        (json['preferences'] as Map?) ?? const {},
      ),
    );
  }
}

class UserPreferencesService {
  UserPreferencesService._();
  static final UserPreferencesService instance = UserPreferencesService._();

  Future<BackendUserPreferences> getMe() async {
    final res = await ApiClient.instance.get('/user-preferences/me');
    return BackendUserPreferences.fromJson(res as Map<String, dynamic>);
  }

  Future<BackendUserPreferences> update(
      Map<String, dynamic> preferences) async {
    final res = await ApiClient.instance.put(
      '/user-preferences/me',
      body: {'preferences': preferences},
    );
    return BackendUserPreferences.fromJson(res as Map<String, dynamic>);
  }
}
