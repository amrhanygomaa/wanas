import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // للوصول إلى الملفات (مثل الخطوط)
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_models.dart'; // نماذج البيانات المستخدمة في التطبيق
// مكتبة إدارة التصاريح
import 'package:flutter_secure_storage/flutter_secure_storage.dart'; // مكتبة التخزين الآمن
import 'package:flutter_contacts/flutter_contacts.dart'; // مكتبة جهات الاتصال
import 'package:url_launcher/url_launcher.dart'; // مكتبة تشغيل الروابط والمكالمات
import 'package:photo_manager/photo_manager.dart'; // مكتبة إدارة الصور
import 'package:image_picker/image_picker.dart'; // مكتبة اختيار الصور من المعرض
// للتعامل مع ملفات الصور المختارة
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'package:flutter_tts/flutter_tts.dart'; // مكتبة تحويل النص إلى كلام
import 'package:audioplayers/audioplayers.dart'; // مشغل الرسائل الصوتية داخل التطبيق

import '../services/api_client.dart';
import '../services/notification_service.dart';
import '../services/ai_service.dart';
import '../services/auth_service.dart';
import '../services/backend_sync_service.dart';
import '../services/backend_mutation_service.dart';
import '../services/complaints_service.dart';
import '../services/family_bridge_service.dart';
import '../services/facility_settings_service.dart';
import '../services/health_service.dart';
import '../services/emergency_service.dart';
import '../services/medications_service.dart';
import '../services/messages_service.dart';
import '../services/notifications_api_service.dart';
import '../services/social_service.dart';
import '../services/ai_media_service.dart';
import '../services/push_notification_service.dart';
import '../services/profile_image_service.dart';
import '../services/realtime_service.dart';
import '../services/user_preferences_service.dart';
import '../services/user_progress_service.dart';
import '../services/video_call_service.dart';
import '../services/voice_message_service.dart';
import '../services/family_media_service.dart';

final appRiverpod = ChangeNotifierProvider((ref) => AppRiverpod());

class AppRiverpod extends ChangeNotifier {
  int selectedIndex = 0;
  bool showSpecialistNeedMap = false;
  String facilityName = ''; // يُملأ من backend عند الـ login
  String managerName = ''; // يُملأ من backend عند الـ login

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

  String currentRole = ''; // يُحدد بعد نجاح استعادة جلسة AWS أو تسجيل الدخول
  bool hasSeenOnboarding = false; // هل شاهد المستخدم شاشات الترحيب؟
  bool isAuthenticated = false; // هل المستخدم مسجل دخوله؟
  bool isInitialized = false; // هل تم تحميل البيانات من الذاكرة؟
  double fontScaleFactor = 1.0; // حجم الخط المختار لسهولة القراءة
  bool isHighContrast = false; // تفعيل وضع التباين العالي
  bool isDarkMode = false; // تفعيل الوضع الليلي

  final _storage = const FlutterSecureStorage(); // إنشاء كائن التخزين الآمن
  bool isRefreshingSession = false;
  String selectedAdminDateFilter = 'اليوم';
  DateTime? _sessionExpiry;
  StreamSubscription<Map<String, dynamic>>? _realtimeSub;

  AppAccount? currentAccount; // الحساب الحالي المسجل دخوله

