import 'package:image_picker/image_picker.dart';

import 'api_client.dart';
import 's3_upload_helper.dart';

class UploadedProfileImage {
  final String imageUrl;

  UploadedProfileImage({required this.imageUrl});
}

class ProfileImageService {
  ProfileImageService._();
  static final ProfileImageService instance = ProfileImageService._();

  Future<UploadedProfileImage> uploadResidentImage({
    required String residentId,
    required XFile image,
  }) async {
    try {
      return await _uploadImage(
        requestPath: '/residents/$residentId/photo/upload',
        confirmPath: '/residents/$residentId/photo/confirm',
        image: image,
      );
    } on ApiException catch (e) {
      if (!_isMissingEndpoint(e)) rethrow;
      return _uploadResidentImageViaDocumentEndpoint(
        residentId: residentId,
        image: image,
      );
    }
  }

  Future<UploadedProfileImage> uploadStaffImage({
    required String staffId,
    required XFile image,
  }) {
    return _uploadImage(
      requestPath: '/admin/users/$staffId/photo/upload',
      confirmPath: '/admin/users/$staffId/photo/confirm',
      image: image,
    );
  }

  Future<UploadedProfileImage> _uploadImage({
    required String requestPath,
    required String confirmPath,
    required XFile image,
  }) async {
    final contentType = image.mimeType ?? _contentTypeForName(image.name);
    final requested = await ApiClient.instance.post(requestPath, body: {
      'fileName': image.name.isEmpty ? 'profile.jpg' : image.name,
      'contentType': contentType,
    });
    final uploadMap = Map<String, dynamic>.from(requested as Map);
    final s3Key = (uploadMap['s3Key'] ?? uploadMap['key'] ?? '').toString();
    final uploadUrl =
        (uploadMap['presignedUrl'] ?? uploadMap['uploadUrl'] ?? '').toString();
    if (s3Key.isEmpty || uploadUrl.isEmpty) {
      throw ApiException(500, 'Invalid profile image upload response');
    }

    final bytes = await image.readAsBytes();
    await s3Put(
      uploadUrl: uploadUrl,
      bytes: bytes,
      contentType: contentType,
      label: image.name,
    );

    final confirmed = await ApiClient.instance.patch(confirmPath, body: {
      's3Key': s3Key,
    });
    final confirmedMap = Map<String, dynamic>.from(confirmed as Map);
    return UploadedProfileImage(
      imageUrl: (confirmedMap['imageUrl'] ??
              confirmedMap['url'] ??
              confirmedMap['fileUrl'] ??
              '')
          .toString(),
    );
  }

  Future<UploadedProfileImage> _uploadResidentImageViaDocumentEndpoint({
    required String residentId,
    required XFile image,
  }) async {
    final contentType = image.mimeType ?? _contentTypeForName(image.name);
    final fileName = _safeImageFileName(image.name);
    final requested = await ApiClient.instance.post(
      '/residents/$residentId/documents/upload',
      body: {
        'fileName': fileName,
        'contentType': contentType,
      },
    );
    final uploadMap = Map<String, dynamic>.from(requested as Map);
    final uploadUrl =
        (uploadMap['uploadUrl'] ?? uploadMap['presignedUrl'] ?? '').toString();
    final documentId =
        (uploadMap['id'] ?? uploadMap['documentId'] ?? uploadMap['docId'] ?? '')
            .toString();
    if (uploadUrl.isEmpty || documentId.isEmpty) {
      throw ApiException(500, 'لم يرجع الباك اند رابط رفع صورة المقيم');
    }

    final bytes = await image.readAsBytes();
    await s3Put(
      uploadUrl: uploadUrl,
      bytes: bytes,
      contentType: contentType,
      label: fileName,
    );

    final confirmed = await ApiClient.instance.patch(
      '/residents/$residentId/documents/$documentId/confirm',
    );
    final confirmedMap = Map<String, dynamic>.from(confirmed as Map);
    final imageUrl = _extractImageUrl(confirmedMap);
    if (imageUrl.isEmpty) {
      throw ApiException(500, 'تم رفع الصورة لكن لم يرجع الباك اند رابطها');
    }

    await _persistResidentImageUrl(residentId, imageUrl);
    return UploadedProfileImage(imageUrl: imageUrl);
  }

  String _extractImageUrl(Map<String, dynamic> data) {
    final direct = (data['imageUrl'] ??
            data['url'] ??
            data['fileUrl'] ??
            data['file_url'] ??
            data['downloadUrl'] ??
            data['download_url'] ??
            '')
        .toString();
    if (direct.isNotEmpty) return direct;

    for (final key in const ['document', 'file', 'media']) {
      final nested = data[key];
      if (nested is Map) {
        final nestedUrl = _extractImageUrl(Map<String, dynamic>.from(nested));
        if (nestedUrl.isNotEmpty) return nestedUrl;
      }
    }
    return '';
  }

  Future<void> _persistResidentImageUrl(
    String residentId,
    String imageUrl,
  ) async {
    try {
      await ApiClient.instance.patch('/residents/$residentId', body: {
        'imageUrl': imageUrl,
      });
    } on ApiException catch (e) {
      if (e.statusCode != 400 && e.statusCode != 422) rethrow;
      await ApiClient.instance.patch('/residents/$residentId', body: {
        'image_url': imageUrl,
      });
    }
  }

  bool _isMissingEndpoint(ApiException error) {
    final message = error.message.toLowerCase();
    return error.statusCode == 404 && message.contains('cannot post');
  }

  String _safeImageFileName(String originalName) {
    final cleanName = originalName.trim();
    if (cleanName.isNotEmpty && cleanName.contains('.')) return cleanName;
    final stamp = DateTime.now().millisecondsSinceEpoch;
    return 'resident-profile-$stamp.jpg';
  }

  String _contentTypeForName(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.gif')) return 'image/gif';
    return 'image/jpeg';
  }
}
