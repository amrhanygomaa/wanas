// ignore_for_file: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
// أنشطة الأسرة وتحديث AI واستجابة الطوارئ
// جزء (part) من مكتبة app_riverpod.dart — يوسّع AppRiverpod عبر extension.
part of 'app_riverpod.dart';

extension AppRiverpodActivitiesAiEmergency on AppRiverpod {
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
}
