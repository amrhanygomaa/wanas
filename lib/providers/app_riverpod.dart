import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // للوصول إلى الملفات (مثل الخطوط)
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_models.dart'; // نماذج البيانات المستخدمة في التطبيق
import 'package:permission_handler/permission_handler.dart'; // مكتبة إدارة التصاريح
import 'package:flutter_secure_storage/flutter_secure_storage.dart'; // مكتبة التخزين الآمن
import 'package:flutter_contacts/flutter_contacts.dart'; // مكتبة جهات الاتصال
import 'package:url_launcher/url_launcher.dart'; // مكتبة تشغيل الروابط والمكالمات
import 'package:photo_manager/photo_manager.dart'; // مكتبة إدارة الصور
import 'package:image_picker/image_picker.dart'; // مكتبة اختيار الصور من المعرض
import 'dart:io'; // للتعامل مع ملفات الصور المختارة
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'package:flutter_tts/flutter_tts.dart';
import 'package:audioplayers/audioplayers.dart';

import '../services/notification_service.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../services/backend_sync_service.dart';
import '../services/realtime_service.dart';
import '../services/push_notification_service.dart';
import '../services/facility_settings_service.dart';
import '../services/emergency_service.dart';
import '../services/ai_service.dart';
import '../services/video_call_service.dart';
import '../services/voice_message_service.dart';
import '../services/user_progress_service.dart';
import '../services/backend_mutation_service.dart';
import '../services/social_service.dart';
import '../services/medications_service.dart';
import '../services/health_service.dart';
import '../services/user_preferences_service.dart';
import '../services/complaints_service.dart';
import '../services/ai_media_service.dart';

final appRiverpod = ChangeNotifierProvider((ref) => AppRiverpod());

class AppRiverpod extends ChangeNotifier {
  int selectedIndex = 0;
  int currentAdminTabIndex = 0;

  void setAdminTabIndex(int index) {
    currentAdminTabIndex = index;
    notifyListeners();
  }

  String facilityName = 'دار الأمل لرعاية كبار السن'; // اسم المنشأة
  String managerName = 'م. إبراهيم الجوهري'; // اسم المدير

  void scheduleMedicationReminders(NotificationService service) {
    for (var med in medications) {
      if (!med.isTaken &&
          med.scheduledTime != null &&
          med.scheduledTime!.isAfter(DateTime.now())) {
        service.scheduleNotification(
          id: med.id.hashCode,
          title: 'موعد دواء 💊',
          body: 'حان موعد تناول ${med.name} (${med.dosage})',
          scheduledDate: med.scheduledTime!,
          payload: 'medical',
        );
      }
    }
  }

  String currentRole = 'أخصائي اجتماعي'; // الدور الحالي للمستخدم (مؤقتاً للتجربة)
  bool hasSeenOnboarding = false; // هل شاهد المستخدم شاشات الترحيب؟
  bool isAuthenticated = false; // هل المستخدم مسجل دخوله؟
  bool isInitialized = false; // هل تم تحميل البيانات من الذاكرة؟
  bool isDemoMode = false; // وضع تجريبي بدون اتصال بـ AWS
  double fontScaleFactor = 1.0; // حجم الخط المختار لسهولة القراءة
  bool isHighContrast = false; // تفعيل وضع التباين العالي
  bool isDarkMode = false; // تفعيل الوضع الليلي

  final _storage = const FlutterSecureStorage(); // إنشاء كائن التخزين الآمن
  bool isRefreshingSession = false;
  String selectedAdminDateFilter = 'اليوم';
  DateTime? _sessionExpiry;

  AppAccount? currentAccount; // الحساب الحالي المسجل دخوله

  // --- إدارة الحسابات (Account Management) ---
  List<AppAccount> accounts = [
    AppAccount(
        email: 'admin@admin.com',
        password: '123',
        role: 'إدارة',
        name: 'م. إبراهيم الجوهري',
        facilityName: 'دار الأمل لرعاية كبار السن',
        facilityAddress: 'القاهرة، المعادي، شارع النصر',
        facilityPhone: '0223456789',
        facilityEmail: 'contact@dar-alamal.com',
        licenseNumber: 'LC-2024-9988',
        amenities: ['رعاية طبية 24/7', 'حديقة واسعة', 'علاج طبيعي'],
        phone: '01012345678'),
    AppAccount(
        email: 'nurse@nurse.com',
        password: '123',
        role: 'ممرض',
        name: 'أ. منى زكي',
        facilityName: 'دار الأمل لرعاية كبار السن',
        specialty: 'تمريض كبار السن وقياسات حيوية',
        shift: 'الفترة الصباحية',
        phone: '01122334455'),
    AppAccount(
        email: 'specialist@specialist.com',
        password: '123',
        role: 'أخصائي اجتماعي',
        name: 'د. سارة عثمان',
        facilityName: 'دار الأمل لرعاية كبار السن',
        specialty: 'دعم نفسي واجتماعي',
        shift: 'مرن',
        phone: '01223344556'),
    AppAccount(
        email: 'elderly@taptaba.com',
        password: '123',
        role: 'مسن',
        name: 'أ. محمود عبد العزيز',
        room: 'غرفة 102 - الطابق الأول',
        bloodType: 'A+',
        chronicDiseases: ['ضغط دم مرتفع', 'سكري'],
        mobilityStatus: 'مستقل - مساعدة خفيفة',
        dietType: 'نظام غذائي قليل الأملاح',
        facilityName: 'دار الأمل لرعاية كبار السن',
        phone: '01555666777'),
    AppAccount(
        email: 'family@taptaba.com',
        password: '123',
        role: 'أسرة',
        name: 'أ. أحمد الشريف',
        linkedResidentId: 'res1',
        facilityName: 'دار الأمل لرعاية كبار السن',
        phone: '01222333444'),
    AppAccount(
        email: 'volunteer@taptaba.com',
        password: '123',
        role: 'متطوع',
        name: 'خالد إبراهيم',
        specialty: 'أنشطة ترفيهية وموسيقى',
        phone: '01099887766'),
  ];

  // دالة لتحديث بيانات الحساب الحالي
  void updateCurrentAccount(AppAccount updatedAccount) {
    currentAccount = updatedAccount;
    // تحديث في القائمة العامة أيضاً
    final idx = accounts.indexWhere((a) => a.email == updatedAccount.email);
    if (idx != -1) {
      accounts[idx] = updatedAccount;
    }
    notifyListeners();
  }

