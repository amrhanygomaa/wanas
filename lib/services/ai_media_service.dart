import 'dart:io';

import 'package:http/http.dart' as http;

import 'api_client.dart';

class AiMediaUpload {
  final String id;
  final String fileName;
  final String contentType;
  final String status;
  final String? mediaUrl;
  final String? uploadUrl;

  AiMediaUpload({
    required this.id,
    required this.fileName,
    required this.contentType,
    required this.status,
    this.mediaUrl,
    this.uploadUrl,
  });

  factory AiMediaUpload.fromJson(Map<String, dynamic> json) {
    return AiMediaUpload(
      id: (json['id'] ?? '').toString(),
      fileName: (json['fileName'] ?? json['file_name'] ?? '').toString(),
      contentType:
          (json['contentType'] ?? json['content_type'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      mediaUrl: json['mediaUrl']?.toString(),
      uploadUrl: json['uploadUrl']?.toString(),
    );
  }
}

class AiMediaService {
  AiMediaService._();
  static final AiMediaService instance = AiMediaService._();

  Future<AiMediaUpload> uploadFile({
    required String filePath,
    String? residentId,
  }) async {
    final fileName = filePath.split(RegExp(r'[\\/]')).last;
    final contentType = _contentType(fileName);
    final requested = await ApiClient.instance.post('/ai/media/upload', body: {
      'fileName': fileName,
      'contentType': contentType,
      if (residentId != null && residentId.isNotEmpty) 'residentId': residentId,
    });
    final upload = AiMediaUpload.fromJson(requested as Map<String, dynamic>);
    if (upload.uploadUrl == null || upload.uploadUrl!.isEmpty) {
      throw ApiException(500, 'لم يرجع الباك اند رابط رفع S3');
    }

    final bytes = await File(filePath).readAsBytes();
    final put = await http.put(
      Uri.parse(upload.uploadUrl!),
      headers: {'Content-Type': contentType},
      body: bytes,
    );
    if (put.statusCode < 200 || put.statusCode >= 300) {
      throw ApiException(put.statusCode, 'فشل رفع ملف AI إلى S3', put.body);
    }

    final confirmed = await ApiClient.instance.patch(
      '/ai/media/${upload.id}/confirm',
      body: {'notes': 'AI companion media upload'},
    );
    return AiMediaUpload.fromJson(confirmed as Map<String, dynamic>);
  }

  String _contentType(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.pdf')) return 'application/pdf';
    if (lower.endsWith('.doc')) return 'application/msword';
    if (lower.endsWith('.docx')) {
      return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
    }
    if (lower.endsWith('.m4a')) return 'audio/mp4';
    if (lower.endsWith('.mp3')) return 'audio/mpeg';
    return 'application/octet-stream';
  }
}
