import 'package:flutter/material.dart';

class AppSpacing {
  AppSpacing._();
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
}

class AppRadius {
  AppRadius._();
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 24.0;
  static const double xxl = 32.0;
  static const double full = 999.0;
}

class AppCardSizes {
  AppCardSizes._();
  static const double identityCardHeight = 220.0;
  static const double welcomeCardHeight = 190.0;
  static const double infoCardHeight = 120.0;
  static const double medicationCardHeight = 140.0;
}

class AppColors {
  AppColors._();

  // Primary brand
  static const Color primary = Color(0xFFea580c);
  static const Color primaryLight = Color(0xFFfff7ed);
  static const Color primaryBorder = Color(0xFFfed7aa);

  // Purple / AI
  static const Color aiPurple = Color(0xFF6366F1);
  static const Color aiPurpleLight = Color(0xFFEEF2FF);
  static const Color aiPurpleBorder = Color(0xFFC7D2FE);

  // Medical / Nurse blue
  static const Color medical = Color(0xFF0369a1);
  static const Color medicalLight = Color(0xFFe0f2fe);

  // Status
  static const Color success = Color(0xFF059669);
  static const Color successLight = Color(0xFFd1fae5);
  static const Color warning = Color(0xFFd97706);
  static const Color warningLight = Color(0xFFfef3c7);
  static const Color danger = Color(0xFFdc2626);
  static const Color dangerLight = Color(0xFFfee2e2);
  static const Color info = Color(0xFF0284c7);
  static const Color infoLight = Color(0xFFe0f2fe);
  static const Color infoBorder = Color(0xFF7dd3fc);

  // Neutral
  static const Color textPrimary = Color(0xFF1e293b);
  static const Color textSecondary = Color(0xFF475569);
  static const Color textMuted = Color(0xFF94a3b8);
  static const Color surface = Color(0xFFf8fafc);
  static const Color border = Color(0xFFe2e8f0);
  static const Color cardBg = Colors.white;
}

class AppShadows {
  AppShadows._();

  static const List<BoxShadow> card = [
    BoxShadow(
      color: Color(0x08000000),
      blurRadius: 12,
      offset: Offset(0, 4),
    ),
  ];

  static const List<BoxShadow> elevated = [
    BoxShadow(
      color: Color(0x14000000),
      blurRadius: 20,
      offset: Offset(0, 6),
    ),
  ];

  static const List<BoxShadow> navigationBar = [
    BoxShadow(
      color: Color(0x0D000000),
      blurRadius: 10,
      offset: Offset(0, -3),
    ),
  ];
}

class AppGradients {
  AppGradients._();

  static const LinearGradient primary = LinearGradient(
    colors: [Color(0xFFea580c), Color(0xFFf97316)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient medical = LinearGradient(
    colors: [Color(0xFF0369a1), Color(0xFF0284c7)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient ai = LinearGradient(
    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient dark = LinearGradient(
    colors: [Color(0xFF0f172a), Color(0xFF1e293b)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
