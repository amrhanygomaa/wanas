import 'api_client.dart';

class BackendResident {
  final String id;
  final String firstName;
  final String lastName;
  final String? roomNumber;
  final String? gender;
  final String? dateOfBirth;
  final String? admissionDate;
  final String status;
  final String? notes;
  final String? nationalId;

  BackendResident({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.roomNumber,
    this.gender,
    this.dateOfBirth,
    this.admissionDate,
    required this.status,
    this.notes,
    this.nationalId,
  });

  String get fullName => '$firstName $lastName'.trim();

  int? get age {
    if (dateOfBirth == null) return null;
    final dob = DateTime.tryParse(dateOfBirth!);
    if (dob == null) return null;
    return DateTime.now().year - dob.year;
  }

  factory BackendResident.fromJson(Map<String, dynamic> json) {
    return BackendResident(
      id: (json['id'] ?? '').toString(),
      firstName: (json['firstName'] ?? '').toString(),
      lastName: (json['lastName'] ?? '').toString(),
      roomNumber: json['roomNumber']?.toString(),
      gender: json['gender']?.toString(),
      dateOfBirth: json['dateOfBirth']?.toString(),
      admissionDate: json['admissionDate']?.toString(),
      status: (json['status'] ?? 'active').toString(),
      notes: json['notes']?.toString(),
      nationalId: json['nationalId']?.toString(),
    );
  }
}

class ResidentsService {
  ResidentsService._();
  static final ResidentsService instance = ResidentsService._();

  Future<List<BackendResident>> getAll({String? status}) async {
    final res = await ApiClient.instance.get(
      '/residents',
      query: status != null ? {'status': status} : null,
    );
    if (res is! List) return [];
    return res
        .map((e) => BackendResident.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<BackendResident> getOne(String id) async {
    final res = await ApiClient.instance.get('/residents/$id');
    return BackendResident.fromJson(res as Map<String, dynamic>);
  }

  // Admin only - يتطلب JWT بدور Admin
  Future<BackendResident> create({
    required String firstName,
    required String lastName,
    required String dateOfBirth, // YYYY-MM-DD
    required String gender, // male | female | other
    required String admissionDate, // YYYY-MM-DD
    String? nationalId,
    String? roomNumber,
    String? notes,
  }) async {
    final res = await ApiClient.instance.post('/residents', body: {
      'firstName': firstName,
      'lastName': lastName,
      'dateOfBirth': dateOfBirth,
      'gender': gender,
      'admissionDate': admissionDate,
      if (nationalId != null && nationalId.isNotEmpty) 'nationalId': nationalId,
      if (roomNumber != null && roomNumber.isNotEmpty) 'roomNumber': roomNumber,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
    });
    return BackendResident.fromJson(res as Map<String, dynamic>);
  }
}
