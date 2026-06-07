import 'dart:async';
import 'dart:convert';
import 'dart:io';

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

import 'package:flutter_tts/flutter_tts.dart';
import 'package:audioplayers/audioplayers.dart';

import '../config/api_config.dart';
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
import '../services/messages_service.dart';
import '../services/profile_image_service.dart';
import 'package:path_provider/path_provider.dart';

// أجزاء AppRiverpod المقسّمة حسب الدومين (extensions داخل ملفات part).
part 'app_riverpod_memories.dart';
part 'app_riverpod_facility.dart';
part 'app_riverpod_residents_family.dart';
part 'app_riverpod_staff_reports.dart';
part 'app_riverpod_nursing_ops.dart';
part 'app_riverpod_family_reminders.dart';
part 'app_riverpod_assessments.dart';
part 'app_riverpod_memory_wall.dart';
part 'app_riverpod_elderly_media.dart';

final appRiverpod = ChangeNotifierProvider((ref) => AppRiverpod());

class AppRiverpod extends ChangeNotifier {
  int selectedIndex = 0;
  int currentAdminTabIndex = 0;

  void refreshState() {
    notifyListeners();
  }

  void setAdminTabIndex(int index) {
    currentAdminTabIndex = index;
    notifyListeners();
  }

  String facilityName = ''; // اسم المنشأة من السيرفر
  String managerName = ''; // اسم المدير من السيرفر
  String splashStatus = ''; // حالة التحميل للعرض في شاشة البداية
  Set<String> earnedBadgeIds = {}; // معرّفات الأوسمة التي فتحها المسن
  BadgeDefinition?
      newlyUnlockedBadge; // آخر وسام انفتح — يُمسح بعد عرض الاحتفال

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

  String currentRole = ''; // الدور الحالي للمستخدم بعد تسجيل الدخول من السيرفر
  bool hasSeenOnboarding = false; // هل شاهد المستخدم شاشات الترحيب؟
  bool isAuthenticated = false; // هل المستخدم مسجل دخوله؟
  bool isInitialized = false; // هل تم تحميل البيانات من الذاكرة؟
  double fontScaleFactor = 1.0; // حجم الخط المختار لسهولة القراءة
  bool isHighContrast = false; // تفعيل وضع التباين العالي
  bool isDarkMode = false; // تفعيل الوضع الليلي
  bool isBiometricEnabled = false; // تفعيل تسجيل الدخول البيومتري

