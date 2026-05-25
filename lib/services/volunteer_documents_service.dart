import 'dart:io';

import 'package:file_picker/file_picker.dart' as fp;
import 'package:http/http.dart' as http;

import 'api_client.dart';

class VolunteerDocumentUpload {
  final String id;
  final String documentType;
  final String fileName;
  final String contentType;
  final String status;
  final String? fileUrl;
  final String? uploadUrl;

  VolunteerDocumentUpload({
    required this.id,
    required this.documentType,
    required this.fileName,
    required this.contentType,
    required this.status,
    this.fileUrl,
    this.uploadUrl,
  });

  factory VolunteerDocumentUpload.fromJson(Map<String, dynamic> json) {
    return VolunteerDocumentUpload(
      id: (json['id'] ?? '').toString(),
      documentType:
          (json['documentType'] ?? json['document_type'] ?? '').toString(),
      fileName: (json['fileName'] ?? json['file_name'] ?? '').toString(),
      contentType:
          (json['contentType'] ?? json['content_type'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      fileUrl: json['fileUrl']?.toString() ?? json['file_url']?.toString(),
      uploadUrl: json['uploadUrl']?.toString() ??
          json['presignedUrl']?.toString() ??
          json['presigned_url']?.toString(),
    );
  }
}

class VolunteerDocumentsService {
  VolunteerDocumentsService._();
  static final VolunteerDocumentsService instance =
      VolunteerDocumentsService._();

  Future<VolunteerDocumentUpload> uploadDocument({
    required String documentType,
    required fp.PlatformFile file,
  }) async {
    final contentType = _contentType(file.name);
    final requested = await ApiClient.instance.post(
      '/volunteers/documents/upload',
      body: {
        'documentType': documentType,
        'fileName': file.name,
        'contentType': contentType,
      },
    );
    final upload =
        VolunteerDocumentUpload.fromJson(requested as Map<String, dynamic>);
    final uploadUrl = upload.uploadUrl;
    if (uploadUrl == null || uploadUrl.isEmpty) {
      throw ApiException(500, 'لم يرجع الباك اند رابط رفع المستند');
    }

    final bytes = file.bytes ??
        (file.path == null ? null : await File(file.path!).readAsBytes());
    if (bytes == null) {
      throw ApiException(400, 'تعذر قراءة الملف المحدد');
    }

    final put = await http.put(
      Uri.parse(uploadUrl),
      headers: {'Content-Type': contentType},
      body: bytes,
    );
    if (put.statusCode < 200 || put.statusCode >= 300) {
      throw ApiException(put.statusCode, 'فشل رفع المستند إلى S3', put.body);
    }

    final confirmed = await ApiClient.instance.patch(
      '/volunteers/documents/${upload.id}/confirm',
      body: {},
    );
    return VolunteerDocumentUpload.fromJson(confirmed as Map<String, dynamic>);
  }

  Future<String> createPublicProfileLink() async {
    final response =
        await ApiClient.instance.post('/volunteers/profile/public-link');
    final data = Map<String, dynamic>.from(response as Map);
    final url = (data['url'] ?? '').toString();
    if (url.isEmpty) {
      throw ApiException(500, 'لم يرجع الباك اند رابط الملف العام');
    }
    return url;
  }

  String _contentType(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.pdf')) return 'application/pdf';
    if (lower.endsWith('.doc')) return 'application/msword';
    if (lower.endsWith('.docx')) {
      return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
    }
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
    if (lower.endsWith('.png')) return 'image/png';
    return 'application/octet-stream';
  }
}
