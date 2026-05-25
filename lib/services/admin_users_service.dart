import 'api_client.dart';

class ManagedStaffDetails {
  final String id;
  final String email;
  final String fullName;
  final String role;
  final String status;

  const ManagedStaffDetails({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    required this.status,
  });

  factory ManagedStaffDetails.fromJson(Map<String, dynamic> json) {
    return ManagedStaffDetails(
      id: json['id']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      fullName:
          (json['fullName'] ?? json['full_name'] ?? json['name'])?.toString() ??
              '',
      role: json['role']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
    );
  }
}

class StaffReview {
  final String id;
  final String fromName;
  final String fromRole;
  final double rating;
  final String comment;
  final DateTime? createdAt;

  const StaffReview({
    required this.id,
    required this.fromName,
    required this.fromRole,
    required this.rating,
    required this.comment,
    this.createdAt,
  });

  factory StaffReview.fromJson(Map<String, dynamic> json) {
    return StaffReview(
      id: json['id']?.toString() ?? '',
      fromName:
          (json['fromName'] ?? json['from_name'] ?? 'مستخدم')?.toString() ??
              'مستخدم',
      fromRole: (json['fromRole'] ?? json['from_role'] ?? '')?.toString() ?? '',
      rating: double.tryParse((json['rating'] ?? '').toString()) ?? 0,
      comment: json['comment']?.toString() ?? '',
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ??
          json['created_at']?.toString() ??
          ''),
    );
  }
}

class AdminUsersService {
  AdminUsersService._();
  static final AdminUsersService instance = AdminUsersService._();

  Future<ManagedStaffDetails> getUser(String id) async {
    final res = await ApiClient.instance.get('/admin/users/$id');
    return ManagedStaffDetails.fromJson(Map<String, dynamic>.from(res as Map));
  }

  Future<List<StaffReview>> getUserReviews(String id) async {
    final res = await ApiClient.instance.get('/admin/users/$id/reviews');
    return (res as List)
        .map((item) => StaffReview.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }
}
