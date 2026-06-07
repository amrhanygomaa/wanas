// ignore_for_file: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
// إعدادات المنشأة والفوترة وسجلّ التدقيق وسجل المكالمات
// جزء (part) من مكتبة app_riverpod.dart — يوسّع AppRiverpod عبر extension.
part of 'app_riverpod.dart';

extension AppRiverpodFacility on AppRiverpod {
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
    bool clearExistingData = true,
  }) {
    isAuthenticated = true;
    currentRole = role;
    backendUserId = userId;
    backendFacilityId = facilityId;
    if (_looksLikeBackendId(linkedResidentId)) {
      backendResidentId = linkedResidentId;
    }
    if (clearExistingData) {
      _clearBackendCollections();
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
      points: clearExistingData ? 0 : currentUser.points,
      streakDays: clearExistingData ? 0 : currentUser.streakDays,
      completedActivities:
          clearExistingData ? 0 : currentUser.completedActivities,
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
    // حمّل الأوسمة أولاً ثم ابدأ sync لتجنب إعادة إطلاق أوسمة مكتسبة مسبقاً
    unawaited(_loadEarnedBadges().then((_) => syncBackendData()));
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
    if (token == null) {
      if (isAuthenticated) {
        backendSyncError = 'لا توجد جلسة السيرفر نشطة';
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
      unawaited(loadLocalAlbums());
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
    if (currentRole == 'مسن') {
      unawaited(checkMedicationAdherence());
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
      // Deduplicate by id — backend may return duplicate rows
      final seen = <String>{};
      residentFiles = snapshot.residentFiles!
          .where((r) => r.id.isNotEmpty && seen.add(r.id))
          .toList();
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
      final localMoments =
          memoryMoments.where(_shouldPersistMemoryMoment).toList();
      memoryMoments =
          _dedupeMemoryMoments([...localMoments, ...snapshot.memoryMoments!]);
    }
    if (snapshot.memories != null) {
      final localMemories =
          memoriesList.where(_shouldPersistMemoryItem).toList();
      memoriesList =
          _dedupeMemoryItems([...localMemories, ...snapshot.memories!]);
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
    if (snapshot.volunteerApplications != null) {
      volunteerApplications = snapshot.volunteerApplications!;
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
      socialAssessmentTools = snapshot.socialAssessmentTools!.isNotEmpty
          ? snapshot.socialAssessmentTools!
          : _fallbackAssessmentTools();
    }
    if (snapshot.socialResidentScores != null) {
      final seenScores = <String>{};
      socialResidentScores = snapshot.socialResidentScores!
          .where((s) => s.id.isNotEmpty && seenScores.add(s.id))
          .toList();
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
      final preferenceKey =
          _familyCardPreferenceKey(snapshot.primaryResidentId);
      unawaited(
          loadFamilyCardPreferences(residentId: snapshot.primaryResidentId));
      _pruneFamilyCardFavorites(preferenceKey);
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
    _checkAndUnlockBadges();
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
}
