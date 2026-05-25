import 'package:flutter/material.dart';

import '../models/app_models.dart';
import '../screens/common/notifications_center_screen.dart';
import '../screens/elderly/calls_screen.dart';
import '../screens/elderly/medication_screen.dart';
import '../screens/family/chat_with_specialist_screen.dart';
import '../screens/nurse/nurse_dashboard_screen.dart';

class AppNavigationService {
  AppNavigationService._();

  static final navigatorKey = GlobalKey<NavigatorState>();

  static void openPushData(Map<String, dynamic> data) {
    final context = navigatorKey.currentContext;
    final navigator = navigatorKey.currentState;
    if (context == null || navigator == null) return;

    final screen = (data['screen'] ?? data['route'] ?? data['type'] ?? '')
        .toString()
        .toLowerCase();

    if (screen.contains('message')) {
      final otherUserId = data['otherUserId']?.toString();
      navigator.push(MaterialPageRoute(
        builder: (_) => ChatWithSpecialistScreen(
          otherUserId: otherUserId,
          report: CareReport(
            id: 'push-message',
            title: 'محادثة',
            date: 'الآن',
            summary: '',
            socialNotes: '',
            recommendations: '',
            authorName: 'الأخصائي',
            authorRole: 'فريق الرعاية',
            interactionLevel: '',
            moodStatus: '',
          ),
        ),
      ));
      return;
    }

    if (screen.contains('sos') ||
        screen.contains('emergency') ||
        screen.contains('task') ||
        screen.contains('inventory')) {
      navigator.push(
        MaterialPageRoute(builder: (_) => const NurseDashboardScreen()),
      );
      return;
    }

    if (screen.contains('medication')) {
      navigator.push(
        MaterialPageRoute(builder: (_) => const MedicationScreen()),
      );
      return;
    }

    if (screen.contains('call') || screen.contains('video')) {
      navigator.push(
        MaterialPageRoute(builder: (_) => const CallsScreen()),
      );
      return;
    }

    navigator.push(
      MaterialPageRoute(builder: (_) => const NotificationsCenterScreen()),
    );
  }
}
