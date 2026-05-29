import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../providers/app_riverpod.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  WidgetRef? _ref;
  bool _isInitialized = false;
  bool _isRequestingPermissions = false;

  Future<void> initialize(WidgetRef ref) async {
    _ref = ref;
    if (_isInitialized) return; // منع التهيئة المتكررة
    _isInitialized = true;

    // تهيئة المناطق الزمنية للجدولة
    tz.initializeTimeZones();

    // إعدادات أندرويد
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // إعدادات آيفون
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (details) {
        if (details.payload != null && _ref != null) {
          _ref!.read(appRiverpod).handleDeepLink(details.payload!);
        }
      },
    );

    // طلب الصلاحيات للأندرويد (خاصة نسخة 13+)
    await requestPermissions();
  }

  Future<void> requestPermissions() async {
    if (_isRequestingPermissions) return; // منع الطلب المتزامن
    _isRequestingPermissions = true;
    try {
      // للأندرويد
      final androidPlugin =
          _notificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        // طلب صلاحية الإشعارات (لأندرويد 13+)
        await androidPlugin.requestNotificationsPermission();
      }

      // للآيفون
      final iosPlugin =
          _notificationsPlugin.resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>();
      if (iosPlugin != null) {
        await iosPlugin.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
      }
    } catch (e) {
      debugPrint('Error requesting permissions: $e');
    } finally {
      _isRequestingPermissions = false;
    }
  }

  // إظهار تنبيه فوري
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'taptaba_general',
      'تنبيهات عامة',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    await _notificationsPlugin.show(id, title, body, details, payload: payload);
  }

  // جدولة تنبيه لموعد معين (مثل الدواء)
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    try {
      await _notificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(scheduledDate, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'taptaba_meds',
            'تنبيهات الأدوية',
            importance: Importance.max,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload,
      );
    } catch (e) {
      // إذا فشلت الجدولة الدقيقة بسبب الصلاحيات، نستخدم الجدولة التقريبية
      debugPrint('Exact alarm failed, falling back to inexact: $e');
      await _notificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(scheduledDate, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'taptaba_meds',
            'تنبيهات الأدوية',
            importance: Importance.max,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload,
      );
    }
  }

  void simulateIncomingNotification(String type) {
    showNotification(
      id: DateTime.now().millisecond,
      title: 'تنبيه جديد من ونس ✨',
      body: 'لديك إشعار جديد بخصوص: $type',
      payload: type,
    );
  }
}

final notificationServiceProvider = Provider((ref) => NotificationService());
