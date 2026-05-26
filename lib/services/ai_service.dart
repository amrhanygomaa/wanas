import 'package:flutter/foundation.dart';
import 'api_client.dart';

class AiChatResponse {
  final String reply;
  final String sentiment;
  final String mode;
  final bool bedrockEnabled;
  final String disclaimer;

  AiChatResponse({
    required this.reply,
    required this.sentiment,
    required this.mode,
    required this.bedrockEnabled,
    required this.disclaimer,
  });

  bool get isFromBedrock => mode == 'bedrock';

  factory AiChatResponse.fromJson(Map<String, dynamic> json) {
    return AiChatResponse(
      reply: (json['reply'] ?? '').toString(),
      sentiment: (json['sentiment'] ?? 'neutral').toString(),
      mode: (json['mode'] ?? 'backend').toString(),
      bedrockEnabled: json['bedrockEnabled'] == true,
      disclaimer: (json['disclaimer'] ?? '').toString(),
    );
  }
}

class AiRecommendation {
  final String residentId;
  final String summary;
  final String rationale;
  final String generatedAt;
  final String flag;
  final String disclaimer;

  AiRecommendation({
    required this.residentId,
    required this.summary,
    required this.rationale,
    required this.generatedAt,
    required this.flag,
    required this.disclaimer,
  });

  factory AiRecommendation.fromJson(Map<String, dynamic> json) {
    return AiRecommendation(
      residentId: (json['residentId'] ?? '').toString(),
      summary: (json['summary'] ?? '').toString(),
      rationale: (json['rationale'] ?? '').toString(),
      generatedAt: (json['generatedAt'] ?? '').toString(),
      flag: (json['flag'] ?? '').toString(),
      disclaimer: (json['disclaimer'] ?? '').toString(),
    );
  }
}

class AiSpeechResponse {
  final String provider;
  final String voiceId;
  final String engine;
  final String contentType;
  final String audioBase64;

  AiSpeechResponse({
    required this.provider,
    required this.voiceId,
    required this.engine,
    required this.contentType,
    required this.audioBase64,
  });

  factory AiSpeechResponse.fromJson(Map<String, dynamic> json) {
    return AiSpeechResponse(
      provider: (json['provider'] ?? 'aws-polly').toString(),
      voiceId: (json['voiceId'] ?? '').toString(),
      engine: (json['engine'] ?? '').toString(),
      contentType: (json['contentType'] ?? 'audio/mpeg').toString(),
      audioBase64: (json['audioBase64'] ?? '').toString(),
    );
  }
}

// خدمة الذكاء الاصطناعي عبر AWS Bedrock (Claude Haiku 4.5)
// متصلة فعلياً بالباك اند الإنتاجي على EC2.
class AiService {
  AiService._();
  static final AiService instance = AiService._();

  // إرسال رسالة للرفيق الذكي
  Future<AiChatResponse> sendChat({
    required String message,
    String residentName = 'صديقنا',
    String? residentId,
    String language = 'ar-eg',
    List<Map<String, String>>? conversationHistory,
  }) async {
    final body = <String, dynamic>{
      'message': message,
      'residentName': residentName,
      'language': language,
    };
    if (residentId != null) body['residentId'] = residentId;
    if (conversationHistory != null && conversationHistory.isNotEmpty) {
      body['conversationHistory'] = conversationHistory;
    }

    final res = await ApiClient.instance.post(
      '/ai/chat',
      body: body,
      auth: false, // endpoint عام في الباك اند
    );

    if (kDebugMode) {
      debugPrint('[AI] chat mode=${res['mode']} sentiment=${res['sentiment']}');
    }

    return AiChatResponse.fromJson(res as Map<String, dynamic>);
  }

  Future<AiSpeechResponse> synthesizeSpeech({
    required String text,
    String voiceId = 'Hala',
    String engine = 'neural',
  }) async {
    final res = await ApiClient.instance.post(
      '/ai/speech',
      body: {
        'text': text,
        'voiceId': voiceId,
        'engine': engine,
      },
      auth: false,
    );
    return AiSpeechResponse.fromJson(res as Map<String, dynamic>);
  }

  // جلب توصيات الذكاء الاصطناعي لمقيم
  Future<AiRecommendation> getRecommendations(String residentId) async {
    final res = await ApiClient.instance.get(
      '/ai/recommendations/$residentId',
      auth: false,
    );
    return AiRecommendation.fromJson(res as Map<String, dynamic>);
  }

  // حفظ ذاكرة المقيم في السيرفر (مفيد للسياق)
  Future<void> saveMemory(String residentId, List<String> facts) async {
    if (facts.isEmpty) return;
    await ApiClient.instance.post(
      '/ai/memory/$residentId',
      body: {'memory': facts},
      auth: false,
    );
  }

  // جلب الذاكرة المحفوظة للمقيم
  Future<List<String>> getMemory(String residentId) async {
    try {
      final res = await ApiClient.instance.get(
        '/ai/memory/$residentId',
        auth: false,
      );
      final memory = res['memory'];
      if (memory is List) return memory.map((e) => e.toString()).toList();
    } catch (_) {}
    return [];
  }
}
