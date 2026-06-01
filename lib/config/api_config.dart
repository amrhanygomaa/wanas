// إعدادات الاتصال بالـ Backend (السيرفر Raaya Backend)
//
// لتغيير البيئة، عدّل [baseUrl].
//   - Android Emulator (local dev) → 'http://10.0.2.2:3000'
//   - iOS Simulator    (local dev) → 'http://localhost:3000'
//   - Production                   → 'https://api.helpers-tech.com' ✅
class ApiConfig {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api.helpers-tech.com',
  );

  // السيرفر (raaya-users-dev pool)
  static const String cognitoRegion = 'us-east-1';
  static const String cognitoUserPoolId = 'us-east-1_WQgMPSADf';
  static const String cognitoClientId = 'ifk56gi2vp5jn4tshvp96vn06';

  static const String cognitoEndpoint =
      'https://cognito-idp.$cognitoRegion.amazonaws.com/';

  static const Duration requestTimeout = Duration(seconds: 10);

  // secret يُطلب عند تسجيل أول مدير لمنشأة جديدة
  // يجب أن يطابق ADMIN_REGISTRATION_SECRET في .env الباك اند
  static const String adminRegistrationSecret =
      String.fromEnvironment('ADMIN_REG_SECRET', defaultValue: '');

  // يستخدمه التسجيل الذاتي للأسرة والمتطوعين عندما يكون التطبيق مخصصاً لمنشأة واحدة.
  static const String defaultFacilityId =
      String.fromEnvironment('FACILITY_ID', defaultValue: '');
}