  // دالة لاختيار صورة البروفايل
  Future<void> pickProfileImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image != null && currentAccount != null) {
      final updatedAccount = currentAccount!.copyWith(imageUrl: image.path);
      updateCurrentAccount(updatedAccount);
    }
  }

  // دالة للمدير لإنشاء حسابات جديدة
  void createAccount(
      {required String name,
      required String email,
      required String password,
      required String role}) {
    accounts.add(
        AppAccount(name: name, email: email, password: password, role: role));
    notifyListeners();
  }

  // دالة للتسجيل الذاتي (للمتطوعين والأهالي)
  void selfRegister(
      {required String name,
      required String email,
      required String password,
      required String role}) {
    accounts.add(
        AppAccount(name: name, email: email, password: password, role: role));
    notifyListeners();
  }

  // دالة تسجيل المدير مع بيانات المنشأة (تمهيداً للربط مع الباك آند)
  Future<void> registerAdmin({
    required String name,
    required String email,
    required String password,
    required String facilityName,
    required String facilityAddress,
    required List<String> amenities,
    String? facilityYearOfEst,
    String? facilityCapacity,
    String? facilityLicenseNumber,
    String? facilityLocationUrl,
  }) async {
    // محاكاة تأخير الشبكة
    await Future.delayed(const Duration(seconds: 1));

    // إضافة الحساب للقائمة المحلية حالياً
    final newAccount = AppAccount(
      name: name,
      email: email,
      password: password,
      role: 'إدارة',
      facilityName: facilityName,
      facilityAddress: facilityAddress,
      amenities: amenities,
      facilityYearOfEst: facilityYearOfEst,
      facilityCapacity: facilityCapacity,
      licenseNumber: facilityLicenseNumber,
      facilityLocationUrl: facilityLocationUrl,
    );
    
    accounts.add(newAccount);
    currentAccount = newAccount;

    this.facilityName = facilityName;
    this.managerName = name;

    notifyListeners();
  }

  // ربط عائلة بمسن
  void linkFamilyToResident(String residentId, String familyEmail) {
    final idx = residentFiles.indexWhere((r) => r.id == residentId);
    if (idx != -1) {
      final r = residentFiles[idx];
      residentFiles[idx] = SpecialistResidentFile(
        id: r.id,
        name: r.name,
        nameEn: r.nameEn,
        room: r.room,
        status: r.status,
        lastUpdate: r.lastUpdate,
        categories: r.categories,
        initials: r.initials,
        phone: r.phone,
        age: r.age,
        familyMembers: r.familyMembers,
        familyEmail: familyEmail, // الحقل الجديد للربط
        bloodType: r.bloodType,
        chronicDiseases: r.chronicDiseases,
        allergies: r.allergies,
        insuranceInfo: r.insuranceInfo,
        mobilityStatus: r.mobilityStatus,
        assistiveDevices: r.assistiveDevices,
        cognitiveStatus: r.cognitiveStatus,
        dietType: r.dietType,
        foodRestrictions: r.foodRestrictions,
        foodPreferences: r.foodPreferences,
        previousProfession: r.previousProfession,
        hobbies: r.hobbies,
        socialStatus: r.socialStatus,
        uploadedDocuments: r.uploadedDocuments,
      );
      notifyListeners();
    }
  }

  AppRiverpod() {
    _loadAuthState(); // تحميل حالة الدخول عند بدء تشغيل المزود
  }

  // تحميل بيانات الدخول والجلسة من التخزين الآمن
  Future<void> _loadAuthState() async {
    final auth = await _storage.read(key: 'isAuthenticated');
    final role = await _storage.read(key: 'currentRole');
    final onboarding = await _storage.read(key: 'hasSeenOnboarding');
    final expiryStr = await _storage.read(key: 'sessionExpiry');
    final savedEmail = await _storage.read(key: 'userEmail');

    if (auth == 'true') {
      isAuthenticated = true;
      if (expiryStr != null) {
        _sessionExpiry = DateTime.parse(expiryStr);
      }
      
      if (savedEmail != null) {
        final idx = accounts.indexWhere((a) => a.email == savedEmail);
        if (idx != -1) currentAccount = accounts[idx];
      }
    }
    
    // Default fallback if not authenticated
    if (currentAccount == null && accounts.isNotEmpty) {
      currentAccount = accounts[0]; // Admin by default for demo
    }

    if (role != null) currentRole = role;
    if (onboarding == 'true') hasSeenOnboarding = true;

    isInitialized = true; // اكتمل التحميل
    notifyListeners();
  }

  // حفظ الدور في الذاكرة لتجنب الخروج عند الريلود
  Future<void> setAndSaveRole(String role) async {
    currentRole = role;
    await _storage.write(key: 'currentRole', value: role);
    notifyListeners();
  }

  // محاكاة انتهاء الجلسة لأغراض العرض (Demo)
  void simulateSessionExpiry() {
    _sessionExpiry = DateTime.now().subtract(const Duration(minutes: 1));
    notifyListeners();
  }

  // التحقق من صحة الجلسة وتجديدها إذا لزم الأمر
  Future<bool> checkAndRefreshSession() async {
    if (isDemoMode) return true; // لا حاجة لتجديد الجلسة في الوضع التجريبي
    if (!isAuthenticated || _sessionExpiry == null) return true;

    // إذا كانت الجلسة منتهية أو ستنتهي خلال دقيقة
    if (_sessionExpiry!.isBefore(DateTime.now())) {
      if (isRefreshingSession) return false;

      isRefreshingSession = true;
      notifyListeners();

      // محاكاة طلب تجديد الجلسة من السيرفر
      await Future.delayed(const Duration(seconds: 2));

      // نجاح التجديد (في ٩٠٪ من الحالات للمحاكاة)
      bool refreshSuccess = DateTime.now().second % 10 != 0;

      if (refreshSuccess) {
        _sessionExpiry = DateTime.now().add(const Duration(hours: 2));
        await _storage.write(
            key: 'sessionExpiry', value: _sessionExpiry!.toIso8601String());
        isRefreshingSession = false;
        notifyListeners();
        return true;
      } else {
        // فشل التجديد -> يتطلب تسجيل دخول جديد
        isRefreshingSession = false;
        logout(); // تسجيل الخروج التلقائي
        return false;
      }
    }
    return true;
  }

  void toggleDarkMode() {
    isDarkMode = !isDarkMode;
    notifyListeners();
  }

  // تحديث فلتر التاريخ للوحة تحكم المدير ومحاكاة جلب البيانات بناءً على الفترة الزمنية
  void updateAdminDateFilter(String filter) {
    selectedAdminDateFilter = filter;
    // ملاحظة: هنا يمكن إضافة استدعاء للـ API لتحديث قائمة الإحصائيات (adminStats)
    // بناءً على التاريخ المختار (اليوم مقابل الشهر الماضي مثلاً)
    notifyListeners(); // إشعار كافة واجهات المدير بضرورة إعادة البناء بالبيانات الجديدة
  }

  // Offline Mode State
  List<PendingAssessment> pendingAssessments = [];
  bool isSyncing = false;

  void addPendingAssessment(PendingAssessment assessment) {
    pendingAssessments.add(assessment);
    notifyListeners();
  }

  Future<void> syncAssessments() async {
    if (pendingAssessments.isEmpty) return;
    isSyncing = true;
    notifyListeners();

    // محاكاة عملية الرفع للسيرفر
    await Future.delayed(const Duration(seconds: 2));

    pendingAssessments.clear();
    isSyncing = false;
    notifyListeners();
  }

  // Shift Handoff State
  List<ShiftHandoff> handoffs = [
    ShiftHandoff(
      nurseName: 'أ. منى زكي',
      shiftType: 'الوردية المسائية',
      notes:
          'جميع المقيمين استلموا أدويتهم. الحاج محمود ارتفع ضغطه قليلاً الساعة ٨ م وتم إعطاؤه الدواء اللازم.',
      timestamp: DateTime.now().subtract(const Duration(hours: 4)),
      criticalCases: ['محمود Salem'],
    ),
  ];

  void submitHandoff(ShiftHandoff h) {
    handoffs.insert(0, h);
    notifyListeners();
  }

  // Real Notification State
  List<TaptabaNotification> notifications = [
    TaptabaNotification(
      id: '1',
      title: 'موعد الدواء',
      body: 'حان موعد جرعة "كونكور" الخاصة بك.',
      time: 'منذ ١٠ دقائق',
      type: 'medical',
      targetRole: 'مسن',
    ),
    TaptabaNotification(
      id: 'spec_1',
      title: 'شكوى جديدة ⚠️',
      body: 'تم استلام شكوى من الغرفة ٢٠٤ بخصوص جودة الطعام.',
      time: 'منذ ١٠ دقائق',
      type: 'complaint',
      targetRole: 'specialist',
    ),
    TaptabaNotification(
      id: 'spec_2',
      title: 'تأخر تقييم ⏳',
      body: 'المقيم محمود سالم يحتاج لتقييم اجتماعي دوري.',
      time: 'منذ ساعة',
      type: 'assessment',
      targetRole: 'specialist',
    ),
    TaptabaNotification(
      id: '1',
      title: 'موعد دواء',
      body: 'حان الآن موعد دواء الضغط.',
      time: 'الآن',
      type: 'medical',
      targetRole: 'nurse',
    ),
    TaptabaNotification(
      id: '2',
      title: 'زيارة مرتقبة',
      body: 'سارة في طريقها إليك الآن.',
      time: 'منذ ساعة',
      type: 'visit',
      targetRole: 'مسن',
    ),
    TaptabaNotification(
      id: '3',
      title: 'تقرير مالي جديد',
      body: 'تم إصدار فاتورة شهر أبريل.',
      time: 'منذ ساعتين',
      type: 'admin',
      targetRole: 'أهل',
    ),
    TaptabaNotification(
      id: '4',
      title: 'تذكير بالماء 💧',
      body: 'حان وقت شرب كوب من الماء.',
      time: 'منذ ٣ ساعات',
      type: 'medical',
      targetRole: 'مسن',
    ),
    TaptabaNotification(
      id: '5',
      title: 'رسالة من المتطوع',
      body: 'أحمد يريد زيارتك غداً صباحاً.',
      time: 'منذ ٤ ساعات',
      type: 'social',
      targetRole: 'مسن',
    ),
    TaptabaNotification(
      id: '6',
      title: 'تحديث الطبيب',
      body: 'تم تحديث سجل الأدوية الخاص بك.',
      time: 'منذ ٥ ساعات',
      type: 'medical',
      targetRole: 'nurse',
    ),
    TaptabaNotification(
      id: '7',
      title: 'فعالية جديدة',
      body: 'غداً رحلة إلى حديقة الأزهر.',
      time: 'منذ ٦ ساعات',
      type: 'social',
      targetRole: 'all',
    ),
    TaptabaNotification(
      id: '8',
      title: 'تقييم مكتمل',
      body: 'تم الانتهاء من التقييم الاجتماعي الدوري.',
      time: 'منذ ٧ ساعات',
      type: 'assessment',
      targetRole: 'specialist',
    ),
    TaptabaNotification(
      id: '9',
      title: 'تنبيه أمان',
      body: 'تم تفعيل نظام الطوارئ في الغرفة ١٠١.',
      time: 'منذ ٨ ساعات',
      type: 'medical',
      targetRole: 'nurse',
    ),
    TaptabaNotification(
      id: '10',
      title: 'رسالة شكر',
      body: 'عائلة المقيم محمود تشكرك على مجهودك.',
      time: 'منذ ٩ ساعات',
      type: 'social',
      targetRole: 'volunteer',
    ),
    TaptabaNotification(
      id: '11',
      title: 'تحديث إداري',
      body: 'سيتم إجراء صيانة دورية للمصاعد غداً.',
      time: 'منذ ١٠ ساعات',
      type: 'admin',
      targetRole: 'all',
    ),
    TaptabaNotification(
      id: '12',
      title: 'صورة جديدة',
      body: 'تمت إضافة صورة جديدة لرحلة الإسكندرية.',
      time: 'أمس',
      type: 'social',
      targetRole: 'مسن',
    ),
    TaptabaNotification(
      id: '13',
      title: 'فحص دوري',
      body: 'موعد فحص السكر بعد ١٠ دقائق.',
      time: 'أمس',
      type: 'medical',
      targetRole: 'nurse',
    ),
    TaptabaNotification(
      id: '14',
      title: 'اجتماع الأخصائيين',
      body: 'اجتماع تنسيقي لمناقشة حالات الطابق الثالث.',
      time: 'أمس',
      type: 'assessment',
      targetRole: 'specialist',
    ),
    TaptabaNotification(
      id: '15',
      title: 'زيارة عائلية',
      body: 'عائلة الحاجة فاطمة في صالة الاستقبال.',
      time: 'أمس',
      type: 'visit',
      targetRole: 'all',
    ),
    TaptabaNotification(
      id: '16',
      title: 'تذكير بالرياضة',
      body: 'حان موعد تمارين الصباح الخفيفة.',
      time: 'أمس',
      type: 'social',
      targetRole: 'مسن',
    ),
    TaptabaNotification(
      id: '17',
      title: 'تسليم وردية',
      body: 'تم الانتهاء من تسليم الوردية الليلية.',
      time: 'أمس',
      type: 'admin',
      targetRole: 'nurse',
    ),
    TaptabaNotification(
      id: '18',
      title: 'شكوى مغلقة',
      body: 'تم حل شكوى الغرفة ٢٠٤ بنجاح.',
      time: 'أمس',
      type: 'complaint',
      targetRole: 'specialist',
    ),
    TaptabaNotification(
      id: '19',
      title: 'مكالمة فائتة',
      body: 'حاول ابنك الاتصال بك منذ قليل.',
      time: 'أمس',
      type: 'family',
      targetRole: 'مسن',
    ),
    TaptabaNotification(
      id: '20',
      title: 'هدية من المتطوع',
      body: 'وصلت هدية صغيرة من فريق المتطوعين.',
      time: 'أمس',
      type: 'social',
      targetRole: 'all',
    ),
  ];

  List<TaptabaNotification> get filteredNotifications {
    return notifications
        .where((n) => n.targetRole == currentRole || n.targetRole == 'all')
        .toList();
  }

  bool get hasNewNotification => filteredNotifications.any((n) => !n.isRead);

  void triggerNotification(
      {required String title,
      required String body,
      String type = 'admin',
      String targetRole = 'all'}) {
    final newNotif = TaptabaNotification(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      body: body,
      time: 'الآن',
      type: type,
      targetRole: targetRole,
    );
    notifications.insert(0, newNotif);
    notifyListeners();
  }

  void markNotificationAsRead(String id) {
    final idx = notifications.indexWhere((n) => n.id == id);
    if (idx != -1) {
      notifications[idx].isRead = true;
      notifyListeners();
    }
  }

  void deleteNotification(String id) {
    notifications.removeWhere((n) => n.id == id);
    notifyListeners();
  }

  void markAllFilteredNotificationsAsRead() {
    for (var n in notifications) {
      if (n.targetRole == currentRole || n.targetRole == 'all') {
        n.isRead = true;
      }
    }
    notifyListeners();
  }

  void clearNotifications() {
    notifications.clear();
    notifyListeners();
  }

  // Nursing Notes State
  List<NursingNote> nursingNotes = [
    NursingNote(
      id: 'n1',
      residentName: 'الحاج محمود سالم',
      title: 'وجبة الغداء',
      content:
          'تناول الوجبة كاملة مع شهية جيدة. مستوى السكر كان مستقراً قبل الوجبة.',
      author: 'أ. منى (مشرف)',
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    NursingNote(
      id: 'n2',
      residentName: 'الحاجة فاطمة علي',
      title: 'متابعة الضغط',
      content:
          'الضغط في انخفاض تدريجي بعد تناول الجرعة الصباحية. الحالة مستقرة الآن.',
      author: 'أ. منى (مشرف)',
      timestamp: DateTime.now().subtract(const Duration(hours: 5)),
    ),
  ];

  void addNursingNote(NursingNote note) {
    nursingNotes.insert(0, note);
    notifyListeners();
  }

  List<NursingNote> getNotesForResident(String residentName) {
    return nursingNotes.where((n) => n.residentName == residentName).toList();
  }

  // Resident Medical Info State
  List<ResidentMedicalInfo> residentMedicalInfos = [
    ResidentMedicalInfo(
      residentName: 'الحاج محمود سالم',
      medications: ['ميتفورمين ٥٠٠ ملغ', 'أسبرين حماية', 'كونكور ٥ ملغ'],
      allergies: ['حساسية من البنسلين'],
      chronicDiseases: ['ضغط الدم المرتفع', 'سكري من النوع الثاني'],
    ),
    ResidentMedicalInfo(
      residentName: 'الحاجة فاطمة علي',
      medications: ['أملوديبين ٥ ملغ', 'أوميغا ٣'],
      allergies: ['حساسية من اللاكتوز'],
      chronicDiseases: ['أمراض القلب التاجية'],
    ),
  ];

  ResidentMedicalInfo getMedicalInfo(String residentName) {
    return residentMedicalInfos.firstWhere(
      (info) => info.residentName == residentName,
      orElse: () => ResidentMedicalInfo(residentName: residentName),
    );
  }

  void updateMedicalInfo(ResidentMedicalInfo newInfo) {
    final index = residentMedicalInfos
        .indexWhere((info) => info.residentName == newInfo.residentName);
    if (index != -1) {
      residentMedicalInfos[index] = newInfo;
    } else {
      residentMedicalInfos.add(newInfo);
    }
    notifyListeners();
  }

  // عملية تسجيل الدخول وحفظ البيانات آمنياً مع ضبط موعد انتهاء الجلسة (US-SmartLogin)
  // تسجيل الدخول عبر الـ Backend الحقيقي (AWS Cognito)
  // يستخدمه LoginScreen بعد نجاح AuthService.login()
  String? backendUserId;
  String? backendFacilityId;
  String? backendResidentId;
  bool isBackendSyncing = false;
  DateTime? lastBackendSyncAt;
  String? backendSyncError;
  Future<void>? _backendSyncFuture;
  Map<String, String> mealPlanIdsByResidentName = {};

  Map<String, String> emergencyContacts = {};
  FacilityBillingSettings? billingSettings;
  FacilityProfileSettings? facilityProfileSettings;

  String? get billingPaymentInstructions {
    final settings = billingSettings;
    if (settings == null || settings.isEmpty) return null;
    return settings.displayText;
  }

  Future<void> loadEmergencyContacts() async {
    try {
      final settings =
          await FacilitySettingsService.instance.emergencyContacts();
      emergencyContacts = settings.toPhoneMap();
      notifyListeners();
    } catch (e) {
      backendSyncError = e.toString();
      notifyListeners();
    }
  }

  Future<void> loadBillingSettings() async {
    try {
      billingSettings =
          await FacilitySettingsService.instance.billingSettings();
      notifyListeners();
    } catch (e) {
      backendSyncError = e.toString();
      notifyListeners();
    }
  }

  Future<void> loadFacilityProfileSettings() async {
    try {
      final profile = await FacilitySettingsService.instance.facilityProfile();
      facilityProfileSettings = profile;
      if (profile.facilityName != null) {
        facilityName = profile.facilityName!;
      }
      if (currentAccount != null) {
        currentAccount = currentAccount!.copyWith(
          facilityName: profile.facilityName,
          facilityAddress: profile.address,
          facilityPhone: profile.phone,
          facilityEmail: profile.email,
          licenseNumber: profile.licenseNumber,
          facilityYearOfEst: profile.facilityYearOfEst,
          facilityCapacity: profile.facilityCapacity,
          facilityLocationUrl: profile.facilityLocationUrl,
        );
      }
      notifyListeners();
    } catch (e) {
      backendSyncError = e.toString();
      notifyListeners();
    }
  }

  Future<void> updateFacilityProfileSettings({
    required AppAccount account,
    required String facilityName,
    required String facilityAddress,
    String? facilityPhone,
    String? facilityEmail,
    String? licenseNumber,
    String? facilityYearOfEst,
    String? facilityCapacity,
    String? facilityLocationUrl,
  }) async {
    try {
      final profile =
          await FacilitySettingsService.instance.updateFacilityProfile(
        facilityName: facilityName,
        address: facilityAddress,
        phone: facilityPhone,
        email: facilityEmail,
        licenseNumber: licenseNumber,
        facilityYearOfEst: facilityYearOfEst,
        facilityCapacity: facilityCapacity,
        facilityLocationUrl: facilityLocationUrl,
      );
      facilityProfileSettings = profile;
      final updated = account.copyWith(
        facilityName: profile.facilityName ?? facilityName,
        facilityAddress: profile.address ?? facilityAddress,
        facilityPhone: profile.phone ?? facilityPhone,
        facilityEmail: profile.email ?? facilityEmail,
        licenseNumber: profile.licenseNumber ?? licenseNumber,
        facilityYearOfEst: profile.facilityYearOfEst ?? facilityYearOfEst,
        facilityCapacity: profile.facilityCapacity ?? facilityCapacity,
        facilityLocationUrl: profile.facilityLocationUrl ?? facilityLocationUrl,
      );
      updateCurrentAccount(updated);
      this.facilityName = updated.facilityName ?? this.facilityName;
      backendSyncError = null;
    } catch (e) {
      backendSyncError = e.toString();
      rethrow;
    } finally {
      notifyListeners();
    }
  }

  void _applyBackendUser({
    required String email,
    required String role,
    required String userId,
    required String facilityId,
    String? name,
    String? linkedResidentId,
    String? facilityName,
  }) {
    isAuthenticated = true;
    currentRole = role;
    backendUserId = userId;
    backendFacilityId = facilityId;
    if (_looksLikeBackendId(linkedResidentId)) {
      backendResidentId = linkedResidentId;
    }

    final idx = accounts.indexWhere((a) => a.email == email);
    if (idx != -1) {
      currentAccount = accounts[idx].copyWith(
        name: name?.isNotEmpty == true ? name : null,
        role: role,
        facilityName: facilityName,
        linkedResidentId:
            _looksLikeBackendId(linkedResidentId) ? linkedResidentId : null,
      );
      accounts[idx] = currentAccount!;
    } else {
      currentAccount = AppAccount(
        email: email,
        name: name?.isNotEmpty == true ? name! : email.split('@').first,
        role: role,
        password: '',
        facilityName: facilityName,
        linkedResidentId:
            _looksLikeBackendId(linkedResidentId) ? linkedResidentId : null,
      );
      accounts.add(currentAccount!);
    }

    managerName = currentAccount!.name;
    if (currentAccount!.facilityName != null) {
      facilityName = currentAccount!.facilityName!;
    }

    currentUser = User(
      name: currentAccount!.name,
      points: currentUser.points,
      streakDays: currentUser.streakDays,
      completedActivities: currentUser.completedActivities,
    );
    _startRealtime();
  }

  void _startRealtime() {
    RealtimeService.instance.connect();
    _realtimeSub ??= RealtimeService.instance
        .liveEventsFor({'resident_audit', 'residents'}).listen((event) {
      final residentId = event['residentId']?.toString() ?? '';
      if (residentId.isEmpty) {
        residentAuditTrails = {};
      } else {
        residentAuditTrails =
            Map<String, List<Map<String, dynamic>>>.from(residentAuditTrails)
              ..remove(residentId);
      }
      notifyListeners();
    });
  }

  Future<void> markBackendAuthenticated({
    required String email,
    required String role,
    required String userId,
    required String facilityId,
    String? name,
    String? linkedResidentId,
    String? facilityName,
  }) async {
    _applyBackendUser(
      email: email,
      role: role,
      userId: userId,
      facilityId: facilityId,
      name: name,
      linkedResidentId: linkedResidentId,
      facilityName: facilityName,
    );
    _sessionExpiry = DateTime.now().add(const Duration(hours: 1));

    await _storage.write(key: 'isAuthenticated', value: 'true');
    await _storage.write(key: 'currentRole', value: role);
    await _storage.write(key: 'userEmail', value: email);
    await _storage.write(
        key: 'sessionExpiry', value: _sessionExpiry!.toIso8601String());

    notifyListeners();
    unawaited(syncBackendData());
    unawaited(PushNotificationService.instance.init());
  }

  Future<void> syncBackendData() {
    if (isDemoMode) return Future.value(); // تجاوز المزامنة في الوضع التجريبي
    if (_backendSyncFuture != null) return _backendSyncFuture!;
    _backendSyncFuture = _syncBackendDataInternal().whenComplete(() {
      _backendSyncFuture = null;
    });
    return _backendSyncFuture!;
  }

  Future<void> _syncBackendDataInternal() async {
    final token = await AuthService.instance.restoreSession();
    if (token == null) {
      // لا توجد جلسة — نحمل بيانات محلية تلقائياً
      if (isAuthenticated && currentRole.isNotEmpty) {
        _loadDemoSeedData(currentRole);
        isDemoMode = true;
        lastBackendSyncAt = DateTime.now();
        notifyListeners();
      }
      return;
    }

    isBackendSyncing = true;
    backendSyncError = null;
    notifyListeners();

    try {
      final snapshot = await BackendSyncService.instance.load(
        preferredResidentId:
            _looksLikeBackendId(backendResidentId) ? backendResidentId : null,
        requireResidentScope: currentRole == 'أسرة',
        role: currentRole,
      );
      _applyBackendSnapshot(snapshot);
      lastBackendSyncAt = DateTime.now();
    } catch (_) {
      // فشل المزامنة — نحمل بيانات محلية بدلاً من إظهار خطأ
      _loadDemoSeedData(currentRole);
      isDemoMode = true;
      lastBackendSyncAt = DateTime.now();
      backendSyncError = null;
    } finally {
      isBackendSyncing = false;
      notifyListeners();
    }

    if (_looksLikeBackendId(backendResidentId)) {
      unawaited(refreshAiInsightFromBackend());
    }

    unawaited(refreshUserProgress());
    unawaited(refreshUserPreferences());

    if (currentRole == 'مسن' || currentRole == 'أسرة') {
      unawaited(refreshActiveVideoCalls());
    }
    if (currentRole == 'ممرض' ||
        currentRole == 'إدارة' ||
        currentRole == 'أخصائي اجتماعي') {
      unawaited(refreshActiveEmergencies());
    }
    if (currentRole == 'أخصائي اجتماعي') {
      unawaited(loadGdsQuestions());
    }
    if (currentRole == 'إدارة') {
      unawaited(loadEmergencyContacts());
      unawaited(loadBillingSettings());
      unawaited(loadFacilityProfileSettings());
    }
  }

  void _applyBackendSnapshot(BackendSyncSnapshot snapshot) {
    backendResidentId = currentRole == 'أسرة'
        ? snapshot.primaryResidentId
        : snapshot.primaryResidentId ?? backendResidentId;
    if (snapshot.primaryResidentName != null &&
        currentRole == 'مسن' &&
        snapshot.primaryResidentName!.isNotEmpty) {
      currentUser.name = snapshot.primaryResidentName!;
      if (currentAccount != null) {
        currentAccount = currentAccount!.copyWith(
          name: snapshot.primaryResidentName,
          linkedResidentId: snapshot.primaryResidentId,
        );
      }
    }
    if (currentRole == 'أسرة' &&
        currentAccount != null &&
        snapshot.primaryResidentId != null) {
      currentAccount = currentAccount!.copyWith(
        linkedResidentId: snapshot.primaryResidentId,
      );
    }

    if (snapshot.residentFiles != null) {
      residentFiles = snapshot.residentFiles!;
    }
    if (snapshot.medications != null) {
      medications = snapshot.medications!;
    }
    if (snapshot.activities != null) {
      activities = snapshot.activities!;
    }
    if (snapshot.activitySessions != null) {
      activitySessions = snapshot.activitySessions!;
    }
    if (snapshot.complaints != null) {
      socialComplaints = snapshot.complaints!;
    }
    if (snapshot.familyVisits != null) {
      familyVisits = snapshot.familyVisits!;
    }
    if (snapshot.familyBills != null) {
      familyBills = snapshot.familyBills!;
    }
    if (snapshot.memoryMoments != null) {
      memoryMoments = snapshot.memoryMoments!;
    }
    if (snapshot.memories != null) {
      memoriesList = snapshot.memories!;
    }
    if (snapshot.voiceMessages != null) {
      voiceMessagesList = snapshot.voiceMessages!;
    }
    if (snapshot.careTasks != null) {
      careTasks = snapshot.careTasks!;
    }
    if (snapshot.inventoryItems != null) {
      inventoryItems = snapshot.inventoryItems!;
    }
    if (snapshot.doctorVisits != null) {
      doctorVisits = snapshot.doctorVisits!;
    }
    if (snapshot.mealPlans != null) {
      mealPlans = snapshot.mealPlans!;
    }
    if (snapshot.mealPlanIdsByResidentName != null) {
      mealPlanIdsByResidentName = snapshot.mealPlanIdsByResidentName!;
    }
    if (snapshot.medicalSessions != null) {
      medicalSessions = snapshot.medicalSessions!;
    }
    if (snapshot.medicalPrescriptions != null) {
      medicalPrescriptions = snapshot.medicalPrescriptions!;
    }
    if (snapshot.volunteerOpportunities != null) {
      volunteerOpportunities = snapshot.volunteerOpportunities!;
    }
    if (snapshot.volunteerBookings != null) {
      volunteerBookings = snapshot.volunteerBookings!;
    }
    if (snapshot.volunteerCertificates != null) {
      volunteerCertificates = snapshot.volunteerCertificates!;
    }
    if (snapshot.volunteerRatings != null) {
      volunteerRatings = snapshot.volunteerRatings!;
    }
    if (snapshot.volunteerReviews != null) {
      volunteerReviews = snapshot.volunteerReviews!;
    }
    if (snapshot.volunteerProfile != null) {
      volunteerProfile = snapshot.volunteerProfile!;
    }
    if (snapshot.notifications != null) {
      notifications = snapshot.notifications!;
    }
    if (snapshot.nursingNotes != null) {
      nursingNotes = snapshot.nursingNotes!;
    }
    if (snapshot.handoffs != null) {
      handoffs = snapshot.handoffs!;
    }
    if (snapshot.socialNeeds != null) {
      socialNeeds = snapshot.socialNeeds!;
    }
    if (snapshot.socialAssessmentTools != null) {
      socialAssessmentTools = snapshot.socialAssessmentTools!;
    }
    if (snapshot.socialResidentScores != null) {
      socialResidentScores = snapshot.socialResidentScores!;
    }
    if (snapshot.staffPerformance != null) {
      staffPerformanceList = snapshot.staffPerformance!;
    }
    if (snapshot.sentReports != null) {
      sentReports = snapshot.sentReports!;
    }
    if (snapshot.careReportPreview != null) {
      careReports = [snapshot.careReportPreview!];
    }
    if (snapshot.familyHealthMetrics != null) {
      familyHealthMetrics = snapshot.familyHealthMetrics!;
    }
    if (snapshot.familyMembers != null) {
      familyMembersList = snapshot.familyMembers!;
    }
    if (snapshot.assessmentHistory != null &&
        snapshot.assessmentHistory!.isNotEmpty) {
      assessmentHistory = snapshot.assessmentHistory!;
    }

    if (currentRole == 'مسن' && companionChatHistory.isEmpty) {
      final name = currentAccount?.name.isNotEmpty == true
          ? currentAccount!.name
          : (snapshot.primaryResidentName ?? 'صديقنا');
      companionChatHistory.add(CompanionMessage(
        id: 'welcome_${DateTime.now().millisecondsSinceEpoch}',
        text: 'مرحباً بك يا $name! أنا رفيقك الذكي، كيف تشعر اليوم؟ ✨',
        isFromAI: true,
        timestamp: DateTime.now(),
      ));
    }

    if (residentFiles.isNotEmpty) {
      residentMedicalInfos = residentFiles.map((r) {
        final meds = medications
            .where((m) => m.residentName == r.name)
            .map((m) => '${m.name} ${m.dosage}'.trim())
            .toList();
        return ResidentMedicalInfo(
          residentName: r.name,
          medications: meds,
          allergies: r.allergies ?? const [],
          chronicDiseases: r.chronicDiseases ?? const [],
        );
      }).toList();
    }
  }

  void _applyUserProgress(BackendUserProgress progress) {
    currentUser = User(
      name: currentUser.name,
      points: progress.points,
      streakDays: progress.streakDays,
      completedActivities: progress.completedActivities,
    );
  }

  Future<void> refreshUserProgress() async {
    if (isDemoMode || AuthService.instance.currentUser == null) return;
    try {
      final progress = await UserProgressService.instance.getMe();
      _applyUserProgress(progress);
      backendSyncError = null;
    } catch (e) {
      backendSyncError = e.toString();
    }
    notifyListeners();
  }

  List<BackendVideoCall> callHistory = [];
  bool isLoadingCallHistory = false;

  Future<void> loadCallHistory() async {
    if (isLoadingCallHistory) return;
    isLoadingCallHistory = true;
    notifyListeners();
    try {
      callHistory = await VideoCallService.instance.history(
        userId: (backendUserId?.isNotEmpty == true) ? backendUserId : null,
      );
    } catch (_) {
      callHistory = [];
    } finally {
      isLoadingCallHistory = false;
      notifyListeners();
    }
  }

  Map<String, List<Map<String, dynamic>>> residentAuditTrails = {};
  final Set<String> loadingAuditTrailResidentIds = {};

  Future<void> loadAuditTrail(String residentId, {bool force = false}) async {
    if (residentId.isEmpty ||
        (!force && residentAuditTrails.containsKey(residentId)) ||
        loadingAuditTrailResidentIds.contains(residentId)) {
      return;
    }
    loadingAuditTrailResidentIds.add(residentId);
    try {
      final res =
          await ApiClient.instance.get('/residents/$residentId/audit-trail');
      if (res is List) {
        residentAuditTrails =
            Map<String, List<Map<String, dynamic>>>.from(residentAuditTrails)
              ..[residentId] = res
                  .whereType<Map>()
                  .map((e) => Map<String, dynamic>.from(e))
                  .toList();
      } else {
        residentAuditTrails =
            Map<String, List<Map<String, dynamic>>>.from(residentAuditTrails)
              ..[residentId] = [];
      }
    } catch (_) {
      residentAuditTrails =
          Map<String, List<Map<String, dynamic>>>.from(residentAuditTrails)
            ..[residentId] = [];
    } finally {
      loadingAuditTrailResidentIds.remove(residentId);
      notifyListeners();
    }
  }

  Future<void> refreshActiveVideoCalls() async {
    if (isDemoMode || AuthService.instance.currentUser == null) return;
    try {
      final calls = await VideoCallService.instance.active();
      if (calls.isEmpty) {
        activeVideoCallId = null;
        activeVideoCallJoinUrl = null;
        isIncomingCall = false;
        isVideoCallActive = false;
        backendSyncError = null;
        notifyListeners();
        return;
      }
      final call = calls.first;
      activeVideoCallId = call.id;
      activeVideoCallJoinUrl = call.joinUrl;
      activeCallerName = call.calleeName?.isNotEmpty == true
          ? call.calleeName!
          : 'مكالمة فيديو';
      activeCallerInitials =
          activeCallerName.isNotEmpty ? activeCallerName.substring(0, 1) : '؟';
      final isOutgoing = call.callerId == backendUserId;
      isIncomingCall = !isOutgoing && call.status == 'ringing';
      isVideoCallActive = call.status == 'accepted' || isOutgoing;
      backendSyncError = null;
    } catch (e) {
      backendSyncError = e.toString();
    }
    notifyListeners();
  }

  Future<void> refreshUserPreferences() async {
    if (isDemoMode || AuthService.instance.currentUser == null) return;
    try {
      final prefs = await UserPreferencesService.instance.getMe();
      _applyUserPreferences(prefs.preferences);
      backendSyncError = null;
    } catch (e) {
      backendSyncError = e.toString();
    }
    notifyListeners();
  }

  void _applyUserPreferences(Map<String, dynamic> prefs) {
    final fontScale = prefs['fontScaleFactor'];
    if (fontScale is num) {
      fontScaleFactor = fontScale.toDouble().clamp(0.8, 1.6);
    }
    final highContrast = prefs['isHighContrast'];
    if (highContrast is bool) isHighContrast = highContrast;
    final darkMode = prefs['isDarkMode'];
    if (darkMode is bool) isDarkMode = darkMode;
    final aiInsights = prefs['isAIInsightsEnabled'];
    if (aiInsights is bool) isAIInsightsEnabled = aiInsights;
    final aiCompanion = prefs['isAICompanionEnabled'];
    if (aiCompanion is bool) isAICompanionEnabled = aiCompanion;
  }

  Map<String, dynamic> _userPreferencesPayload() => {
        'fontScaleFactor': fontScaleFactor,
        'isHighContrast': isHighContrast,
        'isDarkMode': isDarkMode,
        'isAIInsightsEnabled': isAIInsightsEnabled,
        'isAICompanionEnabled': isAICompanionEnabled,
      };

  void _saveUserPreferencesLater() {
    if (isDemoMode || AuthService.instance.currentUser == null) return;
    unawaited(_syncUserPreferences());
  }

  Future<void> _syncUserPreferences() async {
    try {
      await UserPreferencesService.instance.update(_userPreferencesPayload());
      backendSyncError = null;
    } catch (e) {
      backendSyncError = e.toString();
    }
    notifyListeners();
  }

  bool _looksLikeBackendId(String? id) {
    if (id == null || id.isEmpty) return false;
    return RegExp(r'^[0-9a-fA-F-]{30,}$').hasMatch(id);
  }

  String? _residentIdForName(String residentName) {
    final cleanName = residentName.trim();
    for (final resident in residentFiles) {
      if (resident.name.trim() == cleanName &&
          _looksLikeBackendId(resident.id)) {
        return resident.id;
      }
    }
    return _looksLikeBackendId(backendResidentId) ? backendResidentId : null;
  }

  Future<void> _syncMedicationDose(
    Medication medication,
    String status, {
    String? notes,
  }) async {
    if (isDemoMode || AuthService.instance.currentUser == null) return;

    try {
      final parts = medication.id.split('|');
      if (parts.length >= 4 && parts[0] == 'schedule') {
        await MedicationsService.instance.logDose(
          scheduleId: parts[1],
          residentId: parts[2],
          scheduledTime: medication.scheduledTime ?? DateTime.now(),
          status: status,
          notes: notes,
        );
      } else if (parts.length >= 2 && parts[0] == 'dose') {
        await MedicationsService.instance.updateDose(
          doseId: parts[1],
          status: status,
          notes: notes,
        );
      } else {
        return;
      }
      backendSyncError = null;
    } catch (e) {
      backendSyncError = e.toString();
    }
    notifyListeners();
  }

  Future<void> _syncVitals({
    required String residentName,
    required String bp,
    required String sugar,
    required String temp,
  }) async {
    if (AuthService.instance.currentUser == null) return;
    final residentId = _residentIdForName(residentName);
    if (residentId == null) return;

    final bpParts = _bloodPressureParts(bp);
    try {
      await HealthService.instance.recordVitals(
        residentId: residentId,
        bloodPressureSystolic: bpParts[0],
        bloodPressureDiastolic: bpParts[1],
        bloodGlucose: _firstInt(sugar),
        temperature: _firstDouble(temp),
        notes: 'تم التسجيل من تطبيق طبطبة',
      );
      backendSyncError = null;
    } catch (e) {
      backendSyncError = e.toString();
    }
    notifyListeners();
  }

  Future<void> _syncComplaintStatus(
    String id,
    String status, {
    String? resolutionNotes,
  }) async {
    if ((AuthService.instance.currentUser == null && !isDemoMode) ||
        id.startsWith('comp_') ||
        id.isEmpty) {
      return;
    }

    try {
      await ComplaintsService.instance.updateStatus(
        id: id,
        status: status,
        resolutionNotes: resolutionNotes,
      );
      backendSyncError = null;
    } catch (e) {
      backendSyncError = e.toString();
    }
    notifyListeners();
  }

  String _normaliseDigits(String value) {
    const arabic = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    var result = value;
    for (var i = 0; i < arabic.length; i++) {
      result = result.replaceAll(arabic[i], '$i');
    }
    return result;
  }

  int? _firstInt(String value) {
    final match = RegExp(r'\d+').firstMatch(_normaliseDigits(value));
    return match == null ? null : int.tryParse(match.group(0)!);
  }

  double? _firstDouble(String value) {
    final match = RegExp(r'\d+(\.\d+)?').firstMatch(_normaliseDigits(value));
    return match == null ? null : double.tryParse(match.group(0)!);
  }

  List<int?> _bloodPressureParts(String value) {
    final matches = RegExp(r'\d+').allMatches(_normaliseDigits(value)).toList();
    return [
      matches.isNotEmpty ? int.tryParse(matches[0].group(0)!) : null,
      matches.length > 1 ? int.tryParse(matches[1].group(0)!) : null,
    ];
  }

  String _backendComplaintCategory(String category) {
    final normalized = category.toLowerCase();
    if (normalized.contains('food') || category.contains('طعام')) {
      return 'food';
    }
    if (normalized.contains('maintenance') || category.contains('صيانة')) {
      return 'facility';
    }
    if (normalized.contains('communication') || category.contains('تواصل')) {
      return 'communication';
    }
    if (normalized.contains('service') || category.contains('خدمة')) {
      return 'care_quality';
    }
    return 'general';
  }

  String _backendNotificationType(String type) {
    return switch (type) {
      'medical' => 'medication_reminder',
      'complaint' => 'complaint',
      'visit' || 'family' => 'visit_reminder',
      'ai' => 'ai_summary',
      _ => 'vital_alert',
    };
  }

  Future<bool> _runBackendMutation(Future<void> Function() mutation) async {
    if (isDemoMode) return true;

    if (AuthService.instance.currentUser == null) {
      return true;
    }

    try {
      await mutation();
      backendSyncError = null;
      return true;
    } catch (e) {
      backendSyncError = e.toString();
      return false;
    }
  }

  Future<bool> login(String idRaw, String passRaw) async {
    final identifier = idRaw.trim();
    final password = passRaw.trim();

    // البحث في الحسابات المسجلة
    final accountIdx = accounts
        .indexWhere((a) => a.email == identifier && a.password == password);

    if (accountIdx != -1) {
      final account = accounts[accountIdx];
      currentAccount = account;
      isAuthenticated = true;
      currentRole = account.role;
      managerName = account.name;
      if (account.facilityName != null) {
        facilityName = account.facilityName!;
      }
      _sessionExpiry = DateTime.now().add(const Duration(hours: 2));

      await _storage.write(key: 'isAuthenticated', value: 'true');
      await _storage.write(key: 'currentRole', value: currentRole);
      await _storage.write(key: 'userEmail', value: account.email);
      await _storage.write(
          key: 'sessionExpiry', value: _sessionExpiry!.toIso8601String());

      notifyListeners();
      return true;
    }

    // دعم الدخول السريع للمحاكاة (Legacy Support)
    if (password == '123') {
      String role = 'أسرة';
      if (identifier.contains('@admin.com')) {
        role = 'إدارة';
      } else if (identifier.contains('@nurse.com')) {
        role = 'ممرض';
      } else if (identifier.contains('@specialist.com')) {
        role = 'أخصائي اجتماعي';
      } else if (identifier.startsWith('01')) {
        role = 'مسن';
      } else if (identifier.contains('@volunteer.com')) {
        role = 'متطوع';
      }

      // محاولة إيجاد الحساب الفعلي لربطه بالـ UI
      final accountIdx = accounts.indexWhere((a) => a.email == identifier);
      if (accountIdx != -1) {
        currentAccount = accounts[accountIdx];
      } else {
        // إذا لم يوجد حساب، ننشئ حساباً وهمياً مؤقتاً لتجنب القيم الفارغة
        currentAccount = AppAccount(
          email: identifier,
          name: identifier.split('@')[0],
          role: role,
          password: password,
        );
      }

      currentRole = role;
      isAuthenticated = true;
      _sessionExpiry = DateTime.now().add(const Duration(hours: 2));
      notifyListeners();
      return true;
    }

    return false;
  }

  Future<void> logout() async {
    final wasDemo = isDemoMode;
    isAuthenticated = false;
    isDemoMode = false;
    currentRole = '';
    currentAccount = null;
    _sessionExpiry = null;
    backendUserId = null;
    backendFacilityId = null;
    backendResidentId = null;
    backendSyncError = null;
    lastBackendSyncAt = null;
    isBackendSyncing = false;
    activeVideoCallId = null;
    activeVideoCallJoinUrl = null;
    isVideoCallActive = false;
    isIncomingCall = false;
    _clearSeedState();
    await _realtimeSub?.cancel();
    _realtimeSub = null;
    RealtimeService.instance.disconnect();
    if (!wasDemo) {
      await AuthService.instance.logout();
      unawaited(PushNotificationService.instance.removeToken());
    }

    await _storage.delete(key: 'isAuthenticated');
    await _storage.delete(key: 'currentRole');
    await _storage.delete(key: 'userEmail');
    await _storage.delete(key: 'sessionExpiry');

    notifyListeners();
  }

  void _clearSeedState() {
    backendSyncError = null;
    isBackendSyncing = false;
    mealPlanIdsByResidentName.clear();
    activeEmergencies.clear();
    activeVideoCallId = null;
    activeVideoCallJoinUrl = null;
  }

  void loginAsDemo(String role) {
    _clearSeedState();
    isDemoMode = true;
    isAuthenticated = true;
    hasSeenOnboarding = true;
    currentRole = role;
    backendUserId = 'demo-user-001';
    backendFacilityId = 'demo-facility';
    backendResidentId = 'demo-resident-001';
    backendSyncError = null;
    lastBackendSyncAt = DateTime.now();

    final demoName = switch (role) {
      'إدارة' => 'أحمد المدير',
      'ممرض' => 'نورة الممرضة',
      'مسن' => 'عبدالله المقيم',
      'أسرة' => 'سارة (ابنة المقيم)',
      'أخصائي اجتماعي' => 'فاطمة الأخصائية',
      'متطوع' => 'خالد المتطوع',
      _ => 'مستخدم تجريبي',
    };

    currentAccount = AppAccount(
      name: demoName,
      email: 'demo@taptaba.app',
      password: '',
      role: role,
      facilityName: 'دار ونس النموذجية',
      facilityAddress: 'الرياض - حي الملقا',
    );
    accounts = [currentAccount!];
    facilityName = 'دار ونس النموذجية';
    managerName = demoName;
    currentUser = User(
      name: demoName,
      points: 120,
      streakDays: 5,
      completedActivities: 8,
    );

    _loadDemoSeedData(role);
    notifyListeners();
  }

  void _loadDemoSeedData(String role) {
    final demoResidents = [
      Resident(
        id: 'demo-resident-001', name: 'عبدالله الشمري', roomNumber: '101',
        gender: 'ذكر',
        birthDate: DateTime(1945, 3, 15),
        entryDate: DateTime(2024, 1, 10),
        nationalId: '1010101010', imageUrl: '',
        emergencyContactName: 'سارة', emergencyContactPhone: '0501234567',
        emergencyRelation: 'ابنة', bloodType: 'A+',
        allergies: ['بنسلين'], chronicDiseases: ['سكري', 'ضغط'],
        insuranceInfo: 'تأمين شامل', mobilityStatus: 'يستخدم عكاز',
        cognitiveStatus: 'جيد', dietType: 'سكري',
        foodPreferences: 'خالي من الملح', previousProfession: 'مهندس',
        socialStatus: 'أرمل', contractType: 'شهري',
      ),
      Resident(
        id: 'demo-resident-002', name: 'فاطمة العتيبي', roomNumber: '102',
        gender: 'أنثى',
        birthDate: DateTime(1940, 7, 22),
        entryDate: DateTime(2023, 6, 5),
        nationalId: '2020202020', imageUrl: '',
        emergencyContactName: 'محمد', emergencyContactPhone: '0559876543',
        emergencyRelation: 'ابن', bloodType: 'O+',
        allergies: [], chronicDiseases: ['ضغط', 'روماتيزم'],
        insuranceInfo: 'تأمين حكومي', mobilityStatus: 'كرسي متحرك',
        cognitiveStatus: 'خفيف', dietType: 'عادي',
        foodPreferences: '', previousProfession: 'معلمة',
        socialStatus: 'أرملة', contractType: 'سنوي',
      ),
      Resident(
        id: 'demo-resident-003', name: 'محمد القحطاني', roomNumber: '103',
        gender: 'ذكر',
        birthDate: DateTime(1948, 11, 1),
        entryDate: DateTime(2024, 3, 20),
        nationalId: '3030303030', imageUrl: '',
        emergencyContactName: 'نورة', emergencyContactPhone: '0541112233',
        emergencyRelation: 'زوجة', bloodType: 'B+',
        allergies: ['لاكتوز'], chronicDiseases: ['قلب'],
        insuranceInfo: 'تأمين خاص', mobilityStatus: 'مستقل',
        cognitiveStatus: 'جيد', dietType: 'قلب',
        foodPreferences: 'نباتي', previousProfession: 'طبيب',
        socialStatus: 'متزوج', contractType: 'شهري',
      ),
    ];

    residentFiles = demoResidents.map((r) => SpecialistResidentFile(
      id: r.id, name: r.name, nameEn: r.name, room: r.roomNumber,
      status: 'updated', lastUpdate: 'تجريبي',
      categories: const ['medical', 'social'],
      initials: r.name.isNotEmpty ? r.name[0] : '؟',
      phone: r.emergencyContactPhone, age: DateTime.now().year - r.birthDate.year,
      bloodType: r.bloodType, chronicDiseases: r.chronicDiseases,
      allergies: r.allergies, mobilityStatus: r.mobilityStatus,
      dietType: r.dietType, uploadedDocuments: const [], imageUrl: '',
    )).toList();

    final now = DateTime.now();
    medications = [
      Medication(id: 'med-1', name: 'ميتفورمين', dosage: 'قرص واحد 500mg',
        timeDescription: '08:00', timeOfDay: 'الصباح',
        residentName: 'عبدالله الشمري',
        scheduledTime: DateTime(now.year, now.month, now.day, 8), dayTag: 'اليوم'),
      Medication(id: 'med-2', name: 'أملودبين', dosage: 'قرص واحد 5mg',
        timeDescription: '09:00', timeOfDay: 'الصباح',
        residentName: 'عبدالله الشمري',
        scheduledTime: DateTime(now.year, now.month, now.day, 9), dayTag: 'اليوم'),
      Medication(id: 'med-3', name: 'أسبرين', dosage: 'قرص واحد 100mg',
        timeDescription: '14:00', timeOfDay: 'الظهر',
        residentName: 'فاطمة العتيبي',
        scheduledTime: DateTime(now.year, now.month, now.day, 14), dayTag: 'اليوم'),
      Medication(id: 'med-4', name: 'فيتامين D', dosage: 'كبسولة واحدة',
        timeDescription: '20:00', timeOfDay: 'المساء',
        residentName: 'محمد القحطاني',
        scheduledTime: DateTime(now.year, now.month, now.day, 20), dayTag: 'اليوم'),
    ];

    activities = [
      Activity(id: 'act-1', name: 'تمارين صباحية', emoji: '🏃',
        location: 'صالة الرياضة', time: '07:30', status: 'done',
        badges: 'تجريبي', pointsReward: 15, type: 'نشاط'),
      Activity(id: 'act-2', name: 'جلسة قراءة جماعية', emoji: '📚',
        location: 'المكتبة', time: '10:00', status: 'active',
        badges: 'تجريبي', pointsReward: 10, type: 'نشاط'),
      Activity(id: 'act-3', name: 'رحلة حديقة', emoji: '🌳',
        location: 'حديقة المنتزه', time: '15:00', status: 'coming',
        badges: 'تجريبي', pointsReward: 20, type: 'رحلة'),
    ];

    activitySessions = activities.map((a) => ActivitySession(
      id: a.id, title: a.name, description: 'نشاط تجريبي',
      startTime: DateTime.now(), location: a.location, participants: const [],
    )).toList();

    familyMembersList = [
      FamilyMember(id: 'fm-1', name: 'سارة الشمري', relation: 'ابنة',
        avatarPath: '', initials: 'س', phoneNumber: '0501234567',
        isPinned: true, isAvailable: true),
      FamilyMember(id: 'fm-2', name: 'محمد الشمري', relation: 'ابن',
        avatarPath: '', initials: 'م', phoneNumber: '0559876543',
        isPinned: true, isAvailable: false),
    ];

    familyVisits = [
      FamilyVisit(id: 'fv-1', date: 'اليوم', time: '14:00',
        visitorName: 'سارة الشمري', status: 'upcoming', type: 'physical'),
      FamilyVisit(id: 'fv-2', date: 'أمس', time: '11:00',
        visitorName: 'محمد الشمري', status: 'completed', type: 'video'),
    ];

    familyBills = [
      FamilyBill(id: 'bill-1', title: 'رسوم الإقامة - يناير', month: 'يناير',
        amount: 5000, isPaid: true, dueDate: '2025-01-15'),
      FamilyBill(id: 'bill-2', title: 'رسوم الإقامة - فبراير', month: 'فبراير',
        amount: 5000, isPaid: false, dueDate: '2025-02-15'),
    ];

    careTasks = [
      CareTask(id: 'ct-1', residentName: 'عبدالله الشمري',
        title: 'قياس ضغط الدم', category: 'شخصية', isCompleted: false, time: '08:00'),
      CareTask(id: 'ct-2', residentName: 'فاطمة العتيبي',
        title: 'تغيير الضمادات', category: 'شخصية', isCompleted: true, time: '09:30'),
      CareTask(id: 'ct-3', residentName: 'محمد القحطاني',
        title: 'جلسة علاج طبيعي', category: 'ترفيهية', isCompleted: false, time: '11:00'),
    ];

    inventoryItems = [
      InventoryItem(id: 'inv-1', name: 'قفازات طبية', category: 'مستلزمات',
        currentStock: 150, minRequired: 50, unit: 'زوج'),
      InventoryItem(id: 'inv-2', name: 'شاش معقم', category: 'مستلزمات',
        currentStock: 30, minRequired: 20, unit: 'لفة'),
      InventoryItem(id: 'inv-3', name: 'ميتفورمين 500mg', category: 'أدوية',
        currentStock: 45, minRequired: 10, unit: 'شريط'),
    ];

    notifications = [
      TaptabaNotification(id: 'n-1', title: 'تذكير بموعد الدواء',
        body: 'حان موعد دواء الضغط لعبدالله', time: 'منذ 10 دقائق',
        type: 'medical', targetRole: 'all'),
      TaptabaNotification(id: 'n-2', title: 'زيارة عائلية جديدة',
        body: 'طلب زيارة جديد من سارة الشمري', time: 'منذ ساعة',
        type: 'visit', targetRole: 'all'),
    ];

    nursingNotes = [
      NursingNote(id: 'nn-1', residentName: 'عبدالله الشمري',
        title: 'علامات حيوية',
        content: 'ضغط الدم مستقر 130/85 - حالة عامة جيدة',
        author: 'نورة الممرضة', timestamp: DateTime.now()),
      NursingNote(id: 'nn-2', residentName: 'فاطمة العتيبي',
        title: 'إجراءات',
        content: 'تم تغيير الضمادات - الجرح يلتئم بشكل جيد',
        author: 'نورة الممرضة',
        timestamp: DateTime.now().subtract(const Duration(hours: 2))),
    ];

    socialComplaints = [
      SocialSpecialistComplaint(id: 'sc-1', title: 'جودة الطعام',
        residentName: 'عبدالله الشمري', room: '101',
        date: 'اليوم', priority: 'medium', status: 'open',
        category: 'food', icon: '🍽️',
        timeline: [ComplaintStep(text: 'تم تسجيل الشكوى', time: 'اليوم', status: 'done')]),
      SocialSpecialistComplaint(id: 'sc-2', title: 'طلب صيانة',
        residentName: 'فاطمة العتيبي', room: '102',
        date: 'أمس', priority: 'low', status: 'done',
        category: 'maintenance', icon: '🔧',
        timeline: [
          ComplaintStep(text: 'تم تسجيل الشكوى', time: 'أمس', status: 'done'),
          ComplaintStep(text: 'تمت المعالجة', time: 'اليوم', status: 'done'),
        ]),
    ];

    familyHealthMetrics = [
      FamilyHealthMetric(label: 'ضغط الدم', value: 0.75, status: 'good',
        trend: 'stable', history: [0.7, 0.72, 0.74, 0.75]),
      FamilyHealthMetric(label: 'السكر', value: 0.65, status: 'medium',
        trend: 'up', history: [0.6, 0.62, 0.64, 0.65]),
      FamilyHealthMetric(label: 'الوزن', value: 0.8, status: 'good',
        trend: 'stable', history: [0.78, 0.79, 0.8, 0.8]),
    ];

    volunteerOpportunities = [
      VolunteerOpportunity(id: 'vo-1', title: 'مرافقة مسنين في رحلة',
        org: 'دار ونس', dateInfo: 'الأحد القادم', icon: '🚌',
        tags: const ['رحلة', 'مرافقة'], hours: 4, isNew: true,
        description: 'مرافقة ٣ مقيمين في رحلة للحديقة', points: 30),
      VolunteerOpportunity(id: 'vo-2', title: 'جلسة قراءة تفاعلية',
        org: 'دار ونس', dateInfo: 'يوم الثلاثاء', icon: '📖',
        tags: const ['تعليم', 'ترفيه'], hours: 2,
        description: 'قراءة قصص وأشعار للمقيمين', points: 15),
    ];

    volunteerBookings = [
      VolunteerBooking(id: 'vb-1', title: 'مرافقة مسنين في رحلة',
        timeInfo: '09:00 - 13:00', day: 15, month: 'مارس',
        status: 'confirmed', location: 'حديقة المنتزه', points: 30),
    ];

    volunteerCertificates = [
      VolunteerCertificate(id: 'vc-1', name: 'شهادة الرعاية الأساسية',
        icon: '🏅', date: '2025-01-15', progressInfo: 'مكتمل',
        awardTitle: 'متطوع نشط', description: 'إتمام ٢٠ ساعة تطوع', progress: 1.0),
    ];

    volunteerHours = 24;
    volunteerGoal = 50;

    staffPerformanceList = [
      StaffPerformance(id: 'sp-1', name: 'نورة الممرضة', role: 'Nurse',
        completionRate: 0.92, lastActive: 'الآن', status: 'online'),
      StaffPerformance(id: 'sp-2', name: 'فاطمة الأخصائية', role: 'Specialist',
        completionRate: 0.87, lastActive: 'منذ ساعة', status: 'online'),
    ];

    mealPlans = [
      MealPlan(residentName: 'عبدالله الشمري',
        breakfast: 'خبز أسمر + جبن قليل الدسم + شاي بدون سكر',
        lunch: 'أرز بني + دجاج مشوي + سلطة',
        dinner: 'شوربة خضار + خبز',
        specialInstructions: 'نظام سكري'),
      MealPlan(residentName: 'فاطمة العتيبي',
        breakfast: 'فول + خبز + عصير برتقال',
        lunch: 'أرز + لحم + خضار مشكلة',
        dinner: 'زبادي + فواكه + بسكويت'),
    ];

    if (role == 'أسرة') {
      backendResidentId = 'demo-resident-001';
    }
  }

  Future<void> completeOnboarding() async {
    hasSeenOnboarding = true;
    await _storage.write(key: 'hasSeenOnboarding', value: 'true');
    notifyListeners();
  }

  Future<void> resetOnboarding() async {
    hasSeenOnboarding = false;
    await _storage.delete(key: 'hasSeenOnboarding');
    notifyListeners();
  }

  void updateFontScale(double value) {
    fontScaleFactor = value;
    notifyListeners();
  }

  void toggleHighContrast() {
    isHighContrast = !isHighContrast;
    notifyListeners();
  }

  // --- ELDERLY / RESIDENT STATE (RE-ADDED) ---
  User currentUser = User(
    name: 'الحاج محمود سالم',
    points: 1250,
    streakDays: 14,
    completedActivities: 42,
  );

  List<Medication> medications = [
    Medication(
        id: 'm1',
        name: 'كونكور ٥ مجم',
        dosage: 'قرص واحد',
        timeDescription: 'بعد الإفطار',
        timeOfDay: 'الصباح',
        isTaken: true,
        residentName: 'الحاج محمود سالم',
        scheduledTime: DateTime.now().subtract(const Duration(hours: 4)),
        dayTag: 'اليوم'),
    Medication(
        id: 'm2',
        name: 'أسبرين بروتكت',
        dosage: 'قرص واحد',
        timeDescription: 'بعد الغداء',
        timeOfDay: 'الظهر',
        residentName: 'الحاج محمود سالم',
        scheduledTime: DateTime.now().subtract(const Duration(minutes: 30)),
        dayTag: 'اليوم'),
    Medication(
        id: 'm_missed_1',
        name: 'أنسولين سريع المفعول',
        dosage: '١٠ وحدات',
        timeDescription: 'قبل الإفطار',
        timeOfDay: 'الصباح',
        residentName: 'الحاجة فاطمة الزهراء',
        scheduledTime: DateTime.now().subtract(const Duration(hours: 2)),
        isTaken: false,
        dayTag: 'اليوم'),
    Medication(
        id: 'm3',
        name: 'أوميجا ٣',
        dosage: 'كبسولة واحدة',
        timeDescription: 'قبل النوم',
        timeOfDay: 'المساء',
        residentName: 'الحاج محمود سالم',
        scheduledTime: DateTime.now().add(const Duration(hours: 6)),
        dayTag: 'اليوم'),
    Medication(
        id: 'm_nurse_1',
        name: 'دواء ضغط',
        dosage: 'قرص واحد',
        timeDescription: 'الساعة ٩ ص',
        timeOfDay: 'الصباح',
        residentName: 'أستاذ أحمد كمال',
        scheduledTime: DateTime.now().subtract(const Duration(hours: 1)),
        isTaken: false,
        dayTag: 'اليوم'),
  ];

  List<Medication> get missedMedications =>
      medications.where((m) => m.isMissed).toList();

  Future<void> markMedicationAsTaken(String id) async {
    final index = medications.indexWhere((m) => m.id == id);
    if (index != -1) {
      final med = medications[index];
      await _syncMedicationDose(med, 'given');
      if (backendSyncError != null && !isDemoMode) return;
      medications[index].isTaken = true;

      triggerNotification(
        title: 'تم إعطاء الدواء 💊',
        body: 'الممرض قام بإعطاء ${med.name} لـ ${med.residentName} في موعده.',
        type: 'medical',
        targetRole: 'أهل',
      );

      if (med.isMissed) {
        triggerNotification(
          title: 'معالجة تأخير دواء ⚠️',
          body: 'تم إعطاء الجرعة المتأخرة لـ ${med.residentName}.',
          type: 'admin',
          targetRole: 'مدير',
        );
      }

      notifyListeners();
    }
  }

  List<Activity> activities = [
    Activity(
        id: 'a1',
        name: 'جلسة قراءة جماعية',
        emoji: '📚',
        location: 'المكتبة',
        time: '١٠:٠٠ ص',
        status: 'done',
        badges: 'تحفيز',
        pointsReward: 20,
        dayTag: 'اليوم'),
    Activity(
        id: 'a2',
        name: 'رياضة صباحية خفيفة',
        emoji: '🧘',
        location: 'الحديقة',
        time: '٠٨:٣٠ ص',
        status: 'done',
        badges: 'نشاط',
        pointsReward: 15,
        dayTag: 'اليوم'),
    Activity(
        id: 'a3',
        name: 'مسابقة الذاكرة',
        emoji: '🧩',
        location: 'قاعة الأنشطة',
        time: '٠٤:٠٠ م',
        status: 'active',
        badges: 'تحدي',
        pointsReward: 50,
        dayTag: 'اليوم'),
    Activity(
        id: 'a4',
        name: 'اتصال فيديو مع الأسرة',
        emoji: '📱',
        location: 'غرفتي',
        time: '٠٦:٠٠ م',
        status: 'later',
        badges: 'تواصل',
        pointsReward: 10,
        dayTag: 'اليوم'),
    Activity(
        id: 'a5',
        name: 'نزهة في الحديقة',
        emoji: '🌳',
        location: 'الخارج',
        time: '٠٥:٠٠ م',
        status: 'done',
        badges: 'ترفيه',
        pointsReward: 30,
        dayTag: 'أمس'),
    Activity(
        id: 'a6',
        name: 'فحص ضغط روتيني',
        emoji: '🩺',
        location: 'العيادة',
        time: '٠٩:٠٠ ص',
        status: 'coming',
        badges: 'صحة',
        pointsReward: 5,
        dayTag: 'غداً'),
  ];

  // الحقول والدوال الجديدة لربط الأنشطة المشتركة بين المسن وعائلته
  final Map<String, bool> familyActivityParticipations = {};
  final Map<String, String> familyActivityNotes = {};

  void toggleFamilyParticipation(String activityId) {
    final current = familyActivityParticipations[activityId] ?? false;
    familyActivityParticipations[activityId] = !current;
    notifyListeners();
  }

  void updateFamilyActivityNote(String activityId, String note) {
    familyActivityNotes[activityId] = note;
    notifyListeners();
  }

  bool isFamilyParticipating(String activityId) {
    return familyActivityParticipations[activityId] ?? false;
  }

  String getFamilyActivityNote(String activityId) {
    return familyActivityNotes[activityId] ?? '';
  }

  List<FamilyMember> familyMembersList = [
    FamilyMember(
      id: 'f1',
      name: 'سارة',
      relation: 'ابنة',
      avatarPath: '',
      initials: 'س',
      phoneNumber: '01012345678',
      zoomLink: 'https://zoom.us/j/1234567890',
      isAvailable: true,
      isPinned: true,
    ),
    FamilyMember(
      id: 'f2',
      name: 'محمد',
      relation: 'ابن',
      avatarPath: '',
      initials: 'م',
      phoneNumber: '01122334455',
      zoomLink: 'https://zoom.us/j/0987654321',
      isAvailable: false,
      isPinned: true,
    ),
    FamilyMember(
      id: 'f3',
      name: 'ليلى',
      relation: 'حفيدة',
      avatarPath: '',
      initials: 'ل',
      phoneNumber: '01233445566',
      zoomLink: 'https://zoom.us/j/1122334455',
      isAvailable: true,
      isPinned: true,
    ),
    FamilyMember(
      id: 'f4',
      name: 'أحمد',
      relation: 'حفيد',
      avatarPath: '',
      initials: 'أ',
      phoneNumber: '01099887766',
      isAvailable: false,
      isPinned: false, // مثال لغير مثبت
    ),
  ];

  List<VoiceMessage> voiceMessagesList = [
    VoiceMessage(
        id: 'v1',
        senderId: 'f1',
        title: 'رسالة من سارة 💜',
        timeDescription: 'منذ ساعتين',
        isUnread: true),
    VoiceMessage(
        id: 'v2',
        senderId: 'f3',
        title: 'حكاية من ليلى 👧',
        timeDescription: 'اليوم ١٠:٠٠ ص',
        isUnread: true),
    VoiceMessage(
        id: 'v3',
        senderId: 'f2',
        title: 'أخبار من أحمد 🏠',
        timeDescription: 'أمس ٠٩:٣٠ م',
        isUnread: false),
    VoiceMessage(
        id: 'v4',
        senderId: 'f1',
        title: 'تحية صباحية ☕',
        timeDescription: 'أمس ٠٨:٠٠ ص',
        isUnread: false),
  ];

  bool isVideoCallActive = false;
  bool isIncomingCall = false;
  String? activeVideoCallId;
  String? activeVideoCallJoinUrl;
  String activeCallerName = 'سارة';
  String activeCallerInitials = 'سا';
  StreamSubscription<dynamic>? _realtimeSub;
  bool isLoadingSpecialistChat = false;

  bool isAIInsightsEnabled = true;
  bool isLoadingAiInsight = false;
  String aiInsightMode = 'backend';

  Future<void> refreshAiInsightFromBackend({String? residentId}) async {
    final resolvedResidentId = residentId ?? backendResidentId;
    if (resolvedResidentId == null || resolvedResidentId.isEmpty) {
      aiInsightMode = 'error';
      backendSyncError =
          'لا يوجد residentId من AWS لجلب توصية الذكاء الاصطناعي';
      notifyListeners();
      return;
    }
    isLoadingAiInsight = true;
    notifyListeners();
    try {
      final rec =
          await AiService.instance.getRecommendations(resolvedResidentId);
      if (aiInsights.isNotEmpty) {
        aiInsights[0] = AIInsight(
          id: aiInsights[0].id,
          residentName: aiInsights[0].residentName,
          summary: rec.summary,
          rationale: rec.rationale,
          generationDate: DateTime.tryParse(rec.generatedAt) ?? DateTime.now(),
          confidenceScore: 0.85,
        );
      } else {
        aiInsights.add(AIInsight(
          id: 'ai_${DateTime.now().millisecondsSinceEpoch}',
          residentName:
              currentUser.name.isEmpty ? resolvedResidentId : currentUser.name,
          summary: rec.summary,
          rationale: rec.rationale,
          generationDate: DateTime.tryParse(rec.generatedAt) ?? DateTime.now(),
        ));
      }
      aiInsightMode = 'bedrock';
      backendSyncError = null;
    } catch (e) {
      aiInsightMode = 'error';
      backendSyncError = e.toString();
    } finally {
      isLoadingAiInsight = false;
      notifyListeners();
    }
  }

  List<AIInsight> aiInsights = [];

  bool isAICompanionEnabled = true;
  List<CompanionMessage> companionChatHistory = [
    CompanionMessage(
      id: 'c1',
      text: 'مرحباً بك يا حاج محمود! أنا رفيقك الذكي، كيف تشعر اليوم؟ ✨',
      isFromAI: true,
      timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
    ),
  ];

  bool isEmergencyActive = false;
  bool isEmergencySyncing = false;
  String? currentEmergencyId;
  List<BackendEmergency> activeEmergencies = [];
  String currentMood = '';
  bool isReadingAudio = false;
  String readingText = '';

  List<AssetEntity> deviceGalleryImages = [];

  List<MemoryItem> memoriesList = [
    MemoryItem(
        id: 'mem1',
        category: 'أسرة',
        title: 'عيد ميلاد يحيى',
        date: '١٥ يناير ٢٠٢٤',
        type: 'image',
        assetPath: ''),
    MemoryItem(
        id: 'mem2',
        category: 'رحلات',
        title: 'رحلة الإسكندرية',
        date: '١٠ سبتمبر ٢٠٢٣',
        type: 'video',
        assetPath: ''),
    MemoryItem(
        id: 'mem3',
        category: 'مناسبات',
        title: 'حفل الزفاف',
        date: '٥ مارس ٢٠٢٤',
        type: 'image',
        assetPath: ''),
    MemoryItem(
        id: 'mem4',
        category: 'أسرة',
        title: 'الغداء الأسبوعي',
        date: '٢٠ أبريل ٢٠٢٤',
        type: 'image',
        assetPath: ''),
    MemoryItem(
        id: 'mem5',
        category: 'رحلات',
        title: 'يوم الشاطئ',
        date: '١٢ أغسطس ٢٠٢٣',
        type: 'image',
        assetPath: ''),
  ];

  // --- Albums Management ---
  List<String> customAlbums = ['أسرة', 'رحلات', 'فيديو', 'مناسبات'];
  Map<String, String> albumCovers = {}; // albumName -> assetPath or url

  List<String> get allAlbums {
    return customAlbums;
  }

  void createAlbum(String name) {
    if (!customAlbums.contains(name)) {
      customAlbums.add(name);
      notifyListeners();
    }
  }

  void renameAlbum(String oldName, String newName) {
    if (newName.trim().isEmpty || customAlbums.contains(newName)) return;
    int index = customAlbums.indexOf(oldName);
    if (index != -1) {
      customAlbums[index] = newName;
      for (var item in memoriesList) {
        if (item.category == oldName) {
          item.category = newName;
        }
      }
      if (albumCovers.containsKey(oldName)) {
        albumCovers[newName] = albumCovers.remove(oldName)!;
      }
      notifyListeners();
    }
  }

  void deleteAlbum(String name) {
    customAlbums.remove(name);
    memoriesList.removeWhere((item) => item.category == name);
    albumCovers.remove(name);
    notifyListeners();
  }

  void addPhotoToAlbum(String albumName, String photoPath, {String type = 'image'}) {
    final newItem = MemoryItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      category: albumName,
      title: 'صورة جديدة',
      date: '${DateTime.now().day} / ${DateTime.now().month} / ${DateTime.now().year}',
      type: type,
      assetPath: photoPath,
    );
    memoriesList.insert(0, newItem);
    notifyListeners();
  }

  void setAlbumCover(String albumName, String imagePath) {
    albumCovers[albumName] = imagePath;
    notifyListeners();
  }

  void deleteMemoryItem(String id) {
    memoriesList.removeWhere((item) => item.id == id);
    notifyListeners();
  }
  // --- VOLUNTEER STATE ---
  int volunteerHours = 38;
  int volunteerGoal = 50;

  VolunteerProfile volunteerProfile = VolunteerProfile(
    name: 'عمر أحمد الشريف',
    location: 'القاهرة',
    bio:
        'شاب طموح يسعى لخدمة المجتمع من خلال التطوع في رعاية كبار السن وتعليمهم التكنولوجيا.',
    skills: ['قراءة', 'ترفيه', 'تعليم رقمي', 'دعم نفسي'],
    linkedinUrl: 'https://linkedin.com/in/omar',
    facebookUrl: 'https://facebook.com/omar',
    instagramUrl: 'https://instagram.com/omar',
  );

  List<VolunteerOpportunity> volunteerOpportunities = [
    VolunteerOpportunity(
      id: 'vo1',
      title: 'جلسة قراءة قصص',
      org: 'دار المسنين - المعادي',
      hours: 2,
      points: 20,
      tags: ['قراءة', 'دعم نفسي'],
      icon: '📚',
      isNew: true,
      description:
          'نبحث عن متطوع لقراءة الروايات والقصص القصيرة للمقيمين في فترة العصر.',
      totalSlots: 4,
      filledSlots: 3,
      dateInfo: 'اليوم',
    ),
    VolunteerOpportunity(
      id: 'vo2',
      title: 'تعليم أساسيات التابلت',
      org: 'دار رعاية النيل',
      hours: 3,
      points: 30,
      tags: ['تكنولوجيا', 'تعليم'],
      icon: '💻',
      description:
          'مساعدة كبار السن في التواصل مع ذويهم عبر برامج الفيديو ومواقع التواصل.',
      totalSlots: 2,
      filledSlots: 1,
      dateInfo: 'غداً',
    ),
    VolunteerOpportunity(
      id: 'vo3',
      title: 'نشاط ترفيهي جماعي',
      org: 'دار الأمل',
      hours: 4,
      points: 40,
      tags: ['ترفيه', 'جماعي'],
      icon: '🎮',
      description:
          'تنظيم مسابقات بسيطة وألعاب ذهنية للمقيمين لإضفاء جو من البهجة.',
      totalSlots: 8,
      filledSlots: 5,
      dateInfo: 'الخميس',
    ),
  ];

  List<VolunteerBooking> volunteerBookings = [
    VolunteerBooking(
      id: 'vb1',
      title: 'جلسة دعم نفسي جماعي',
      timeInfo: '٣:٠٠ م — ٦:٠٠ م · غرفة النشاط',
      day: 10,
      month: 'أبريل',
      status: 'confirmed',
      location: 'غرفة النشاط — الطابق الأول',
      points: 30,
      isUrgent: true,
      startTime: DateTime.now().add(const Duration(hours: 26, minutes: 14)),
    ),
    VolunteerBooking(
      id: 'vb2',
      title: 'ورشة تعليم رقمي',
      timeInfo: '١٠:٠٠ ص — ١٢:٠٠ م · قاعة الكمبيوتر',
      day: 14,
      month: 'أبريل',
      status: 'confirmed',
      location: 'قاعة الكمبيوتر — الطابق الثاني',
      points: 20,
    ),
    VolunteerBooking(
      id: 'vb3',
      title: 'جلسة قراءة أسبوعية',
      timeInfo: '٤:٠٠ م — ٦:٠٠ م · ٢ ساعة',
      day: 5,
      month: 'أبريل',
      status: 'done',
      location: 'الحديقة الخارجية',
      points: 20,
      isRatingRequired: true,
    ),
  ];

  List<VolunteerCertificate> volunteerCertificates = [
    VolunteerCertificate(
      id: 'vc1',
      icon: '',
      name: 'وسام التميز',
      date: 'مارس ٢٠٢٥',
      awardTitle: 'وسام التميز الإنساني التطوعي',
      description:
          'تمنح هذه الشهادة تقديراً للتفاني الاستثنائي والمساهمة المتميزة في خدمة المجتمع وتحسين جودة حياة كبار السن.',
    ),
    VolunteerCertificate(
      id: 'vc2',
      icon: '',
      name: 'الريادة المعرفية',
      date: 'فبراير ٢٠٢٥',
      awardTitle: 'شهادة الريادة المعرفية والتمكين',
      description:
          'تقديراً للجهود المخلصة والمستمرة في إثراء الجانب المعرفي والثقافي للمقيمين من خلال المبادرات التفاعلية.',
    ),
    VolunteerCertificate(
      id: 'vc3',
      icon: '',
      name: 'الالتزام المجتمعي',
      date: 'يناير ٢٠٢٥',
      awardTitle: 'شهادة الالتزام والتميز المجتمعي',
      description: 'تقديراً للالتزام المتميز والمساهمة الفعالة في تقديم الدعم والمساندة المستمرة للمستفيدين.',
    ),
    VolunteerCertificate(
      id: 'vc4',
      icon: '',
      name: 'الوسام الذهبي',
      date: 'باقي ١٢ س',
      isLocked: true,
      progressInfo: '٧٦٪ تم الإنجاز',
      progress: 0.76,
      awardTitle: 'وسام العطاء والريادة الذهبي',
      description: 'يمنح هذا الوسام تقديراً لاستيفاء كافة معايير العطاء والتميز والريادة في العمل التطوعي الإنساني.',
    ),
    VolunteerCertificate(
      id: 'vc5',
      icon: '',
      name: 'الوسام الماسي',
      date: 'باقي ٦٢ س',
      isLocked: true,
      progressInfo: '٣٨٪ تم الإنجاز',
      progress: 0.38,
      awardTitle: 'وسام التميز والريادة الماسي',
      description: 'يمنح هذا الوسام الرفيع تقديراً للبصمة المستدامة والأثر الإنساني الاستثنائي في خدمة الفئات الأكثر احتياجاً.',
    ),
  ];

  List<VolunteerRating> volunteerRatings = [
    VolunteerRating(
      id: 'vr1',
      fromName: 'الحاج محمود صبحي',
      category: 'القراءة والتحاور',
      score: 5.0,
      comment:
          'عمر شاب مهذب جداً، وصوته هادئ ومريح أثناء القراءة. استمتعت جداً بجلستنا الأخيرة.',
      date: '٥ أبريل ٢٠٢٥',
      icon: '👴',
      chips: ['صبور', 'منظّم', 'محفّز'],
      criteriaScores: {'التعامل': 5.0, 'الالتزام': 5.0, 'جودة التحضير': 5.0},
    ),
    VolunteerRating(
      id: 'vr2',
      fromName: 'أ. سمر (منسقة الأنشطة)',
      category: 'الالتزام والتحضير',
      score: 4.5,
      comment:
          'ملتزم جداً بالمواعيد ويأتي دائماً مبتسماً. يحتاج فقط للتركيز أكثر على تنويع الكتب المختارة.',
      date: '٢ أبريل ٢٠٢٥',
      icon: '👩‍💼',
      chips: ['مبتسم', 'دقيق'],
      criteriaScores: {'التعامل': 4.7, 'الالتزام': 5.0, 'جودة التحضير': 4.0},
    ),
    VolunteerRating(
      id: 'vr3',
      fromName: 'السيدة زبيدة هانم',
      category: 'الدعم الرقمي',
      score: 5.0,
      comment:
          'بصبره وطول باله، علمني كيف أتحدث مع أحفادي عبر الفيديو. شكراً جزيلاً له.',
      date: '٣٠ مارس ٢٠٢٥',
      icon: '👵',
      chips: ['خبير تقني', 'هادئ'],
      criteriaScores: {'التعامل': 5.0, 'الالتزام': 4.8, 'المهارة': 5.0},
    ),
  ];

  List<VolunteerReview> volunteerReviews = [
    VolunteerReview(
      id: 'vw1',
      toName: 'الحاج محمود سالم',
      session: 'جلسة قراءة',
      date: 'أمس',
      score: 4.0,
      isPending: true,
      icon: 'مح',
    ),
    VolunteerReview(
      id: 'vw2',
      toName: 'الحاجة فاطمة',
      session: 'جلسة ترفيه',
      date: '٢٢ مارس',
      score: 5.0,
      isPending: false,
      icon: 'فا',
    ),
    VolunteerReview(
      id: 'vw3',
      toName: 'الحاج أحمد',
      session: 'دعم نفسي',
      date: '١٥ مارس',
      score: 5.0,
      isPending: false,
      icon: 'أح',
    ),
  ];

  // --- DYNAMIC QUESTION BANK ---
  Map<String, List<Map<String, dynamic>>> questionBank = {
    't1': [
      // Psychological (GDS-15)
      {
        'text': 'هل تشعر بالرضا عن حياتك بشكل عام؟',
        'type': 'choice',
        'options': ['نعم', 'لا']
      },
      {
        'text': 'هل تخلت عن الكثير من اهتماماتك؟',
        'type': 'choice',
        'options': ['نعم', 'لا']
      },
      {
        'text': 'هل تشعر بفرط الملل؟',
        'type': 'choice',
        'options': ['نعم', 'لا']
      },
      {
        'text': 'هل تشعر بالقلق من حدوث شيء سيء؟',
        'type': 'choice',
        'options': ['نعم', 'لا']
      },
      {
        'text': 'هل تشعر بالسعادة معظم الوقت؟',
        'type': 'choice',
        'options': ['نعم', 'لا']
      },
    ],
    't2': [
      // Social (LSNS-6)
      {
        'text': 'كم عدد الأصدقاء الذين تراهم أو تسمع منهم شهرياً؟',
        'type': 'choice',
        'options': ['٠', '١', '٢', '٣-٤', '٥-٨', '٩+']
      },
      {
        'text': 'مع كم من أصدقائك تشعر بالراحة للحديث عن أمورك الخاصة؟',
        'type': 'choice',
        'options': ['٠', '١', '٢', '٣-٤', '٥-٨', '٩+']
      },
      {
        'text':
            'كم عدد الأصدقاء الذين تشعر بقربهم بحيث يمكنك طلب المساعدة منهم؟',
        'type': 'choice',
        'options': ['٠', '١', '٢', '٣-٤', '٥-٨', '٩+']
      },
      {
        'text': 'كم عدد أفراد العائلة الذين تراهم أو تسمع منهم شهرياً؟',
        'type': 'choice',
        'options': ['٠', '١', '٢', '٣-٤', '٥-٨', '٩+']
      },
      {
        'text': 'مع كم من أفراد عائلتك تشعر بالراحة للحديث عن أمورك الخاصة؟',
        'type': 'choice',
        'options': ['٠', '١', '٢', '٣-٤', '٥-٨', '٩+']
      },
    ],
    't3': [
      // Physical (ADL)
      {
        'text': 'هل يمكنك الاستحمام بمفردك؟',
        'type': 'choice',
        'options': ['بشكل مستقل', 'بمساعدة جزئية', 'بمساعدة كاملة']
      },
      {
        'text': 'هل يمكنك ارتداء ملابسك بمفردك؟',
        'type': 'choice',
        'options': ['بشكل مستقل', 'بمساعدة جزئية', 'بمساعدة كاملة']
      },
      {
        'text': 'القدرة على الحركة والانتقال؟',
        'type': 'choice',
        'options': ['بشكل مستقل', 'بمساعدة جزئية', 'بمساعدة كاملة']
      },
    ],
    't4': [
      // Quality of Life (WHOQOL-BREF)
      {
        'text': 'كيف تقيم جودة حياتك بشكل عام؟',
        'type': 'choice',
        'options': ['ممتازة', 'جيدة', 'متوسطة', 'سيئة', 'سيئة جداً']
      },
      {
        'text': 'إلى أي مدى أنت راضٍ عن صحتك؟',
        'type': 'choice',
        'options': ['راضٍ جداً', 'راضٍ', 'محايد', 'غير راضٍ', 'غير راضٍ تماماً']
      },
      {
        'text': 'إلى أي مدى تشعر أن حياتك لها معنى؟',
        'type': 'choice',
        'options': ['بشدة', 'إلى حد ما', 'قليلاً', 'أبداً']
      },
      {
        'text': 'كيف تقيم قدرتك على أداء أنشطتك اليومية؟',
        'type': 'choice',
        'options': ['ممتازة', 'جيدة', 'متوسطة', 'سيئة', 'سيئة جداً']
      },
    ],
  };

  List<Map<String, dynamic>> getQuestionsForTool(String toolId) {
    return questionBank[toolId] ??
        [
          {
            'text': 'سؤال عام ١',
            'type': 'choice',
            'options': ['نعم', 'لا']
          },
          {'text': 'سؤال عام ٢', 'type': 'scale'},
        ];
  }

  String selectedSpecialistFilter = 'الكل';
  String residentSearchQuery = '';
  String? selectedHealthStatus;
  String? selectedRoomFilter;
  int selectedFloor = 1;

  List<SocialSpecialistAssessmentTool> socialAssessmentTools = [
    SocialSpecialistAssessmentTool(
      id: 't1',
      name: 'التقييم النفسي (GDS)',
      subtitle: 'مقياس الاكتئاب للمسنين',
      score: '٨/١٥',
      status: 'مكتمل',
      icon: '🧠',
    ),
    SocialSpecialistAssessmentTool(
      id: 't2',
      name: 'التقييم الاجتماعي',
      subtitle: 'شبكة التواصل والعلاقات',
      score: '٥/٢٠',
      status: 'يُوصى به',
      icon: '🤝',
    ),
    SocialSpecialistAssessmentTool(
      id: 't3',
      name: 'التقييم البدني (ADL)',
      subtitle: 'أنشطة الحياة اليومية',
      score: '٧٨/١٠٠',
      status: 'دوري',
      icon: '🏃',
    ),
    SocialSpecialistAssessmentTool(
      id: 't4',
      name: 'جودة الحياة',
      subtitle: 'الرضا العام والرفاهية',
      score: '٦٢/١٠٠',
      status: 'اختياري',
      icon: '❤️',
    ),
  ];

  List<SocialSpecialistNeed> socialNeeds = [
    SocialSpecialistNeed(
        id: 'n1', type: 'مالي', roomNumber: '١٠١', label: 'م', isUrgent: true),
    SocialSpecialistNeed(id: 'n2', type: 'أسري', roomNumber: '١٠٣', label: 'أ'),
    SocialSpecialistNeed(id: 'n3', type: 'نفسي', roomNumber: '١٠٤', label: 'ن'),
    SocialSpecialistNeed(id: 'n4', type: 'نفسي', roomNumber: '١٠٤', label: 'ن'),
    SocialSpecialistNeed(id: 'n5', type: 'أسري', roomNumber: '١٠٥', label: 'أ'),
    SocialSpecialistNeed(id: 'n6', type: 'نفسي', roomNumber: '١٠٦', label: 'ن'),
    SocialSpecialistNeed(id: 'n7', type: 'أسري', roomNumber: '١٠٧', label: 'أ'),
    SocialSpecialistNeed(id: 'n8', type: 'نفسي', roomNumber: '١٠٧', label: 'ن'),
    SocialSpecialistNeed(id: 'n9', type: 'طبي', roomNumber: '١٠٩', label: 'ط'),
    SocialSpecialistNeed(
        id: 'n10', type: 'نفسي', roomNumber: '١٠١', label: 'ن'),
    SocialSpecialistNeed(
        id: 'n11', type: 'نفسي', roomNumber: '١١٠', label: 'ن'),
    SocialSpecialistNeed(
        id: 'n12', type: 'أسري', roomNumber: '١٠٢', label: 'أ'),
    SocialSpecialistNeed(
        id: 'n13', type: 'مالي', roomNumber: '١٠٨', label: 'م'),
  ];

  List<SocialSpecialistResidentScore> socialResidentScores = [
    SocialSpecialistResidentScore(
      id: 'rs1',
      name: 'الحاج محمود سالم',
      initials: 'مح',
      room: '١٠٣',
      date: 'قبل ٣ أشهر',
      isUrgent: true,
      healthStatus: 'monitoring',
      lastAssessment: DateTime.now().subtract(const Duration(days: 90)),
      scores: {'نفسي': 0.45, 'اجتماعي': 0.30, 'بدني': 0.72, 'أسري': 0.55},
    ),
    SocialSpecialistResidentScore(
      id: 'rs2',
      name: 'الحاجة فاطمة الزهراء',
      initials: 'فا',
      room: '١٠٧',
      date: 'قبل أسبوع',
      isUrgent: false,
      healthStatus: 'stable',
      lastAssessment: DateTime.now().subtract(const Duration(days: 7)),
      scores: {'نفسي': 0.85, 'اجتماعي': 0.70, 'بدني': 0.62, 'أسري': 0.95},
    ),
    SocialSpecialistResidentScore(
      id: 'rs3',
      name: 'أستاذ أحمد كمال',
      initials: 'أح',
      room: '٢٠٤',
      date: 'مطلوب الآن',
      isUrgent: true,
      healthStatus: 'critical',
      lastAssessment: DateTime.now().subtract(const Duration(days: 120)),
      scores: {'نفسي': 0.25, 'اجتماعي': 0.40, 'بدني': 0.32, 'أسري': 0.15},
    ),
  ];

  List<SocialSpecialistResidentScore> get filteredResidentScores {
    return socialResidentScores.where((r) {
      final matchQuery = r.name.contains(residentSearchQuery) ||
          r.room.contains(residentSearchQuery);
      final matchStatus = selectedHealthStatus == null ||
          r.healthStatus == selectedHealthStatus;
      final matchRoom =
          selectedRoomFilter == null || r.room == selectedRoomFilter;
      return matchQuery && matchStatus && matchRoom;
    }).toList();
  }

  void setResidentSearch(String query) {
    residentSearchQuery = query;
    notifyListeners();
  }

  void setHealthFilter(String? status) {
    selectedHealthStatus = status;
    notifyListeners();
  }

  List<SocialSpecialistComplaint> socialComplaints = [
    SocialSpecialistComplaint(
      id: 'c1',
      title: 'شعور بالوحدة والعزلة الشديدة',
      residentName: 'الحاج محمود',
      room: '١٠١',
      date: 'اليوم ٩:٠٠ ص',
      priority: 'high',
      status: 'open',
      category: 'psych',
      icon: '😔',
      timeline: [
        ComplaintStep(
            text: 'تم استلام الشكوى من الممرضة',
            time: '٩:٠٠ ص',
            status: 'done'),
        ComplaintStep(
            text: 'بانتظار التحقق والمتابعة', time: 'الآن', status: 'alert'),
      ],
    ),
    SocialSpecialistComplaint(
      id: 'c2',
      title: 'اقتراح تنويع قائمة الطعام',
      residentName: 'الحاجة فاطمة',
      room: '١٠٧',
      date: 'أمس ٢:٣٠ م',
      priority: 'medium',
      status: 'progress',
      category: 'food',
      icon: '🍽️',
      timeline: [
        ComplaintStep(
            text: 'تم التحقق والتواصل مع المطبخ', time: 'أمس', status: 'done'),
        ComplaintStep(
            text: 'في انتظار موافقة الإدارة', time: 'اليوم', status: 'pending'),
      ],
      isEscalated: true,
    ),
    SocialSpecialistComplaint(
      id: 'c3',
      title: 'طلب رحلة للحديقة العامة',
      residentName: 'مجموعة مقيمين',
      room: 'عام',
      date: 'أمس ١١:٠٠ ص',
      priority: 'low',
      status: 'done',
      category: 'activity',
      icon: '🌳',
      timeline: [
        ComplaintStep(
            text: 'تمت الموافقة وتنظيم الرحلة',
            time: 'الأربعاء',
            status: 'done'),
        ComplaintStep(
            text: 'تم تنفيذ الرحلة بنجاح ✓', time: 'الخميس', status: 'done'),
      ],
    ),
    SocialSpecialistComplaint(
      id: 'c4',
      title: 'مشكلة في إضاءة الغرفة',
      residentName: 'سامي حسن',
      room: '١٠٤',
      date: 'اليوم ١٠:٠٠ ص',
      priority: 'low',
      status: 'open',
      category: 'maintenance',
      icon: '💡',
      timeline: [
        ComplaintStep(text: 'تم تسجيل الطلب', time: '١٠:٠٠ ص', status: 'done'),
      ],
    ),
  ];

  String _toArabicDigits(int value) {
    return value.toString()
        .replaceAll('0', '٠')
        .replaceAll('1', '١')
        .replaceAll('2', '٢')
        .replaceAll('3', '٣')
        .replaceAll('4', '٤')
        .replaceAll('5', '٥')
        .replaceAll('6', '٦')
        .replaceAll('7', '٧')
        .replaceAll('8', '٨')
        .replaceAll('9', '٩');
  }

  List<SocialSpecialistKPI> get socialKPIs {
    double totalSatisfaction = 0;
    int satisfactionCount = 0;
    for (var r in socialResidentScores) {
      if (r.scores.isNotEmpty) {
        double sum = 0;
        r.scores.forEach((key, value) => sum += value);
        totalSatisfaction += (sum / r.scores.length);
        satisfactionCount++;
      }
    }
    int satisfactionRate = satisfactionCount > 0 
        ? ((totalSatisfaction / satisfactionCount) * 100).toInt() 
        : 84;

    int criticalCases =
        socialResidentScores.where((r) => r.healthStatus == 'critical').length;

    int openComplaints =
        socialComplaints.where((c) => c.status == 'open').length;

    final doneActivities = activities.where((a) => a.status == 'done').length;
    final activityRate = activities.isNotEmpty
        ? ((doneActivities / activities.length) * 100).toInt()
        : 0;

    return [
      SocialSpecialistKPI(
          id: 'k1',
          label: 'معدل الرضا العام',
          value: '${_toArabicDigits(satisfactionRate)}٪',
          trend: '↑ تحسّن ٤٪',
          isPositive: true),
      SocialSpecialistKPI(
          id: 'k2',
          label: 'مشاركة الأنشطة',
          value: '٧٦٪', // هذا المؤشر نتركه ثابت مؤقتاً لعدم وجود بيانات كافية
          trend: '↑ هذا الأسبوع',
          isPositive: true),
      SocialSpecialistKPI(
          id: 'k3',
          label: 'حالات حرجة',
          value: _toArabicDigits(criticalCases),
          trend: '↑ تحتاج تدخل',
          isPositive: false),
      SocialSpecialistKPI(
          id: 'k4',
          label: 'شكاوى مفتوحة',
          value: _toArabicDigits(openComplaints),
          trend: '← نفس الأسبوع',
          isPositive: true),
    ];
  }

  int get totalResidentsCount => residentFiles.length;
  int get criticalResidentsCount =>
      residentFiles.where((f) => f.status == 'critical').length;
  int get compliancePercentage {
    if (medications.isEmpty) return 100;
    final takenCount = medications.where((m) => m.isTaken).length;
    return ((takenCount / medications.length) * 100).toInt();
  }

  int get unpaidBillsAmount {
    return familyBills
        .where((b) => !b.isPaid)
        .fold(0, (sum, b) => sum + b.amount.toInt());
  }

  int get totalOpenNeeds => socialNeeds.length;
  int get totalOpenComplaints =>
      socialComplaints.where((c) => c.status == 'open').length;
  int get totalPendingAssessments => 7;

  double get averageRating => 4.7;
  int get totalReviews => 12;
  String get topSkill => 'التعامل ⭐ ٥.٠';
  String get skillNeedsImprovement => 'التحضير ٤.٠';

  List<Medication> get todayMedications => medications;
  Medication? get nextMedication {
    try {
      return medications.firstWhere((m) => !m.isTaken);
    } catch (_) {
      return null;
    }
  }

  int get remainingSecondsToNextMed {
    final next = nextMedication;
    if (next == null || next.scheduledTime == null) return 0;
    final diff = next.scheduledTime!.difference(DateTime.now()).inSeconds;
    return diff > 0 ? diff : 0;
  }

  List<FamilyMember> get familyMembers => familyMembersList;

  Future<void> fetchFavoriteContacts() async {
    if (await FlutterContacts.requestPermission()) {
      // جلب جهات الاتصال مع الصور وأرقام الهواتف
      final contacts = await FlutterContacts.getContacts(withProperties: true);

      // جلب جهات الاتصال المفضلة (Starred) فقط
      final favorites = contacts.where((c) => c.isStarred).toList();

      // إذا لم يكن هناك مفضلين، نأخذ أول ٣ جهات اتصال كأمثلة
      final toShow =
          favorites.isNotEmpty ? favorites : contacts.take(3).toList();

      for (var contact in toShow) {
        if (contact.phones.isNotEmpty) {
          final phone = contact.phones.first.number;
          final name = contact.displayName;
          if (!familyMembersList.any((m) => m.phoneNumber == phone)) {
            String memberId = contact.id;
            if (_looksLikeBackendId(backendResidentId)) {
              final backendId =
                  await BackendMutationService.instance.createFamilyMemberFromPhone(
                residentId: backendResidentId!,
                name: name,
                phone: phone,
              );
              if (backendId != null && backendId.isNotEmpty) memberId = backendId;
            }
            familyMembersList.add(FamilyMember(
              id: memberId,
              name: name,
              relation: 'قريب',
              avatarPath: '',
              initials: name.isNotEmpty ? name.substring(0, 1) : '؟',
              phoneNumber: phone,
              isAvailable: true,
            ));
          }
        }
      }
      notifyListeners();
    }
  }

  void toggleFamilyPin(String id) {
    final idx = familyMembersList.indexWhere((m) => m.id == id);
    if (idx != -1) {
      familyMembersList[idx].isPinned = !familyMembersList[idx].isPinned;
      notifyListeners();
    }
  }

  Future<bool> pickAndAddContact() async {
    try {
      if (!await FlutterContacts.requestPermission()) return false;

      final contact = await FlutterContacts.openExternalPick();
      if (contact == null) return true;

      final fullContact = await FlutterContacts.getContact(contact.id);
      if (fullContact != null && fullContact.phones.isNotEmpty) {
        final phone = fullContact.phones.first.number;
        final name = fullContact.displayName;
        if (!familyMembersList.any((m) => m.phoneNumber == phone)) {
          String memberId = fullContact.id;
          if (_looksLikeBackendId(backendResidentId)) {
            final backendId =
                await BackendMutationService.instance.createFamilyMemberFromPhone(
              residentId: backendResidentId!,
              name: name,
              phone: phone,
            );
            if (backendId != null && backendId.isNotEmpty) memberId = backendId;
          }
          familyMembersList.add(FamilyMember(
            id: memberId,
            name: name,
            relation: 'قريب',
            avatarPath: '',
            initials: name.isNotEmpty ? name.substring(0, 1) : '؟',
            phoneNumber: phone,
            isAvailable: true,
            isPinned: true,
          ));
          notifyListeners();
        }
      }
      return true;
    } catch (e) {
      debugPrint("EXCEPTION: Error in pickAndAddContact: $e");
      return false;
    }
  }

  Future<void> callPhoneNumber(String phone) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phone,
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      debugPrint('Could not launch dialer for $phone');
    }
  }

  Future<void> launchZoom(String? link) async {
    if (link == null || link.isEmpty) return;

    final Uri url = Uri.parse(link);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      debugPrint('Could not launch Zoom link: $link');
    }
  }

  List<VoiceMessage> get voiceMessages => voiceMessagesList;
  List<MemoryItem> get memories => memoriesList;

  VolunteerImpact get volunteerImpact => VolunteerImpact(
        residentsServed: totalResidentsCount,
        positiveRatings: 18,
        totalHours: volunteerHours,
      );

  // --- DETAILED ASSESSMENT STATE ---
  List<AssessmentQuestion> gdsQuestions = [
    AssessmentQuestion(
        id: 'q1',
        text: 'هل تشعر بأساس من الرضا عن حياتك؟',
        type: 'choice',
        options: ['نعم', 'لا']),
    AssessmentQuestion(
        id: 'q2',
        text: 'هل تركت الكثير من أنشطتك واهتماماتك؟',
        type: 'choice',
        options: ['نعم', 'لا']),
    AssessmentQuestion(
        id: 'q3',
        text: 'هل تشعر أن حياتك فارغة؟',
        type: 'choice',
        options: ['نعم', 'لا']),
    AssessmentQuestion(
        id: 'q4',
        text: 'هل تشعر بالملل في كثير من الأحيان؟',
        type: 'choice',
        options: ['نعم', 'لا']),
    AssessmentQuestion(
        id: 'q5',
        text: 'هل تشعر بالروح المعنوية الجيدة في معظم الأوقات؟',
        type: 'choice',
        options: ['نعم', 'لا']),
    AssessmentQuestion(
        id: 'q6',
        text: 'هل تشعر بالقلق وأن هناك أشياء سيئة ستحدث لك؟',
        type: 'choice',
        options: ['نعم — أحياناً', 'لا — نادراً', 'أحياناً جداً']),
    AssessmentQuestion(
        id: 'q7',
        text: 'كيف تقيّم مزاجك العام خلال الأسبوع الماضي؟',
        type: 'scale'),
    AssessmentQuestion(
        id: 'q8',
        text: 'هل تشعر أنك عاجز عن مساعدة الآخرين؟ اشرح بكلماتك:',
        type: 'text'),
  ];

  List<AssessmentHistoricalEntry> assessmentHistory = [
    AssessmentHistoricalEntry(
        date: 'اليوم', score: 8, total: '15', trend: 'down'),
    AssessmentHistoricalEntry(
        date: 'يناير ٢٠٢٥', score: 9, total: '15', trend: 'down'),
    AssessmentHistoricalEntry(
        date: 'أكتوبر ٢٠٢٤', score: 11, total: '15', trend: 'stable'),
    AssessmentHistoricalEntry(
        date: 'يوليو ٢٠٢٤', score: 7, total: '15', trend: 'up'),
  ];
  Future<void> loadGdsQuestions() async {
    try {
      final raw = await SocialService.instance.getGdsQuestions();
      final loaded = raw
          .map((e) => AssessmentQuestion(
                id: (e['id'] ?? '').toString(),
                text: (e['text'] ?? '').toString(),
                type: (e['type'] ?? 'choice').toString(),
                options: (e['options'] as List?)?.map((o) => o.toString()).toList(),
              ))
          .where((q) => q.id.isNotEmpty && q.text.isNotEmpty)
          .toList();
      if (loaded.isNotEmpty) gdsQuestions = loaded;
      notifyListeners();
    } catch (e) {
      backendSyncError = e.toString();
      notifyListeners();
    }
  }

  Future<void> loadQuestionsForTool(String toolId) async {
    try {
      final raw = await SocialService.instance.getToolQuestions(toolId);
      questionBank = Map<String, List<Map<String, dynamic>>>.from(questionBank)
        ..[toolId] = raw;
      notifyListeners();
    } catch (e) {
      backendSyncError = e.toString();
      notifyListeners();
    }
  }

  void setRole(String role) {
    currentRole = role;
    notifyListeners();
  }

  void setIndex(int index) {
    selectedIndex = index;
    notifyListeners();
  }

  List<Activity> getActivitiesForDay(int index) {
    final daysMapping = ['أمس', 'اليوم', 'غداً', 'الأسبوع'];
    String tag = daysMapping[index];
    if (tag == 'الأسبوع') return activities;
    return activities.where((a) => a.dayTag == tag).toList();
  }

  void completeActivity(String id) {
    final idx = activities.indexWhere((a) => a.id == id);
    if (idx != -1) {
      activities[idx].status = 'done';
      notifyListeners();
    }
  }

  void addActivity(Activity activity) {
    activities.insert(0, activity);
    notifyListeners();
  }

  void updateStaff(StaffPerformance staff) {
    final index = staffPerformanceList.indexWhere((s) => s.id == staff.id);
    if (index != -1) {
      staffPerformanceList[index] = staff;
      notifyListeners();
    }
  }

  void deleteStaff(String id) {
    staffPerformanceList.removeWhere((s) => s.id == id);
    notifyListeners();
  }

  Future<void> pickAndSetResidentImage(String residentId) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      updateResidentImage(residentId, image.path);
    }
  }

  void updateResidentImage(String residentId, String path) {
    final index = residentFiles.indexWhere((r) => r.id == residentId);
    if (index != -1) {
      residentFiles[index] = residentFiles[index].copyWith(imageUrl: path);
      notifyListeners();
    }
  }

  Future<void> pickAndSetStaffImage(String staffId) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      updateStaffImage(staffId, image.path);
    }
  }

  void updateStaffImage(String staffId, String path) {
    final index = staffPerformanceList.indexWhere((s) => s.id == staffId);
    if (index != -1) {
      staffPerformanceList[index] =
          staffPerformanceList[index].copyWith(imageUrl: path);
      notifyListeners();
    }
  }

  void elderlyConfirmMedication(String id) {
    final idx = medications.indexWhere((m) => m.id == id);
    if (idx != -1 &&
        !medications[idx].isTaken &&
        !medications[idx].isElderlyConfirmed) {
      medications[idx].isElderlyConfirmed = true;
      medications[idx].isSkipped = false;

      // إرسال تنبيه للممرض لتأكيد الدواء
      triggerNotification(
        title: 'تأكيد دواء 💊',
        body:
            'المقيم أكد تناوله لدواء (${medications[idx].name}). يرجى التأكيد.',
        type: 'medical',
        targetRole: 'ممرض',
      );
      if (backendSyncError != null && !isDemoMode) return;
      medications[idx].isElderlyConfirmed = true;
      medications[idx].isSkipped = false;

      notifyListeners();
    }
  }

  Future<void> nurseConfirmMedication(String id) async {
    final idx = medications.indexWhere((m) => m.id == id);
    if (idx != -1 && !medications[idx].isTaken) {
      final med = medications[idx];
      await _syncMedicationDose(med, 'given');
      if (backendSyncError != null && !isDemoMode) return;
      medications[idx].isTaken = true;
      medications[idx].isElderlyConfirmed = true;
      medications[idx].isSkipped = false;
      addPoints(10);

      triggerNotification(
        title: 'إنجاز صحي جديد! 🏆',
        body:
            'والدك أتم أخذ دوائه (${medications[idx].name}) في الموعد وكسب 10 نقاط!',
        type: 'medical',
        targetRole: 'عائلة',
      );

      notifyListeners();
    }
  }

  Future<void> skipMedication(String id, String reason) async {
    final idx = medications.indexWhere((m) => m.id == id);
    if (idx != -1) {
      final med = medications[idx];
      await _syncMedicationDose(med, 'skipped', notes: reason);
      if (backendSyncError != null && !isDemoMode) return;
      medications[idx].isSkipped = true;
      medications[idx].isTaken = false;
      medications[idx].skipReason = reason;
      notifyListeners();
    }
  }

  List<Medication> getMedicationsForDay(int index) {
    final daysMapping = ['أمس', 'اليوم', 'غداً', 'الأسبوع'];
    String tag = daysMapping[index];
    if (tag == 'الأسبوع') return medications;
    return medications.where((m) => m.dayTag == tag).toList();
  }

  void addPoints(int p, {int completedActivitiesDelta = 1}) {
    final nextStreak = currentUser.streakDays == 0 ? 1 : currentUser.streakDays;
    currentUser = User(
      name: currentUser.name,
      points: currentUser.points + p,
      streakDays: nextStreak,
      completedActivities:
          currentUser.completedActivities + completedActivitiesDelta,
    );
    notifyListeners();

    if (isDemoMode || AuthService.instance.currentUser == null) return;
    unawaited(_syncUserPoints(
      p,
      completedActivitiesDelta: completedActivitiesDelta,
      streakDays: nextStreak,
    ));
  }

  Future<void> _syncUserPoints(
    int points, {
    required int completedActivitiesDelta,
    int? streakDays,
  }) async {
    try {
      final progress = await UserProgressService.instance.addPoints(
        points: points,
        completedActivitiesDelta: completedActivitiesDelta,
        streakDays: streakDays,
      );
      _applyUserProgress(progress);
      backendSyncError = null;
    } catch (e) {
      backendSyncError = e.toString();
    }
    notifyListeners();
  }

  void toggleAIInsights(bool value) {
    isAIInsightsEnabled = value;
    notifyListeners();
  }

  void toggleAICompanion(bool value) {
    isAICompanionEnabled = value;
    notifyListeners();
  }

  bool isAiThinking = false;
  String lastAiMode = 'bedrock';

  Future<void> sendCompanionMessage(String text,
      {String? mediaPath, String? mediaType}) async {
    if (text.isEmpty && mediaPath == null) return;

    // Add user message
    companionChatHistory.add(CompanionMessage(
      id: DateTime.now().toString(),
      text: text,
      isFromAI: false,
      timestamp: DateTime.now(),
      mediaPath: mediaPath,
      mediaType: mediaType,
    ));
    notifyListeners();

    try {
      AiMediaUpload? uploadedMedia;
      if (mediaPath != null && mediaPath.isNotEmpty) {
        uploadedMedia = await AiMediaService.instance.uploadFile(
          filePath: mediaPath,
          residentId: backendResidentId,
        );
      }

      final history = companionChatHistory
          .where((m) => m.text.isNotEmpty)
          .toList()
          .reversed
          .take(6)
          .toList()
          .reversed
          .map((m) => {
                'role': m.isFromAI ? 'assistant' : 'user',
                'content': m.text,
              })
          .toList();
      final effectiveMessage = text.trim().isNotEmpty
          ? text.trim()
          : uploadedMedia == null
              ? ''
              : 'تم رفع ملف للمراجعة باسم ${uploadedMedia.fileName} ونوعه ${uploadedMedia.contentType}. رجاءً أعطني ملاحظة داعمة وآمنة عنه بدون تشخيص طبي.';

      final response = await AiService.instance.sendChat(
        message: effectiveMessage,
        residentName: currentAccount?.name ?? 'صديقنا',
        residentId: backendResidentId,
        language: 'ar-eg',
        conversationHistory: history,
      );

      lastAiMode = response.mode;
      companionChatHistory.add(CompanionMessage(
        id: DateTime.now().toString(),
        text: response.reply,
        isFromAI: true,
        timestamp: DateTime.now(),
      ));
      notifyListeners();
    } catch (e) {
      backendSyncError = e.toString();
      notifyListeners();
    }
  }

  Future<void> refreshActiveEmergencies() async {
    if (isDemoMode || AuthService.instance.currentUser == null) return;
    try {
      activeEmergencies = await EmergencyService.instance.active();
      backendSyncError = null;
    } catch (e) {
      backendSyncError = e.toString();
    }
    notifyListeners();
  }

  Future<void> triggerSOS({
    String? message,
    String? type,
    String? location,
  }) async {
    final authUser = AuthService.instance.currentUser;
    final triggeredBy =
        (backendUserId?.isNotEmpty == true ? backendUserId : authUser?.userId)
                ?.trim() ??
            '';

    if (triggeredBy.isEmpty && !isDemoMode) {
      isEmergencyActive = false;
      isEmergencySyncing = false;
      backendSyncError = 'لا توجد جلسة AWS نشطة لإرسال نداء الطوارئ';
      notifyListeners();
      return;
    }

    isEmergencyActive = true;
    isEmergencySyncing = true;
    notifyListeners();

    try {
      final sos = await EmergencyService.instance.triggerSos(
        triggeredBy: triggeredBy,
        residentId:
            _looksLikeBackendId(backendResidentId) ? backendResidentId : null,
        notes: message ??
            (type == null
                ? 'تم تفعيل نداء طوارئ من التطبيق'
                : 'تم تفعيل نداء طوارئ من التطبيق: $type'),
        location: location ?? currentAccount?.room,
      );
      currentEmergencyId = sos.id;
      activeEmergencies.removeWhere((e) => e.id == sos.id);
      activeEmergencies.insert(0, sos);
      backendSyncError = null;
    } catch (e) {
      backendSyncError = e.toString();
      if (currentEmergencyId == null) {
        isEmergencyActive = false;
      }
    } finally {
      isEmergencySyncing = false;
      notifyListeners();
    }
  }

  Future<void> cancelSOS() async {
    final id = currentEmergencyId;
    if (id != null) {
      await resolveEmergency(id);
    }
    isEmergencyActive = false;
    currentEmergencyId = null;
    notifyListeners();
  }

  Future<void> resolveEmergency(String id) async {
    final synced = await _runBackendMutation(() {
      return EmergencyService.instance.resolve(id).then((_) {});
    });
  }

  void handleDeepLink(String route) {
    if (currentRole == 'مسن') {
      switch (route) {
        case 'medication':
          setElderlyTabIndex(1);
          break;
        case 'family_update':
          setElderlyTabIndex(3);
          break;
        case 'calls':
          setElderlyTabIndex(2);
          break;
        case 'activities':
          setElderlyTabIndex(4);
          break;
        default:
          setElderlyTabIndex(0);
      }
    }

    notifyListeners();
  }

  void simulateNotification(String type) {
    handleDeepLink(type);
  }

  void setMood(String mood) {
    currentMood = mood;
    addPoints(5);
    notifyListeners();
  }

  final FlutterTts _tts = FlutterTts();
  bool _ttsInitialized = false;
  final AudioPlayer _companionPlayer = AudioPlayer();
  StreamSubscription<void>? _companionPlayerCompleteSub;

  Future<void> _initTts() async {
    if (_ttsInitialized) return;

    try {
      final arEgAvailable = await _tts.isLanguageAvailable('ar-EG');
      await _tts.setLanguage(arEgAvailable == true ? 'ar-EG' : 'ar');
      await _tts.setSpeechRate(0.34);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.06);

      _tts.setCompletionHandler(() {
        isReadingAudio = false;
        notifyListeners();
      });

      _tts.setErrorHandler((msg) {
        isReadingAudio = false;
        debugPrint("TTS Error: $msg");
        notifyListeners();
      });

      _ttsInitialized = true;
    } catch (e) {
      debugPrint("TTS Initialization failed: $e");
    }
  }

  void startReading(String text) async {
    await _initTts();

    if (text.isEmpty) return;

    readingText = text;
    isReadingAudio = true;
    notifyListeners();

    try {
      await _tts.stop();
      var result = await _tts.speak(text);
      if (result == 0) {
        isReadingAudio = false;
        notifyListeners();
        debugPrint("TTS Speak failed result: 0");
      }
    } catch (e) {
      isReadingAudio = false;
      notifyListeners();
      debugPrint("TTS Speak error: $e");
    }
  }

  Future<void> startCompanionSpeech(String text) async {
    final cleanText = text.trim();
    if (cleanText.isEmpty) return;

    readingText = cleanText;
    isReadingAudio = true;
    notifyListeners();

    try {
      await _tts.stop();
      await _companionPlayer.stop();
      _companionPlayerCompleteSub ??=
          _companionPlayer.onPlayerComplete.listen((_) {
        isReadingAudio = false;
        notifyListeners();
      });

      final speech = await AiService.instance.synthesizeSpeech(text: cleanText);
      final bytes = base64Decode(speech.audioBase64);
      await _companionPlayer.play(
        BytesSource(bytes, mimeType: speech.contentType),
      );
    } catch (e) {
      isReadingAudio = false;
      backendSyncError = e.toString();
      debugPrint('AI companion speech error: $e');
      notifyListeners();
    }
  }

  final AudioPlayer _voicePlayer = AudioPlayer();
  StreamSubscription<void>? _voicePlayerCompleteSub;
  String? _playingVoiceMessageId;
  String? voiceMessageBanner;

  void clearVoiceMessageBanner() {
    if (voiceMessageBanner != null) {
      voiceMessageBanner = null;
      notifyListeners();
    }
  }

  void _stopAllVoiceMessageFlags() {
    for (final v in voiceMessagesList) {
      v.isPlaying = false;
    }
  }

  Future<void> toggleVoiceMessage(String id) async {
    final idx = voiceMessagesList.indexWhere((v) => v.id == id);
    if (idx != -1) {
      voiceMessagesList[idx].isPlaying = !voiceMessagesList[idx].isPlaying;
      if (voiceMessagesList[idx].isUnread) {
        voiceMessagesList[idx].isUnread = false;
      }
      notifyListeners();
    }
  }

  void markVoiceMessageRead(String id) {
    final idx = voiceMessagesList.indexWhere((v) => v.id == id);
    if (idx != -1) {
      voiceMessagesList[idx].isUnread = false;
      notifyListeners();
    }
  }

  void setSelectedSpecialistFilter(String filter) {
    selectedSpecialistFilter = filter;
    notifyListeners();
  }

  void setSelectedRoom(String? room) {
    selectedRoomFilter = room;
    notifyListeners();
  }

  void setSelectedFloor(int floor) {
    selectedFloor = floor;
    notifyListeners();
  }

  String selectedComplaintStatus = 'الكل';
  String complaintSearchQuery = '';

  void setSelectedComplaintStatus(String status) {
    selectedComplaintStatus = status;
    notifyListeners();
  }

  void setComplaintSearchQuery(String query) {
    complaintSearchQuery = query;
    notifyListeners();
  }

  void escalateComplaint(String id) {
    final index = socialComplaints.indexWhere((c) => c.id == id);
    if (index != -1) {
      socialComplaints[index] =
          socialComplaints[index].copyWith(isEscalated: true);
      notifyListeners();
    }
  }

  List<SocialSpecialistNeed> get filteredSocialNeeds {
    if (selectedSpecialistFilter == 'الكل') return socialNeeds;
    return socialNeeds
        .where((n) => n.type == selectedSpecialistFilter)
        .toList();
  }

  List<SocialSpecialistComplaint> get filteredSocialComplaints {
    List<SocialSpecialistComplaint> list = socialComplaints;

    if (currentRole == 'مدير') {
      list = list.where((c) => c.isEscalated).toList();
    }

    if (!selectedComplaintStatus.contains('الكل')) {
      if (selectedComplaintStatus.contains('مفتوحة')) {
        list = list.where((c) => c.status == 'open').toList();
      } else if (selectedComplaintStatus.contains('جاري')) {
        list = list.where((c) => c.status == 'progress').toList();
      } else if (selectedComplaintStatus.contains('مُغلقة')) {
        list = list.where((c) => c.status == 'done').toList();
      }
    }

    if (complaintSearchQuery.isNotEmpty) {
      list = list
          .where((c) =>
              c.title.contains(complaintSearchQuery) ||
              c.residentName.contains(complaintSearchQuery))
          .toList();
    }

    return list;
  }

  List<dynamic> getMemoriesByCategory(String category) {
    List<dynamic> results = [];

    String cleanCategory =
        category.replaceAll(RegExp(r'[^\w\s\u0600-\u06FF]'), '').trim();

    if (category == 'الكل') {
      results.addAll(memoriesList);
      results.addAll(memoryMoments);
    } else if (cleanCategory == 'أسرة') {
      results.addAll(memoriesList.where((m) => m.category == 'أسرة'));
    } else if (category == '🎬 فيديو' || cleanCategory == 'فيديو') {
      results.addAll(memoriesList.where((m) => m.type == 'video'));
    } else if (cleanCategory == 'المسكن') {
      results.addAll(memoryMoments);
    } else if (cleanCategory == 'رحلات') {
      results.addAll(memoriesList.where((m) => m.category == 'رحلات'));
    } else if (cleanCategory == 'مناسبات') {
      results.addAll(memoriesList.where((m) => m.category == 'مناسبات'));
    } else {
      results.addAll(memoriesList.where((m) => m.category == cleanCategory));
    }
    return results;
  }

  // --- FAMILY STATE ---
  List<FamilyHealthMetric> familyHealthMetrics = [
    FamilyHealthMetric(
        label: 'المزاج العام', value: 0.85, status: 'good', trend: 'up', history: [0.85, 0.80, 0.75]),
    FamilyHealthMetric(
        label: 'النشاط البدني', value: 0.60, status: 'medium', trend: 'stable', history: [0.60, 0.65, 0.50]),
    FamilyHealthMetric(
        label: 'جودة النوم', value: 0.75, status: 'good', trend: 'up', history: [0.75, 0.70, 0.80]),
    FamilyHealthMetric(
        label: 'الشهية', value: 0.45, status: 'medium', trend: 'down', history: [0.45, 0.50, 0.40]),
  ];
  
  void updateFamilyHealthMetric(String label, double value) {
    final index = familyHealthMetrics.indexWhere((m) => m.label == label);
    if (index != -1) {
      final oldVal = familyHealthMetrics[index].value;
      final history = familyHealthMetrics[index].history;
      familyHealthMetrics[index] = FamilyHealthMetric(
        label: label,
        value: value,
        status: value >= 0.7 ? 'good' : (value >= 0.5 ? 'medium' : 'low'),
        trend: value > oldVal ? 'up' : (value < oldVal ? 'down' : 'stable'),
        history: [...history, value],
      );
      notifyListeners();
    }
  }

  List<FamilyVisit> familyVisits = [
    FamilyVisit(
        id: 'v4',
        date: '٢٠ مايو',
        time: '٠٢:٠٠ م',
        visitorName: 'خالد عبد الرحمن',
        status: 'pending',
        type: 'physical'),
    FamilyVisit(
        id: 'v5',
        date: '٢٢ مايو',
        time: '٠٥:٠٠ م',
        visitorName: 'منى أحمد',
        status: 'pending',
        type: 'video'),
    FamilyVisit(
        id: 'v1',
        date: '٢٤ أبريل',
        time: '٠٤:٠٠ م',
        visitorName: 'سارة (أنا)',
        status: 'upcoming',
        type: 'physical'),
    FamilyVisit(
        id: 'v2',
        date: '١٠ أبريل',
        time: '٠٦:٣٠ م',
        visitorName: 'محمد',
        status: 'completed',
        type: 'video'),
    FamilyVisit(
        id: 'v3',
        date: '٠٢ أبريل',
        time: '١١:٠٠ ص',
        visitorName: 'سارة (أنا)',
        status: 'completed',
        type: 'physical'),
  ];

  List<FamilyBill> familyBills = [
    FamilyBill(
        id: 'b1',
        title: 'إقامة ورعاية - أبريل',
        month: 'أبريل ٢٠٢٤',
        amount: 4500,
        isPaid: false,
        dueDate: '٣٠ أبريل'),
    FamilyBill(
        id: 'b2',
        title: 'خدمات طبية إضافية',
        month: 'أبريل ٢٠٢٤',
        amount: 750,
        isPaid: false,
        dueDate: '٣٠ أبريل'),
    FamilyBill(
        id: 'b3',
        title: 'إقامة ورعاية - مارس',
        month: 'مارس ٢٠٢٤',
        amount: 4500,
        isPaid: true,
        dueDate: '٣١ مارس'),
  ];

  // --- SPECIALIST FILES STATE ---
  List<SpecialistResidentFile> residentFiles = [
    SpecialistResidentFile(
        id: 'rf1',
        name: 'الحاج محمود الجوهري',
        nameEn: 'Mahmoud El Gohary',
        room: '١٠١',
        status: 'updated',
        lastUpdate: 'اليوم ١٠:٠٠ ص',
        initials: 'مح',
        categories: ['social', 'medical'],
        age: 72,
        phone: '01012345678',
        familyMembers: [
          FamilyMember(
              id: 'f1',
              name: 'أحمد محمود',
              relation: 'ابن',
              avatarPath: '',
              initials: 'أم',
              phoneNumber: '01011112222',
              isAvailable: true),
          FamilyMember(
              id: 'f2',
              name: 'سارة محمود',
              relation: 'ابنة',
              avatarPath: '',
              initials: 'سم',
              phoneNumber: '01033334444'),
        ]),
    SpecialistResidentFile(
        id: 'rf2',
        name: 'سعدية علي كامل',
        nameEn: 'Saadia Ali Kamel',
        room: '١٠٢',
        status: 'pending',
        lastUpdate: 'أمس ٠٩:٣٠ م',
        initials: 'سع',
        categories: ['social', 'admin'],
        age: 68,
        phone: '01112223334',
        familyMembers: [
          FamilyMember(
              id: 'f3',
              name: 'منى حسن',
              relation: 'ابنة',
              avatarPath: '',
              initials: 'مح',
              phoneNumber: '01155556666'),
        ]),
    SpecialistResidentFile(
        id: 'rf3',
        name: 'إبراهيم سليمان',
        nameEn: 'Ibrahim Soliman',
        room: '١٠٣',
        status: 'updated',
        lastUpdate: '١٨ أبريل',
        initials: 'إب',
        categories: ['medical', 'psychological'],
        familyMembers: []),
    SpecialistResidentFile(
        id: 'rf4',
        name: 'سامي حسن',
        nameEn: 'Sami Hassan',
        room: '١٠٤',
        status: 'critical',
        lastUpdate: 'اليوم ٠٨:١٥ ص',
        initials: 'اس',
        categories: ['social', 'psychological'],
        familyMembers: []),
    SpecialistResidentFile(
        id: 'rf5',
        name: 'فاطمة الزهراء',
        nameEn: 'Fatma El Zahraa',
        room: '١٠٥',
        status: 'updated',
        lastUpdate: '١٥ أبريل',
        initials: 'فا',
        categories: ['admin'],
        familyMembers: []),
    SpecialistResidentFile(
        id: 'rf6',
        name: 'عمر المختار',
        nameEn: 'Omar El Mokhtar',
        room: '٢٠١',
        status: 'pending',
        lastUpdate: '١٤ أبريل',
        initials: 'عم',
        categories: ['social'],
        familyMembers: []),
  ];

  String residentFilesSearchQuery = '';
  String selectedResidentFileCategory = 'الكل';

  void setResidentFilesSearchQuery(String query) {
    residentFilesSearchQuery = query;
    notifyListeners();
  }

  void setSelectedResidentFileCategory(String category) {
    selectedResidentFileCategory = category;
    notifyListeners();
  }

  List<SpecialistResidentFile> get filteredResidentFiles {
    List<SpecialistResidentFile> filtered = residentFiles;

    if (selectedResidentFileCategory != 'الكل') {
      final catMap = {
        'اجتماعي': 'social',
        'نفسي': 'psychological',
        'طبي': 'medical',
        'إداري': 'admin',
      };
      final targetCat = catMap[selectedResidentFileCategory];
      if (targetCat != null) {
        filtered =
            filtered.where((f) => f.categories.contains(targetCat)).toList();
      }
    }

    if (residentFilesSearchQuery.isNotEmpty) {
      filtered = filtered
          .where((f) =>
              f.name.contains(residentFilesSearchQuery) ||
              f.room.contains(residentFilesSearchQuery))
          .toList();
    }

    return filtered;
  }

  // --- NURSE MEDICAL ADMIN STATE ---
  List<MedicalSession> medicalSessions = [
    MedicalSession(
        id: 's1',
        type: 'doctor',
        specialistName: 'د. خالد صفا',
        time: '١٠:٣٠ ص',
        date: 'اليوم',
        notes: 'يُنصح بالاستمرار على الخطة العلاجية الحالية.',
        residentName: 'الحاج محمود'),
    MedicalSession(
        id: 's2',
        type: 'pt',
        specialistName: 'أ. سامر (علاج طبيعي)',
        time: '١٢:٠٠ م',
        date: 'اليوم',
        notes: 'تمارين تقوية عضلات الفخذ والمشي لمدة ١٥ دقيقة.',
        residentName: 'الحاج محمود'),
    MedicalSession(
        id: 's3',
        type: 'doctor',
        specialistName: 'د. ليلى حسن (قلب)',
        time: '٠٩:٠٠ ص',
        date: 'أمس',
        notes: 'الحالة مستقرة، استكمال علاج القلب بانتظام.',
        residentName: 'فاطمة الزهراء'),
  ];

  List<MedicalPrescription> medicalPrescriptions = [
    MedicalPrescription(
        id: 'p1',
        title: 'روشتة القلب وضبط الحالة',
        doctorName: 'د. خالد صفا',
        date: '١٨ أبريل ٢٠٢٤',
        residentName: 'الحاج محمود'),
    MedicalPrescription(
        id: 'p2',
        title: 'تقرير أشعة الصدر',
        doctorName: 'مركز النيل للأشعة',
        date: '١٠ أبريل ٢٠٢٤',
        residentName: 'الحاج محمود'),
  ];

  List<Review> reviews = [];

  List<SentReport> sentReports = [
    SentReport(
        id: 'r1',
        icon: '📋',
        title: 'تقرير يومي — السبت ٥ أبريل',
        meta: 'أُرسل تلقائياً لـ ٣ جهات · ٨:٠٢ ص',
        status: 'أُرسل',
        date: '٢٠٢٦-٠٥-٠٥'),
    SentReport(
        id: 'r2',
        icon: '🚨',
        title: 'تنبيه حرج — الحاج محمود',
        meta: 'أُرسل يدوياً للطبيب · أمس ٤:١٥ م',
        status: 'أُرسل',
        date: '٢٠٢٦-٠٥-١٦'),
    SentReport(
        id: 'r3',
        icon: '📊',
        title: 'تقرير أسبوعي — أبريل',
        meta: 'مجدول للجمعة القادمة',
        status: 'مجدول',
        date: '٢٠٢٦-٠٥-٢٠'),
  ];

  void addMedication(String residentName, Medication med) {
    medications.insert(0, med);

    triggerNotification(
      title: 'تمت إضافة جرعة دواء جديدة 💊',
      body:
          'قام فريق التمريض بإضافة دواء (${med.name}) لخطة $residentName العلاجية.',
      type: 'medical',
      targetRole: 'عائلة',
    );

    notifyListeners();
  }

  void logMedicalSession(MedicalSession session) {
    medicalSessions.insert(0, session);
    notifyListeners();
  }

  void addPrescription(MedicalPrescription p) {
    medicalPrescriptions.insert(0, p);

    triggerNotification(
      title: 'روشتة طبية جديدة 📄',
      body:
          'تمت إضافة روشتة طبية جديدة لـ ${p.residentName} بواسطة ${p.doctorName}.',
      type: 'medical',
      targetRole: 'عائلة',
    );

    notifyListeners();
  }

  List<CenterOperationalStat> get adminStats {
    final occupancy = (residentFiles.length / 10.0) * 100;

    double revenueValue = residentFiles.length * 70000.0;
    if (selectedAdminDateFilter == 'اليوم') {
      revenueValue = revenueValue / 30;
    } else if (selectedAdminDateFilter == 'أسبوع') {
      revenueValue = revenueValue / 4;
    }

    final revenueStr = revenueValue.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},');

    double satisfactionValue = 4.8;
    if (volunteerRatings.isNotEmpty) {
      satisfactionValue =
          volunteerRatings.map((r) => r.score).reduce((a, b) => a + b) /
              volunteerRatings.length;
    }

    return [
      CenterOperationalStat(
          label: 'نسبة الإشغال',
          value: '${occupancy.toInt()}٪',
          trend: '↑ ٢٪ عن الشهر الماضي',
          isPositive: true,
          history: [0.8, 0.82, 0.85, 0.88, 0.9, occupancy / 100]),
      CenterOperationalStat(
          label: selectedAdminDateFilter == 'اليوم'
              ? 'إيرادات اليوم'
              : (selectedAdminDateFilter == 'أسبوع'
                  ? 'إيرادات الأسبوع'
                  : 'إيرادات الشهر'),
          value: '$revenueStr ج.م',
          trend: '↑ ٥٪ هذا الربع',
          isPositive: true,
          history: [
            (revenueValue / 1000) * 0.8,
            (revenueValue / 1000) * 0.85,
            (revenueValue / 1000) * 0.9,
            (revenueValue / 1000) * 0.95,
            (revenueValue / 1000) * 0.98,
            revenueValue / 1000
          ]),
      CenterOperationalStat(
          label: 'الحالات الحرجة',
          value: '$criticalResidentsCount',
          trend: criticalResidentsCount > 2 ? '↑ تحتاج متابعة' : '↓ مستقر وئام',
          isPositive: criticalResidentsCount <= 2,
          history: [5.0, 4.0, 3.0, criticalResidentsCount.toDouble()]),
      CenterOperationalStat(
          label: 'رضا الأهالي',
          value: '${satisfactionValue.toStringAsFixed(1)} / ٥',
          trend: '↑ مستقر عند مستوى عالٍ',
          isPositive: true,
          history: [4.5, 4.6, 4.7, satisfactionValue]),
    ];
  }

  List<StaffPerformance> staffPerformanceList = [
    StaffPerformance(
        id: 'st1',
        name: 'أ. منى (تمريض)',
        role: 'Nurse',
        completionRate: 0.98,
        lastActive: 'نشط الآن',
        status: 'online'),
    StaffPerformance(
        id: 'st2',
        name: 'أ. نور الدين',
        role: 'Specialist',
        completionRate: 0.92,
        lastActive: 'منذ ١٥ دقيقة',
        status: 'online'),
    StaffPerformance(
        id: 'st3',
        name: 'أ. سامر (علاج طبيعي)',
        role: 'PT',
        completionRate: 0.85,
        lastActive: 'منذ ٢ ساعة',
        status: 'offline'),
  ];

  int get totalStaffCount => staffPerformanceList.length;
  int get activeStaffCount =>
      staffPerformanceList.where((s) => s.status == 'online').length;
  double get averageStaffCompletion {
    if (staffPerformanceList.isEmpty) return 0.0;
    final total = staffPerformanceList
        .map((s) => s.completionRate)
        .reduce((a, b) => a + b);
    return total / staffPerformanceList.length;
  }

  void addStaff(StaffPerformance staff) {
    staffPerformanceList.insert(0, staff);

    triggerNotification(
      title: 'موظف جديد بالمنشأة 📋',
      body: 'تم تسجيل ${staff.name} ضمن الطاقم (${staff.role}).',
      type: 'admin',
      targetRole: 'مدير',
    );

    notifyListeners();
  }

  void joinOpportunity(String opportunityId) {
    final idx = volunteerOpportunities.indexWhere((o) => o.id == opportunityId);
    if (idx != -1) {
      final opp = volunteerOpportunities[idx];

      final bookingId = 'book_$opportunityId';
      if (!volunteerBookings.any((b) => b.id == bookingId)) {
        volunteerBookings.insert(
          0,
          VolunteerBooking(
            id: bookingId,
            title: opp.title,
            timeInfo: '${opp.dateInfo} · ${opp.hours} ساعة',
            day: DateTime.now().day + 1,
            month: 'أبريل',
            status: 'confirmed',
            location: opp.org,
            points: opp.points,
          ),
        );

        volunteerOpportunities[idx] = VolunteerOpportunity(
          id: opp.id,
          title: opp.title,
          org: opp.org,
          dateInfo: opp.dateInfo,
          icon: opp.icon,
          tags: opp.tags,
          hours: opp.hours,
          points: opp.points,
          isNew: opp.isNew,
          description: opp.description,
          totalSlots: opp.totalSlots,
          filledSlots: opp.filledSlots + 1,
        );

        triggerNotification(
          title: 'تم الانضمام بنجاح! 🎉',
          body: 'أنت الآن مسجل في "${opp.title}". موعدنا قادماً!',
          type: 'volunteer',
          targetRole: 'متطوع',
        );

        notifyListeners();
      }
    }
  }

  void cancelBooking(String bookingId) {
    final idx = volunteerBookings.indexWhere((b) => b.id == bookingId);
    if (idx != -1) {
      final booking = volunteerBookings[idx];
      volunteerBookings[idx] = VolunteerBooking(
        id: booking.id,
        title: booking.title,
        timeInfo: booking.timeInfo,
        day: booking.day,
        month: booking.month,
        status: 'cancelled',
        location: booking.location,
        points: booking.points,
        isUrgent: booking.isUrgent,
        startTime: booking.startTime,
        isRatingRequired: booking.isRatingRequired,
      );
      notifyListeners();
    }
  }

  void confirmAttendance(String bookingId) {
    final idx = volunteerBookings.indexWhere((b) => b.id == bookingId);
    if (idx != -1) {
      final b = volunteerBookings[idx];
      volunteerBookings[idx] = VolunteerBooking(
        id: b.id,
        title: b.title,
        timeInfo: b.timeInfo,
        day: b.day,
        month: b.month,
        status: 'done',
        location: b.location,
        points: b.points,
        isUrgent: false,
        startTime: b.startTime,
        isRatingRequired: true,
      );
      addPoints(b.points);

      triggerNotification(
        title: 'تم تأكيد الحضور! ✅',
        body:
            'شكراً لمساهمتك في "${b.title}". تم إضافة ${b.points} نقطة لحسابك.',
        type: 'volunteer',
        targetRole: 'متطوع',
      );

      notifyListeners();
    }
  }

  void submitBookingRating(String bookingId) {
    final idx = volunteerBookings.indexWhere((b) => b.id == bookingId);
    if (idx != -1) {
      final b = volunteerBookings[idx];
      volunteerBookings[idx] = VolunteerBooking(
        id: b.id,
        title: b.title,
        timeInfo: b.timeInfo,
        day: b.day,
        month: b.month,
        status: b.status,
        location: b.location,
        points: b.points,
        isUrgent: b.isUrgent,
        startTime: b.startTime,
        isRatingRequired: false,
      );
      notifyListeners();
    }
  }

  void saveMedicalVitals({
    required String residentName,
    required String bp,
    required String sugar,
    required String temp,
  }) async {
    await _syncVitals(
      residentName: residentName,
      bp: bp,
      sugar: sugar,
      temp: temp,
    );
    if (backendSyncError != null && !isDemoMode) return;

    final newSession = MedicalSession(
      id: 's${DateTime.now().millisecondsSinceEpoch}',
      type: 'vitals', // Change type to 'vitals'
      specialistName: 'الممرضة منى',
      time: 'الآن',
      date: 'اليوم',
      notes:
          'تم فحص المؤشرات الحيوية: الضغط ($bp)، السكر ($sugar مجم/دل)، الحرارة ($temp°)',
      residentName: residentName,
    );

    medicalSessions.insert(0, newSession);

    triggerNotification(
      title: 'تم حفظ القراءات 🏥',
      body: 'تم تسجيل العلامات الحيوية لـ $residentName بنجاح.',
      type: 'medical',
    );

    notifyListeners();
  }

  void addFamilyVisit(FamilyVisit visit) {
    familyVisits.insert(0, visit);
    notifyListeners();
  }

  void approveVisit(String id) {
    final idx = familyVisits.indexWhere((v) => v.id == id);
    if (idx != -1) {
      familyVisits[idx] = familyVisits[idx].copyWith(status: 'upcoming');
      notifyListeners();
    }
  }

  void rejectVisit(String id) {
    final idx = familyVisits.indexWhere((v) => v.id == id);
    if (idx != -1) {
      familyVisits[idx] = familyVisits[idx].copyWith(status: 'cancelled');
      notifyListeners();
    }
  }

  void sendFamilyMessage(String message, String residentName) {
    // LINK: Family to Specialist
    triggerNotification(
      title: 'رسالة من الأهل 📩',
      body: 'بخصوص $residentName: $message',
      type: 'complaint',
      targetRole: 'أخصائي',
    );
    notifyListeners();
  }

  void clearUnpaidBills() {
    // Mark all bills as paid for simulation
    familyBills = familyBills.map((b) => b.copyWith(isPaid: true)).toList();
    notifyListeners();
  }

  void addSocialNeed(SocialSpecialistNeed need) {
    socialNeeds.insert(0, need);

    triggerNotification(
      title: 'احتياج جديد مسجل 🛡️',
      body: 'تم تسجيل احتياج ${need.type} للغرفة ${need.roomNumber}.',
      type: 'specialist',
      targetRole: 'أخصائي',
    );

    notifyListeners();
  }

  void updateResident(SpecialistResidentFile resident) {
    final index = residentFiles.indexWhere((r) => r.id == resident.id);
    if (index != -1) {
      residentFiles[index] = resident;
      notifyListeners();
    }
  }

  void addResident(SpecialistResidentFile resident) {
    residentFiles.insert(0, resident);

    triggerNotification(
      title: 'إضافة مقيم جديد 👥',
      body: 'تم تسجيل ${resident.name} في الغرفة ${resident.room}.',
      type: 'admin',
      targetRole: 'مدير',
    );

    triggerNotification(
      title: 'مقيم جديد تحت الرعاية 🛡️',
      body: 'الحاج ${resident.name} انضم للمسكن في الغرفة ${resident.room}.',
      type: 'social',
      targetRole: 'أخصائي',
    );

    notifyListeners();
  }

  double get medicationComplianceRate {
    if (medications.isEmpty) return 1.0;
    final taken = medications.where((m) => m.isTaken).length;
    return taken / medications.length;
  }

  int get unresolvedComplaintsCount =>
      socialComplaints.where((c) => c.status != 'done').length;

  Future<void> closeComplaint(String id, String resolutionNote) async {
    final idx = socialComplaints.indexWhere((c) => c.id == id);
    if (idx != -1) {
      final c = socialComplaints[idx];
      await _syncComplaintStatus(
        id,
        'closed',
        resolutionNotes: resolutionNote,
      );
      if (backendSyncError != null && !isDemoMode) return;

      // Update status and add to timeline
      final updatedTimeline = List<ComplaintStep>.from(c.timeline);
      updatedTimeline.add(ComplaintStep(
        text: 'تم الحل: $resolutionNote',
        time: 'الآن',
        status: 'done',
      ));

      socialComplaints[idx] = SocialSpecialistComplaint(
        id: c.id,
        title: c.title,
        residentName: c.residentName,
        room: c.room,
        date: c.date,
        priority: c.priority,
        status: 'done',
        category: c.category,
        icon: c.icon,
        timeline: updatedTimeline,
      );

      triggerNotification(
        title: 'تم حل شكواكم بنجاح ✅',
        body:
            'بخصوص "${c.title}" لسرير ${c.residentName}. التفاصيل: $resolutionNote',
        type: 'social',
        targetRole: 'أهل',
      );

      notifyListeners();
    }
  }

  int totalCapacity = 50; // السعة الإجمالية للدار

  double get occupancyRate {
    if (totalCapacity == 0) return 0.0;
    return residentFiles.length / totalCapacity;
  }

  String generatePerformanceSummary() {
    final compliance = (medicationComplianceRate * 100).toInt();
    final occupancy = (occupancyRate * 100).toInt();
    return '''
ملخص أداء دار ونس للرعاية
التاريخ: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}

1. الإشغال: $occupancy%
2. الالتزام الدوائي: $compliance%
3. الشكاوى المفتوحة: $unresolvedComplaintsCount شكاوى
4. الطاقم النشط: $activeStaffCount من أصل $totalStaffCount موظف

التوصيات: 
- الحفاظ على مستوى الاستجابة السريع للشكاوى.
- تعزيز فترات الراحة للطاقم الطبي لضمان استمرارية الجودة.
''';
  }

  Future<String> exportReport(String format) async {
    // محاكاة وقت المعالجة
    await Future.delayed(const Duration(seconds: 1));

    if (format == 'pdf') {
      final pdf = pw.Document();
      final now = DateTime.now();
      final timeStr = "${now.hour}:${now.minute.toString().padLeft(2, '0')}";
      final dateStr = "${now.day}/${now.month}/${now.year}";

      final fontData = await rootBundle.load("assets/fonts/Cairo-Regular.ttf");
      final ttf = pw.Font.ttf(fontData);
      final boldFontData = await rootBundle.load("assets/fonts/Cairo-Bold.ttf");
      final ttfBold = pw.Font.ttf(boldFontData);

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          theme: pw.ThemeData.withFont(base: ttf, bold: ttfBold),
          textDirection: pw.TextDirection.rtl,
          build: (pw.Context context) {
            return [
              pw.Header(
                level: 0,
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(facilityName,
                            style: pw.TextStyle(
                                fontSize: 22,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.blue900)),
                        pw.Text('تقرير الأداء الإداري والتشغيلي',
                            style: const pw.TextStyle(
                                fontSize: 12, color: PdfColors.grey700)),
                      ],
                    ),
                    pw.PdfLogo(),
                  ],
                ),
              ),
              pw.SizedBox(height: 25),

              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                child: pw.Column(
                  children: [
                    _pdfInfoRow('اسم الدار:', facilityName),
                    _pdfInfoRow('اسم المدير المسئول:', managerName),
                    _pdfInfoRow('تاريخ التقرير:', dateStr),
                    _pdfInfoRow('وقت الاستخراج:', timeStr),
                  ],
                ),
              ),

              pw.SizedBox(height: 30),
              pw.Text('ملخص مؤشرات الأداء:',
                  style: pw.TextStyle(
                      fontSize: 16, fontWeight: pw.FontWeight.bold)),
              pw.Divider(thickness: 1.5, color: PdfColors.blue100),
              pw.SizedBox(height: 15),

              pw.TableHelper.fromTextArray(
                context: context,
                headerStyle: pw.TextStyle(
                    color: PdfColors.white, fontWeight: pw.FontWeight.bold),
                headerDecoration:
                    const pw.BoxDecoration(color: PdfColors.blue800),
                cellAlignment: pw.Alignment.centerRight,
                data: <List<String>>[
                  <String>['المؤشر الإحصائي', 'القيمة'],
                  <String>[
                    'نسبة إشغال الأسرة',
                    '${(occupancyRate * 100).toInt()}%'
                  ],
                  <String>[
                    'معدل الالتزام الدوائي',
                    '${(medicationComplianceRate * 100).toInt()}%'
                  ],
                  <String>[
                    'عدد الشكاوى قيد المعالجة',
                    unresolvedComplaintsCount.toString()
                  ],
                  <String>['عدد الموظفين المتواجدين', '$activeStaffCount موظف'],
                ],
              ),
              pw.SizedBox(height: 40),
              pw.Text('التوصيات والإجراءات المطلوبة:',
                  style: pw.TextStyle(
                      fontSize: 15, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              _pdfBullet(ttf, 'ضرورة متابعة تحديث بيانات المقيمين الجدد.'),
              _pdfBullet(ttf, 'التأكد من جاهزية مخزون الأدوية للأسبوع القادم.'),
              _pdfBullet(ttf,
                  'مراجعة ملاحظات الأخصائي الاجتماعي بخصوص الحالات الحرجة.'),

              pw.Spacer(),

              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.start,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Text('يعتمد من مدير المنشأة',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.SizedBox(height: 10),
                      pw.Text(managerName),
                      pw.SizedBox(height: 30),
                      pw.Container(
                        width: 150,
                        decoration: const pw.BoxDecoration(
                          border: pw.Border(
                              bottom: pw.BorderSide(
                                  width: 1, style: pw.BorderStyle.dashed)),
                        ),
                      ),
                      pw.SizedBox(height: 5),
                      pw.Text('التوقيع والختم الرسمي',
                          style: const pw.TextStyle(
                              fontSize: 10, color: PdfColors.grey)),
                    ],
                  ),
                ],
              ),
            ];
          },
        ),
      );

      await Printing.sharePdf(
          bytes: await pdf.save(), filename: 'Taptaba_Report.pdf');
    } else if (format == 'csv' || format == 'excel') {
      final csvBuffer = StringBuffer();
      csvBuffer.write('\uFEFF');
      csvBuffer.writeln('تقرير أداء المنشأة: $facilityName');
      csvBuffer.writeln('المدير المسئول: $managerName');
      csvBuffer.writeln(
          'التاريخ: ${DateTime.now().toLocal().toString().split(' ')[0]}');
      csvBuffer.writeln('');
      csvBuffer.writeln('المؤشر الإحصائي,القيمة');
      csvBuffer.writeln('نسبة الإشغال,${(occupancyRate * 100).toInt()}%');
      csvBuffer.writeln(
          'الالتزام الدوائي,${(medicationComplianceRate * 100).toInt()}%');
      csvBuffer.writeln('الشكاوى المفتوحة,$unresolvedComplaintsCount');
      csvBuffer.writeln('الطاقم النشط,$activeStaffCount');

      // محاكاة حفظ الملف وتصديره
      final encodedCsv = Uri.encodeComponent(csvBuffer.toString());
      final url = 'data:text/csv;charset=utf-8,$encodedCsv';

      try {
        final uri = Uri.parse(url);
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      } catch (e) {
        // إذا فشل كل شيء، ننتظر قليلاً لمحاكاة العملية
        await Future.delayed(const Duration(seconds: 1));
      }
    }

    final dateStrFile =
        "${DateTime.now().year}-${DateTime.now().month}-${DateTime.now().day}";
    final fileName = "Taptaba_Report_$dateStrFile.$format";
    return fileName;
  }

  pw.Widget _pdfInfoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        children: [
          pw.Text(label,
              style:
                  pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
          pw.SizedBox(width: 5),
          pw.Text(value, style: const pw.TextStyle(fontSize: 10)),
        ],
      ),
    );
  }

  // --- MEMORY WALL ---

  List<MemoryMoment> memoryMoments = [
    MemoryMoment(
      id: 'm1',
      residentId: 'r1',
      residentName: 'الحاج محمود',
      imageUrl:
          'https://images.unsplash.com/photo-1544367567-0f2fcb009e0b?auto=format&fit=crop&q=80&w=400',
      activityTitle: 'جلسة اليوغا الصباحية 🧘',
      date: 'منذ ساعتين',
      appreciations: 3,
    ),
    MemoryMoment(
      id: 'm2',
      residentId: 'r1',
      residentName: 'الحاج محمود',
      imageUrl:
          'https://images.unsplash.com/photo-1595113316349-9fa4eb24f884?auto=format&fit=crop&q=80&w=400',
      activityTitle: 'ورشة الفخار اليدوي 🏺',
      date: 'أمس',
      appreciations: 5,
    ),
  ];

  void addMemoryMoment(MemoryMoment moment) {
    memoryMoments.insert(0, moment);

    triggerNotification(
      title: 'لحظة سعادة جديدة 📸',
      body:
          'والدكم ${moment.residentName} يستمتع بوقته الآن في "${moment.activityTitle}".',
      type: 'social',
      targetRole: 'أهل',
    );

    final newItem = MemoryItem(
      id: 'mem_custom_${DateTime.now().millisecondsSinceEpoch}',
      category: 'أسرة',
      title: moment.activityTitle,
      date: 'اليوم',
      type: 'image',
      assetPath: moment.imageUrl,
    );
    memoriesList.insert(0, newItem);

    notifyListeners();
  }

  void deleteMemoryMoment(String id) {
    memoryMoments.removeWhere((m) => m.id == id);
    notifyListeners();
  }

  void addAppreciation(String momentId) {
    final idx = memoryMoments.indexWhere((m) => m.id == momentId);
    if (idx != -1) {
      final m = memoryMoments[idx];
      memoryMoments[idx] = MemoryMoment(
        id: m.id,
        residentId: m.residentId,
        residentName: m.residentName,
        imageUrl: m.imageUrl,
        activityTitle: m.activityTitle,
        date: m.date,
        appreciations: m.appreciations + 1,
      );

      triggerNotification(
        title: 'عائلة ${m.residentName} سعيدة! ❤️',
        body:
            'تم استلام "شكراً" من عائلة المقيم بخصوص صورة "${m.activityTitle}".',
        type: 'social',
        targetRole: 'أخصائي',
      );

      notifyListeners();
    }
  }

  int currentElderlyTabIndex = 0;
  void setElderlyTabIndex(int index) {
    currentElderlyTabIndex = index;
    notifyListeners();
  }

  MemoryMoment? get latestMemoryMoment =>
      memoryMoments.isNotEmpty ? memoryMoments.first : null;

  bool hasGalleryPermission = false;

  Future<void> requestGalleryPermission() async {
    final PermissionState ps = await PhotoManager.requestPermissionExtend();
    hasGalleryPermission = ps.isAuth;
    if (hasGalleryPermission) {
      List<AssetPathEntity> albums =
          await PhotoManager.getAssetPathList(type: RequestType.image);
      if (albums.isNotEmpty) {
        List<AssetEntity> photos =
            await albums[0].getAssetListPaged(page: 0, size: 50);
        deviceGalleryImages = photos;
      }
    }
    notifyListeners();
  }

  void setGalleryPermission(bool val) {
    hasGalleryPermission = val;
    notifyListeners();
  }

  Future<void> updateVolunteerProfile(VolunteerProfile newProfile) async {
    final synced = await _runBackendMutation(() {
      return BackendMutationService.instance.updateVolunteerProfile(newProfile);
    });
    if (!synced) return;
    volunteerProfile = newProfile;
    notifyListeners();
  }

  void addVolunteerSkill(String skill) {
    if (!volunteerProfile.skills.contains(skill)) {
      final updatedSkills = List<String>.from(volunteerProfile.skills)
        ..add(skill);
      volunteerProfile = volunteerProfile.copyWith(skills: updatedSkills);
      notifyListeners();
    }
  }

  void removeVolunteerSkill(String skill) {
    final updatedSkills = List<String>.from(volunteerProfile.skills)
      ..remove(skill);
    volunteerProfile = volunteerProfile.copyWith(skills: updatedSkills);
    notifyListeners();
  }

  void uploadVolunteerDocument(String type, String fileName) {
    if (type == 'cv') {
      volunteerProfile = volunteerProfile.copyWith(cvFileName: fileName);
    } else if (type == 'recommendation') {
      volunteerProfile =
          volunteerProfile.copyWith(recommendationFileName: fileName);
    }

    triggerNotification(
      title: 'تم رفع الملف بنجاح 📁',
      body: 'تم تسجيل ملف "$fileName" كـ $type في ملفك الشخصي.',
      type: 'admin',
      targetRole: 'متطوع',
    );

    notifyListeners();
  }

  Future<void> startVideoCall(
    String name,
    String initials, {
    String? calleeId,
    String? residentId,
    String? joinUrl,
  }) async {
    activeCallerName = name;
    activeCallerInitials = initials;
    isVideoCallActive = true;
    isIncomingCall = false;
    notifyListeners();

    if (isDemoMode || AuthService.instance.currentUser == null) {
      if ((joinUrl ?? '').isNotEmpty) await launchZoom(joinUrl);
      return;
    }
    try {
      final call = await VideoCallService.instance.start(
        residentId: residentId,
        calleeId: calleeId,
        calleeName: name,
        provider: 'zoom',
        joinUrl: joinUrl,
      );
      activeVideoCallId = call.id;
      activeVideoCallJoinUrl = call.joinUrl;
      backendSyncError = null;
      if ((call.joinUrl ?? '').isNotEmpty) {
        await launchZoom(call.joinUrl);
      }
    } catch (e) {
      backendSyncError = e.toString();
    }
    notifyListeners();
  }

  void acceptCall() {
    isVideoCallActive = true;
    isIncomingCall = false;
    notifyListeners();
  }

  void rejectCall() {
    isIncomingCall = false;
    notifyListeners();
  }

  void endVideoCall() {
    isVideoCallActive = false;
    notifyListeners();
  }

  Future<void> _updateActiveVideoCallStatus(String id, String status) async {
    if (isDemoMode || AuthService.instance.currentUser == null) return;
    try {
      await VideoCallService.instance.updateStatus(id, status);
      backendSyncError = null;
    } catch (e) {
      backendSyncError = e.toString();
    }
    notifyListeners();
  }

  Future<void> sendVoiceMessageFromResident(
    String title, {
    String? audioPath,
    int durationSeconds = 0,
  }) async {
    final residentId = _looksLikeBackendId(backendResidentId)
        ? backendResidentId
        : residentFiles.isNotEmpty
            ? residentFiles.first.id
            : null;
    if (residentId == null) {
      backendSyncError = 'لا يوجد residentId من AWS لإرسال الرسالة الصوتية';
      notifyListeners();
      return;
    }
    try {
      await VoiceMessageService.instance.create(
        residentId: residentId,
        title: title,
        senderType: 'resident',
        filePath: audioPath,
        durationSeconds: durationSeconds,
      );
      backendSyncError = null;
    } catch (e) {
      backendSyncError = e.toString();
      notifyListeners();
      return;
    }
    final newMsg = VoiceMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      senderId: 'resident', // Special ID for the resident themselves
      title: title,
      timeDescription: 'الآن',
    );
    voiceMessagesList.insert(0, newMsg);

    // Add points for communicating!
    addPoints(15);

    triggerNotification(
      title: 'تم إرسال الرسالة! 🎙️',
      body: 'رسالتك الصوتية في طريقها لعائلتك الآن.',
      type: 'social',
      targetRole: 'مسن',
    );

    notifyListeners();
  }

  // --- NURSING OPERATIONS STATE ---
  List<CareTask> careTasks = [
    CareTask(
        id: 'c1',
        residentName: 'الحاج محمود سالم',
        title: 'تغيير ملابس الصباح',
        category: 'شخصية',
        time: '٠٧:٠٠ ص'),
    CareTask(
        id: 'c2',
        residentName: 'الحاج محمود سالم',
        title: 'رياضة تنفس خفيفة',
        category: 'ترفيهية',
        time: '٠٩:٠٠ ص'),
    CareTask(
        id: 'c3',
        residentName: 'الحاجة فاطمة علي',
        title: 'استحمام دوري',
        category: 'فندقية',
        time: '٠٨:٣٠ ص'),
    CareTask(
        id: 'c4',
        residentName: 'الحاجة فاطمة علي',
        title: 'تمارين حركة للأطراف',
        category: 'شخصية',
        time: '١٠:٠٠ ص'),
  ];

  List<InventoryItem> inventoryItems = [
    InventoryItem(
        id: 'i1',
        name: 'أسبوسيد ٧٥ مجم',
        category: 'أدوية',
        currentStock: 12,
        minRequired: 20,
        unit: 'شريط'),
    InventoryItem(
        id: 'i2',
        name: 'حفاضات كبار (L)',
        category: 'شخصي',
        currentStock: 45,
        minRequired: 30,
        unit: 'عبوة'),
    InventoryItem(
        id: 'i3',
        name: 'شاش معقم',
        category: 'مستلزمات',
        currentStock: 5,
        minRequired: 15,
        unit: 'علبة'),
    InventoryItem(
        id: 'i4',
        name: 'كونكور ٥ مجم',
        category: 'أدوية',
        currentStock: 25,
        minRequired: 10,
        unit: 'شريط'),
  ];

  List<DoctorVisit> doctorVisits = [
    DoctorVisit(
        id: 'v1',
        doctorName: 'د. يحيى الفخراني',
        specialty: 'باطنة وقلب',
        date: DateTime.now().subtract(const Duration(days: 2)),
        purpose: 'متابعة ضغط دورية',
        results: 'استقرار الحالة مع تعديل بسيط في جرعة الصباح',
        residentName: 'الحاج محمود سالم'),
    DoctorVisit(
        id: 'v2',
        doctorName: 'د. سميحة أيوب',
        specialty: 'عظام ومفاصل',
        date: DateTime.now().add(const Duration(days: 1)),
        purpose: 'فحص آلام الركبة',
        residentName: 'الحاجة فاطمة علي'),
  ];

  List<MealPlan> mealPlans = [
    MealPlan(
        residentName: 'الحاج محمود سالم',
        breakfast: 'فول بالزيت الحار، بيض مسلوق',
        lunch: 'فراخ مشوية، خضار سوتيه، أرز بني',
        dinner: 'زبادي بالعسل، ثمرة فاكهة',
        specialInstructions: 'قليل الملح جداً، منع السكريات'),
    MealPlan(
        residentName: 'الحاجة فاطمة علي',
        breakfast: 'جبنة قريش، توست سن',
        lunch: 'سمك مشوي، سلطة خضراء',
        dinner: 'شوربة خضار دافئة',
        specialInstructions: 'تقطيع الطعام قطع صغيرة جداً لتسهيل البلع'),
  ];

  List<ActivitySession> activitySessions = [
    ActivitySession(
        id: 's1',
        title: 'حلقة قراءة الصالون',
        description: 'قراءة مقتطفات من الأدب العربي ومناقشتها',
        startTime: DateTime.now().add(const Duration(hours: 2)),
        location: 'القاعة الرئيسية',
        participants: ['الحاج محمود', 'الحاجة فاطمة']),
    ActivitySession(
        id: 's2',
        title: 'عرض سينمائي كلاسيكي',
        description: 'فيلم "غزل البنات" - نجيب الريحاني',
        startTime: DateTime.now().add(const Duration(hours: 6)),
        location: 'غرفة العرض',
        participants: ['جميع المقيمين']),
  ];

  // Nursing Operations Methods
  void toggleCareTask(String id) {
    final idx = careTasks.indexWhere((t) => t.id == id);
    if (idx != -1) {
      careTasks[idx].isCompleted = !careTasks[idx].isCompleted;
      notifyListeners();
    }
  }

  void addCareTask(CareTask task) {
    careTasks.add(task);
    notifyListeners();
  }

  void deleteCareTask(String id) {
    careTasks.removeWhere((t) => t.id == id);
    notifyListeners();
  }

  void addInventoryItem(InventoryItem item) {
    inventoryItems.add(item);
    notifyListeners();
  }

  void deleteInventoryItem(String id) {
    inventoryItems.removeWhere((i) => i.id == id);
    notifyListeners();
  }

  void addDoctorVisit(DoctorVisit visit) {
    doctorVisits.add(visit);
    notifyListeners();
  }

  void deleteDoctorVisit(String id) {
    doctorVisits.removeWhere((v) => v.id == id);
    notifyListeners();
  }

  void addMealPlan(MealPlan plan) {
    mealPlans.add(plan);
    notifyListeners();
  }

  void deleteMealPlan(String residentName) {
    mealPlans.removeWhere((p) => p.residentName == residentName);
    notifyListeners();
  }

  void addActivitySession(ActivitySession session) {
    activitySessions.add(session);
    notifyListeners();
  }

  void deleteActivitySession(String id) {
    activitySessions.removeWhere((s) => s.id == id);
    notifyListeners();
  }

  void deleteMedicalSession(String id) {
    medicalSessions.removeWhere((s) => s.id == id);
    notifyListeners();
  }

  void deletePrescription(String id) {
    medicalPrescriptions.removeWhere((p) => p.id == id);
    notifyListeners();
  }

  void addSentReport(SentReport report) {
    sentReports.insert(0, report);
    notifyListeners();
  }

  void addReview(Review review) {
    reviews.insert(0, review);
    notifyListeners();
  }

  void addHandoff(ShiftHandoff handoff) {
    handoffs.insert(0, handoff);
    notifyListeners();
  }

  void updateInventoryStock(String id, int change) {
    final idx = inventoryItems.indexWhere((i) => i.id == id);
    if (idx != -1) {
      final newItem = InventoryItem(
        id: inventoryItems[idx].id,
        name: inventoryItems[idx].name,
        category: inventoryItems[idx].category,
        currentStock: inventoryItems[idx].currentStock + change,
        minRequired: inventoryItems[idx].minRequired,
        unit: inventoryItems[idx].unit,
      );
      inventoryItems[idx] = newItem;
      notifyListeners();
    }
  }

  void updateMealPlan(MealPlan plan) {
    final idx =
        mealPlans.indexWhere((p) => p.residentName == plan.residentName);
    if (idx != -1) {
      mealPlans[idx] = plan;
      notifyListeners();
    } else {
      mealPlans.add(plan);
    }
  }

  // بدء عملية التدخل الاجتماعي وتغيير حالة الشكوى
  void startIntervention(String id) {
    final idx = socialComplaints.indexWhere((c) => c.id == id);
    if (idx != -1) {
      final updatedTimeline =
          List<ComplaintStep>.from(socialComplaints[idx].timeline);
      updatedTimeline.add(ComplaintStep(
        text: 'بدء التدخل والمتابعة',
        time: 'الآن',
        status: 'progress',
      ));

      socialComplaints[idx] = SocialSpecialistComplaint(
        id: socialComplaints[idx].id,
        title: socialComplaints[idx].title,
        residentName: socialComplaints[idx].residentName,
        room: socialComplaints[idx].room,
        date: socialComplaints[idx].date,
        priority: socialComplaints[idx].priority,
        status: 'progress',
        category: socialComplaints[idx].category,
        icon: socialComplaints[idx].icon,
        timeline: updatedTimeline,
      );

      notifyListeners();
    }
  }

  // حفظ تقييم اجتماعي جديد وتحديث درجات المقيم
  void saveSocialAssessment({
    required String residentId,
    required Map<String, double> newScores,
    required bool needsIntervention,
    String? notes,
  }) {
    final idx = filteredResidentScores.indexWhere((r) => r.id == residentId);
    if (idx != -1) {
      final r = filteredResidentScores[idx];

      // Update scores
      final updatedScores = Map<String, double>.from(r.scores);
      newScores.forEach((key, value) {
        updatedScores[key] = value;
      });

      filteredResidentScores[idx] = SocialSpecialistResidentScore(
        id: r.id,
        name: r.name,
        room: r.room,
        date: 'الآن',
        isUrgent: needsIntervention,
        scores: updatedScores,
        initials: r.initials,
        healthStatus: r.healthStatus,
        lastAssessment: DateTime.now(),
      );

      // Add a social notification if urgent
      if (needsIntervention) {
        notifications.insert(
            0,
            TaptabaNotification(
              id: 'soc_${DateTime.now().millisecondsSinceEpoch}',
              title: 'تنبيه تدخل اجتماعي: ${r.name}',
              body: 'المقيم بحاجة لمتابعة عاجلة بناءً على التقييم الأخير.',
              time: 'الآن',
              type: 'social',
              targetRole: 'specialist',
              residentId: residentId,
              isRead: false,
            ));
      }

      notifyListeners();
    }
  }

  // خريطة الاحتياجات: تجميع بيانات المقيمين مع حساب لون الحالة بصرياً
  List<Map<String, dynamic>> get needMapData {
    return filteredResidentScores.map((r) {
      // Calculate overall social health
      double avgScore = 0;
      if (r.scores.isNotEmpty) {
        avgScore = r.scores.values.reduce((a, b) => a + b) / r.scores.length;
      }

      Color statusColor;
      if (r.isUrgent || avgScore < 0.4) {
        statusColor = const Color(0xFFef4444); // High Need
      } else if (avgScore < 0.7) {
        statusColor = const Color(0xFFf59e0b); // Medium Need
      } else {
        statusColor = const Color(0xFF10b981); // Stable
      }

      return {
        'id': r.id,
        'name': r.name,
        'room': r.room,
        'color': statusColor,
        'score': avgScore,
        'initials': r.initials,
      };
    }).toList();
  }

  // وضع علامة "تم الحل" على التنبيهات الإدارية
  void resolveNotification(String id) {
    final idx = notifications.indexWhere((n) => n.id == id);
    if (idx != -1) {
      notifications[idx].isRead = true;
      notifyListeners();
    }
  }

  // --- MEMORIES METHODS ---
  Future<void> fetchGalleryImages() async {
    try {
      final PermissionState ps = await PhotoManager.requestPermissionExtend();
      if (ps.isAuth || ps.hasAccess) {
        final List<AssetPathEntity> paths = await PhotoManager.getAssetPathList(
          type: RequestType.image,
        );
        if (paths.isNotEmpty) {
          final List<AssetEntity> entities =
              await paths[0].getAssetListRange(start: 0, end: 50);
          deviceGalleryImages = entities;
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('Error fetching gallery: $e');
    }
  }

  Future<void> pickMemoryImage() async {
    try {
      // استخدام ImagePicker مباشرة فهو يتعامل مع الصلاحيات بشكل أفضل في النسخ الحديثة
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (image != null) {
        final newItem = MemoryItem(
          id: 'mem_custom_${DateTime.now().millisecondsSinceEpoch}',
          category: 'الاستوديو',
          title: 'ذكرى من الاستوديو',
          date: 'اليوم',
          type: 'image',
          assetPath: image.path,
        );

        memoriesList.insert(0, newItem);
        notifyListeners();

        triggerNotification(
          title: 'تمت إضافة ذكرى جديدة! 📸',
          body: 'ستجدها الآن في صندوق ذكرياتك الجميل.',
          type: 'social',
          targetRole: 'مسن',
        );
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  // --- INTEGRATION & CROSS-ROLE REQUESTS ---

  void submitComplaint(String message, String type, String fromRole) {
    // محاكاة إرسال شكوى/طلب إلى الأخصائي الاجتماعي أو الإدارة
    // في الواقع سيتم رفعها للـ Backend وإنشاء Object من نوع Complaint
    final complaint = SocialSpecialistComplaint(
      id: 'comp_${DateTime.now().millisecondsSinceEpoch}',
      residentName: fromRole == 'مسن' ? currentUser.name : 'أحد أفراد الأسرة',
      room: '١١٢', // محاكاة لغرفة المسن
      date: 'اليوم',
      title: type,
      category: 'عام',
      icon: '🚨',
      status: 'open',
      priority: 'high',
      timeline: [ComplaintStep(text: message, time: 'الآن', status: 'pending')],
    );
    socialComplaints.insert(0, complaint);

    // إرسال إشعار تأكيد للمرسل
    triggerNotification(
      title: 'تم إرسال طلبك بنجاح ✅',
      body: 'قام فريقنا باستلام طلبك بخصوص "$type" وسيتم التعامل معه فوراً.',
      type: 'system',
      targetRole: fromRole,
    );
    notifyListeners();
  }

  void requestConsultation(String type) {
    // محاكاة طلب استشارة من الأسرة للطبيب أو الأخصائي
    triggerNotification(
      title: 'طلب استشارة مرسل 💬',
      body:
          'تم تحويل طلب الاستشارة الـ $type إلى الفريق المختص، سيتم التواصل معك قريباً.',
      type: 'medical',
      targetRole: 'أسرة',
    );
    notifyListeners();
  }

  void addVolunteerOpportunity(VolunteerOpportunity opp) {
    // إضافة الفرصة إلى قائمة الفرص التطوعية لتظهر فوراً للمتطوعين
    volunteerOpportunities.insert(0, opp);

    // إشعار الإدارة بنجاح الإنشاء
    triggerNotification(
      title: 'تم نشر الفرصة بنجاح 🌟',
      body: 'أصبحت فرصة "${opp.title}" متاحة الآن للمتطوعين.',
      type: 'system',
      targetRole: 'إدارة',
    );

    notifyListeners();
  }

  void updateVolunteerOpportunity(VolunteerOpportunity opp) {
    final index = volunteerOpportunities.indexWhere((o) => o.id == opp.id);
    if (index != -1) {
      volunteerOpportunities[index] = opp;
      notifyListeners();
    }
  }

  void rateVolunteerSession(String volunteerId, int ratingScore, {String comment = ''}) {
    // تقييم المتطوع من قِبل المسن (ratingScore: 1 لغير سعيد، 2 لعادي، 3 لسعيد)
    int pointsEarned = 0;
    if (ratingScore == 3) {
      pointsEarned = 15;
    } else if (ratingScore == 2) pointsEarned = 5;

    // إضافة التقييم لقائمة التقييمات العامة لربطها بشاشة المتطوع
    final review = Review(
      id: 'rev_${DateTime.now().millisecondsSinceEpoch}',
      fromRole: 'elderly',
      fromName: currentUser.name,
      toRole: 'volunteer',
      rating: ratingScore.toDouble(),
      comment: comment,
      date: DateTime.now().toString(),
    );
    reviews.insert(0, review);

    // إشعار للمسن بشكره على التقييم
    triggerNotification(
      title: 'شكراً لتقييمك! 💖',
      body: 'رأيك يهمنا جداً في تحسين جودة الرعاية المقدمة لك.',
      type: 'system',
      targetRole: 'مسن',
    );

    notifyListeners();
  }

  void sendEncouragementMessage(String messageType, {String? text}) {
    String title = messageType == 'voice' ? 'رسالة صوتية جديدة 🎤' : 'رسالة من العائلة ✉️';
    String body = messageType == 'voice'
        ? 'عائلتك أرسلت لك رسالة صوتية تشجيعية لسماعها!'
        : (text ?? 'عائلتك أرسلت لك رسالة تشجيعية!');

    triggerNotification(
      title: title,
      body: body,
      type: 'family',
      targetRole: 'مسن',
    );

    // إضافة الذكرى لشاشة الذكريات
    final newItem = MemoryItem(
      id: 'mem_custom_${DateTime.now().millisecondsSinceEpoch}',
      category: 'أسرة',
      title: title,
      date: 'اليوم',
      type: messageType == 'voice' ? 'voice' : 'text',
      assetPath: '',
      content: body,
    );

    memoriesList.insert(0, newItem);

    if (messageType == 'voice') {
      voiceMessagesList.insert(
        0,
        VoiceMessage(
          id: 'v_custom_${DateTime.now().millisecondsSinceEpoch}',
          senderId: 'family',
          title: 'رسالة صوتية من العائلة ❤️',
          timeDescription: 'اليوم',
          isUnread: true,
        ),
      );
    }
    notifyListeners();
  }

  void sendMedicationReminder(String medName) {
    String title = 'تذكير بموعد الدواء 💊';
    String body = 'عائلتك تذكرك بموعد أخذ $medName. نتمنى لك دوام الصحة والعافية!';

    triggerNotification(
      title: title,
      body: body,
      type: 'medical',
      targetRole: 'مسن',
    );

    // إضافة الذكرى لشاشة الذكريات
    final newItem = MemoryItem(
      id: 'mem_med_${DateTime.now().millisecondsSinceEpoch}',
      category: 'صحة',
      title: title,
      date: 'اليوم',
      type: 'text',
      assetPath: '',
      content: body,
    );

    memoriesList.insert(0, newItem);
    notifyListeners();
  }

  void toggleMedicationTaken(String id) {
    final index = medications.indexWhere((m) => m.id == id);
    if (index != -1) {
      bool newState = !medications[index].isTaken;
      medications[index].isTaken = newState;
      medications[index].isElderlyConfirmed = newState;
      notifyListeners();
    }
  }

  // --- Specialist Recommendations ---
  List<SpecialistRecommendation> specialistRecommendations = [];

  void addSpecialistRecommendation(SpecialistRecommendation rec) {
    specialistRecommendations.insert(0, rec);
    triggerNotification(
      title: 'توصية نفسية جديدة 🧠',
      body: 'توصية للمقيم ${rec.residentName}: ${rec.content}',
      type: 'medical',
      targetRole: 'ممرض',
    );
    notifyListeners();
  }

  // --- Care Reports ---
  List<CareReport> careReports = [
    CareReport(
      id: 'rep_1',
      title: 'تقييم ربع سنوي — أخصائي اجتماعي',
      date: '١٧ مايو ٢٠٢٦',
      summary: 'يُظهر المقيم تحسناً ملحوظاً في التفاعل مع الأنشطة الجماعية وخاصة جلسات القراءة. الروح المعنوية مرتفعة والشهية للطعام منتظمة.',
      socialNotes: 'شارك في مسابقة الذاكرة وحصل على المركز الثاني. أبدى رغبة في التحدث عن ذكريات الطفولة مع زملائه في الغرفة.',
      recommendations: 'يُنصح بزيادة التفاعل العائلي عبر مكالمات الفيديو خلال عطلة نهاية الأسبوع لتعزيز الشعور بالانتماء.',
      authorName: 'أ. نور الدين',
      authorRole: 'أخصائي اجتماعي أول',
      interactionLevel: 'ممتاز',
      moodStatus: 'مستقر',
    ),
  ];

  void addCareReport(CareReport report) {
    careReports.insert(0, report);
    triggerNotification(
      title: 'تقرير رعاية جديد 📄',
      body: 'تم إضافة تقرير جديد: ${report.title}',
      type: 'medical',
      targetRole: 'عائلة',
    );
    notifyListeners();
  }

  // --- Specialist Chat ---
  List<ChatMessage> specialistChatHistory = [
    ChatMessage(
      id: 'msg_1',
      text: 'مرحباً بكم. أنا هنا للإجابة على أي استفسار بخصوص التقرير.',
      isFromMe: false,
      timestamp: DateTime.now().subtract(const Duration(hours: 1)),
    ),
  ];

  void sendSpecialistMessage(String text, {String? mediaPath, String? mediaType}) {
    specialistChatHistory.add(ChatMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      text: text,
      isFromMe: true, // true means from Family
      timestamp: DateTime.now(),
      mediaPath: mediaPath,
      mediaType: mediaType,
    ));
    notifyListeners();
  }

  Future<void> loadSpecialistThread({
    String? otherUserId,
    String? otherUserName,
    String? otherUserRole,
  }) async {
    if (isDemoMode || AuthService.instance.currentUser == null) return;
    isLoadingSpecialistChat = true;
    notifyListeners();
  }

  void sendSpecialistReply(String text, {String? mediaPath, String? mediaType}) {
    specialistChatHistory.add(ChatMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      text: text,
      isFromMe: false, // false means from Specialist
      timestamp: DateTime.now(),
      mediaPath: mediaPath,
      mediaType: mediaType,
    ));
    notifyListeners();
  }

  pw.Widget _pdfBullet(pw.Font font, String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.start,
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: 4,
            height: 4,
            margin: const pw.EdgeInsets.only(top: 6, left: 8),
            decoration: const pw.BoxDecoration(
                color: PdfColors.black, shape: pw.BoxShape.circle),
          ),
          pw.Expanded(
            child: pw.Text(text,
                style: pw.TextStyle(font: font, fontSize: 11),
                textDirection: pw.TextDirection.rtl),
          ),
        ],
      ),
    );
  }
}
