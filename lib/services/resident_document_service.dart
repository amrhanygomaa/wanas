import 'dart:io';

import 'api_client.dart';
import 's3_upload_helper.dart';

class ResidentDocument {
  final String id;
  final String title;
  final String url;
  final String createdAt;

  ResidentDocument({
    required this.id,
    required this.title,
    required this.url,
    required this.createdAt,
  });

  factory ResidentDocument.fromJson(Map<String, dynamic> json) {
    return ResidentDocument(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      url: (json['url'] ?? '').toString(),
      createdAt: (json['createdAt'] ?? '').toString(),
    );
  }
}

class ResidentDocumentService {
  ResidentDocumentService._();
  static final ResidentDocumentService instance = ResidentDocumentService._();

  Future<ResidentDocument> uploadDocument({
    required String residentId,
    required String filePath,
  }) async {
    final fileName = filePath.split(RegExp(r'[\\/]')).last;
    final contentType = _contentType(fileName);

    final requested = await ApiClient.instance.post(
      '/residents/$residentId/documents/upload',
      body: {'fileName': fileName, 'contentType': contentType},
    );
    final requestedMap = Map<String, dynamic>.from(requested as Map);
    final docId = (requestedMap['id'] ?? '').toString();
    final uploadUrl = (requestedMap['uploadUrl'] ?? '').toString();

    if (uploadUrl.isEmpty || docId.isEmpty) {
      throw ApiException(500, 'لم يرجع الباك اند رابط رفع المستند');
    }

    final bytes = await File(filePath).readAsBytes();
    await s3Put(
      uploadUrl: uploadUrl,
      bytes: bytes,
      contentType: contentType,
      label: fileName,
    );

    final confirmed = await ApiClient.instance.patch(
      '/residents/$residentId/documents/$docId/confirm',
    );
    return ResidentDocument.fromJson(confirmed as Map<String, dynamic>);
  }

  Future<List<ResidentDocument>> fetchDocuments(String residentId) async {
    final response =
        await ApiClient.instance.get('/residents/$residentId/documents');
    final list = response as List;
    return list
        .map((e) => ResidentDocument.fromJson(e as Map<String, dynamic>))
        .toList();
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
