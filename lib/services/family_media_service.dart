import 'package:image_picker/image_picker.dart';

import 'api_client.dart';
import 's3_upload_helper.dart';

class BackendFamilyMedia {
  final String id;
  final String residentId;
  final String fileName;
  final String contentType;
  final String status;
  final String? caption;
  final int? fileSizeBytes;
  final String? mediaUrl;
  final String createdAt;

  BackendFamilyMedia({
    required this.id,
    required this.residentId,
    required this.fileName,
    required this.contentType,
    required this.status,
    this.caption,
    this.fileSizeBytes,
    this.mediaUrl,
    required this.createdAt,
  });

  factory BackendFamilyMedia.fromJson(Map<String, dynamic> j) {
    return BackendFamilyMedia(
      id: (j['id'] ?? '').toString(),
      residentId: (j['residentId'] ?? j['resident_id'] ?? '').toString(),
      fileName: (j['fileName'] ?? j['file_name'] ?? '').toString(),
      contentType: (j['contentType'] ?? j['content_type'] ?? '').toString(),
      status: (j['status'] ?? '').toString(),
      caption: (j['caption'])?.toString(),
      fileSizeBytes: (j['fileSizeBytes'] ?? j['file_size_bytes']) is num
          ? ((j['fileSizeBytes'] ?? j['file_size_bytes']) as num).toInt()
          : null,
      mediaUrl: (j['mediaUrl'] ??
              j['media_url'] ??
              j['downloadUrl'] ??
              j['presignedUrl'])
          ?.toString(),
      createdAt: (j['createdAt'] ?? j['created_at'] ?? '').toString(),
    );
  }
}

class FamilyMediaService {
  FamilyMediaService._();
  static final FamilyMediaService instance = FamilyMediaService._();

  Future<List<BackendFamilyMedia>> list({
    String? residentId,
    String status = 'confirmed',
  }) async {
    final res = await ApiClient.instance.get('/family-bridge/media', query: {
      if (residentId != null && residentId.isNotEmpty) 'residentId': residentId,
      if (status.isNotEmpty) 'status': status,
    });
    if (res is! List) return [];
    return res
        .whereType<Map>()
        .map((e) => BackendFamilyMedia.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<BackendFamilyMedia> uploadImage({
    required String residentId,
    required XFile image,
    String? caption,
  }) async {
    final contentType = image.mimeType ?? _contentTypeForName(image.name);
    final requested = await ApiClient.instance.post(
      '/family-bridge/media/upload',
      body: {
        'residentId': residentId,
        'fileName': image.name.isEmpty ? 'family-photo.jpg' : image.name,
        'contentType': contentType,
        if (caption != null && caption.isNotEmpty) 'caption': caption,
      },
    );

    final uploadMap = Map<String, dynamic>.from(requested as Map);
    final uploadUrl = (uploadMap['presignedUrl'] ?? '').toString();
    final media = BackendFamilyMedia.fromJson(
      Map<String, dynamic>.from(uploadMap['media'] as Map),
    );
    if (uploadUrl.isEmpty || media.id.isEmpty) {
      throw ApiException(500, 'Invalid family media upload response');
    }

    final bytes = await image.readAsBytes();
    await s3Put(
      uploadUrl: uploadUrl,
      bytes: bytes,
      contentType: contentType,
      label: image.name,
    );

    final confirmed = await ApiClient.instance.patch(
      '/family-bridge/media/${media.id}/confirm',
      body: {'fileSizeBytes': bytes.length},
    );
    return BackendFamilyMedia.fromJson(
      Map<String, dynamic>.from(confirmed as Map),
    );
  }

  Future<void> delete(String id) {
    return ApiClient.instance.delete('/family-bridge/media/$id');
  }

  String _contentTypeForName(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.gif')) return 'image/gif';
    return 'image/jpeg';
  }
}
