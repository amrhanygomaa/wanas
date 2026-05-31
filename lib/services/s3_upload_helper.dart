import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'api_client.dart';

/// Performs an HTTP PUT to a presigned S3 URL with retry logic.
///
/// Retries up to [maxAttempts] times using exponential backoff on network
/// errors and 5xx responses. Throws [ApiException] if all attempts fail.
Future<void> s3Put({
  required String uploadUrl,
  required List<int> bytes,
  required String contentType,
  String label = 'file',
  int maxAttempts = 3,
}) async {
  for (int attempt = 1; attempt <= maxAttempts; attempt++) {
    try {
      debugPrint('[S3] Uploading $label — attempt $attempt/$maxAttempts'
          ' (${bytes.length} bytes)');
      final response = await http
          .put(
            Uri.parse(uploadUrl),
            headers: {'Content-Type': contentType},
            body: bytes,
          )
          .timeout(const Duration(seconds: 60));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        debugPrint('[S3] Upload succeeded: $label');
        return;
      }

      final isRetryable = response.statusCode >= 500;
      debugPrint('[S3] Upload failed: $label — '
          'HTTP ${response.statusCode}${isRetryable ? ' (retryable)' : ''}');

      if (!isRetryable || attempt == maxAttempts) {
        throw ApiException(
          response.statusCode,
          'فشل رفع الملف إلى S3 بعد $attempt محاولة',
          response.body,
        );
      }
    } on TimeoutException {
      debugPrint('[S3] Timeout uploading $label — attempt $attempt');
      if (attempt == maxAttempts) {
        throw ApiException(0, 'انتهت مهلة رفع الملف إلى S3 — تحقق من الاتصال');
      }
    }

    final delay = Duration(seconds: 1 << (attempt - 1)); // 1s, 2s, 4s
    debugPrint('[S3] Retrying in ${delay.inSeconds}s…');
    await Future.delayed(delay);
  }
}
