import 'dart:io';
import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../firebase_options.dart';
import 'app_navigation_service.dart';
import 'api_client.dart';

// Handler للـ background messages (لازم top-level function)
@pragma('vm:entry-point')
Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
  debugPrint('[FCM] Background: ${message.notification?.title}');
}

class PushNotificationService {
  PushNotificationService._();
  static final PushNotificationService instance = PushNotificationService._();

  final _localNotifications = FlutterLocalNotificationsPlugin();

  String? _currentToken;
  Future<void>? _initFuture;

  FirebaseMessaging get _fcm => FirebaseMessaging.instance;

  Future<void> init() {
    _initFuture ??= _initInternal();
    return _initFuture!;
  }

  Future<void> _initInternal() async {
    final firebaseReady = await _ensureFirebaseInitialized();
    if (!firebaseReady) return;

    // طلب إذن الإشعارات
    final settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      debugPrint('[FCM] إذن الإشعارات مرفوض');
      return;
    }

    // إعداد local notifications للعرض أثناء الـ foreground
    await _initLocalNotifications();

    // Register background handler
    FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);

    // Foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // الضغط على إشعار وهو background
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // الضغط على إشعار وهو terminated
    final initial = await _fcm.getInitialMessage();
    if (initial != null) _handleNotificationTap(initial);

    // جلب الـ token وإرساله للـ backend
    await _registerToken();

    // تجديد الـ token تلقائياً
    _fcm.onTokenRefresh.listen((token) async {
      _currentToken = token;
      await _sendTokenToBackend(token);
    });
  }

  Future<bool> _ensureFirebaseInitialized() async {
    if (kIsWeb || !(Platform.isAndroid || Platform.isIOS)) {
      debugPrint('[FCM] Firebase Messaging غير مدعوم على هذه المنصة');
      return false;
    }

    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }
      return true;
    } catch (e) {
      debugPrint('[FCM] فشل تهيئة Firebase: $e');
      return false;
    }
  }

  Future<void> _initLocalNotifications() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    await _localNotifications.initialize(
      settings,
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload == null || payload.isEmpty) return;
        try {
          final data = jsonDecode(payload);
          if (data is Map) {
            AppNavigationService.openPushData(Map<String, dynamic>.from(data));
          }
        } catch (_) {
          debugPrint('[FCM] Local notification payload غير صالح');
        }
      },
    );

    // Android channel عالي الأولوية للـ SOS
    if (Platform.isAndroid) {
      const channel = AndroidNotificationChannel(
        'raaya_high',
        'تنبيهات طوارئ',
        description: 'إشعارات SOS والتنبيهات الحرجة',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
      );
      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    debugPrint('[FCM] Foreground: ${notification.title}');

    // عرض كـ local notification
    _localNotifications.show(
      message.hashCode,
      notification.title ?? 'طبطبة',
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          message.data['type'] == 'sos' ? 'raaya_high' : 'raaya_default',
          message.data['type'] == 'sos' ? 'تنبيهات طوارئ' : 'إشعارات',
          importance: message.data['type'] == 'sos'
              ? Importance.max
              : Importance.defaultImportance,
          priority: message.data['type'] == 'sos'
              ? Priority.max
              : Priority.defaultPriority,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      payload: jsonEncode(message.data),
    );
  }

  void _handleNotificationTap(RemoteMessage message) {
    debugPrint('[FCM] Tap: type=${message.data['type']}');
    AppNavigationService.openPushData(Map<String, dynamic>.from(message.data));
  }

  Future<void> _registerToken() async {
    try {
      final token = Platform.isIOS
          ? await _fcm.getAPNSToken().then((_) => _fcm.getToken())
          : await _fcm.getToken();

      if (token == null || token.isEmpty) return;
      _currentToken = token;
      await _sendTokenToBackend(token);
    } catch (e) {
      debugPrint('[FCM] فشل جلب الـ token: $e');
    }
  }

  Future<void> _sendTokenToBackend(String token) async {
    try {
      await ApiClient.instance.post('/notifications/push-tokens', body: {
        'token': token,
        'platform': Platform.isIOS ? 'ios' : 'android',
      });
      debugPrint('[FCM] Token مُسجَّل في الباك اند');
    } catch (e) {
      debugPrint('[FCM] فشل تسجيل Token: $e');
    }
  }

  Future<void> removeToken() async {
    if (_currentToken == null) return;
    try {
      await ApiClient.instance.delete(
          '/notifications/push-tokens/${Uri.encodeComponent(_currentToken!)}');
      if (await _ensureFirebaseInitialized()) {
        await _fcm.deleteToken();
      }
      _currentToken = null;
    } catch (e) {
      debugPrint('[FCM] فشل حذف Token: $e');
    }
  }
}
