import 'api_client.dart';

class FacilitySearchResult {
  final String facilityId;
  final String facilityName;

  const FacilitySearchResult({
    required this.facilityId,
    required this.facilityName,
  });

  factory FacilitySearchResult.fromJson(Map<String, dynamic> json) {
    return FacilitySearchResult(
      facilityId: json['facilityId']?.toString() ?? '',
      facilityName:
          (json['facilityName'] ?? json['facility_name'])?.toString() ?? '',
    );
  }
}

class FacilityInquiryService {
  FacilityInquiryService._();
  static final FacilityInquiryService instance = FacilityInquiryService._();

  Future<List<FacilitySearchResult>> search({
    required String governorate,
    required String city,
    required List<String> features,
  }) async {
    final res = await ApiClient.instance.get(
      '/facilities/search',
      auth: false,
      query: {
        'governorate': governorate,
        'city': city,
        if (features.isNotEmpty) 'features': features.join(','),
      },
    );
    if (res is! List) return const [];
    return res
        .whereType<Map>()
        .map((item) =>
            FacilitySearchResult.fromJson(Map<String, dynamic>.from(item)))
        .where((item) => item.facilityId.isNotEmpty)
        .toList();
  }

  Future<void> createInquiry({
    required String name,
    required String phone,
    required String governorate,
    required String city,
    required List<String> features,
    String? facilityId,
  }) {
    return ApiClient.instance.post(
      '/facility-inquiries',
      auth: false,
      body: {
        'name': name,
        'phone': phone,
        'governorate': governorate,
        'city': city,
        'features': features,
        if (facilityId != null && facilityId.isNotEmpty)
          'facilityId': facilityId,
      },
    ).then((_) {});
  }
}
