import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';

class BiometricService {
  BiometricService._();
  static final BiometricService instance = BiometricService._();

  final LocalAuthentication _auth = LocalAuthentication();

  Future<bool> isAvailable() async {
    try {
      return await _auth.canCheckBiometrics || await _auth.isDeviceSupported();
    } on PlatformException {
      return false;
    }
  }

  Future<List<BiometricType>> getAvailableTypes() async {
    try {
      return await _auth.getAvailableBiometrics();
    } on PlatformException {
      return [];
    }
  }

  /// يعيد true عند نجاح التحقق، false عند الفشل أو الإلغاء
  Future<bool> authenticate({String reason = 'تأكيد هويتك للدخول'}) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: false, // يسمح بـ PIN كبديل
          stickyAuth: true, // لا يلغي عند تغيير التطبيق
          useErrorDialogs: true,
        ),
      );
    } on PlatformException {
      return false;
    }
  }

  /// نص وصفي للنوع المتاح (للعرض في الواجهة)
  Future<String> getBiometricLabel() async {
    final types = await getAvailableTypes();
    if (types.contains(BiometricType.face)) return 'Face ID';
    if (types.contains(BiometricType.fingerprint)) return 'بصمة الإصبع';
    if (types.contains(BiometricType.iris)) return 'مسح القزحية';
    return 'التحقق البيومتري';
  }
}