  final _storage = const FlutterSecureStorage(); // إنشاء كائن التخزين الآمن
  bool isRefreshingSession = false;
  String selectedAdminDateFilter = 'اليوم';
  DateTime? _sessionExpiry;

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
      final updatedAccount = currentAccount!.copyWith(imageUrl: image.path);
      updateCurrentAccount(updatedAccount);
    }
  }

  // دالة للمدير لإنشاء حسابات جديدة عبر السيرفر.
  Future<bool> createAccount({
    required String name,
    required String email,
    required String password,
    required String role,
  }) async {
    final synced = await _runBackendMutation(() {
      return BackendMutationService.instance.createManagedUser(
        email: email,
        fullName: name,
        role: role,
        temporaryPassword: password,
      );
    });
    if (synced) {
      unawaited(syncBackendData());
    }
    return synced;
  }

  // دالة للتسجيل الذاتي (للمتطوعين والأهالي) عبر السيرفر.
  Future<void> selfRegister({
    required String name,
    required String email,
    required String password,
    required String role,
  }) async {
    final facilityId = _registrationFacilityId();
    if (facilityId.isEmpty) {
      throw ApiException(
        400,
        'لا يوجد FACILITY_ID مضبوط للتسجيل الذاتي على السيرفر',
      );
    }

    await AuthService.instance.register(
      email: email,
      password: password,
      name: name,
      role: _selfRegistrationRole(role),
      facilityId: facilityId,
    );
    backendSyncError = null;
    notifyListeners();
  }

  // دالة تسجيل المدير مع بيانات المنشأة عبر السيرفر.
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
    final setupSecret = ApiConfig.adminRegistrationSecret.trim();
    if (setupSecret.isEmpty) {
      throw ApiException(
        400,
        'ADMIN_REG_SECRET غير مضبوط، لا يمكن تسجيل مدير منشأة على السيرفر',
      );
    }

    await AuthService.instance.registerAdmin(
      name: name,
      email: email,
      password: password,
      facilityId: _facilityIdForAdminRegistration(
        email: email,
        licenseNumber: facilityLicenseNumber,
      ),
      setupSecret: setupSecret,
      facilityName: facilityName,
      facilityAddress: facilityAddress,
      licenseNumber: facilityLicenseNumber,
      facilityYearOfEst: facilityYearOfEst,
      facilityCapacity: facilityCapacity,
      facilityLocationUrl: facilityLocationUrl,
    );

    this.facilityName = facilityName;
    managerName = name;
    backendSyncError = null;

    notifyListeners();
  }

  // ربط عائلة بمسن
  Future<bool> linkFamilyToResident(
      String residentId, String familyEmail) async {
    final synced = await _runBackendMutation(() {
      return BackendMutationService.instance.createFamilyMemberForEmail(
        residentId: residentId,
        email: familyEmail,
      );
    });
    if (!synced) return false;
    final idx = residentFiles.indexWhere((r) => r.id == residentId);
    if (idx != -1) {
      final r = residentFiles[idx];
      residentFiles[idx] = r.copyWith(familyEmail: familyEmail);
      notifyListeners();
    }
    unawaited(syncBackendData());
    return true;
  }

  void updateResidentSocialHistory({
    required String residentId,
    required String previousProfession,
    required String socialStatus,
    required List<String> hobbies,
  }) {
    final idx = residentFiles.indexWhere((r) => r.id == residentId);
    if (idx == -1) return;
    final r = residentFiles[idx];
    residentFiles[idx] = r.copyWith(
      previousProfession: previousProfession,
      hobbies: hobbies,
      socialStatus: socialStatus,
    );
    notifyListeners();
  }

  void setDocumentsForResident(String residentId, List<String> documentUrls) {
    final idx = residentFiles.indexWhere((r) => r.id == residentId);
    if (idx == -1) return;
    final r = residentFiles[idx];
    residentFiles[idx] = r.copyWith(uploadedDocuments: documentUrls);
    notifyListeners();
  }

  void addDocumentToResident(String residentId, String documentUrl) {
    final idx = residentFiles.indexWhere((r) => r.id == residentId);
    if (idx == -1) return;
    final r = residentFiles[idx];
    final updated = List<String>.from(r.uploadedDocuments ?? [])
      ..add(documentUrl);
    residentFiles[idx] = r.copyWith(uploadedDocuments: updated);
    notifyListeners();
  }

  Future<bool> deleteFamilyMemberFromResident({
    required String residentId,
    required FamilyMember member,
  }) async {
    final residentIndex = residentFiles.indexWhere((r) => r.id == residentId);
    final previousResident =
        residentIndex == -1 ? null : residentFiles[residentIndex];

    if (previousResident != null) {
      final updatedMembers = previousResident.familyMembers
          .where((m) => m.id != member.id)
          .toList();
      residentFiles[residentIndex] =
          previousResident.copyWith(familyMembers: updatedMembers);
    }
    final globalIndex = familyMembersList.indexWhere((m) => m.id == member.id);
    FamilyMember? previousGlobal;
    if (globalIndex != -1) {
      previousGlobal = familyMembersList[globalIndex];
      familyMembersList.removeAt(globalIndex);
    }
    notifyListeners();

    final synced = await _runBackendMutation(() {
      return BackendMutationService.instance.deleteFamilyMember(member.id);
    });
    if (!synced) {
      if (previousResident != null && residentIndex < residentFiles.length) {
        residentFiles[residentIndex] = previousResident;
      } else if (previousResident != null) {
        residentFiles.add(previousResident);
      }
      if (previousGlobal != null) {
        final restoreAt = globalIndex > familyMembersList.length
            ? familyMembersList.length
            : globalIndex;
        familyMembersList.insert(restoreAt, previousGlobal);
      }
      notifyListeners();
      return false;
    }

    _pruneFamilyCardFavorites(_familyCardPreferenceKey(residentId));
    unawaited(syncBackendData());
    return true;
  }

  AppRiverpod() {
    socialAssessmentTools = _fallbackAssessmentTools();
    _seedFallbackQuestionBank();
    _loadAuthState(); // تحميل حالة الدخول عند بدء تشغيل المزود
  }

  // تحميل بيانات الدخول والجلسة من التخزين الآمن
  Future<void> _loadAuthState() async {
    splashStatus = 'جاري التحقق من هويتك...';
    notifyListeners();

    final auth = await _storage.read(key: 'isAuthenticated');
    final role = await _storage.read(key: 'currentRole');
    final onboarding = await _storage.read(key: 'hasSeenOnboarding');
    final expiryStr = await _storage.read(key: 'sessionExpiry');

    if (auth == 'true') {
      try {
        final user = await AuthService.instance.restoreSession();
        if (user == null) {
          await _storage.delete(key: 'isAuthenticated');
          await _storage.delete(key: 'currentRole');
          await _storage.delete(key: 'userEmail');
          await _storage.delete(key: 'sessionExpiry');
        } else {
          if (expiryStr != null) {
            _sessionExpiry = DateTime.tryParse(expiryStr);
          }
          _applyBackendUser(
            email: user.email,
            role: role ?? user.arabicRole,
            userId: user.userId,
            facilityId: user.facilityId,
            name: user.name,
            linkedResidentId: user.linkedResidentId,
            facilityName: user.facilityName,
          );

          splashStatus = 'جاري تحميل بياناتك...';
          notifyListeners();

          // حمّل الأوسمة أولاً قبل sync البيانات لتجنب إعادة إطلاقها
          await _loadEarnedBadges();

          // انتظر sync البيانات (حد أقصى 8 ثوانٍ) + تهيئة الإشعارات بالتوازي
          await Future.wait<void>([
            syncBackendData().timeout(
              const Duration(seconds: 8),
              onTimeout: () {},
            ),
            PushNotificationService.instance.init(),
          ]).catchError((_) => <void>[]);
        }
      } catch (e) {
        isAuthenticated = false;
        currentRole = '';
        currentAccount = null;
        backendSyncError = e.toString();
        await AuthService.instance.logout();
        await _storage.delete(key: 'isAuthenticated');
        await _storage.delete(key: 'currentRole');
        await _storage.delete(key: 'userEmail');
        await _storage.delete(key: 'sessionExpiry');
      }
    }

    if (onboarding == 'true') hasSeenOnboarding = true;

    final biometric = await _storage.read(key: 'isBiometricEnabled');
    if (biometric == 'true') isBiometricEnabled = true;

    splashStatus = 'جاهز!';
    isInitialized = true;
    notifyListeners();
  }

  /// يُعيد تفعيل آخر جلسة محفوظة (يُستدعى بعد نجاح التحقق البيومتري)
  Future<bool> restoreLastSession() async {
    try {
      final user = await AuthService.instance.restoreSession();
      if (user == null) return false;
      _applyBackendUser(
        email: user.email,
        role: user.arabicRole,
        userId: user.userId,
        facilityId: user.facilityId,
        name: user.name,
        linkedResidentId: user.linkedResidentId,
        facilityName: user.facilityName,
      );
      unawaited(syncBackendData());
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  // حفظ الدور في الذاكرة لتجنب الخروج عند الريلود
  Future<void> setAndSaveRole(String role) async {
    currentRole = role;
    await _storage.write(key: 'currentRole', value: role);
    notifyListeners();
  }

  // أداة اختبار داخلية لإنهاء الجلسة محلياً والتحقق من مسار التجديد الحقيقي.
  void simulateSessionExpiry() {
    _sessionExpiry = DateTime.now().subtract(const Duration(minutes: 1));
    notifyListeners();
  }

  // التحقق من صحة الجلسة وتجديدها إذا لزم الأمر
  Future<bool> checkAndRefreshSession() async {
    if (!isAuthenticated || _sessionExpiry == null) return true;

    // إذا كانت الجلسة منتهية أو ستنتهي خلال دقيقة
    if (_sessionExpiry!.isBefore(DateTime.now())) {
      if (isRefreshingSession) return false;

      isRefreshingSession = true;
      notifyListeners();

      try {
        final user = await AuthService.instance.refreshSession();
        if (user == null) {
          await logout();
          return false;
        }
        _applyBackendUser(
          email: user.email,
          role: user.arabicRole,
          userId: user.userId,
          facilityId: user.facilityId,
          name: user.name,
          linkedResidentId: user.linkedResidentId,
          facilityName: user.facilityName,
          clearExistingData: false,
        );
        _sessionExpiry = DateTime.now().add(const Duration(hours: 1));
        await _storage.write(
            key: 'sessionExpiry', value: _sessionExpiry!.toIso8601String());
        backendSyncError = null;
        isRefreshingSession = false;
        notifyListeners();
        return true;
      } catch (e) {
        backendSyncError = e.toString();
        isRefreshingSession = false;
        await logout();
        return false;
      }
    }
    return true;
  }

  void toggleDarkMode() {
    isDarkMode = !isDarkMode;
    unawaited(_syncUserPreferences());
    notifyListeners();
  }

  // تحديث فلتر التاريخ للوحة تحكم المدير وإعادة بناء المؤشرات المحملة من السيرفر.
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

    final remaining = <PendingAssessment>[];
    for (final assessment in List<PendingAssessment>.from(pendingAssessments)) {
      final residentId = _residentIdForName(assessment.residentName);
      if (residentId == null) {
        backendSyncError =
            'لا يوجد residentId من السيرفر للتقييم الخاص بـ ${assessment.residentName}';
        remaining.add(assessment);
        continue;
      }

      final synced = await _runBackendMutation(() {
        return BackendMutationService.instance.createSocialAssessment(
          residentId: residentId,
          scores: _pendingAssessmentScores(assessment),
          needsIntervention: false,
          notes: assessment.notes,
        );
      });
      if (!synced) {
        remaining.add(assessment);
      }
    }

    pendingAssessments = remaining;
    isSyncing = false;
    notifyListeners();

    if (pendingAssessments.isEmpty) {
      unawaited(syncBackendData());
    }
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
    unawaited(syncBackendData());
  }

  // Real Notification State
  List<TaptabaNotification> notifications = [];

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
  List<NursingNote> nursingNotes = [];

  Future<void> addNursingNote(NursingNote note) async {
    final residentId = _residentIdForName(note.residentName);
    if (residentId == null) {
      backendSyncError =
          'لا يوجد residentId من السيرفر لملاحظة ${note.residentName}';
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
    unawaited(syncBackendData());
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
      backendSyncError =
          'لا يوجد residentId من السيرفر للملف الطبي الخاص بـ ${newInfo.residentName}';
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
    unawaited(syncBackendData());
  }

  // عملية تسجيل الدخول وحفظ البيانات آمنياً مع ضبط موعد انتهاء الجلسة (US-SmartLogin)
  // تسجيل الدخول عبر الـ Backend الحقيقي (السيرفر)
  // يستخدمه LoginScreen بعد نجاح AuthService.login()
  String? backendUserId;
  String? backendFacilityId;
  String? backendResidentId;
  bool isBackendSyncing = false;
  DateTime? lastBackendSyncAt;
  String? backendSyncError;

  // Messages inbox — loaded on demand for Family and Resident roles
  List<BackendMessageThreadSummary> messageInbox = [];
  bool isLoadingInbox = false;

  Future<void> loadMessageInbox() async {
    if (isLoadingInbox) return;
    isLoadingInbox = true;
    notifyListeners();
    try {
      messageInbox = await MessagesService.instance.inbox();
    } catch (_) {
      // silently fail — inbox is non-critical
    } finally {
      isLoadingInbox = false;
      notifyListeners();
    }
  }

  // Upload progress state — used by any screen that uploads files to S3
  bool isUploadingFile = false;
  double uploadProgress = 0.0;
  String? uploadError;

  void setUploadState({
    required bool uploading,
    double progress = 0.0,
    String? error,
  }) {
    isUploadingFile = uploading;
    uploadProgress = progress;
    uploadError = error;
    notifyListeners();
  }

  Future<void>? _backendSyncFuture;
  Map<String, String> mealPlanIdsByResidentName = {};

  Map<String, String> emergencyContacts = {};
  FacilityBillingSettings? billingSettings;
  FacilityProfileSettings? facilityProfileSettings;

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

  // --- ELDERLY / RESIDENT STATE (RE-ADDED) ---
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

  List<Activity> activities = [];

  // الحقول والدوال الجديدة لربط الأنشطة المشتركة بين المسن وعائلته
  final Map<String, bool> familyActivityParticipations = {};
  final Map<String, String> familyActivityNotes = {};

  void toggleFamilyParticipation(String activityId) {
    final current = familyActivityParticipations[activityId] ?? false;
    familyActivityParticipations[activityId] = !current;
    notifyListeners();
  }

  bool toggleFamilyActivityAttendance(
    Activity activity, {
    String? residentName,
  }) {
    final current = familyActivityParticipations[activity.id] ?? false;
    final isJoined = !current;
    familyActivityParticipations[activity.id] = isJoined;

    if (isJoined) {
      final familyName = (currentAccount?.name.trim().isNotEmpty ?? false)
          ? currentAccount!.name.trim()
          : 'أحد أفراد الأسرة';
      final linkedResidentName =
          _linkedFamilyResidentName(fallback: residentName);
      final activityTime = activity.time.trim().isEmpty
          ? 'اليوم'
          : 'الساعة ${activity.time.trim()}';

      triggerNotification(
        title: 'تأكيد حضور نشاط عائلي',
        body:
            '$familyName أكد حضوره نشاط "${activity.name}" مع $linkedResidentName في $activityTime.',
        type: 'activity',
        targetRole: 'إدارة',
      );

      triggerNotification(
        title: 'عائلتك ستكون معك اليوم ❤️',
        body:
            '$familyName أكد مشاركته معك في نشاط "${activity.name}" في $activityTime.',
        type: 'activity',
        targetRole: 'مسن',
      );
    }

    notifyListeners();
    return isJoined;
  }

  String _linkedFamilyResidentName({String? fallback}) {
    final linkedResidentId = currentAccount?.linkedResidentId;
    final activeResidentId =
        _looksLikeBackendId(backendResidentId) ? backendResidentId : null;
    final wantedId = _looksLikeBackendId(linkedResidentId)
        ? linkedResidentId
        : activeResidentId;

    if (wantedId != null) {
      for (final resident in residentFiles) {
        if (resident.id == wantedId && resident.name.trim().isNotEmpty) {
          return resident.name.trim();
        }
      }
    }

    final cleanFallback = fallback?.trim() ?? '';
    if (cleanFallback.isNotEmpty && cleanFallback != 'المقيم العزيز') {
      return cleanFallback;
    }

    if (residentFiles.isNotEmpty &&
        residentFiles.first.name.trim().isNotEmpty) {
      return residentFiles.first.name.trim();
    }

    return 'المقيم';
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

  List<FamilyMember> familyMembersList = [];
  final Map<String, Set<String>> _favoriteFamilyMemberIdsByResident = {};
  final Map<String, int> _familyCardLimitByResident = {};
  final Set<String> _loadedFamilyCardPreferenceKeys = {};
  static const int _defaultFamilyCardLimit = 3;
  static const int _maxFamilyCardLimit = 6;

  List<VoiceMessage> voiceMessagesList = [];

  bool isVideoCallActive = false;
  bool isIncomingCall = false;
  String? activeVideoCallId;
  String? activeVideoCallJoinUrl;
  String activeCallerName = '';
  String activeCallerInitials = '';
  StreamSubscription<dynamic>? _realtimeSub;
  bool isLoadingSpecialistChat = false;

  bool isAIInsightsEnabled = true;
  bool isLoadingAiInsight = false;
  String aiInsightMode = 'backend';
  String? aiInsightError;

  Future<bool> refreshAiInsightFromBackend({String? residentId}) async {
    final resolvedResidentId = residentId ?? backendResidentId;
    if (resolvedResidentId == null || resolvedResidentId.isEmpty) {
      aiInsightMode = 'error';
      aiInsightError =
          'لا يوجد معرف مقيم من السيرفر لجلب توصية الذكاء الاصطناعي';
      backendSyncError = aiInsightError;
      notifyListeners();
      return false;
    }
    isLoadingAiInsight = true;
    aiInsightError = null;
    notifyListeners();
    try {
      final rec =
          await AiService.instance.getRecommendations(resolvedResidentId);

      // Resolve human-readable name and room from the residents list.
      final residentFile =
          residentFiles.where((r) => r.id == resolvedResidentId).firstOrNull;
      final safeName = residentFile?.name.isNotEmpty == true
          ? residentFile!.name
          : (currentUser.name.isNotEmpty ? currentUser.name : 'مقيم');
      final roomNumber = residentFile?.room;

      // Strip any UUID patterns the backend may have included in text fields.
      final safeSummary = stripUuids(rec.summary);
      final safeRationale = stripUuids(rec.rationale);
      final existingIndex = aiInsights.indexWhere(
        (i) =>
            i.residentId == resolvedResidentId ||
            (i.residentId == null && i.residentName == safeName),
      );

      if (existingIndex != -1) {
        aiInsights[existingIndex] = AIInsight(
          id: aiInsights[existingIndex].id,
          residentId: resolvedResidentId,
          residentName: safeName,
          roomNumber: roomNumber ?? aiInsights[existingIndex].roomNumber,
          summary: safeSummary,
          rationale: safeRationale,
          generationDate: DateTime.tryParse(rec.generatedAt) ?? DateTime.now(),
          confidenceScore: 0.85,
        );
      } else {
        aiInsights.add(AIInsight(
          id: 'ai_${DateTime.now().millisecondsSinceEpoch}',
          residentId: resolvedResidentId,
          residentName: safeName,
          roomNumber: roomNumber,
          summary: safeSummary,
          rationale: safeRationale,
          generationDate: DateTime.tryParse(rec.generatedAt) ?? DateTime.now(),
        ));
      }
      aiInsightMode = rec.mode.isEmpty ? 'bedrock' : rec.mode;
      aiInsightError = aiInsightMode == 'fallback'
          ? 'تعذر الاتصال بخدمة الذكاء الاصطناعي، فتم عرض توصية احتياطية قابلة للمراجعة.'
          : null;
      backendSyncError = null;
      return true;
    } catch (e) {
      aiInsightMode = 'error';
      aiInsightError = _friendlyAiError(e);
      backendSyncError = aiInsightError;
      return false;
    } finally {
      isLoadingAiInsight = false;
      notifyListeners();
    }
  }

  String _friendlyAiError(Object error) {
    final raw = error.toString();
    if (raw.contains('لا يوجد اتصال') || raw.contains('Timeout')) {
      return 'تعذر الاتصال بالسيرفر. تحقق من الشبكة ثم حاول مرة أخرى.';
    }
    if (raw.contains('AI_ENABLED') || raw.contains('Bedrock')) {
      return 'خدمة الذكاء الاصطناعي غير متاحة حالياً. حاول لاحقاً أو راجع إعدادات السيرفر.';
    }
    return 'تعذر جلب توصيات الذكاء الاصطناعي حالياً. حاول مرة أخرى.';
  }

  List<AIInsight> aiInsights = [];

  // خريطة لتخزين ملاحظات الذكاء الاصطناعي لكل مقيم (residentId → notes)
  final Map<String, ResidentAINotes> _residentAINotesMap = {};

  ResidentAINotes? getResidentAINotes(String residentId) =>
      _residentAINotesMap[residentId];

  void setResidentAINotes(ResidentAINotes notes) {
    _residentAINotesMap[notes.residentId] = notes;
    notifyListeners();
  }

  bool isAICompanionEnabled = true;
  List<CompanionMessage> companionChatHistory = [];

  bool isEmergencyActive = false;
  bool isEmergencySyncing = false;
  String? currentEmergencyId;
  List<BackendEmergency> activeEmergencies = [];
  String currentMood = '';
  bool isReadingAudio = false;
  String readingText = '';

  List<AssetEntity> deviceGalleryImages = [];

  List<MemoryItem> memoriesList = [];

  // --- Albums Management ---
  static const String defaultPhotoAlbumName = 'صوري';
  List<String> customAlbums = [];
  Map<String, String> albumCovers = {}; // albumName -> assetPath or url

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

  List<VolunteerApplication> volunteerApplications = [];

  List<VolunteerCertificate> volunteerCertificates = [];

  List<VolunteerRating> volunteerRatings = [];

  List<VolunteerReview> volunteerReviews = [];

  // --- DYNAMIC QUESTION BANK ---
  Map<String, List<Map<String, dynamic>>> questionBank = {};

  static const int maxAssessmentQuestionsPerCategory = 15;

  List<Map<String, dynamic>> getQuestionsForTool(String toolId) {
    final questions = _limitedAssessmentQuestions(questionBank[toolId]);
    if (questions.isNotEmpty) return questions;
    return _fallbackQuestionsForAssessmentKey(toolId);
  }

  List<Map<String, dynamic>> getQuestionsForAssessmentTool(
    SocialSpecialistAssessmentTool tool,
  ) {
    final questions = _limitedAssessmentQuestions(questionBank[tool.id]);
    if (questions.isNotEmpty) return questions;
    return _fallbackQuestionsForAssessmentTool(tool);
  }

  List<Map<String, dynamic>> _limitedAssessmentQuestions(
    List<Map<String, dynamic>>? questions,
  ) {
    if (questions == null || questions.isEmpty) return const [];
    return questions
        .where((q) => (q['text'] ?? q['question'] ?? '').toString().isNotEmpty)
        .take(maxAssessmentQuestionsPerCategory)
        .toList();
  }

  void _seedFallbackQuestionBank() {
    for (final entry in _fallbackAssessmentQuestionBank().entries) {
      questionBank.putIfAbsent(entry.key, () => entry.value);
    }
  }

  List<SocialSpecialistAssessmentTool> _fallbackAssessmentTools() {
    return [
      SocialSpecialistAssessmentTool(
        id: 'global_psych_gds15',
        name: 'تقييم نفسي مختصر',
        subtitle: 'مبني على GDS-15 لكبار السن - 15 سؤال',
        score: '0/15',
        status: 'جديد',
        icon: '🧠',
      ),
      SocialSpecialistAssessmentTool(
        id: 'global_social_lsns_ucla',
        name: 'تقييم اجتماعي',
        subtitle: 'عزلة ودعم اجتماعي LSNS-6 + UCLA-3 - 9 أسئلة',
        score: '0/9',
        status: 'جديد',
        icon: '🤝',
      ),
      SocialSpecialistAssessmentTool(
        id: 'global_functional_katz_lawton',
        name: 'تقييم وظيفي وبدني',
        subtitle: 'Katz ADL + Lawton IADL - 14 سؤال',
        score: '0/14',
        status: 'جديد',
        icon: '🏃',
      ),
      SocialSpecialistAssessmentTool(
        id: 'global_health_mna_braden',
        name: 'تقييم صحي وتغذوي',
        subtitle: 'MNA-SF + Braden domains - 12 سؤال',
        score: '0/12',
        status: 'جديد',
        icon: '❤️',
      ),
    ];
  }

  List<Map<String, dynamic>> _fallbackQuestionsForAssessmentTool(
    SocialSpecialistAssessmentTool tool,
  ) {
    final key = _assessmentFallbackKey(
      '${tool.id} ${tool.name} ${tool.subtitle} ${tool.icon}',
    );
    return _fallbackQuestionsForAssessmentKey(key);
  }

  List<Map<String, dynamic>> _fallbackQuestionsForAssessmentKey(String value) {
    final key = _assessmentFallbackKey(value);
    return _fallbackAssessmentQuestionBank()[key] ??
        _fallbackAssessmentQuestionBank()['psych']!;
  }

  String _assessmentFallbackKey(String value) {
    final text = value.toLowerCase();
    if (text.contains('social') ||
        text.contains('family') ||
        text.contains('relation') ||
        text.contains('اجتما') ||
        text.contains('علاق') ||
        text.contains('أسرة') ||
        text.contains('عزلة') ||
        text.contains('🤝')) {
      return 'social';
    }
    if (text.contains('phys') ||
        text.contains('mobil') ||
        text.contains('adl') ||
        text.contains('function') ||
        text.contains('بدن') ||
        text.contains('حرك') ||
        text.contains('وظيف') ||
        text.contains('نشاط') ||
        text.contains('🏃')) {
      return 'functional';
    }
    if (text.contains('health') ||
        text.contains('medical') ||
        text.contains('nutrition') ||
        text.contains('mna') ||
        text.contains('braden') ||
        text.contains('صحي') ||
        text.contains('طبي') ||
        text.contains('تغذ') ||
        text.contains('رعاية') ||
        text.contains('❤️')) {
      return 'health';
    }
    return 'psych';
  }

  Map<String, List<Map<String, dynamic>>> _fallbackAssessmentQuestionBank() {
    const yesNo = ['نعم', 'لا'];
    const frequency = ['نادراً أو أبداً', 'أحياناً', 'غالباً'];
    const supportFrequency = [
      'أقل من مرة شهرياً',
      'شهرياً',
      'أسبوعياً',
      'يومياً'
    ];
    const independence = ['مستقل', 'يحتاج مساعدة جزئية', 'يعتمد على الآخرين'];
    const nutrition = ['طبيعي/مستقر', 'تغير متوسط', 'تدهور واضح'];

    Map<String, dynamic> q(
      String id,
      String text, {
      List<String>? options,
    }) {
      return {
        'id': id,
        'text': text,
        'type': 'choice',
        'options': options ?? yesNo,
      };
    }

    return {
      'psych': [
        q('gds15_01', 'GDS-15: هل أنت راضٍ بشكل عام عن حياتك؟'),
        q('gds15_02', 'GDS-15: هل توقفت عن كثير من اهتماماتك أو أنشطتك؟'),
        q('gds15_03', 'GDS-15: هل تشعر أن حياتك فارغة؟'),
        q('gds15_04', 'GDS-15: هل تشعر بالملل كثيراً؟'),
        q('gds15_05', 'GDS-15: هل تكون في مزاج جيد معظم الوقت؟'),
        q('gds15_06', 'GDS-15: هل تخشى أن يحدث لك شيء سيئ؟'),
        q('gds15_07', 'GDS-15: هل تشعر بالسعادة معظم الوقت؟'),
        q('gds15_08', 'GDS-15: هل تشعر غالباً بالعجز أو قلة الحيلة؟'),
        q('gds15_09',
            'GDS-15: هل تفضل البقاء في الغرفة بدل الخروج أو المشاركة؟'),
        q('gds15_10', 'GDS-15: هل تشعر أن ذاكرتك أسوأ من أغلب من هم في سنك؟'),
        q('gds15_11', 'GDS-15: هل ترى أن الحياة الآن جيدة وممتعة؟'),
        q('gds15_12', 'GDS-15: هل تشعر بأنك بلا قيمة كما أنت الآن؟'),
        q('gds15_13', 'GDS-15: هل تشعر بوجود طاقة كافية خلال اليوم؟'),
        q('gds15_14', 'GDS-15: هل تشعر أن وضعك الحالي بلا أمل؟'),
        q('gds15_15', 'GDS-15: هل ترى أن أغلب الناس أفضل حالاً منك؟'),
      ],
      'social': [
        q('lsns_01', 'LSNS-6: كم مرة تتواصل مع أحد أفراد الأسرة أو الأقارب؟',
            options: supportFrequency),
        q('lsns_02',
            'LSNS-6: كم عدد الأقارب الذين يمكن طلب المساعدة منهم عند الحاجة؟',
            options: ['لا يوجد', 'واحد أو اثنان', 'ثلاثة فأكثر']),
        q('lsns_03',
            'LSNS-6: كم عدد الأقارب الذين يمكن الحديث معهم عن أمور خاصة؟',
            options: ['لا يوجد', 'واحد أو اثنان', 'ثلاثة فأكثر']),
        q('lsns_04',
            'LSNS-6: كم مرة تتواصل مع صديق أو زميل داخل أو خارج الدار؟',
            options: supportFrequency),
        q('lsns_05', 'LSNS-6: كم عدد الأصدقاء الذين يمكن طلب المساعدة منهم؟',
            options: ['لا يوجد', 'واحد أو اثنان', 'ثلاثة فأكثر']),
        q('lsns_06', 'LSNS-6: كم عدد الأصدقاء الذين يمكن الحديث معهم بثقة؟',
            options: ['لا يوجد', 'واحد أو اثنان', 'ثلاثة فأكثر']),
        q('ucla3_01', 'UCLA-3: كم مرة تشعر بنقص الصحبة أو الرفقة؟',
            options: frequency),
        q('ucla3_02', 'UCLA-3: كم مرة تشعر بأنك مستبعد أو غير مندمج؟',
            options: frequency),
        q('ucla3_03', 'UCLA-3: كم مرة تشعر بالعزلة عن الآخرين؟',
            options: frequency),
      ],
      'functional': [
        q('katz_01', 'Katz ADL: الاستحمام والعناية بالنظافة الشخصية.',
            options: independence),
        q('katz_02', 'Katz ADL: ارتداء الملابس وخلعها.', options: independence),
        q('katz_03', 'Katz ADL: استخدام الحمام بأمان.', options: independence),
        q('katz_04', 'Katz ADL: الانتقال من السرير إلى الكرسي أو العكس.',
            options: independence),
        q('katz_05',
            'Katz ADL: التحكم في الإخراج أو التعامل مع الاحتياج للمساعدة.',
            options: independence),
        q('katz_06', 'Katz ADL: تناول الطعام دون مساعدة.',
            options: independence),
        q('lawton_01', 'Lawton IADL: استخدام الهاتف أو وسيلة تواصل مناسبة.',
            options: independence),
        q('lawton_02', 'Lawton IADL: إدارة الأدوية أو تذكر مواعيدها.',
            options: independence),
        q('lawton_03',
            'Lawton IADL: إدارة المصروفات أو المتعلقات الشخصية البسيطة.',
            options: independence),
        q('lawton_04', 'Lawton IADL: اختيار الملابس أو المستلزمات اليومية.',
            options: independence),
        q('lawton_05', 'Lawton IADL: التنقل داخل الدار أو الوصول للأنشطة.',
            options: independence),
        q('lawton_06', 'Lawton IADL: المشاركة في ترتيب المساحة الشخصية.',
            options: independence),
        q('lawton_07', 'Lawton IADL: القدرة على طلب المساعدة عند الحاجة.',
            options: independence),
        q('lawton_08', 'Lawton IADL: متابعة التعليمات اليومية البسيطة.',
            options: independence),
      ],
      'health': [
        q('mna_sf_01',
            'MNA-SF: هل قلّ تناول الطعام مؤخراً بسبب فقدان شهية أو صعوبة بلع/مضغ؟',
            options: nutrition),
        q('mna_sf_02', 'MNA-SF: هل حدث فقدان وزن ملحوظ خلال آخر ثلاثة أشهر؟',
            options: nutrition),
        q('mna_sf_03', 'MNA-SF: مستوى الحركة الحالي داخل الدار.', options: [
          'حر الحركة',
          'حركة محدودة',
          'ملازم للسرير/الكرسي غالباً'
        ]),
        q('mna_sf_04', 'MNA-SF: هل تعرض لضغط نفسي أو مرض حاد مؤخراً؟',
            options: yesNo),
        q('mna_sf_05',
            'MNA-SF: هل توجد مشكلات معرفية أو مزاجية تؤثر على الأكل؟',
            options: ['لا توجد', 'خفيفة', 'متوسطة أو شديدة']),
        q('mna_sf_06',
            'MNA-SF: مؤشر الكتلة/المظهر التغذوي العام حسب التقييم المتاح.',
            options: [
              'ضمن الطبيعي',
              'احتمال نقص تغذية',
              'نقص واضح يحتاج تدخل'
            ]),
        q('braden_01',
            'Braden: قدرة المقيم على الإحساس بالضغط أو الألم الموضعي.',
            options: ['جيدة', 'محدودة قليلاً', 'محدودة بوضوح']),
        q('braden_02', 'Braden: تعرض الجلد للرطوبة خلال اليوم.',
            options: ['نادراً', 'أحياناً', 'متكرر']),
        q('braden_03', 'Braden: مستوى النشاط والحركة اليومية.',
            options: ['يمشي/يتحرك جيداً', 'حركة محدودة', 'ملازم غالباً']),
        q('braden_04', 'Braden: القدرة على تغيير الوضعية دون مساعدة.',
            options: ['مستقل', 'يحتاج تذكير/مساعدة', 'يعتمد على المساعدة']),
        q('braden_05', 'Braden: كفاية التغذية والسوائل خلال اليوم.',
            options: ['كافية', 'غير منتظمة', 'ضعيفة']),
        q('braden_06', 'Braden: احتكاك الجلد أو الانزلاق أثناء الحركة/النقل.',
            options: ['لا يوجد غالباً', 'أحياناً', 'متكرر']),
      ],
    };
  }

  String selectedSpecialistFilter = 'الكل';
  String residentSearchQuery = '';
  String? selectedHealthStatus;
  String? selectedRoomFilter;
  int selectedFloor = 1;

  List<SocialSpecialistAssessmentTool> socialAssessmentTools = [];

  List<SocialSpecialistNeed> socialNeeds = [];

  List<SocialSpecialistResidentScore> socialResidentScores = [];

  List<SocialSpecialistResidentScore> get filteredResidentScores {
    // Sort by most recent assessment first so dedup keeps the latest
    final sorted =
        List<SocialSpecialistResidentScore>.from(socialResidentScores)
          ..sort((a, b) => b.lastAssessment.compareTo(a.lastAssessment));

    // Deduplicate by resident name, filter invalid/test entries
    final seenNames = <String>{};
    final deduped = sorted.where((r) {
      final nameClean = r.name.trim().toLowerCase();
      if (nameClean.isEmpty || r.name == 'مقيم') return false;
      if (r.name.contains('?')) return false;
      if (nameClean.startsWith('test') || nameClean.contains('test ')) {
        return false;
      }
      return seenNames.add(nameClean);
    }).toList();

    return deduped.where((r) {
      final matchQuery = residentSearchQuery.isEmpty ||
          r.name.contains(residentSearchQuery) ||
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
          value: '${_toArabicDigits(activityRate)}٪',
          trend: activityRate > 0 ? 'من بيانات السيرفر' : 'لا توجد بيانات',
          isPositive: activityRate >= 60),
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
  int get totalPendingAssessments =>
      socialResidentScores.where((r) => r.isUrgent).length;

  double get averageRating {
    if (volunteerRatings.isEmpty) return 0;
    return volunteerRatings.map((r) => r.score).reduce((a, b) => a + b) /
        volunteerRatings.length;
  }

  int get totalReviews => volunteerRatings.length;

  String get topSkill {
    if (volunteerRatings.isEmpty) return '—';
    final allCriteria = <String, List<double>>{};
    for (final r in volunteerRatings) {
      for (final e in r.criteriaScores.entries) {
        allCriteria.putIfAbsent(e.key, () => []).add(e.value);
      }
    }
    if (allCriteria.isEmpty) return '—';
    final avgs = allCriteria
        .map((k, v) => MapEntry(k, v.reduce((a, b) => a + b) / v.length));
    final best = avgs.entries.reduce((a, b) => a.value >= b.value ? a : b);
    return '${best.key} ⭐ ${best.value.toStringAsFixed(1)}';
  }

  String get skillNeedsImprovement {
    if (volunteerRatings.isEmpty) return '—';
    final allCriteria = <String, List<double>>{};
    for (final r in volunteerRatings) {
      for (final e in r.criteriaScores.entries) {
        allCriteria.putIfAbsent(e.key, () => []).add(e.value);
      }
    }
    if (allCriteria.isEmpty) return '—';
    final avgs = allCriteria
        .map((k, v) => MapEntry(k, v.reduce((a, b) => a + b) / v.length));
    final worst = avgs.entries.reduce((a, b) => a.value <= b.value ? a : b);
    return '${worst.key} ${worst.value.toStringAsFixed(1)}';
  }

  List<Medication> get todayMedications => medications;
  Medication? get nextMedication {
    try {
      return medications.firstWhere((m) => !m.isTaken);
    } catch (_) {
      return null;
    }
  }

  final Set<String> _familyRemindedMedicationKeys = {};

  // --- DETAILED ASSESSMENT STATE ---
  List<AssessmentQuestion> gdsQuestions = [];

  List<AssessmentHistoricalEntry> assessmentHistory = [];

  bool isAiThinking = false;
  String lastAiMode = 'bedrock';

  // Checks for missed medications and triggers alerts for the resident and
  // the nursing team. Called automatically after each sync for resident role.
  Future<void> checkMedicationAdherence() async {
    final missed =
        medications.where((m) => m.isMissed && m.dayTag == 'اليوم').toList();
    if (missed.isEmpty) return;

    final names = missed.map((m) => m.name).join('، ');
    final count = missed.length;

    // Proactive in-app notification for the resident
    triggerNotification(
      title: 'تذكير بالأدوية 💊',
      body: 'لم تأخذ ${count == 1 ? 'دواء' : '$count أدوية'} حتى الآن: $names',
      type: 'health',
      targetRole: 'مسن',
    );

    // Alert nursing team
    triggerNotification(
      title: 'تنبيه التزام الدواء',
      body: 'المقيم ${currentAccount?.name ?? ''} لم يأخذ: $names',
      type: 'health',
      targetRole: 'ممرض',
    );

    // Add proactive AI message to companion chat if it's empty or old
    final lastAiMsg = companionChatHistory.where((m) => m.isFromAI).lastOrNull;
    final isRecent = lastAiMsg != null &&
        DateTime.now().difference(lastAiMsg.timestamp).inMinutes < 30;
    if (!isRecent) {
      final residentTitle = (currentAccount?.name ?? '').isNotEmpty
          ? 'أستاذ ${currentAccount!.name.split(' ').first}'
          : 'صديقي';
      companionChatHistory.add(CompanionMessage(
        id: 'ai_med_${DateTime.now().millisecondsSinceEpoch}',
        text: 'مرحباً $residentTitle 😊 حان وقت دوائك! '
            '${count == 1 ? 'دواء $names' : '$count أدوية: $names'}. '
            'هل تحتاج مساعدة؟',
        isFromAI: true,
        timestamp: DateTime.now(),
      ));
      notifyListeners();
    }
  }

  Future<String?> sendCompanionMessage(String text,
      {String? mediaPath, String? mediaType, bool voiceMode = false}) async {
    if (text.isEmpty && mediaPath == null) return null;

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

      // Build resident context block to include in every message
      final firstName = (currentAccount?.name ?? '').split(' ').first;
      final title = firstName.isNotEmpty ? 'أستاذ $firstName' : 'صديقي';
      final missedMeds = medications
          .where((m) => m.isMissed && m.dayTag == 'اليوم')
          .map((m) => m.name)
          .toList();
      final todayActivities = activities
          .where((a) => a.status == 'coming')
          .take(2)
          .map((a) => '${a.name} الساعة ${a.time}')
          .toList();
      final contextParts = <String>[
        'ناد المقيم دائماً بـ "$title" — لا تستخدم أسماء أكثر ألفة.',
        'أسلوبك: دافئ، محترم، لطيف، لا تبالغ في الألفة.',
        'لو السؤال طبي، دواء، أو تشخيص — وجّه بهدوء للممرضة أو الطبيب.',
        if (missedMeds.isNotEmpty)
          'تنبيه: المقيم لم يأخذ هذه الأدوية اليوم: ${missedMeds.join('، ')}. ذكّره بلطف.',
        if (todayActivities.isNotEmpty)
          'نشاطات اليوم القادمة: ${todayActivities.join(' / ')}.',
      ];
      final contextBlock = contextParts.join(' ');

      final messageForAi = voiceMode
          ? '$contextBlock '
              'أنت مساعد صوتي حي، ردّ بجملة إلى ثلاث جمل بدون قوائم. '
              'كلام المستخدم: $effectiveMessage'
          : '$contextBlock\n\nكلام المقيم: $effectiveMessage';

      final response = await AiService.instance.sendChat(
        message: messageForAi,
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

      // Alert nursing team if sentiment indicates distress
      if (response.sentiment == 'negative' || response.sentiment == 'sad') {
        triggerNotification(
          title: 'تنبيه المساعد الذكي',
          body: 'المقيم ${currentAccount?.name ?? ''} قد يحتاج انتباهاً — '
              'المشاعر المرصودة: ${response.sentiment}',
          type: 'health',
          targetRole: 'ممرض',
        );
      }

      notifyListeners();
      return response.reply;
    } catch (e) {
      backendSyncError = e.toString();
      notifyListeners();
      return null;
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
      backendSyncError = 'لا توجد جلسة السيرفر نشطة لإرسال نداء الطوارئ';
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
    await _runBackendMutation(() {
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
      _companionPlayerCompleteSub?.cancel();
      _companionPlayerCompleteSub = null;

      // Try Gemini TTS (10s), then device TTS as instant fallback.
      // We AWAIT true completion so the caller knows audio is done.
      bool usedCloudTts = false;
      try {
        final speech = await AiService.instance.synthesizeSpeech(
          text: cleanText,
          provider: 'google-cloud-gemini-tts',
          model: 'gemini-2.5-pro-tts',
          voiceName: 'Kore',
          languageCode: 'ar-EG',
          audioEncoding: 'MP3',
          prompt:
              'تحدث بالعربية المصرية بلهجة طبيعية ودافئة ومطمئنة. النبرة هادئة مناسبة لكبار السن، سرعة متوسطة.',
          timeout: const Duration(seconds: 10),
        );
        if (speech.audioBase64.trim().isEmpty) {
          throw const FormatException('Empty Gemini audio');
        }

        final bytes = base64Decode(speech.audioBase64);
        final completer = Completer<void>();
        _companionPlayerCompleteSub =
            _companionPlayer.onPlayerComplete.listen((_) {
          if (!completer.isCompleted) completer.complete();
        });
        await _companionPlayer
            .play(BytesSource(bytes, mimeType: speech.contentType));
        await completer.future;
        usedCloudTts = true;
      } catch (cloudErr) {
        debugPrint('Cloud TTS failed -> device TTS: $cloudErr');
      }

      if (!usedCloudTts) {
        // Device TTS — instant start, await actual completion
        await _initTts();
        final completer = Completer<void>();
        _tts.setCompletionHandler(() {
          if (!completer.isCompleted) completer.complete();
        });
        _tts.setErrorHandler((msg) {
          if (!completer.isCompleted) completer.complete();
        });
        final result = await _tts.speak(cleanText);
        if (result == 1) {
          await completer.future;
        }
      }
    } catch (e) {
      debugPrint('startCompanionSpeech error: $e');
    } finally {
      isReadingAudio = false;
      _companionPlayerCompleteSub?.cancel();
      _companionPlayerCompleteSub = null;
      notifyListeners();
    }
  }

  Future<void> stopReading() async {
    try {
      await _tts.stop();
      await _companionPlayer.stop();
    } catch (_) {}
    isReadingAudio = false;
    notifyListeners();
  }

  String? voiceMessageBanner;

  void clearVoiceMessageBanner() {
    if (voiceMessageBanner != null) {
      voiceMessageBanner = null;
      notifyListeners();
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
    } else if (cleanCategory == defaultPhotoAlbumName) {
      results.addAll(_allPhotoMemories());
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
      results.addAll(memoriesList
          .where((m) => m.category == category || m.category == cleanCategory));
    }
    return results;
  }

  List<dynamic> _allPhotoMemories() {
    final results = <dynamic>[];
    final seen = <String>{};
    for (final item in memoriesList.where(
        (m) => m.type == 'image' && _memoryItemImageCandidates(m).isNotEmpty)) {
      final key = _memoryItemImageCandidates(item).first;
      if (seen.add(key)) results.add(item);
    }
    for (final moment in memoryMoments.where(_hasDisplayableMemoryMoment)) {
      final key = _memoryMomentImageCandidates(moment).first;
      if (seen.add(key)) results.add(moment);
    }
    return results;
  }

  List<String> _memoryItemImageCandidates(MemoryItem item) {
    final seen = <String>{};
    return [item.assetPath, item.content]
        .map((value) => value?.trim() ?? '')
        .where((value) => value.isNotEmpty)
        .where(_hasDisplayableMemoryImage)
        .where((value) => seen.add(value))
        .toList();
  }

  List<MemoryItem> _dedupeMemoryItems(List<MemoryItem> items) {
    final results = <MemoryItem>[];
    final seen = <String>{};
    for (final item in items) {
      final candidates = _memoryItemImageCandidates(item);
      final key = candidates.isNotEmpty ? candidates.first : item.id;
      if (key.isEmpty || !seen.add(key)) continue;
      results.add(item);
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
      backendSyncError =
          'لا يوجد residentId من السيرفر لإضافة دواء لـ $residentName';
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

    triggerNotification(
      title: 'تمت إضافة جرعة دواء جديدة 💊',
      body:
          'قام فريق التمريض بإضافة دواء (${med.name}) لخطة $residentName العلاجية.',
      type: 'medical',
      targetRole: 'عائلة',
    );

    notifyListeners();
    unawaited(syncBackendData());
  }

  Future<void> logMedicalSession(MedicalSession session) async {
    final residentId = _residentIdForName(session.residentName);
    if (residentId == null) {
      backendSyncError =
          'لا يوجد residentId من السيرفر لتسجيل جلسة ${session.residentName}';
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
    unawaited(syncBackendData());
  }

  Future<void> addPrescription(MedicalPrescription p) async {
    final residentId = _residentIdForName(p.residentName);
    if (residentId == null) {
      backendSyncError =
          'لا يوجد residentId من السيرفر لإضافة روشتة لـ ${p.residentName}';
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

    triggerNotification(
      title: 'روشتة طبية جديدة 📄',
      body:
          'تمت إضافة روشتة طبية جديدة لـ ${p.residentName} بواسطة ${p.doctorName}.',
      type: 'medical',
      targetRole: 'عائلة',
    );

    notifyListeners();
    unawaited(syncBackendData());
  }

  List<CenterOperationalStat> get adminStats {
    final capacity = _firstInt(facilityProfileSettings?.facilityCapacity ??
            currentAccount?.facilityCapacity ??
            '') ??
        0;
    final occupancy =
        capacity > 0 ? (residentFiles.length / capacity) * 100 : 0.0;

    final revenueValue = familyBills
        .where((bill) => bill.isPaid)
        .fold<double>(0.0, (total, bill) => total + bill.amount);

    final revenueStr = revenueValue.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},');

    double satisfactionValue = 0.0;
    if (volunteerRatings.isNotEmpty) {
      satisfactionValue =
          volunteerRatings.map((r) => r.score).reduce((a, b) => a + b) /
              volunteerRatings.length;
    }

    return [
      CenterOperationalStat(
          label: 'نسبة الإشغال',
          value: '${occupancy.toInt()}٪',
          trend: lastBackendSyncAt == null
              ? 'بانتظار مزامنة السيرفر'
              : 'آخر تحديث من السيرفر',
          isPositive: occupancy <= 100,
          history: [occupancy / 100]),
      CenterOperationalStat(
          label: selectedAdminDateFilter == 'اليوم'
              ? 'إيرادات اليوم'
              : (selectedAdminDateFilter == 'أسبوع'
                  ? 'إيرادات الأسبوع'
                  : 'إيرادات الشهر'),
          value: '$revenueStr ج.م',
          trend: lastBackendSyncAt == null
              ? 'بانتظار مزامنة السيرفر'
              : 'من فواتير السيرفر المدفوعة',
          isPositive: revenueValue > 0,
          history: [revenueValue / 1000]),
      CenterOperationalStat(
          label: 'الحالات الحرجة',
          value: '$criticalResidentsCount',
          trend: criticalResidentsCount > 0 ? 'تحتاج متابعة' : 'لا توجد حالات',
          isPositive: criticalResidentsCount <= 2,
          history: [criticalResidentsCount.toDouble()]),
      CenterOperationalStat(
          label: 'رضا الأهالي',
          value: '${satisfactionValue.toStringAsFixed(1)} / ٥',
          trend: volunteerRatings.isEmpty
              ? 'لا توجد تقييمات من السيرفر'
              : 'آخر تقييمات السيرفر',
          isPositive: satisfactionValue >= 3.5,
          history: [satisfactionValue]),
    ];
  }

  List<StaffPerformance> staffPerformanceList = [];
  int totalCapacity = 50; // السعة الإجمالية للدار

  // --- MEMORY WALL ---

  List<MemoryMoment> memoryMoments = [];

  int currentElderlyTabIndex = 0;
  void setElderlyTabIndex(int index) {
    currentElderlyTabIndex = index;
    notifyListeners();
  }

  MemoryMoment? get latestMemoryMoment =>
      memoryMoments.isNotEmpty ? memoryMoments.first : null;

  bool hasGalleryPermission = false;

  // --- NURSING OPERATIONS STATE ---
  List<CareTask> careTasks = [];

  List<InventoryItem> inventoryItems = [];

  List<DoctorVisit> doctorVisits = [];

  List<MealPlan> mealPlans = [];

  List<ActivitySession> activitySessions = [];

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

  void sendSpecialistMessage(String text,
      {String? mediaPath, String? mediaType}) {
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
    if (AuthService.instance.currentUser == null) return;
    isLoadingSpecialistChat = true;
    notifyListeners();
  }

  void sendSpecialistReply(String text,
      {String? mediaPath, String? mediaType}) {
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

  // AI Shift Handoff
  Future<String> generateShiftSummary(String residentName) async {
    final notes = getNotesForResident(residentName);
    final tasks =
        careTasks.where((t) => t.residentName == residentName).toList();
    return await AiService.instance.summarizeShiftHandoff(notes, tasks);
  }

  // Smart Diet Planner
  Future<MealPlan> generateAndSaveMealPlan(String residentLookup) async {
    final resident = findResidentForNutrition(residentLookup);
    if (resident == null) {
      backendSyncError =
          'لم يتم العثور على مقيم بهذا الاسم أو رقم الغرفة أو الكود';
      notifyListeners();
      throw ApiException(404, backendSyncError!);
    }

    final info = getNutritionMedicalInfo(resident);
    final plan = await AiService.instance.generateSmartDiet(info);

    final idx = mealPlans.indexWhere((m) => m.residentName == resident.name);
    if (idx != -1) {
      mealPlans[idx] = plan;
    } else {
      mealPlans.add(plan);
    }
    notifyListeners();

    final existingId = mealPlanIdsByResidentName[resident.name];
    final synced = await _runBackendMutation(() {
      if (existingId != null && existingId.isNotEmpty) {
        return BackendMutationService.instance.updateMealPlan(
          id: existingId,
          plan: plan,
        );
      }
      return BackendMutationService.instance.createMealPlan(
        residentId: resident.id,
        plan: plan,
      );
    });
    if (synced) unawaited(syncBackendData());
    return plan;
  }

  // Predictive Alerts
  List<AIInsight> predictiveAlerts = [];
  Future<void> fetchPredictiveAlerts() async {
    if (backendResidentId != null) {
      predictiveAlerts = await AiService.instance
          .getPredictiveHealthAlerts(backendResidentId!);
      notifyListeners();
    } else {
      if (residentFiles.isNotEmpty) {
        predictiveAlerts = await AiService.instance
            .getPredictiveHealthAlerts(residentFiles.first.id);
        notifyListeners();
      }
    }
  }

  // Auto-Generated Family Updates
  String latestFamilyUpdate = "";
  Future<void> fetchFamilyUpdate() async {
    final residentId = _familyUpdateResidentId();
    var generatedUpdate = '';

    if (residentId != null) {
      try {
        generatedUpdate =
            (await AiService.instance.generateFamilyWeeklyUpdate(residentId))
                .trim();
      } catch (_) {
        generatedUpdate = '';
      }
    }

    latestFamilyUpdate = generatedUpdate.isNotEmpty
        ? generatedUpdate
        : _buildLocalFamilyWeeklyUpdate();
    notifyListeners();
  }

  String? _familyUpdateResidentId() {
    if (_looksLikeBackendId(backendResidentId)) return backendResidentId;

    final linkedResidentId = currentAccount?.linkedResidentId;
    if (_looksLikeBackendId(linkedResidentId)) return linkedResidentId;

    for (final resident in residentFiles) {
      if (_looksLikeBackendId(resident.id)) return resident.id;
    }
    return null;
  }

  String _familyUpdateResidentName() {
    final linkedResidentId = currentAccount?.linkedResidentId;
    for (final resident in residentFiles) {
      if (resident.id == linkedResidentId && resident.name.trim().isNotEmpty) {
        return resident.name.trim();
      }
    }

    if (residentFiles.isNotEmpty &&
        residentFiles.first.name.trim().isNotEmpty) {
      return residentFiles.first.name.trim();
    }
    return 'والدك';
  }

  String _metricStatusArabic(String status) {
    switch (status) {
      case 'good':
        return 'ممتاز';
      case 'medium':
        return 'يحتاج متابعة';
      case 'critical':
        return 'يحتاج انتباه';
      default:
        return status.isEmpty ? 'مستقر' : status;
    }
  }

  String _shortFamilyUpdateText(String value, {int maxLength = 100}) {
    final text = value.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength).trim()}...';
  }

  String _buildLocalFamilyWeeklyUpdate() {
    final residentName = _familyUpdateResidentName();
    final observations = <String>[];

    if (familyHealthMetrics.isNotEmpty) {
      final metrics = familyHealthMetrics.take(4).map((metric) {
        final percent = (metric.value * 100).round();
        return '${metric.label} $percent% (${_metricStatusArabic(metric.status)})';
      }).join('، ');
      observations.add('مؤشرات اليوم: $metrics.');
    }

    final todayMedications =
        medications.where((med) => med.dayTag == 'اليوم').toList();
    if (todayMedications.isNotEmpty) {
      final confirmed = todayMedications
          .where((med) => med.isTaken || med.isElderlyConfirmed)
          .length;
      final missed = todayMedications.where((med) => med.isMissed).length;
      final skipped = todayMedications.where((med) => med.isSkipped).length;
      final details = <String>[
        'تم تأكيد $confirmed من ${todayMedications.length} جرعات اليوم',
        if (missed > 0) '$missed جرعات تحتاج مراجعة',
        if (skipped > 0) '$skipped جرعات تم تجاوزها',
      ];
      observations.add('الأدوية: ${details.join('، ')}.');
    }

    final currentActivities = activities
        .where((activity) =>
            activity.dayTag == 'اليوم' || activity.dayTag == 'الأسبوع')
        .toList();
    if (currentActivities.isNotEmpty) {
      final done = currentActivities
          .where((activity) => activity.status == 'done')
          .length;
      observations.add(
          'الأنشطة: تم إنجاز $done من ${currentActivities.length} نشاط مسجل.');
    }

    if (currentMood.trim().isNotEmpty) {
      observations.add('المزاج المسجل حالياً: ${currentMood.trim()}.');
    }

    if (careReports.isNotEmpty) {
      final report = careReports.first;
      final summary = _shortFamilyUpdateText(report.summary);
      if (summary.isNotEmpty) {
        observations.add('آخر تقرير رعاية: $summary.');
      }
    }

    final nextVisit = familyVisits.cast<FamilyVisit?>().firstWhere(
          (visit) =>
              visit != null &&
              (visit.status == 'pending' || visit.status == 'upcoming'),
          orElse: () => null,
        );
    if (nextVisit != null) {
      observations.add(
          'هناك زيارة عائلية ${nextVisit.status == 'pending' ? 'بانتظار التأكيد' : 'قادمة'} يوم ${nextVisit.date} الساعة ${nextVisit.time}.');
    }

    if (observations.isEmpty) return '';

    return [
      'تحديث هذا الأسبوع عن $residentName:',
      ...observations.take(5).map((item) => '- $item'),
      'الخلاصة: الحالة مستقرة إجمالاً، واستمرار المتابعة اليومية والتواصل مع الفريق يساعد على ملاحظة أي تغير مبكراً.',
    ].join('\n');
  }

  // Cognitive Games
  List<CognitiveGameResult> cognitiveScores = [];
  CognitiveGameResult? _cognitiveGameResult;
  CognitiveGameResult? get cognitiveGameResult => _cognitiveGameResult;

  Future<void> fetchCognitiveGame() async {
    await Future.delayed(const Duration(seconds: 1));
    _cognitiveGameResult = CognitiveGameResult(
      id: 'mock_game_1',
      residentId: backendResidentId ?? 'unknown',
      score: 8,
      feedback: "ذاكرة قوية وانتباه جيد.",
      date: DateTime.now(),
    );
    notifyListeners();
  }

  void saveCognitiveGameResult(CognitiveGameResult result) {
    _cognitiveGameResult = result;
    cognitiveScores.add(result);
    notifyListeners();
  }

  Future<AiChatResponse> sendCognitiveGameInput(String input) async {
    final resId = backendResidentId ?? 'unknown';
    final res = await AiService.instance.playCognitiveGame(resId, input);
    notifyListeners();
    return res;
  }
}