  // --- إدارة الحسابات (Account Management) ---
  List<AppAccount> accounts = [];

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
      var imageUrl = image.path;
      if (backendUserId != null && backendUserId!.isNotEmpty) {
        try {
          final uploaded = await ProfileImageService.instance.uploadStaffImage(
            staffId: backendUserId!,
            image: image,
          );
          if (uploaded.imageUrl.isNotEmpty) imageUrl = uploaded.imageUrl;
          backendSyncError = null;
        } catch (e) {
          backendSyncError = e.toString();
        }
      }
      final updatedAccount = currentAccount!.copyWith(imageUrl: imageUrl);
      updateCurrentAccount(updatedAccount);
    }
  }

  // دالة للمدير لإنشاء حسابات جديدة
  Future<void> createAccount(
      {required String name,
      required String email,
      required String password,
      required String role}) async {
    final synced = await _runBackendMutation(() {
      return BackendMutationService.instance.createManagedUser(
        email: email,
        fullName: name,
        role: role,
        temporaryPassword: password,
      );
    });
    if (!synced) return;
    accounts.add(
        AppAccount(name: name, email: email, password: password, role: role));
    notifyListeners();
  }

  // دالة للتسجيل الذاتي (للمتطوعين والأهالي)
  Future<void> selfRegister(
      {required String name,
      required String email,
      required String password,
      required String role}) async {
    final synced = await _runBackendMutation(() {
      return BackendMutationService.instance.createManagedUser(
        email: email,
        fullName: name,
        role: role,
        temporaryPassword: password,
      );
    });
    if (!synced) return;
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
  }) async {
    final synced = await _runBackendMutation(() {
      return BackendMutationService.instance.createManagedUser(
        email: email,
        fullName: name,
        role: 'إدارة',
        temporaryPassword: password,
      );
    });
    if (!synced) return;

    final newAccount = AppAccount(
      name: name,
      email: email,
      password: password,
      role: 'إدارة',
      facilityName: facilityName,
      facilityAddress: facilityAddress,
      amenities: amenities,
    );

    accounts.add(newAccount);
    currentAccount = newAccount;

    this.facilityName = facilityName;
    managerName = name;

    notifyListeners();
  }

  // ربط عائلة بمسن
  Future<void> linkFamilyToResident(
      String residentId, String familyEmail) async {
    final synced = await _runBackendMutation(() {
      return BackendMutationService.instance.createFamilyMemberForEmail(
        residentId: residentId,
        email: familyEmail,
      );
    });
    if (!synced) return;
    await syncBackendData();
    notifyListeners();
  }

  AppRiverpod() {
    _clearSeedState();
    _loadAuthState(); // تحميل حالة الدخول عند بدء تشغيل المزود
  }

  @override
  void dispose() {
    _realtimeSub?.cancel();
    RealtimeService.instance.disconnect();
    _voicePlayerCompleteSub?.cancel();
    _voicePlayer.dispose();
    super.dispose();
  }

  void _clearSeedState() {
    accounts.clear();
    pendingAssessments.clear();
    handoffs.clear();
    notifications.clear();
    nursingNotes.clear();
    residentMedicalInfos.clear();
    medications.clear();
    activities.clear();
    familyMembersList.clear();
    voiceMessagesList.clear();
    aiInsights.clear();
    companionChatHistory.clear();
    memoriesList.clear();
    volunteerOpportunities.clear();
    volunteerBookings.clear();
    volunteerCertificates.clear();
    volunteerRatings.clear();
    volunteerReviews.clear();
    questionBank.clear();
    socialAssessmentTools.clear();
    socialNeeds.clear();
    socialResidentScores.clear();
    socialComplaints.clear();
    gdsQuestions.clear();
    assessmentHistory.clear();
    familyHealthMetrics.clear();
    familyVisits.clear();
    familyBills.clear();
    residentFiles.clear();
    medicalSessions.clear();
    medicalPrescriptions.clear();
    sentReports.clear();
    staffPerformanceList.clear();
    memoryMoments.clear();
    activeEmergencies.clear();
    careTasks.clear();
    inventoryItems.clear();
    doctorVisits.clear();
    mealPlans.clear();
    mealPlanIdsByResidentName.clear();
    activitySessions.clear();
    specialistRecommendations.clear();
    careReports.clear();
    specialistChatHistory.clear();
    specialistChatUser = null;
    isLoadingSpecialistChat = false;
    volunteerHours = 0;
    volunteerGoal = 0;
    aiInsightMode = 'backend';
    lastAiMode = 'backend';
    currentUser = User(
      name: '',
      points: 0,
      streakDays: 0,
      completedActivities: 0,
    );
    volunteerProfile = VolunteerProfile(
      name: '',
      location: '',
      bio: '',
      skills: const [],
      linkedinUrl: '',
      facebookUrl: '',
      instagramUrl: '',
    );
  }

  // تحميل بيانات الدخول والجلسة من التخزين الآمن
  Future<void> _loadAuthState() async {
    final auth = await _storage.read(key: 'isAuthenticated');
    final role = await _storage.read(key: 'currentRole');
    final onboarding = await _storage.read(key: 'hasSeenOnboarding');
    final savedEmail = await _storage.read(key: 'userEmail');
    final backendUser = await AuthService.instance.restoreSession();

    if (backendUser != null) {
      _applyBackendUser(
        email: backendUser.email,
        role: backendUser.arabicRole,
        userId: backendUser.userId,
        facilityId: backendUser.facilityId,
        name: backendUser.name,
        linkedResidentId: backendUser.linkedResidentId,
        facilityName: backendUser.facilityName,
      );
      _sessionExpiry = DateTime.now().add(const Duration(hours: 1));
      await _storage.write(key: 'isAuthenticated', value: 'true');
      await _storage.write(key: 'currentRole', value: currentRole);
      await _storage.write(key: 'userEmail', value: backendUser.email);
      await _storage.write(
          key: 'sessionExpiry', value: _sessionExpiry!.toIso8601String());
    } else if (auth == 'true' || role != null || savedEmail != null) {
      await _storage.delete(key: 'isAuthenticated');
      await _storage.delete(key: 'currentRole');
      await _storage.delete(key: 'userEmail');
      await _storage.delete(key: 'sessionExpiry');
    }

    if (onboarding == 'true') hasSeenOnboarding = true;

    isInitialized = true; // اكتمل التحميل
    notifyListeners();

    if (backendUser != null) {
      await syncBackendData();
    }
  }

  // حفظ الدور في الذاكرة لتجنب الخروج عند الريلود
  Future<void> setAndSaveRole(String role) async {
    currentRole = role;
    await _storage.write(key: 'currentRole', value: role);
    notifyListeners();
  }

  // أداة اختبار داخلية لإنهاء الجلسة محلياً
  void simulateSessionExpiry() {
    _sessionExpiry = DateTime.now().subtract(const Duration(minutes: 1));
    notifyListeners();
  }

  // التحقق من صحة الجلسة وتجديدها إذا لزم الأمر
  Future<bool> checkAndRefreshSession() async {
    if (!isAuthenticated || _sessionExpiry == null) return true;

    // إذا كانت الجلسة منتهية أو ستنتهي خلال دقيقة
    if (_sessionExpiry!
        .isBefore(DateTime.now().add(const Duration(minutes: 1)))) {
      if (isRefreshingSession) return false;

      isRefreshingSession = true;
      notifyListeners();

      try {
        final refreshedUser = await AuthService.instance.refreshSession();
        if (refreshedUser == null) {
          await logout();
          return false;
        }
        _applyBackendUser(
          email: refreshedUser.email,
          role: refreshedUser.arabicRole,
          userId: refreshedUser.userId,
          facilityId: refreshedUser.facilityId,
        );
        _sessionExpiry = DateTime.now().add(const Duration(hours: 2));
        await _storage.write(key: 'isAuthenticated', value: 'true');
        await _storage.write(key: 'currentRole', value: currentRole);
        await _storage.write(key: 'userEmail', value: refreshedUser.email);
        await _storage.write(
            key: 'sessionExpiry', value: _sessionExpiry!.toIso8601String());
        return true;
      } catch (_) {
        await logout(); // تسجيل الخروج التلقائي
        return false;
      } finally {
        isRefreshingSession = false;
        notifyListeners();
      }
    }
    return true;
  }

  void toggleDarkMode() {
    isDarkMode = !isDarkMode;
    _saveUserPreferencesLater();
    notifyListeners();
  }

  // تحديث فلتر التاريخ للوحة تحكم المدير
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

    final syncedAssessments = <PendingAssessment>[];
    for (final assessment in List<PendingAssessment>.from(pendingAssessments)) {
      final residentId = _residentIdForName(assessment.residentName);
      if (residentId == null) continue;

      final score = _scorePendingAssessment(assessment);
      final synced = await _runBackendMutation(() {
        return BackendMutationService.instance.createSocialAssessment(
          residentId: residentId,
          scores: {assessment.toolName: score},
          needsIntervention: score < 0.45,
          notes: assessment.notes,
        );
      });
      if (!synced) break;
      syncedAssessments.add(assessment);
    }

    pendingAssessments.removeWhere(syncedAssessments.contains);
    if (pendingAssessments.isEmpty) {
      backendSyncError = null;
    } else {
      backendSyncError ??= 'تعذر ربط بعض التقييمات بمقيم من AWS';
    }
    isSyncing = false;
    notifyListeners();
  }

  double _scorePendingAssessment(PendingAssessment assessment) {
    final values = assessment.scales.isNotEmpty
        ? assessment.scales.values
        : assessment.selections.values.map((value) => value + 1);
    if (values.isEmpty) return 0.5;
    final average = values.reduce((a, b) => a + b) / values.length;
    return (average / 5).clamp(0.0, 1.0).toDouble();
  }

  // Shift Handoff State
  List<ShiftHandoff> handoffs = [];

  Future<void> submitHandoff(ShiftHandoff h) async {
    final synced = await _runBackendMutation(() {
      return BackendMutationService.instance.createHandoff(h);
    });
    if (!synced) return;
    handoffs.insert(0, h);
    notifyListeners();
  }

  // Real Notification State
  List<TaptabaNotification> notifications = [];

  List<TaptabaNotification> get filteredNotifications {
    return notifications
        .where((n) => n.targetRole == currentRole || n.targetRole == 'all')
        .toList();
  }

  bool get hasNewNotification => filteredNotifications.any((n) => !n.isRead);

  Future<void> triggerNotification(
      {required String title,
      required String body,
      String type = 'admin',
      String targetRole = 'all'}) async {
    final user = AuthService.instance.currentUser;
    if (user == null) {
      backendSyncError = 'لا توجد جلسة AWS نشطة لإنشاء الإشعار';
      notifyListeners();
      return;
    }

    try {
      final created = await NotificationsApiService.instance.create(
        userId: user.userId,
        message: body,
        type: _backendNotificationType(type),
      );
      notifications.insert(
        0,
        TaptabaNotification(
          id: created.id,
          title: title,
          body: created.message,
          time: 'الآن',
          type: created.type,
          targetRole: targetRole,
        ),
      );
      backendSyncError = null;
    } catch (e) {
      backendSyncError = e.toString();
    }
    notifyListeners();
  }

  Future<void> markNotificationAsRead(String id) async {
    final synced = await _runBackendMutation(() {
      return NotificationsApiService.instance.markAsRead(id).then((_) {});
    });
    if (!synced) return;
    final idx = notifications.indexWhere((n) => n.id == id);
    if (idx != -1) {
      notifications[idx].isRead = true;
      notifyListeners();
    }
  }

  Future<void> deleteNotification(String id) async {
    final synced = await _runBackendMutation(() {
      return NotificationsApiService.instance.deleteOne(id);
    });
    if (!synced) return;
    notifications.removeWhere((n) => n.id == id);
    notifyListeners();
  }

  Future<void> markAllFilteredNotificationsAsRead() async {
    final visible = notifications
        .where((n) => n.targetRole == currentRole || n.targetRole == 'all')
        .toList();
    for (var n in visible) {
      final synced = await _runBackendMutation(() {
        return NotificationsApiService.instance.markAsRead(n.id).then((_) {});
      });
      if (!synced) return;
      if (n.targetRole == currentRole || n.targetRole == 'all') {
        n.isRead = true;
      }
    }
    notifyListeners();
  }

  Future<void> clearNotifications() async {
    final user = AuthService.instance.currentUser;
    if (user == null) {
      backendSyncError = 'لا توجد جلسة AWS نشطة لمسح الإشعارات';
      notifyListeners();
      return;
    }
    final synced = await _runBackendMutation(() {
      return NotificationsApiService.instance.clearForUser(user.userId);
    });
    if (!synced) return;
    notifications.clear();
    notifyListeners();
  }

  // Nursing Notes State
  List<NursingNote> nursingNotes = [];

  Future<void> addNursingNote(NursingNote note) async {
    final residentId = _residentIdForName(note.residentName);
    if (residentId == null) {
      backendSyncError = 'لا يوجد residentId من AWS لهذا المقيم';
      notifyListeners();
      return;
    }
    final synced = await _runBackendMutation(() {
      return BackendMutationService.instance.createNursingNote(
        residentId: residentId,
        note: note,
      );
    });
    if (!synced) return;
    nursingNotes.insert(0, note);
    notifyListeners();
  }

  List<NursingNote> getNotesForResident(String residentName) {
    return nursingNotes.where((n) => n.residentName == residentName).toList();
  }

  // Resident Medical Info State
  List<ResidentMedicalInfo> residentMedicalInfos = [];

  ResidentMedicalInfo getMedicalInfo(String residentName) {
    return residentMedicalInfos.firstWhere(
      (info) => info.residentName == residentName,
      orElse: () => ResidentMedicalInfo(residentName: residentName),
    );
  }

  Future<void> updateMedicalInfo(ResidentMedicalInfo newInfo) async {
    final residentId = _residentIdForName(newInfo.residentName);
    if (residentId == null) {
      backendSyncError = 'لا يوجد residentId من AWS لهذا المقيم';
      notifyListeners();
      return;
    }
    final synced = await _runBackendMutation(() {
      return BackendMutationService.instance.upsertMedicalInfo(
        residentId: residentId,
        info: newInfo,
      );
    });
    if (!synced) return;
    final index = residentMedicalInfos
        .indexWhere((info) => info.residentName == newInfo.residentName);
    if (index != -1) {
      residentMedicalInfos[index] = newInfo;
    } else {
      residentMedicalInfos.add(newInfo);
    }
    notifyListeners();
  }

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
    if (_backendSyncFuture != null) return _backendSyncFuture!;
    _backendSyncFuture = _syncBackendDataInternal().whenComplete(() {
      _backendSyncFuture = null;
    });
    return _backendSyncFuture!;
  }

  Future<void> _syncBackendDataInternal() async {
    final token = await AuthService.instance.restoreSession();
    if (token == null) return;

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
    } catch (e) {
      backendSyncError = e.toString();
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
    if (AuthService.instance.currentUser == null) return;
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
    if (AuthService.instance.currentUser == null) return;
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
    if (AuthService.instance.currentUser == null) return;
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
    if (AuthService.instance.currentUser == null) return;
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
    if (AuthService.instance.currentUser == null) return;

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
    if (AuthService.instance.currentUser == null ||
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
    if (AuthService.instance.currentUser == null) {
      backendSyncError = 'لا توجد جلسة AWS نشطة';
      notifyListeners();
      return false;
    }

    try {
      await mutation();
      backendSyncError = null;
      return true;
    } catch (e) {
      backendSyncError = e.toString();
      notifyListeners();
      return false;
    }
  }

  // عملية تسجيل الدخول وحفظ البيانات آمنياً مع ضبط موعد انتهاء الجلسة (US-SmartLogin)
  Future<bool> login(String idRaw, String passRaw) async {
    final identifier = idRaw.trim();
    final password = passRaw.trim();
    if (identifier.isEmpty || password.isEmpty) return false;

    try {
      final user = await AuthService.instance.login(identifier, password);
      await markBackendAuthenticated(
        email: user.email,
        role: user.arabicRole,
        userId: user.userId,
        facilityId: user.facilityId,
        name: user.name,
        linkedResidentId: user.linkedResidentId,
        facilityName: user.facilityName,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  // عملية تسجيل الخروج ومسح البيانات الآمنة تماماً
  Future<void> logout() async {
    isAuthenticated = false;
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
    await _realtimeSub?.cancel();
    _realtimeSub = null;
    RealtimeService.instance.disconnect();
    await AuthService.instance.logout();
    unawaited(PushNotificationService.instance.removeToken());

    // مسح التخزين الآمن تماماً
    await _storage.delete(key: 'isAuthenticated');
    await _storage.delete(key: 'currentRole');
    await _storage.delete(key: 'userEmail');
    await _storage.delete(key: 'sessionExpiry');

    notifyListeners(); // العودة لشاشة تسجيل الدخول تلقائياً
  }

  // إتمام شاشات الترحيب وحفظ الحالة
  Future<void> completeOnboarding() async {
    hasSeenOnboarding = true;
    await _storage.write(key: 'hasSeenOnboarding', value: 'true');
    notifyListeners();
  }

  // إعادة تعيين شاشات الترحيب (للتجربة والاختبار)
  Future<void> resetOnboarding() async {
    hasSeenOnboarding = false;
    await _storage.delete(key: 'hasSeenOnboarding');
    notifyListeners();
  }

  void updateFontScale(double value) {
    fontScaleFactor = value;
    _saveUserPreferencesLater();
    notifyListeners();
  }

  void toggleHighContrast() {
    isHighContrast = !isHighContrast;
    _saveUserPreferencesLater();
    notifyListeners();
  }

  // --- ELDERLY / RESIDENT STATE (RE-ADDED) ---
  // يُحدَّث من Cognito + AppAccount عند الـ login
  User currentUser = User(
    name: '',
    points: 0,
    streakDays: 0,
    completedActivities: 0,
  );

  List<Medication> medications = [];

  List<Medication> get missedMedications =>
      medications.where((m) => m.isMissed).toList();

  Future<void> markMedicationAsTaken(String id) async {
    final index = medications.indexWhere((m) => m.id == id);
    if (index != -1) {
      final med = medications[index];
      await _syncMedicationDose(med, 'given');
      if (backendSyncError != null) return;
      medications[index].isTaken = true;

      // LINK: Notify Family when medication is taken
      triggerNotification(
        title: 'تم إعطاء الدواء 💊',
        body: 'الممرض قام بإعطاء ${med.name} لـ ${med.residentName} في موعده.',
        type: 'medical',
        targetRole: 'أهل',
      );

      // LINK: Notify Admin if a dose is marked after being missed
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

  List<Activity> activities = [];

  List<FamilyMember> familyMembersList = [];

  List<VoiceMessage> voiceMessagesList = [];

  // Call State
  bool isVideoCallActive = false;
  bool isIncomingCall = false;
  String activeCallerName = '';
  String activeCallerInitials = '';
  String? activeVideoCallId;
  String? activeVideoCallJoinUrl;

  // New Features State
  bool isAIInsightsEnabled = true;
  bool isLoadingAiInsight = false;
  String aiInsightMode = 'backend';

  // جلب توصية حقيقية من AWS Bedrock عبر الباك اند
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
  List<CompanionMessage> companionChatHistory = [];

  bool isEmergencyActive = false;
  bool isEmergencySyncing = false;
  String? currentEmergencyId;
  List<BackendEmergency> activeEmergencies = [];
  String currentMood = ''; // 'happy', 'calm', 'tired', 'active'
  bool isReadingAudio = false;
  String readingText = '';

  List<AssetEntity> deviceGalleryImages = []; // Real fetched device assets

  List<MemoryItem> memoriesList = [];

  // --- VOLUNTEER STATE ---
  int volunteerHours = 0;
  int volunteerGoal = 50;

  VolunteerProfile volunteerProfile = VolunteerProfile(
    name: '',
    location: '',
    bio: '',
    skills: [],
  );

  List<VolunteerOpportunity> volunteerOpportunities = [];

  List<VolunteerBooking> volunteerBookings = [];

  List<VolunteerCertificate> volunteerCertificates = [];

  List<VolunteerRating> volunteerRatings = [];

  List<VolunteerReview> volunteerReviews = [];

  // --- DYNAMIC QUESTION BANK ---
  Map<String, List<Map<String, dynamic>>> questionBank = {};

  List<Map<String, dynamic>> getQuestionsForTool(String toolId) {
    return questionBank[toolId] ?? const [];
  }

  // --- SOCIAL SPECIALIST STATE ---
  String selectedSpecialistFilter = 'الكل';
  String residentSearchQuery = '';
  String? selectedHealthStatus; // 'stable', 'monitoring', 'critical'
  String? selectedRoomFilter;
  int selectedFloor = 1;

  List<SocialSpecialistAssessmentTool> socialAssessmentTools = [];

  List<SocialSpecialistNeed> socialNeeds = [];

  List<SocialSpecialistResidentScore> socialResidentScores = [];

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

  List<SocialSpecialistComplaint> socialComplaints = [];

  String _toArabicDigits(int value) {
    return value
        .toString()
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
    // 1. معدل الرضا العام (متوسط تقييمات المقيمين)
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
        : 0;

    // 2. حالات حرجة
    int criticalCases =
        socialResidentScores.where((r) => r.healthStatus == 'critical').length;

    // 3. شكاوى مفتوحة
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
          value: '${_toArabicDigits(activityRate)}٪',
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

  // --- GETTERS ---
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
  int get totalPendingAssessments => pendingAssessments.length;

  double get averageRating {
    if (volunteerRatings.isEmpty) return 0;
    final total = volunteerRatings.fold<double>(0, (sum, r) => sum + r.score);
    return total / volunteerRatings.length;
  }

  int get totalReviews => volunteerReviews.length;

  String get topSkill {
    if (volunteerRatings.isEmpty) return '—';
    final scoresBySkill = <String, List<double>>{};
    for (final r in volunteerRatings) {
      scoresBySkill.putIfAbsent(r.category, () => []).add(r.score);
    }
    if (scoresBySkill.isEmpty) return '—';
    final top = scoresBySkill.entries.reduce((a, b) {
      final avgA = a.value.reduce((x, y) => x + y) / a.value.length;
      final avgB = b.value.reduce((x, y) => x + y) / b.value.length;
      return avgA >= avgB ? a : b;
    });
    final avg = top.value.reduce((x, y) => x + y) / top.value.length;
    return '${top.key} ⭐ ${avg.toStringAsFixed(1)}';
  }

  String get skillNeedsImprovement {
    if (volunteerRatings.isEmpty) return '—';
    final scoresBySkill = <String, List<double>>{};
    for (final r in volunteerRatings) {
      scoresBySkill.putIfAbsent(r.category, () => []).add(r.score);
    }
    if (scoresBySkill.isEmpty) return '—';
    final bottom = scoresBySkill.entries.reduce((a, b) {
      final avgA = a.value.reduce((x, y) => x + y) / a.value.length;
      final avgB = b.value.reduce((x, y) => x + y) / b.value.length;
      return avgA <= avgB ? a : b;
    });
    final avg = bottom.value.reduce((x, y) => x + y) / bottom.value.length;
    return '${bottom.key} ${avg.toStringAsFixed(1)}';
  }

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

  // --- CONTACTS & COMMUNICATION LOGIC ---

  // طلب إذن الوصول لجهات الاتصال وجلب المفضلين
  Future<void> fetchFavoriteContacts() async {
    if (!await FlutterContacts.requestPermission()) return;

    final contacts = await FlutterContacts.getContacts(withProperties: true);
    final favorites = contacts.where((c) => c.isStarred).toList();
    final toShow = favorites.isNotEmpty ? favorites : contacts.take(3).toList();

    for (final contact in toShow) {
      if (contact.phones.isEmpty) continue;
      final phone = contact.phones.first.number;
      if (familyMembersList.any((m) => m.phoneNumber == phone)) continue;

      final name = contact.displayName;
      String memberId = contact.id;

      // أرسل للباك اند إذا توفر residentId
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
    notifyListeners();
  }

  void toggleFamilyPin(String id) {
    final idx = familyMembersList.indexWhere((m) => m.id == id);
    if (idx != -1) {
      familyMembersList[idx].isPinned = !familyMembersList[idx].isPinned;
      notifyListeners();
    }
  }

  // فتح قائمة جهات اتصال الهاتف واختيار رقم يدوياً — يُرجع false إذا رُفض الإذن
  Future<bool> pickAndAddContact() async {
    if (!await FlutterContacts.requestPermission()) return false;

    final contact = await FlutterContacts.openExternalPick();
    if (contact == null) return true; // المستخدم ألغى الاختيار

    final fullContact = await FlutterContacts.getContact(contact.id);
    if (fullContact != null && fullContact.phones.isNotEmpty) {
      final phone = fullContact.phones.first.number;
      final name = fullContact.displayName;
      if (!familyMembersList.any((m) => m.phoneNumber == phone)) {
        // حاول إرسال الـ contact للباك اند أولاً للحصول على UUID حقيقي
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
  }

  // إجراء مكالمة هاتفية حقيقية عبر تطبيق الهاتف
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

  // تشغيل اجتماعات زووم
  Future<void> launchZoom(String? link) async {
    if (link == null || link.isEmpty) return;

    final candidates = <Uri>[
      ..._zoomDeepLinks(link),
      Uri.parse(link),
    ];

    for (final uri in candidates) {
      try {
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          return;
        }
      } catch (_) {}
    }
    debugPrint('Could not launch Zoom link: $link');
  }

  List<Uri> _zoomDeepLinks(String link) {
    final uri = Uri.tryParse(link);
    if (uri == null) return const [];
    final segments = uri.pathSegments;
    final joinIndex = segments.indexOf('j');
    final meetingId = joinIndex >= 0 && joinIndex + 1 < segments.length
        ? segments[joinIndex + 1]
        : null;
    if (meetingId == null || meetingId.isEmpty) return const [];
    final query = <String, String>{
      'confno': meetingId,
      'zc': '0',
      if ((uri.queryParameters['pwd'] ?? '').isNotEmpty)
        'pwd': uri.queryParameters['pwd']!,
      if (currentUser.name.isNotEmpty) 'uname': currentUser.name,
    };
    return [
      Uri(
          scheme: 'zoomus',
          host: 'zoom.us',
          path: '/join',
          queryParameters: query),
      Uri(
          scheme: 'zoommtg',
          host: 'zoom.us',
          path: '/join',
          queryParameters: query),
    ];
  }

  List<VoiceMessage> get voiceMessages => voiceMessagesList;
  List<MemoryItem> get memories => memoriesList;

  VolunteerImpact get volunteerImpact => VolunteerImpact(
        residentsServed: totalResidentsCount,
        positiveRatings: volunteerRatings.where((r) => r.score >= 4.0).length,
        totalHours: volunteerHours,
      );

  // --- DETAILED ASSESSMENT STATE ---
  List<AssessmentQuestion> gdsQuestions = [];

  List<AssessmentHistoricalEntry> assessmentHistory = [];

  // تحميل أسئلة GDS من الباك اند.
  Future<void> loadGdsQuestions() async {
    try {
      final raw = await SocialService.instance.getGdsQuestions();
      gdsQuestions = raw
          .map((e) => AssessmentQuestion.fromJson(e))
          .where((q) => q.id.isNotEmpty && q.text.isNotEmpty)
          .toList();
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

  // --- METHODS ---
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

  Future<void> completeActivity(String id) async {
    final idx = activities.indexWhere((a) => a.id == id);
    if (idx != -1) {
      activities[idx].status = 'done';
      final synced = await _runBackendMutation(() {
        return BackendMutationService.instance.updateActivity(activities[idx]);
      });
      if (!synced) return;
      notifyListeners();
    }
  }

  Future<void> addActivity(Activity activity) async {
    final synced = await _runBackendMutation(() {
      return BackendMutationService.instance.createActivity(activity);
    });
    if (!synced) return;
    activities.insert(0, activity);
    notifyListeners();
  }

  Future<void> updateActivityItem(Activity activity) async {
    final synced = await _runBackendMutation(() {
      return BackendMutationService.instance.updateActivity(activity);
    });
    if (!synced) return;
    final idx = activities.indexWhere((a) => a.id == activity.id);
    if (idx != -1) {
      activities[idx] = activity;
    }
    notifyListeners();
  }

  final Map<String, bool> familyActivityParticipations = {};
  final Map<String, String> familyActivityNotes = {};

  void toggleFamilyParticipation(String activityId) {
    final current = familyActivityParticipations[activityId] ?? false;
    familyActivityParticipations[activityId] = !current;
    notifyListeners();
  }

  bool isFamilyParticipating(String activityId) {
    return familyActivityParticipations[activityId] ?? false;
  }

  void updateFamilyActivityNote(String activityId, String note) {
    familyActivityNotes[activityId] = note.trim();
    notifyListeners();
  }

  String getFamilyActivityNote(String activityId) {
    return familyActivityNotes[activityId] ?? '';
  }

  Future<void> updateStaff(StaffPerformance staff) async {
    final synced = await _runBackendMutation(() {
      return BackendMutationService.instance.updateManagedUser(staff);
    });
    if (!synced) return;
    final idx = staffPerformanceList.indexWhere((s) => s.id == staff.id);
    if (idx != -1) {
      staffPerformanceList[idx] = staff;
    }
    notifyListeners();
  }

  Future<void> deleteStaff(String id) async {
    final synced = await _runBackendMutation(() {
      return BackendMutationService.instance.disableManagedUser(id);
    });
    if (!synced) return;
    staffPerformanceList.removeWhere((s) => s.id == id);
    notifyListeners();
  }

  // --- IMAGE PICKING METHODS ---

  Future<void> pickAndSetResidentImage(String residentId) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      await updateResidentImage(residentId, image);
    }
  }

  Future<void> updateResidentImage(String residentId, XFile image) async {
    try {
      final uploaded = await ProfileImageService.instance.uploadResidentImage(
        residentId: residentId,
        image: image,
      );
      final imageUrl =
          uploaded.imageUrl.isEmpty ? image.path : uploaded.imageUrl;
      residentFiles = residentFiles
          .map((r) => r.id == residentId ? r.copyWith(imageUrl: imageUrl) : r)
          .toList();
      backendSyncError = null;
    } catch (e) {
      backendSyncError = e.toString();
    }
    notifyListeners();
  }

  Future<void> pickAndSetStaffImage(String staffId) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      await updateStaffImage(staffId, image);
    }
  }

  Future<void> updateStaffImage(String staffId, XFile image) async {
    try {
      final uploaded = await ProfileImageService.instance.uploadStaffImage(
        staffId: staffId,
        image: image,
      );
      final imageUrl =
          uploaded.imageUrl.isEmpty ? image.path : uploaded.imageUrl;
      staffPerformanceList = staffPerformanceList
          .map((s) => s.id == staffId ? s.copyWith(imageUrl: imageUrl) : s)
          .toList();
      backendSyncError = null;
    } catch (e) {
      backendSyncError = e.toString();
    }
    notifyListeners();
  }

  Future<void> elderlyConfirmMedication(String id) async {
    final idx = medications.indexWhere((m) => m.id == id);
    if (idx != -1 &&
        !medications[idx].isTaken &&
        !medications[idx].isElderlyConfirmed) {
      await triggerNotification(
        title: 'تأكيد دواء 💊',
        body:
            'المقيم أكد تناوله لدواء (${medications[idx].name}). يرجى التأكيد.',
        type: 'medical',
        targetRole: 'ممرض',
      );
      if (backendSyncError != null) return;
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
      if (backendSyncError != null) return;
      medications[idx].isTaken = true;
      medications[idx].isElderlyConfirmed = true; // For safety
      medications[idx].isSkipped = false;
      addPoints(10); // Reward points for taking medication

      // إشعار الأسرة باكتمال أهداف المسن الصحية
      triggerNotification(
        title: 'إنجاز صحي جديد! 🏆',
        body:
            'والدك أتم أخذ دوائه (${medications[idx].name}) في الموعد وكسب 10 نقاط!',
        type: 'medical',
        targetRole:
            'عائلة', // Changed to match app standards (usually 'عائلة' or 'أسرة')
      );

      notifyListeners();
    }
  }

  Future<void> skipMedication(String id, String reason) async {
    final idx = medications.indexWhere((m) => m.id == id);
    if (idx != -1) {
      final med = medications[idx];
      await _syncMedicationDose(med, 'skipped', notes: reason);
      if (backendSyncError != null) return;
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

    if (AuthService.instance.currentUser == null) return;
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

  // --- NEW FEATURES METHODS ---
  void toggleAIInsights(bool value) {
    isAIInsightsEnabled = value;
    _saveUserPreferencesLater();
    notifyListeners();
  }

  void toggleAICompanion(bool value) {
    isAICompanionEnabled = value;
    _saveUserPreferencesLater();
    notifyListeners();
  }

  // مؤشر "يكتب الآن..." أثناء انتظار رد AWS Bedrock
  bool isAiThinking = false;
  // وضع الرد الأخير القادم من الباك اند
  String lastAiMode = 'bedrock';

  void sendCompanionMessage(String text,
      {String? mediaPath, String? mediaType}) async {
    if (text.isEmpty && mediaPath == null) return;

    // أضف رسالة المستخدم
    companionChatHistory.add(CompanionMessage(
      id: DateTime.now().toString(),
      text: text,
      isFromAI: false,
      timestamp: DateTime.now(),
      mediaPath: mediaPath,
      mediaType: mediaType,
    ));
    isAiThinking = true;
    notifyListeners();

    // اتصال حقيقي بـ AWS Bedrock (Claude Haiku) عبر الباك اند
    try {
      AiMediaUpload? uploadedMedia;
      if (mediaPath != null && mediaPath.isNotEmpty) {
        uploadedMedia = await AiMediaService.instance.uploadFile(
          filePath: mediaPath,
          residentId: backendResidentId,
        );
      }

      // ابني سياق المحادثة من آخر 6 رسائل
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
    } catch (e) {
      lastAiMode = 'error';
      backendSyncError = e.toString();
    } finally {
      isAiThinking = false;
      notifyListeners();
    }
  }

  Future<void> refreshActiveEmergencies() async {
    if (AuthService.instance.currentUser == null) return;
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

    if (triggeredBy.isEmpty) {
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
    if (!synced) return;
    activeEmergencies.removeWhere((e) => e.id == id);
    if (currentEmergencyId == id) {
      currentEmergencyId = null;
      isEmergencyActive = false;
    }
    notifyListeners();
  }

  // --- DEEP LINKING & NOTIFICATIONS (US-09-03) ---
  void handleDeepLink(String route) {
    // Logic for Elderly (مسن) role
    if (currentRole == 'مسن') {
      switch (route) {
        case 'medication':
          setElderlyTabIndex(1); // Medication screen
          break;
        case 'family_update':
          setElderlyTabIndex(3); // Memories screen
          break;
        case 'calls':
          setElderlyTabIndex(2); // Calls screen
          break;
        case 'activities':
          setElderlyTabIndex(4); // Activities screen
          break;
        default:
          setElderlyTabIndex(0); // Home
      }
    }
    // Logic for other roles could be added here

    notifyListeners();
  }

  void simulateNotification(String type) {
    // Simulate a push notification being clicked
    handleDeepLink(type);
  }

  void setMood(String mood) {
    currentMood = mood;
    addPoints(5); // Reward for check-in
    notifyListeners();
  }

  // --- TTS (Text-to-Speech) ---
  final FlutterTts _tts = FlutterTts();
  bool _ttsInitialized = false;

  Future<void> _initTts() async {
    if (_ttsInitialized) return;

    try {
      // محاولة ضبط اللغة العربية (بشكل عام لزيادة التوافق)
      await _tts.setLanguage('ar');
      await _tts.setSpeechRate(0.4);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);

      // مستمعين لحالة الصوت لتحديث الواجهة بشكل صحيح
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
        // إذا فشل النطق (مثلاً المحرك غير جاهز)
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

  // --- مشغل الرسائل الصوتية داخل التطبيق ---
  final AudioPlayer _voicePlayer = AudioPlayer();
  StreamSubscription<void>? _voicePlayerCompleteSub;
  String? _playingVoiceMessageId;
  String? voiceMessageBanner; // رسالة منبثقة للمستخدم (خطأ أو إشعار)

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
    if (idx == -1) return;

    final msg = voiceMessagesList[idx];
    final isCurrentlyPlaying = msg.isPlaying;

    if (isCurrentlyPlaying) {
      await _voicePlayer.pause();
      msg.isPlaying = false;
      _playingVoiceMessageId = null;
      notifyListeners();
      return;
    }

    final audioUrl = msg.audioUrl;
    if (audioUrl == null || audioUrl.isEmpty) {
      voiceMessageBanner = 'الرسالة الصوتية غير متاحة حالياً';
      notifyListeners();
      return;
    }

    _stopAllVoiceMessageFlags();
    try {
      await _voicePlayer.stop();
      _voicePlayerCompleteSub ??= _voicePlayer.onPlayerComplete.listen((_) {
        final pid = _playingVoiceMessageId;
        if (pid != null) {
          final i = voiceMessagesList.indexWhere((v) => v.id == pid);
          if (i != -1) voiceMessagesList[i].isPlaying = false;
        }
        _playingVoiceMessageId = null;
        notifyListeners();
      });

      if (audioUrl.startsWith('http')) {
        await _voicePlayer.play(UrlSource(audioUrl));
      } else if (audioUrl.startsWith('s3://')) {
        voiceMessageBanner = 'الرسالة الصوتية لم يتم رفعها للسحابة بعد';
        notifyListeners();
        return;
      } else {
        await _voicePlayer.play(DeviceFileSource(audioUrl));
      }

      msg.isPlaying = true;
      msg.isUnread = false;
      _playingVoiceMessageId = msg.id;
      notifyListeners();
    } catch (e) {
      msg.isPlaying = false;
      _playingVoiceMessageId = null;
      voiceMessageBanner = 'تعذّر تشغيل الرسالة الصوتية';
      debugPrint('Voice message playback error: $e');
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

  // --- تتبع الشكاوى والمتابعة الاجتماعية (US-07-04) ---

  // فلترة الشكاوى بناءً على حالتها والبحث والدور
  List<SocialSpecialistComplaint> get filteredSocialComplaints {
    List<SocialSpecialistComplaint> list = socialComplaints;

    // التصفية بناءً على الدور (الإدارة ترى فقط الشكاوى المصعدة)
    if (currentRole == 'مدير') {
      list = list.where((c) => c.isEscalated).toList();
    }

    // الفلترة بالحالة
    if (!selectedComplaintStatus.contains('الكل')) {
      if (selectedComplaintStatus.contains('مفتوحة')) {
        list = list.where((c) => c.status == 'open').toList();
      } else if (selectedComplaintStatus.contains('جاري')) {
        list = list.where((c) => c.status == 'progress').toList();
      } else if (selectedComplaintStatus.contains('مُغلقة')) {
        list = list.where((c) => c.status == 'done').toList();
      }
    }

    // الفلترة بالبحث
    if (complaintSearchQuery.isNotEmpty) {
      list = list
          .where((c) =>
              c.title.contains(complaintSearchQuery) ||
              c.residentName.contains(complaintSearchQuery))
          .toList();
    }

    return list;
  }

  final Set<String> customAlbumNames = {};
  Map<String, String> albumCovers = {};

  List<String> get allAlbums {
    final names = <String>{
      'المسكن',
      'أسرة',
      'رحلات',
      'فيديو',
      'مناسبات',
      'الاستوديو',
      ...customAlbumNames,
      ...memoriesList.map((m) => m.category).where((c) => c.trim().isNotEmpty),
    };
    return names.toList();
  }

  void createAlbum(String name) {
    final clean = name.trim();
    if (clean.isEmpty) return;
    customAlbumNames.add(clean);
    notifyListeners();
  }

  void renameAlbum(String oldName, String newName) {
    final clean = newName.trim();
    if (clean.isEmpty || clean == oldName) return;
    if (customAlbumNames.remove(oldName)) customAlbumNames.add(clean);
    for (final item in memoriesList) {
      if (item.category == oldName) item.category = clean;
    }
    final cover = albumCovers.remove(oldName);
    if (cover != null) albumCovers[clean] = cover;
    notifyListeners();
  }

  void deleteAlbum(String name) {
    customAlbumNames.remove(name);
    albumCovers.remove(name);
    final ids =
        memoriesList.where((m) => m.category == name).map((m) => m.id).toList();
    for (final id in ids) {
      deleteMemoryItem(id, notify: false);
    }
    notifyListeners();
  }

  void setAlbumCover(String albumName, String imagePath) {
    if (albumName.trim().isEmpty || imagePath.trim().isEmpty) return;
    albumCovers[albumName] = imagePath;
    notifyListeners();
  }

  Future<void> addPhotoToAlbum(
    String albumName,
    String photoPath, {
    String type = 'image',
  }) async {
    final cleanAlbum =
        albumName.trim().isEmpty ? 'الاستوديو' : albumName.trim();
    customAlbumNames.add(cleanAlbum);
    final tempId = 'mem_album_${DateTime.now().millisecondsSinceEpoch}';
    final localItem = MemoryItem(
      id: tempId,
      category: cleanAlbum,
      title: cleanAlbum,
      date: 'اليوم',
      type: type,
      assetPath: photoPath,
    );
    memoriesList.insert(0, localItem);
    albumCovers.putIfAbsent(cleanAlbum, () => photoPath);
    notifyListeners();

    final residentId = backendResidentId;
    if (residentId == null || residentId.isEmpty || type != 'image') return;

    try {
      final uploaded = await FamilyMediaService.instance.uploadImage(
        residentId: residentId,
        image: XFile(photoPath),
        caption: cleanAlbum,
      );
      final remoteUrl = uploaded.mediaUrl;
      final idx = memoriesList.indexWhere((m) => m.id == tempId);
      if (idx != -1 && remoteUrl != null && remoteUrl.isNotEmpty) {
        memoriesList[idx] = MemoryItem(
          id: 'fb_${uploaded.id}',
          category: cleanAlbum,
          title: cleanAlbum,
          date: localItem.date,
          type: type,
          assetPath: remoteUrl,
        );
        albumCovers[cleanAlbum] = remoteUrl;
        notifyListeners();
      }
    } catch (e) {
      backendSyncError = e.toString();
      notifyListeners();
    }
  }

  void deleteMemoryItem(String id, {bool notify = true}) {
    memoriesList.removeWhere((m) => m.id == id);
    memoryMoments.removeWhere((m) => m.id == id);
    if (id.startsWith('fb_')) {
      unawaited(FamilyMediaService.instance.delete(id.substring(3)).catchError(
        (Object e) {
          backendSyncError = e.toString();
          notifyListeners();
        },
      ));
    }
    if (notify) notifyListeners();
  }

  List<dynamic> getMemoriesByCategory(String category) {
    List<dynamic> results = [];

    // Helper to strip emoji
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
  List<FamilyHealthMetric> familyHealthMetrics = [];

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

  List<FamilyVisit> familyVisits = [];

  List<FamilyBill> familyBills = [];

  // --- SPECIALIST FILES STATE ---
  List<SpecialistResidentFile> residentFiles = [];

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
  List<MedicalSession> medicalSessions = [];

  List<MedicalPrescription> medicalPrescriptions = [];

  List<Review> reviews = [];

  List<SentReport> sentReports = [];

  Future<void> addMedication(String residentName, Medication med) async {
    final residentId = _residentIdForName(residentName);
    if (residentId == null) {
      backendSyncError = 'لا يوجد residentId من AWS لهذا المقيم';
      notifyListeners();
      return;
    }
    final synced = await _runBackendMutation(() {
      return BackendMutationService.instance.createMedicationSchedule(
        residentId: residentId,
        medication: med,
      );
    });
    if (!synced) return;
    medications.insert(0, med);

    // إرسال إشعار للأسرة عند إضافة دواء جديد
    triggerNotification(
      title: 'تمت إضافة جرعة دواء جديدة 💊',
      body:
          'قام فريق التمريض بإضافة دواء (${med.name}) لخطة $residentName العلاجية.',
      type: 'medical',
      targetRole: 'عائلة',
    );

    notifyListeners();
  }

  Future<void> logMedicalSession(MedicalSession session) async {
    final residentId = _residentIdForName(session.residentName);
    if (residentId == null) {
      backendSyncError = 'لا يوجد residentId من AWS لهذا المقيم';
      notifyListeners();
      return;
    }
    final synced = await _runBackendMutation(() {
      return BackendMutationService.instance.createMedicalSession(
        residentId: residentId,
        session: session,
      );
    });
    if (!synced) return;
    medicalSessions.insert(0, session);
    notifyListeners();
  }

  Future<void> addPrescription(MedicalPrescription p) async {
    final residentId = _residentIdForName(p.residentName);
    if (residentId == null) {
      backendSyncError = 'لا يوجد residentId من AWS لهذا المقيم';
      notifyListeners();
      return;
    }
    final synced = await _runBackendMutation(() {
      return BackendMutationService.instance.createPrescription(
        residentId: residentId,
        prescription: p,
      );
    });
    if (!synced) return;
    medicalPrescriptions.insert(0, p);

    // إرسال إشعار للأسرة عند إضافة روشتة طبية جديدة
    triggerNotification(
      title: 'روشتة طبية جديدة 📄',
      body:
          'تمت إضافة روشتة طبية جديدة لـ ${p.residentName} بواسطة ${p.doctorName}.',
      type: 'medical',
      targetRole: 'عائلة',
    );

    notifyListeners();
  }

  // --- ADMIN STATE ---
  List<CenterOperationalStat> get adminStats {
    return [
      CenterOperationalStat(
          label: 'المقيمون',
          value: '${residentFiles.length}',
          trend: 'من AWS',
          isPositive: true,
          history: [residentFiles.length.toDouble()]),
      CenterOperationalStat(
          label: 'الأدوية النشطة',
          value: '${medications.length}',
          trend: 'من AWS',
          isPositive: true,
          history: [medications.length.toDouble()]),
      CenterOperationalStat(
          label: 'الحالات الحرجة',
          value: '$criticalResidentsCount',
          trend: 'من AWS',
          isPositive: criticalResidentsCount <= 2,
          history: [criticalResidentsCount.toDouble()]),
      CenterOperationalStat(
          label: 'الشكاوى المفتوحة',
          value: '$unresolvedComplaintsCount',
          trend: 'من AWS',
          isPositive: unresolvedComplaintsCount == 0,
          history: [unresolvedComplaintsCount.toDouble()]),
    ];
  }

  List<StaffPerformance> staffPerformanceList = [];

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
    backendSyncError =
        'إضافة موظف تتم من createAccount لأنها تحتاج بريد وكلمة مرور لحساب Cognito';
    notifyListeners();
  }

  Future<void> joinOpportunity(String opportunityId) async {
    final idx = volunteerOpportunities.indexWhere((o) => o.id == opportunityId);
    if (idx != -1) {
      final synced = await _runBackendMutation(() {
        return BackendMutationService.instance
            .createVolunteerBooking(opportunityId);
      });
      if (!synced) return;
      final opp = volunteerOpportunities[idx];

      // Add to bookings if not already there
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

        // Update slots instead of removing
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

        // Trigger a real notification
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

  Future<void> cancelBooking(String bookingId) async {
    final idx = volunteerBookings.indexWhere((b) => b.id == bookingId);
    if (idx != -1) {
      final synced = await _runBackendMutation(() {
        return BackendMutationService.instance
            .cancelVolunteerBooking(bookingId);
      });
      if (!synced) return;
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

  Future<void> confirmAttendance(String bookingId) async {
    final idx = volunteerBookings.indexWhere((b) => b.id == bookingId);
    if (idx != -1) {
      final synced = await _runBackendMutation(() {
        return BackendMutationService.instance
            .confirmVolunteerAttendance(bookingId);
      });
      if (!synced) return;
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

  Future<void> submitBookingRating(String bookingId) async {
    final idx = volunteerBookings.indexWhere((b) => b.id == bookingId);
    if (idx != -1) {
      final b = volunteerBookings[idx];
      final synced = await _runBackendMutation(() {
        return BackendMutationService.instance.createVolunteerReview(
          toName: b.title,
          session: b.timeInfo,
          score: 5,
        );
      });
      if (!synced) return;
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

  Future<void> saveMedicalVitals({
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
    if (backendSyncError != null) return;

    final newSession = MedicalSession(
      id: 's${DateTime.now().millisecondsSinceEpoch}',
      type: 'vitals',
      specialistName: currentAccount?.name.isNotEmpty == true
          ? currentAccount!.name
          : 'الممرض/ة',
      time: 'الآن',
      date: 'اليوم',
      notes:
          'تم فحص المؤشرات الحيوية: الضغط ($bp)، السكر ($sugar مجم/دل)، الحرارة ($temp°)',
      residentName: residentName,
    );

    medicalSessions.insert(0, newSession);

    // Trigger a real notification
    triggerNotification(
      title: 'تم حفظ القراءات 🏥',
      body: 'تم تسجيل العلامات الحيوية لـ $residentName بنجاح.',
      type: 'medical',
    );

    notifyListeners(); // Ensure UI updates
  }

  Future<void> addFamilyVisit(FamilyVisit visit) async {
    final residentId = _looksLikeBackendId(backendResidentId)
        ? backendResidentId
        : residentFiles.isNotEmpty
            ? residentFiles.first.id
            : null;
    if (residentId == null) {
      backendSyncError = 'لا يوجد residentId من AWS لحجز الزيارة';
      notifyListeners();
      return;
    }
    final synced = await _runBackendMutation(() {
      return BackendMutationService.instance.bookVisit(
        residentId: residentId,
        visit: visit,
      );
    });
    if (!synced) return;
    familyVisits.insert(0, visit);
    notifyListeners();
  }

  Future<void> approveVisit(String id) async {
    final idx = familyVisits.indexWhere((v) => v.id == id);
    if (idx != -1) {
      final synced = await _runBackendMutation(() {
        return FamilyBridgeService.instance
            .updateVisitStatus(id, 'approved')
            .then((_) {});
      });
      if (!synced) return;
      familyVisits[idx] = familyVisits[idx].copyWith(status: 'upcoming');
      notifyListeners();
    }
  }

  Future<void> rejectVisit(String id) async {
    final idx = familyVisits.indexWhere((v) => v.id == id);
    if (idx != -1) {
      final synced = await _runBackendMutation(() {
        return FamilyBridgeService.instance
            .updateVisitStatus(id, 'rejected')
            .then((_) {});
      });
      if (!synced) return;
      familyVisits[idx] = familyVisits[idx].copyWith(status: 'cancelled');
      notifyListeners();
    }
  }

  Future<void> sendFamilyMessage(String message, String residentName) async {
    await submitComplaint(message, 'رسالة من الأهل', 'أسرة');
    triggerNotification(
      title: 'رسالة من الأهل 📩',
      body: 'بخصوص $residentName: $message',
      type: 'complaint',
      targetRole: 'أخصائي',
    );
    notifyListeners();
  }

  Future<void> clearUnpaidBills() async {
    final unpaidBills = familyBills.where((b) => !b.isPaid).toList();
    for (final bill in unpaidBills) {
      final synced = await _runBackendMutation(() {
        return BackendMutationService.instance.payBill(bill.id);
      });
      if (!synced) return;
    }
    familyBills = familyBills.map((b) => b.copyWith(isPaid: true)).toList();
    notifyListeners();
  }

  Future<void> addSocialNeed(SocialSpecialistNeed need) async {
    final synced = await _runBackendMutation(() {
      return BackendMutationService.instance.createSocialNeed(need);
    });
    if (!synced) return;
    socialNeeds.insert(0, need);

    triggerNotification(
      title: 'احتياج جديد مسجل 🛡️',
      body: 'تم تسجيل احتياج ${need.type} للغرفة ${need.roomNumber}.',
      type: 'specialist',
      targetRole: 'أخصائي',
    );

    notifyListeners();
  }

  Future<void> updateResident(SpecialistResidentFile resident) async {
    final synced = await _runBackendMutation(() {
      return BackendMutationService.instance.updateResident(resident);
    });
    if (!synced) return;
    final index = residentFiles.indexWhere((r) => r.id == resident.id);
    if (index != -1) {
      residentFiles[index] = resident;
      notifyListeners();
    }
  }

  Future<void> addResident(SpecialistResidentFile resident) async {
    final synced = await _runBackendMutation(() {
      return BackendMutationService.instance.createResident(resident);
    });
    if (!synced) return;
    residentFiles.insert(0, resident);

    // Notify Admin and Specialist roles about the new resident
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

  // --- ANALYTICS & COMPLAINT RESOLUTION ---

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
      if (backendSyncError != null) return;

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

      // Notify the family (simulated by triggering a notification for 'أهل' role)
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

  int totalCapacity = 0;

  double get occupancyRate {
    if (totalCapacity == 0) return 0.0;
    return residentFiles.length / totalCapacity;
  }

  String generatePerformanceSummary() {
    final compliance = (medicationComplianceRate * 100).toInt();
    final occupancy = (occupancyRate * 100).toInt();
    return '''
ملخص أداء دار طبطبة للرعاية
التاريخ: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}

1. الإشغال: $occupancy%
2. الالتزام الدوائي: $compliance%
3. الشكاوى المفتوحة: $unresolvedComplaintsCount شكاوى
4. الطاقم النشط: $activeStaffCount من أصل $totalStaffCount موظف
''';
  }

  Future<String> exportReport(String format) async {
    if (format == 'pdf') {
      final pdf = pw.Document();
      final now = DateTime.now();
      final timeStr = "${now.hour}:${now.minute.toString().padLeft(2, '0')}";
      final dateStr = "${now.day}/${now.month}/${now.year}";

      // تحميل الخط العربي لضمان ظهوره بشكل صحيح
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

              // بيانات التقرير الأساسية
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
                // في RTL بمكتبة PDF، العمود الأول يكون هو اللي على اليمين
                // لذا سنضع المؤشر أولاً ثم القيمة
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

              pw.Spacer(), // دفع التوقيع للأسفل

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
      // إنشاء محتوى CSV الاحترافي
      final csvBuffer = StringBuffer();
      // إضافة BOM لدعم اللغة العربية في Excel
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

      final encodedCsv = Uri.encodeComponent(csvBuffer.toString());
      final url = 'data:text/csv;charset=utf-8,$encodedCsv';

      try {
        final uri = Uri.parse(url);
        // نستخدم launchUrl مباشرة لأن بعض المتصفحات تمنع canLaunchUrl مع البيانات الطويلة
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      } catch (e) {
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

  List<MemoryMoment> memoryMoments = [];

  Future<void> addMemoryMoment(MemoryMoment moment) async {
    final synced = await _runBackendMutation(() {
      return BackendMutationService.instance.createMemory(
        residentId: moment.residentId,
        moment: moment,
      );
    });
    if (!synced) return;
    memoryMoments.insert(0, moment);

    // إرسال إشعار للعائلة
    triggerNotification(
      title: 'لحظة سعادة جديدة 📸',
      body:
          'والدكم ${moment.residentName} يستمتع بوقته الآن في "${moment.activityTitle}".',
      type: 'social',
      targetRole: 'أهل',
    );

    // إضافة الذكرى لشاشة ذكريات المسن
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

  void insertFamilyBridgeMoment(MemoryMoment moment) {
    if (memoryMoments.any((m) => m.id == moment.id)) return;
    memoryMoments.insert(0, moment);
    if (!memoriesList.any((m) => m.id == moment.id)) {
      memoriesList.insert(
        0,
        MemoryItem(
          id: moment.id,
          category: 'أسرة',
          title: moment.activityTitle,
          date: moment.date,
          type: 'image',
          assetPath: moment.imageUrl,
        ),
      );
    }
    notifyListeners();
  }

  Future<void> deleteMemoryMoment(String id) async {
    final synced = await _runBackendMutation(() {
      return BackendMutationService.instance.deleteMemory(id);
    });
    if (!synced) return;
    memoryMoments.removeWhere((m) => m.id == id);
    memoriesList.removeWhere((m) => m.id == id);
    notifyListeners();
  }

  Future<void> addAppreciation(String momentId) async {
    final idx = memoryMoments.indexWhere((m) => m.id == momentId);
    if (idx != -1) {
      final synced = await _runBackendMutation(() {
        return BackendMutationService.instance.appreciateMemory(momentId);
      });
      if (!synced) return;
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

      // Notify specialist about the appreciation (Bonus)
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

  // --- NAVIGATION (ELDERLY) ---

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
      // Fetch real images from gallery
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

  // Volunteer Profile Methods
  Future<void> updateVolunteerProfile(VolunteerProfile newProfile) async {
    final synced = await _runBackendMutation(() {
      return BackendMutationService.instance.updateVolunteerProfile(newProfile);
    });
    if (!synced) return;
    volunteerProfile = newProfile;
    notifyListeners();
  }

  Future<void> addVolunteerSkill(String skill) async {
    if (!volunteerProfile.skills.contains(skill)) {
      final updatedSkills = List<String>.from(volunteerProfile.skills)
        ..add(skill);
      await updateVolunteerProfile(
        volunteerProfile.copyWith(skills: updatedSkills),
      );
    }
  }

  Future<void> removeVolunteerSkill(String skill) async {
    final updatedSkills = List<String>.from(volunteerProfile.skills)
      ..remove(skill);
    await updateVolunteerProfile(
        volunteerProfile.copyWith(skills: updatedSkills));
  }

  Future<void> uploadVolunteerDocument(String type, String fileName) async {
    var nextProfile = volunteerProfile;
    if (type == 'cv') {
      nextProfile = volunteerProfile.copyWith(cvFileName: fileName);
    } else if (type == 'recommendation') {
      nextProfile = volunteerProfile.copyWith(recommendationFileName: fileName);
    }
    volunteerProfile = nextProfile;
    notifyListeners();

    await triggerNotification(
      title: 'تم رفع الملف بنجاح 📁',
      body: 'تم تسجيل ملف "$fileName" كـ $type في ملفك الشخصي.',
      type: 'admin',
      targetRole: 'متطوع',
    );
  }

  // --- FAMILY INTERACTION METHODS ---
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
    isIncomingCall = false; // Close incoming banner if we start a call
    notifyListeners();

    if (AuthService.instance.currentUser == null) {
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
    final id = activeVideoCallId;
    if (id != null) {
      unawaited(_updateActiveVideoCallStatus(id, 'accepted'));
    }
    if ((activeVideoCallJoinUrl ?? '').isNotEmpty) {
      unawaited(launchZoom(activeVideoCallJoinUrl));
    }
  }

  void rejectCall() {
    isIncomingCall = false;
    notifyListeners();
    final id = activeVideoCallId;
    if (id != null) {
      unawaited(_updateActiveVideoCallStatus(id, 'rejected'));
      activeVideoCallId = null;
      activeVideoCallJoinUrl = null;
    }
  }

  void endVideoCall() {
    isVideoCallActive = false;
    notifyListeners();
    final id = activeVideoCallId;
    if (id != null) {
      unawaited(_updateActiveVideoCallStatus(id, 'ended'));
      activeVideoCallId = null;
      activeVideoCallJoinUrl = null;
    }
  }

  Future<void> _updateActiveVideoCallStatus(String id, String status) async {
    if (AuthService.instance.currentUser == null) return;
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
      audioUrl: audioPath,
      durationSeconds: durationSeconds,
    );
    voiceMessagesList.insert(0, newMsg);

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
  List<CareTask> careTasks = [];

  List<InventoryItem> inventoryItems = [];

  List<DoctorVisit> doctorVisits = [];

  List<MealPlan> mealPlans = [];

  List<ActivitySession> activitySessions = [];

  // Nursing Operations Methods
  Future<void> toggleCareTask(String id) async {
    final idx = careTasks.indexWhere((t) => t.id == id);
    if (idx != -1) {
      final synced = await _runBackendMutation(() {
        return careTasks[idx].isCompleted
            ? BackendMutationService.instance.reopenCareTask(id)
            : BackendMutationService.instance.completeCareTask(id);
      });
      if (!synced) return;
      careTasks[idx].isCompleted = !careTasks[idx].isCompleted;
      notifyListeners();
    }
  }

  Future<void> addCareTask(CareTask task) async {
    final residentId = _residentIdForName(task.residentName);
    if (residentId == null) {
      backendSyncError = 'لا يوجد residentId من AWS لهذا المقيم';
      notifyListeners();
      return;
    }
    final synced = await _runBackendMutation(() {
      return BackendMutationService.instance.createCareTask(
        residentId: residentId,
        task: task,
      );
    });
    if (!synced) return;
    careTasks.add(task);
    notifyListeners();
  }

  void deleteCareTask(String id) {
    _runBackendMutation(() {
      return BackendMutationService.instance.deleteCareTask(id);
    }).then((synced) {
      if (!synced) return;
      careTasks.removeWhere((t) => t.id == id);
      notifyListeners();
    });
  }

  Future<void> deleteCareTaskAsync(String id) async {
    final synced = await _runBackendMutation(() {
      return BackendMutationService.instance.deleteCareTask(id);
    });
    if (!synced) return;
    careTasks.removeWhere((t) => t.id == id);
    notifyListeners();
  }

  Future<void> addInventoryItem(InventoryItem item) async {
    final synced = await _runBackendMutation(() {
      return BackendMutationService.instance.createInventoryItem(item);
    });
    if (!synced) return;
    inventoryItems.add(item);
    notifyListeners();
  }

  void deleteInventoryItem(String id) {
    _runBackendMutation(() {
      return BackendMutationService.instance.deleteInventoryItem(id);
    }).then((synced) {
      if (!synced) return;
      inventoryItems.removeWhere((i) => i.id == id);
      notifyListeners();
    });
  }

  Future<void> deleteInventoryItemAsync(String id) async {
    final synced = await _runBackendMutation(() {
      return BackendMutationService.instance.deleteInventoryItem(id);
    });
    if (!synced) return;
    inventoryItems.removeWhere((i) => i.id == id);
    notifyListeners();
  }

  Future<void> addDoctorVisit(DoctorVisit visit) async {
    final residentId = _residentIdForName(visit.residentName);
    if (residentId == null) {
      backendSyncError = 'لا يوجد residentId من AWS لهذا المقيم';
      notifyListeners();
      return;
    }
    final synced = await _runBackendMutation(() {
      return BackendMutationService.instance.createDoctorVisit(
        residentId: residentId,
        visit: visit,
      );
    });
    if (!synced) return;
    doctorVisits.add(visit);
    notifyListeners();
  }

  void deleteDoctorVisit(String id) {
    _runBackendMutation(() {
      return BackendMutationService.instance.deleteDoctorVisit(id);
    }).then((synced) {
      if (!synced) return;
      doctorVisits.removeWhere((v) => v.id == id);
      notifyListeners();
    });
  }

  Future<void> deleteDoctorVisitAsync(String id) async {
    final synced = await _runBackendMutation(() {
      return BackendMutationService.instance.deleteDoctorVisit(id);
    });
    if (!synced) return;
    doctorVisits.removeWhere((v) => v.id == id);
    notifyListeners();
  }

  Future<void> addMealPlan(MealPlan plan) async {
    final residentId = _residentIdForName(plan.residentName);
    if (residentId == null) {
      backendSyncError = 'لا يوجد residentId من AWS لهذا المقيم';
      notifyListeners();
      return;
    }
    final synced = await _runBackendMutation(() {
      final mealPlanId = mealPlanIdsByResidentName[plan.residentName];
      if (mealPlanId != null) {
        return BackendMutationService.instance.updateMealPlan(
          id: mealPlanId,
          plan: plan,
        );
      }
      return BackendMutationService.instance
          .createMealPlan(residentId: residentId, plan: plan);
    });
    if (!synced) return;
    mealPlans.add(plan);
    notifyListeners();
  }

  Future<void> deleteMealPlan(String residentName) async {
    final mealPlanId = mealPlanIdsByResidentName[residentName];
    if (mealPlanId == null) {
      backendSyncError = 'لا يوجد mealPlanId من AWS لهذا المقيم';
      notifyListeners();
      return;
    }
    final synced = await _runBackendMutation(() {
      return BackendMutationService.instance.deleteMealPlan(mealPlanId);
    });
    if (!synced) return;
    mealPlans.removeWhere((p) => p.residentName == residentName);
    mealPlanIdsByResidentName.remove(residentName);
    notifyListeners();
  }

  Future<void> addActivitySession(ActivitySession session) async {
    final synced = await _runBackendMutation(() {
      return BackendMutationService.instance.createActivity(Activity(
        id: session.id,
        name: session.title,
        emoji: '',
        location: session.location,
        time: '${session.startTime.hour}:${session.startTime.minute}',
        status: 'coming',
        badges: session.description,
        pointsReward: 0,
      ));
    });
    if (!synced) return;
    activitySessions.add(session);
    notifyListeners();
  }

  void deleteActivitySession(String id) {
    _runBackendMutation(() {
      return BackendMutationService.instance.deleteActivity(id);
    }).then((synced) {
      if (!synced) return;
      activitySessions.removeWhere((s) => s.id == id);
      activities.removeWhere((a) => a.id == id);
      notifyListeners();
    });
  }

  Future<void> deleteActivitySessionAsync(String id) async {
    final synced = await _runBackendMutation(() {
      return BackendMutationService.instance.deleteActivity(id);
    });
    if (!synced) return;
    activitySessions.removeWhere((s) => s.id == id);
    activities.removeWhere((a) => a.id == id);
    notifyListeners();
  }

  void deleteMedicalSession(String id) {
    _runBackendMutation(() {
      return BackendMutationService.instance.deleteMedicalSession(id);
    }).then((synced) {
      if (!synced) return;
      medicalSessions.removeWhere((s) => s.id == id);
      notifyListeners();
    });
  }

  Future<void> deleteMedicalSessionAsync(String id) async {
    final synced = await _runBackendMutation(() {
      return BackendMutationService.instance.deleteMedicalSession(id);
    });
    if (!synced) return;
    medicalSessions.removeWhere((s) => s.id == id);
    notifyListeners();
  }

  void deletePrescription(String id) {
    _runBackendMutation(() {
      return BackendMutationService.instance.deletePrescription(id);
    }).then((synced) {
      if (!synced) return;
      medicalPrescriptions.removeWhere((p) => p.id == id);
      notifyListeners();
    });
  }

  Future<void> deletePrescriptionAsync(String id) async {
    final synced = await _runBackendMutation(() {
      return BackendMutationService.instance.deletePrescription(id);
    });
    if (!synced) return;
    medicalPrescriptions.removeWhere((p) => p.id == id);
    notifyListeners();
  }

  Future<void> addSentReport(SentReport report) async {
    final synced = await _runBackendMutation(() {
      return BackendMutationService.instance.sendNursingReport(
        reportType: report.title,
        recipients: const [],
      );
    });
    if (!synced) return;
    sentReports.insert(0, report);
    notifyListeners();
  }

  Future<void> addReview(Review review) async {
    final synced = await _runBackendMutation(() {
      return BackendMutationService.instance.createVolunteerReview(
        toName: review.toRole,
        session: review.comment,
        score: review.rating,
      );
    });
    if (!synced) return;
    notifyListeners();
  }

  Future<void> addHandoff(ShiftHandoff handoff) async {
    final synced = await _runBackendMutation(() {
      return BackendMutationService.instance.createHandoff(handoff);
    });
    if (!synced) return;
    handoffs.insert(0, handoff);
    notifyListeners();
  }

  Future<void> updateInventoryStock(String id, int change) async {
    final idx = inventoryItems.indexWhere((i) => i.id == id);
    if (idx != -1) {
      final nextStock = inventoryItems[idx].currentStock + change;
      final synced = await _runBackendMutation(() {
        return BackendMutationService.instance.updateInventoryStock(
          id: id,
          currentStock: nextStock < 0 ? 0 : nextStock,
        );
      });
      if (!synced) return;
      final newItem = InventoryItem(
        id: inventoryItems[idx].id,
        name: inventoryItems[idx].name,
        category: inventoryItems[idx].category,
        currentStock: nextStock < 0 ? 0 : nextStock,
        minRequired: inventoryItems[idx].minRequired,
        unit: inventoryItems[idx].unit,
      );
      inventoryItems[idx] = newItem;
      notifyListeners();
    }
  }

  Future<void> updateMealPlan(MealPlan plan) async {
    final residentId = _residentIdForName(plan.residentName);
    if (residentId == null) {
      backendSyncError = 'لا يوجد residentId من AWS لهذا المقيم';
      notifyListeners();
      return;
    }
    final synced = await _runBackendMutation(() {
      return BackendMutationService.instance.createMealPlan(
        residentId: residentId,
        plan: plan,
      );
    });
    if (!synced) return;
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
  Future<void> startIntervention(String id) async {
    final idx = socialComplaints.indexWhere((c) => c.id == id);
    if (idx != -1) {
      await _syncComplaintStatus(id, 'in_progress');
      if (backendSyncError != null) return;
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
  Future<void> saveSocialAssessment({
    required String residentId,
    required Map<String, double> newScores,
    required bool needsIntervention,
    String? notes,
  }) async {
    final synced = await _runBackendMutation(() {
      return BackendMutationService.instance.createSocialAssessment(
        residentId: residentId,
        scores: newScores,
        needsIntervention: needsIntervention,
        notes: notes,
      );
    });
    if (!synced) return;
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

      if (needsIntervention) {
        triggerNotification(
          title: 'تنبيه تدخل اجتماعي: ${r.name}',
          body: 'المقيم بحاجة لمتابعة عاجلة بناءً على التقييم الأخير.',
          type: 'social',
          targetRole: 'specialist',
        );
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
  Future<void> resolveNotification(String id) async {
    await markNotificationAsRead(id);
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
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (image == null) return;

      // إضافة فورية بالمسار المحلي عشان المستخدم يشوف الصورة على طول
      final tempId = 'mem_custom_${DateTime.now().millisecondsSinceEpoch}';
      final localItem = MemoryItem(
        id: tempId,
        category: 'الاستوديو',
        title: 'ذكرى من الاستوديو',
        date: 'اليوم',
        type: 'image',
        assetPath: image.path,
      );
      memoriesList.insert(0, localItem);
      notifyListeners();

      // محاولة رفع الصورة للسحابة لتظهر للأسرة وتبقى بعد إعادة التشغيل
      final residentId = backendResidentId;
      if (residentId == null || residentId.isEmpty) {
        debugPrint('pickMemoryImage: no resident id, kept local only');
      } else {
        try {
          final uploaded = await FamilyMediaService.instance.uploadImage(
            residentId: residentId,
            image: image,
            caption: localItem.title,
          );
          final remoteUrl = uploaded.mediaUrl;
          final idx = memoriesList.indexWhere((m) => m.id == tempId);
          if (idx != -1 && remoteUrl != null && remoteUrl.isNotEmpty) {
            memoriesList[idx] = MemoryItem(
              id: 'fb_${uploaded.id}',
              category: localItem.category,
              title: localItem.title,
              date: localItem.date,
              type: 'image',
              assetPath: remoteUrl,
            );
            notifyListeners();
          }
        } catch (e) {
          debugPrint('pickMemoryImage upload failed: $e');
        }
      }

      triggerNotification(
        title: 'تمت إضافة ذكرى جديدة! 📸',
        body: 'ستجدها الآن في صندوق ذكرياتك الجميل.',
        type: 'social',
        targetRole: 'مسن',
      );
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  // --- INTEGRATION & CROSS-ROLE REQUESTS ---

  Future<void> submitComplaint(
      String message, String type, String fromRole) async {
    BackendComplaint created;
    try {
      created = await ComplaintsService.instance.create(
        residentId: backendResidentId,
        category: _backendComplaintCategory(type),
        subject: type,
        description: message,
        priority: 'high',
      );
      backendSyncError = null;
    } catch (e) {
      backendSyncError = e.toString();
      notifyListeners();
      return;
    }

    final complaint = SocialSpecialistComplaint(
      id: created.id,
      residentName: fromRole == 'مسن' ? currentUser.name : 'أحد أفراد الأسرة',
      room: currentAccount?.room ?? '',
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
    triggerNotification(
      title: 'طلب استشارة مرسل 💬',
      body:
          'تم تحويل طلب الاستشارة الـ $type إلى الفريق المختص، سيتم التواصل معك قريباً.',
      type: 'medical',
      targetRole: 'أسرة',
    );
    notifyListeners();
  }

  Future<void> addVolunteerOpportunity(VolunteerOpportunity opp) async {
    final synced = await _runBackendMutation(() {
      return BackendMutationService.instance.createVolunteerOpportunity(opp);
    });
    if (!synced) return;
    volunteerOpportunities.insert(0, opp);

    await triggerNotification(
      title: 'تم نشر الفرصة بنجاح 🌟',
      body: 'أصبحت فرصة "${opp.title}" متاحة الآن للمتطوعين.',
      type: 'system',
      targetRole: 'إدارة',
    );

    notifyListeners();
  }

  Future<void> updateVolunteerOpportunity(VolunteerOpportunity opp) async {
    final synced = await _runBackendMutation(() {
      return BackendMutationService.instance.updateVolunteerOpportunity(opp);
    });
    if (!synced) return;
    final index = volunteerOpportunities.indexWhere((o) => o.id == opp.id);
    if (index != -1) {
      volunteerOpportunities[index] = opp;
      notifyListeners();
    }
  }

  Future<void> deleteVolunteerOpportunity(String id) async {
    final synced = await _runBackendMutation(() {
      return BackendMutationService.instance.deleteVolunteerOpportunity(id);
    });
    if (!synced) return;
    volunteerOpportunities.removeWhere((o) => o.id == id);
    notifyListeners();
  }

  void setShowSpecialistNeedMap(bool value) {
    if (showSpecialistNeedMap == value) return;
    showSpecialistNeedMap = value;
    notifyListeners();
  }

  void rateVolunteerSession(String volunteerId, int ratingScore,
      {String comment = ''}) {
    // تقييم المتطوع من قِبل المسن (ratingScore: 1 لغير سعيد، 2 لعادي، 3 لسعيد)
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
    String title =
        messageType == 'voice' ? 'رسالة صوتية جديدة 🎤' : 'رسالة من العائلة ✉️';
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
    notifyListeners();
  }

  void sendMedicationReminder(String medName) {
    String title = 'تذكير بموعد الدواء 💊';
    String body =
        'عائلتك تذكرك بموعد أخذ $medName. نتمنى لك دوام الصحة والعافية!';

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

  Future<void> toggleMedicationTaken(String id) async {
    final index = medications.indexWhere((m) => m.id == id);
    if (index != -1) {
      final med = medications[index];
      bool newState = !medications[index].isTaken;
      await _syncMedicationDose(med, newState ? 'given' : 'pending');
      if (backendSyncError != null) return;
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
  List<CareReport> careReports = [];

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
  List<ChatMessage> specialistChatHistory = [];
  BackendUserSummary? specialistChatUser;
  bool isLoadingSpecialistChat = false;

  Future<void> loadSpecialistThread({
    String? otherUserId,
    String? otherUserName,
    String? otherUserRole,
  }) async {
    if (AuthService.instance.currentUser == null) return;
    isLoadingSpecialistChat = true;
    notifyListeners();

    try {
      if (otherUserId != null && otherUserId.isNotEmpty) {
        specialistChatUser = BackendUserSummary(
          id: otherUserId,
          name: (otherUserName != null && otherUserName.isNotEmpty)
              ? otherUserName
              : 'فريق الرعاية',
          email: '',
          role: (otherUserRole != null && otherUserRole.isNotEmpty)
              ? otherUserRole
              : 'ClinicalStaff',
        );
      } else if (specialistChatUser == null) {
        final inbox = await MessagesService.instance.inbox();
        final users = await MessagesService.instance.clinicalUsers();
        if (inbox.isNotEmpty) {
          final recent = inbox.first;
          BackendUserSummary? matchedUser;
          for (final user in users) {
            if (user.id == recent.otherUserId) {
              matchedUser = user;
              break;
            }
          }
          specialistChatUser = matchedUser ??
              BackendUserSummary(
                id: recent.otherUserId,
                name: recent.otherUserName.isNotEmpty
                    ? recent.otherUserName
                    : 'فريق الرعاية',
                email: '',
                role: recent.otherUserRole.isNotEmpty
                    ? recent.otherUserRole
                    : 'ClinicalStaff',
              );
        }
        if (users.isNotEmpty) {
          specialistChatUser ??= users.firstWhere(
            (u) => u.role == 'ClinicalStaff',
            orElse: () => users.first,
          );
        }
      }

      final target = specialistChatUser;
      if (target == null || target.id.isEmpty) {
        specialistChatHistory = const [];
        backendSyncError = 'لا يوجد أخصائي متاح للمحادثة حالياً';
        return;
      }

      final messages = await MessagesService.instance.thread(target.id);
      if (messages.isNotEmpty) {
        await MessagesService.instance.markThreadRead(target.id);
      }
      specialistChatHistory = messages
          .map((m) => ChatMessage(
                id: m.id,
                text: m.body,
                isFromMe: m.senderId == backendUserId,
                timestamp: DateTime.tryParse(m.createdAt) ?? DateTime.now(),
                mediaPath: m.mediaUrl,
                mediaType: m.mediaType,
              ))
          .toList();
      backendSyncError = null;
    } catch (e) {
      backendSyncError = e.toString();
    } finally {
      isLoadingSpecialistChat = false;
      notifyListeners();
    }
  }

  Future<void> sendSpecialistMessage(String text,
      {String? mediaPath, String? mediaType}) async {
    final trimmedText = text.trim();
    final hasMedia = mediaPath != null && mediaPath.isNotEmpty;
    if (trimmedText.isEmpty && !hasMedia) {
      return;
    }
    if (trimmedText.isEmpty && hasMedia) {
      backendSyncError =
          'إرسال الوسائط في المحادثة غير مدعوم من الباك اند حالياً';
      notifyListeners();
      return;
    }

    if (specialistChatUser == null) {
      await loadSpecialistThread();
    }

    final target = specialistChatUser;
    if (target == null || target.id.isEmpty) return;

    try {
      final message = await MessagesService.instance.send(
        recipientId: target.id,
        body: trimmedText,
      );
      specialistChatHistory.add(ChatMessage(
        id: message.id,
        text: message.body,
        isFromMe: true,
        timestamp: DateTime.tryParse(message.createdAt) ?? DateTime.now(),
      ));
      backendSyncError = null;
    } catch (e) {
      backendSyncError = e.toString();
    }
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
