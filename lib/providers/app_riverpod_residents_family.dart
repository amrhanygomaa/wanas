// ignore_for_file: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
// سجل التدقيق، تفضيلات العرض، أنشطة الأسرة، وأخطاء الذكاء الاصطناعي
// جزء (part) من مكتبة app_riverpod.dart — يوسّع AppRiverpod عبر extension.
part of 'app_riverpod.dart';

extension AppRiverpodResidentsFamily on AppRiverpod {
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
      final isOutgoing = call.callerId == backendUserId;
      isIncomingCall = !isOutgoing && call.status == 'ringing';
      isVideoCallActive = call.status == 'accepted' || isOutgoing;
      if (isIncomingCall) {
        // اسم المتصل = اسم المقيم (الطرف الذي بدأ المكالمة)
        final residentName = residentFiles
            .where((r) => r.id == call.residentId)
            .map((r) => r.name)
            .firstOrNull;
        activeCallerName =
            residentName?.isNotEmpty == true ? residentName! : 'المقيم';
      } else {
        activeCallerName = call.calleeName?.isNotEmpty == true
            ? call.calleeName!
            : 'مكالمة فيديو';
      }
      activeCallerInitials =
          activeCallerName.isNotEmpty ? activeCallerName[0] : '؟';
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

  Future<void> _syncUserPreferences() async {
    if (AuthService.instance.currentUser == null) return;
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

  String _registrationFacilityId() {
    final sessionFacilityId = backendFacilityId?.trim() ?? '';
    if (sessionFacilityId.isNotEmpty) return sessionFacilityId;
    return ApiConfig.defaultFacilityId.trim();
  }

  String _selfRegistrationRole(String role) {
    return switch (role) {
      'أسرة' || 'فرد أسرة' => 'Family',
      'متطوع' => 'Volunteer',
      _ => role,
    };
  }

  String _facilityIdForAdminRegistration({
    required String email,
    String? licenseNumber,
  }) {
    final source = (licenseNumber?.trim().isNotEmpty == true
            ? licenseNumber!.trim()
            : email.split('@').first)
        .toLowerCase();
    final normalized = source
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    if (normalized.isNotEmpty) return normalized;
    return 'facility-${DateTime.now().millisecondsSinceEpoch}';
  }

  Map<String, double> _pendingAssessmentScores(PendingAssessment assessment) {
    final scores = <String, double>{};
    for (final entry in assessment.scales.entries) {
      scores['scale_${entry.key}'] = entry.value.toDouble();
    }
    for (final entry in assessment.selections.entries) {
      scores['selection_${entry.key}'] = entry.value.toDouble();
    }
    return scores;
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

  String _normalizeResidentLookup(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll('غرفة', '')
        .replaceAll('room', '')
        .trim();
  }

  bool _residentMatchesLookup(SpecialistResidentFile resident, String lookup) {
    final query = _normalizeResidentLookup(lookup);
    if (query.isEmpty) return true;
    final fields = [
      resident.name,
      resident.nameEn,
      resident.nickname ?? '',
      resident.room,
      resident.id,
      resident.nationalId ?? '',
    ].map(_normalizeResidentLookup);

    return fields.any((field) => field == query) ||
        fields.any((field) => field.startsWith(query)) ||
        fields.any((field) => field.contains(query));
  }

  List<SpecialistResidentFile> searchResidentsForNutrition(String query) {
    final normalized = _normalizeResidentLookup(query);
    final matches = normalized.isEmpty
        ? residentFiles
        : residentFiles
            .where((resident) => _residentMatchesLookup(resident, normalized))
            .toList();

    int score(SpecialistResidentFile resident) {
      final fields = [
        resident.name,
        resident.nameEn,
        resident.nickname ?? '',
        resident.room,
        resident.id,
        resident.nationalId ?? '',
      ].map(_normalizeResidentLookup).toList();
      if (fields.any((field) => field == normalized)) return 0;
      if (fields.any((field) => field.startsWith(normalized))) return 1;
      return 2;
    }

    matches.sort((a, b) {
      final scoreCompare = score(a).compareTo(score(b));
      if (scoreCompare != 0) return scoreCompare;
      return a.name.compareTo(b.name);
    });
    return matches.take(8).toList();
  }

  SpecialistResidentFile? findResidentForNutrition(String lookup) {
    final matches = searchResidentsForNutrition(lookup);
    return matches.isEmpty ? null : matches.first;
  }

  ResidentMedicalInfo getNutritionMedicalInfo(SpecialistResidentFile resident) {
    final stored = getMedicalInfo(resident.name);
    final meds = medications
        .where((m) => m.residentName == resident.name)
        .map((m) => '${m.name} ${m.dosage}'.trim())
        .where((m) => m.isNotEmpty)
        .toList();

    return ResidentMedicalInfo(
      residentName: resident.name,
      medications: {...stored.medications, ...meds}.toList(),
      allergies: {
        ...stored.allergies,
        ...(resident.allergies ?? const <String>[]),
      }.toList(),
      chronicDiseases: {
        ...stored.chronicDiseases,
        ...(resident.chronicDiseases ?? const <String>[]),
        ...(resident.foodRestrictions ?? const <String>[]),
        if ((resident.dietType ?? '').trim().isNotEmpty) resident.dietType!,
      }.toList(),
    );
  }

  Future<String?> _syncMedicationDose(
    Medication medication,
    String status, {
    String? notes,
  }) async {
    if (AuthService.instance.currentUser == null) return null;

    try {
      final parts = medication.id.split('|');
      if (parts.length >= 4 && parts[0] == 'schedule') {
        final dose = await MedicationsService.instance.logDose(
          scheduleId: parts[1],
          residentId: parts[2],
          scheduledTime: medication.scheduledTime ?? DateTime.now(),
          status: status,
          notes: notes,
        );
        backendSyncError = null;
        return dose?['id']?.toString();
      } else if (parts.length >= 2 && parts[0] == 'dose') {
        final dose = await MedicationsService.instance.updateDose(
          doseId: parts[1],
          status: status,
          notes: notes,
        );
        backendSyncError = null;
        return dose?['id']?.toString() ?? parts[1];
      } else {
        return null;
      }
    } catch (e) {
      backendSyncError = e.toString();
    }
    notifyListeners();
    return null;
  }

  String? _residentIdFromMedicationId(Medication medication) {
    final parts = medication.id.split('|');
    if (parts.length >= 3 &&
        (parts[0] == 'schedule' || parts[0] == 'dose') &&
        _looksLikeBackendId(parts[2])) {
      return parts[2];
    }
    return _residentIdForName(medication.residentName ?? '');
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

  Future<bool> _runBackendMutation(Future<void> Function() mutation) async {
    if (AuthService.instance.currentUser == null) {
      backendSyncError = 'لا توجد جلسة السيرفر نشطة';
      notifyListeners();
      return false;
    }

    try {
      await mutation();
      backendSyncError = null;
      return true;
    } on ApiException catch (e) {
      backendSyncError = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      backendSyncError = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> login(String idRaw, String passRaw) async {
    final identifier = idRaw.trim();
    final password = passRaw.trim();

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
    } on ApiException catch (e) {
      backendSyncError = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      backendSyncError = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<CognitoNewPasswordChallenge?> beginTemporaryPasswordActivation(
    String idRaw,
    String passRaw,
  ) async {
    final identifier = idRaw.trim();
    final password = passRaw.trim();

    try {
      final challenge = await AuthService.instance.detectNewPasswordChallenge(
        identifier,
        password,
      );
      if (challenge != null) backendSyncError = null;
      return challenge;
    } on ApiException catch (e) {
      backendSyncError = e.message;
      notifyListeners();
      return null;
    } catch (e) {
      backendSyncError = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<bool> completeTemporaryPasswordActivation(
    CognitoNewPasswordChallenge challenge,
    String newPassword,
  ) async {
    try {
      final user = await AuthService.instance.completeNewPasswordChallenge(
        challenge: challenge,
        newPassword: newPassword,
      );
      await markBackendAuthenticated(
        email: user.email,
        role: user.arabicRole,
        userId: user.userId,
        facilityId: user.facilityId,
        name: user.name,
        linkedResidentId: user.linkedResidentId,
        facilityName: user.facilityName,
      );
      backendSyncError = null;
      return true;
    } on ApiException catch (e) {
      backendSyncError = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      backendSyncError = e.toString();
      notifyListeners();
      return false;
    }
  }

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
    earnedBadgeIds = {};
    newlyUnlockedBadge = null;
    _clearTransientBackendState();
    await _realtimeSub?.cancel();
    _realtimeSub = null;
    RealtimeService.instance.disconnect();
    await AuthService.instance.logout();
    unawaited(PushNotificationService.instance.removeToken());

    await _storage.delete(key: 'isAuthenticated');
    await _storage.delete(key: 'currentRole');
    await _storage.delete(key: 'userEmail');
    await _storage.delete(key: 'sessionExpiry');

    notifyListeners();
  }

  void _clearTransientBackendState() {
    backendSyncError = null;
    isBackendSyncing = false;
    mealPlanIdsByResidentName.clear();
    activeEmergencies.clear();
    activeVideoCallId = null;
    activeVideoCallJoinUrl = null;
  }

  void _clearBackendCollections() {
    residentFiles = [];
    residentMedicalInfos = [];
    medications = [];
    activities = [];
    activitySessions = [];
    socialComplaints = [];
    familyVisits = [];
    familyBills = [];
    memoryMoments = [];
    memoriesList = [];
    voiceMessagesList = [];
    careTasks = [];
    inventoryItems = [];
    doctorVisits = [];
    mealPlans = [];
    mealPlanIdsByResidentName.clear();
    medicalSessions = [];
    medicalPrescriptions = [];
    volunteerOpportunities = [];
    volunteerBookings = [];
    volunteerApplications = [];
    volunteerCertificates = [];
    volunteerRatings = [];
    volunteerReviews = [];
    notifications = [];
    nursingNotes = [];
    handoffs = [];
    socialNeeds = [];
    socialAssessmentTools = [];
    socialResidentScores = [];
    staffPerformanceList = [];
    sentReports = [];
    careReports = [];
    familyHealthMetrics = [];
    familyMembersList = [];
    assessmentHistory = [];
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
    unawaited(_syncUserPreferences());
    notifyListeners();
  }

  void toggleHighContrast() {
    isHighContrast = !isHighContrast;
    unawaited(_syncUserPreferences());
    notifyListeners();
  }

  Future<void> setBiometricEnabled(bool value) async {
    isBiometricEnabled = value;
    await _storage.write(key: 'isBiometricEnabled', value: value.toString());
    if (!value) {
      await _storage.delete(key: 'bio_email');
      await _storage.delete(key: 'bio_pass');
    }
    notifyListeners();
  }

  Future<void> saveBiometricCredentials(String email, String password) async {
    await _storage.write(key: 'bio_email', value: email);
    await _storage.write(key: 'bio_pass', value: password);
  }

  /// يُسجّل الدخول باستخدام الـ credentials المحفوظة للبيومتري
  Future<bool> loginWithBiometric() async {
    final email = await _storage.read(key: 'bio_email');
    final pass = await _storage.read(key: 'bio_pass');
    if (email == null || pass == null || email.isEmpty || pass.isEmpty) {
      return false;
    }
    return login(email, pass);
  }
}
