import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import 'api_client.dart';

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
  }) {
    return _uploadImage(
      requestPath: '/residents/$residentId/photo/upload',
      confirmPath: '/residents/$residentId/photo/confirm',
      image: image,
    );
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
    final s3Key = (uploadMap['s3Key'] ?? '').toString();
    final uploadUrl = (uploadMap['presignedUrl'] ?? '').toString();
    if (s3Key.isEmpty || uploadUrl.isEmpty) {
      throw ApiException(500, 'Invalid profile image upload response');
    }

    final bytes = await image.readAsBytes();
    final uploaded = await http.put(
      Uri.parse(uploadUrl),
      headers: {'Content-Type': contentType},
      body: bytes,
    );
    if (uploaded.statusCode < 200 || uploaded.statusCode >= 300) {
      throw ApiException(
        uploaded.statusCode,
        'S3 profile upload failed',
        uploaded.body,
      );
    }

    final confirmed = await ApiClient.instance.patch(confirmPath, body: {
      's3Key': s3Key,
    });
    final confirmedMap = Map<String, dynamic>.from(confirmed as Map);
    return UploadedProfileImage(
      imageUrl: (confirmedMap['imageUrl'] ?? '').toString(),
    );
  }

  String _contentTypeForName(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.gif')) return 'image/gif';
    return 'image/jpeg';
  }
}
