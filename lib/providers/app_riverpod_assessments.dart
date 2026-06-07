// ignore_for_file: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
// تحميل تقييمات GDS والتقييمات التفصيلية
// جزء (part) من مكتبة app_riverpod.dart — يوسّع AppRiverpod عبر extension.
part of 'app_riverpod.dart';

extension AppRiverpodAssessments on AppRiverpod {
  Future<void> loadGdsQuestions() async {
    try {
      final raw = await SocialService.instance.getGdsQuestions();
      final loaded = raw
          .map((e) => AssessmentQuestion(
                id: (e['id'] ?? '').toString(),
                text: (e['text'] ?? '').toString(),
                type: (e['type'] ?? 'choice').toString(),
                options:
                    (e['options'] as List?)?.map((o) => o.toString()).toList(),
              ))
          .where((q) => q.id.isNotEmpty && q.text.isNotEmpty)
          .take(AppRiverpod.maxAssessmentQuestionsPerCategory)
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
        ..[toolId] = _limitedAssessmentQuestions(raw);
      notifyListeners();
    } catch (e) {
      questionBank = Map<String, List<Map<String, dynamic>>>.from(questionBank)
        ..putIfAbsent(toolId, () => _fallbackQuestionsForAssessmentKey(toolId));
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

  Future<void> addActivity(Activity activity) async {
    final synced = await _runBackendMutation(() {
      return BackendMutationService.instance.createActivity(activity);
    });
    if (!synced) return;
    activities.insert(0, activity);
    notifyListeners();
    unawaited(syncBackendData());
  }

  Future<void> updateActivity(Activity activity) async {
    final synced = await _runBackendMutation(() {
      return BackendMutationService.instance.updateActivity(activity);
    });
    if (!synced) return;
    final index = activities.indexWhere((a) => a.id == activity.id);
    if (index != -1) {
      activities[index] = activity;
      notifyListeners();
    }
    unawaited(syncBackendData());
  }

  Future<void> updateStaff(StaffPerformance staff) async {
    final synced = await _runBackendMutation(() {
      return BackendMutationService.instance.updateManagedUser(staff);
    });
    if (!synced) return;
    final index = staffPerformanceList.indexWhere((s) => s.id == staff.id);
    if (index != -1) {
      staffPerformanceList[index] = staff;
      notifyListeners();
    }
    unawaited(syncBackendData());
  }

  Future<bool> deleteStaff(String id) async {
    final staffIndex = staffPerformanceList.indexWhere(
        (s) => s.id == id || s.managedUserId == id || s.authUserId == id);
    if (staffIndex == -1) return false;

    final staff = staffPerformanceList[staffIndex];
    final synced = await _runBackendMutation(() {
      return BackendMutationService.instance.disableManagedUser(
        staff.managedUserId ?? staff.id,
        fallbackIds: [
          staff.id,
          if (staff.authUserId != null) staff.authUserId!,
        ],
      );
    });
    if (!synced) return false;
    staffPerformanceList.removeAt(staffIndex);
    notifyListeners();
    unawaited(syncBackendData());
    return true;
  }

  Future<bool?> pickAndSetResidentImage(String residentId) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image == null) return null;

    updateResidentImage(residentId, image.path);
    try {
      final uploaded = await ProfileImageService.instance.uploadResidentImage(
        residentId: residentId,
        image: image,
      );
      final remoteUrl = uploaded.imageUrl.trim();
      if (remoteUrl.isEmpty) {
        throw ApiException(500, 'لم يرجع الباك اند رابط صورة المقيم');
      }
      updateResidentImage(residentId, remoteUrl);
      backendSyncError = null;
      notifyListeners();
      unawaited(syncBackendData());
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

  void updateResidentImage(String residentId, String path) {
    final index = residentFiles.indexWhere((r) => r.id == residentId);
    if (index != -1) {
      residentFiles[index] = residentFiles[index].copyWith(imageUrl: path);
      notifyListeners();
    }
  }

  Future<bool?> pickAndSetStaffImage(String staffId) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image == null) return null;

    updateStaffImage(staffId, image.path);
    try {
      final uploaded = await ProfileImageService.instance.uploadStaffImage(
        staffId: staffId,
        image: image,
      );
      final remoteUrl = uploaded.imageUrl.trim();
      if (remoteUrl.isEmpty) {
        throw ApiException(500, 'لم يرجع الباك اند رابط صورة الموظف');
      }
      updateStaffImage(staffId, remoteUrl);
      backendSyncError = null;
      notifyListeners();
      unawaited(syncBackendData());
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

  void updateStaffImage(String staffId, String path) {
    final index = staffPerformanceList.indexWhere((s) => s.id == staffId);
    if (index != -1) {
      staffPerformanceList[index] =
          staffPerformanceList[index].copyWith(imageUrl: path);
      notifyListeners();
    }
  }

  Future<void> elderlyConfirmMedication(String id) async {
    final idx = medications.indexWhere((m) => m.id == id);
    if (idx != -1 &&
        !medications[idx].isTaken &&
        !medications[idx].isElderlyConfirmed) {
      final med = medications[idx];
      final doseId = await _syncMedicationDose(
        med,
        'pending',
        notes: MedicationsService.elderlyConfirmationNote,
      );
      if (backendSyncError != null) return;
      final residentId = _residentIdFromMedicationId(med);
      medications[idx] = med.copyWith(
        id: doseId != null && residentId != null
            ? 'dose|$doseId|$residentId'
            : null,
        isElderlyConfirmed: true,
        isSkipped: false,
      );

      // إرسال تنبيه للممرض لتأكيد الدواء
      triggerNotification(
        title: 'تأكيد دواء 💊',
        body:
            'المقيم أكد تناوله لدواء (${medications[idx].name}). يرجى التأكيد.',
        type: 'medical',
        targetRole: 'ممرض',
      );

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
    _checkAndUnlockBadges();
    notifyListeners();

    if (AuthService.instance.currentUser == null) return;
    unawaited(_syncUserPoints(
      p,
      completedActivitiesDelta: completedActivitiesDelta,
      streakDays: nextStreak,
    ));
  }

  void _checkAndUnlockBadges() {
    for (final badge in BadgeDefinition.all) {
      if (!earnedBadgeIds.contains(badge.id) && badge.isUnlocked(currentUser)) {
        earnedBadgeIds.add(badge.id);
        newlyUnlockedBadge = badge;
        unawaited(_saveEarnedBadges());
      }
    }
  }

  void clearBadgeNotification() {
    newlyUnlockedBadge = null;
    notifyListeners();
  }

  Future<void> _loadEarnedBadges() async {
    try {
      final uid = backendUserId ?? '';
      final raw = await _storage.read(key: 'earnedBadges_$uid');
      if (raw != null) {
        final list = jsonDecode(raw) as List;
        earnedBadgeIds = list.cast<String>().toSet();
      }
    } catch (_) {}
  }

  Future<void> _saveEarnedBadges() async {
    try {
      final uid = backendUserId ?? '';
      await _storage.write(
        key: 'earnedBadges_$uid',
        value: jsonEncode(earnedBadgeIds.toList()),
      );
    } catch (_) {}
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
    unawaited(_syncUserPreferences());
    notifyListeners();
  }

  void toggleAICompanion(bool value) {
    isAICompanionEnabled = value;
    unawaited(_syncUserPreferences());
    notifyListeners();
  }
}
