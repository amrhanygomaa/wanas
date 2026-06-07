// ignore_for_file: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
// عمليات التمريض ومهام الرعاية والمخزون وزيارات الأطباء
// جزء (part) من مكتبة app_riverpod.dart — يوسّع AppRiverpod عبر extension.
part of 'app_riverpod.dart';

extension AppRiverpodNursingOps on AppRiverpod {
  // Nursing Operations Methods
  Future<void> toggleCareTask(String id) async {
    final idx = careTasks.indexWhere((t) => t.id == id);
    if (idx != -1) {
      final shouldComplete = !careTasks[idx].isCompleted;
      final synced = await _runBackendMutation(() {
        return shouldComplete
            ? BackendMutationService.instance.completeCareTask(id)
            : BackendMutationService.instance.reopenCareTask(id);
      });
      if (!synced) return;
      careTasks[idx].isCompleted = shouldComplete;
      notifyListeners();
      unawaited(syncBackendData());
    }
  }

  Future<void> addCareTask(CareTask task) async {
    final residentId = _residentIdForName(task.residentName);
    if (residentId == null) {
      backendSyncError =
          'لا يوجد residentId من السيرفر لإضافة مهمة لـ ${task.residentName}';
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
    unawaited(syncBackendData());
  }

  Future<void> deleteCareTask(String id) async {
    final synced = await _runBackendMutation(() {
      return BackendMutationService.instance.deleteCareTask(id);
    });
    if (!synced) return;
    careTasks.removeWhere((t) => t.id == id);
    notifyListeners();
    unawaited(syncBackendData());
  }

  Future<void> addInventoryItem(InventoryItem item) async {
    final synced = await _runBackendMutation(() {
      return BackendMutationService.instance.createInventoryItem(item);
    });
    if (!synced) return;
    inventoryItems.add(item);
    notifyListeners();
    unawaited(syncBackendData());
  }

  Future<void> deleteInventoryItem(String id) async {
    final synced = await _runBackendMutation(() {
      return BackendMutationService.instance.deleteInventoryItem(id);
    });
    if (!synced) return;
    inventoryItems.removeWhere((i) => i.id == id);
    notifyListeners();
    unawaited(syncBackendData());
  }

  Future<void> addDoctorVisit(DoctorVisit visit) async {
    final residentId = _residentIdForName(visit.residentName);
    if (residentId == null) {
      backendSyncError =
          'لا يوجد residentId من السيرفر لإضافة زيارة طبيب لـ ${visit.residentName}';
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
    unawaited(syncBackendData());
  }

  Future<void> deleteDoctorVisit(String id) async {
    final synced = await _runBackendMutation(() {
      return BackendMutationService.instance.deleteDoctorVisit(id);
    });
    if (!synced) return;
    doctorVisits.removeWhere((v) => v.id == id);
    notifyListeners();
    unawaited(syncBackendData());
  }

  Future<void> addMealPlan(MealPlan plan) async {
    final resident = findResidentForNutrition(plan.residentName);
    final residentName = resident?.name ?? plan.residentName.trim();
    final residentId =
        resident != null ? resident.id : _residentIdForName(residentName);
    if (residentId == null) {
      backendSyncError =
          'لا يوجد residentId من السيرفر لإضافة خطة وجبات لـ $residentName';
      notifyListeners();
      return;
    }
    final planToSave = _mealPlanWithResidentName(plan, residentName);
    final synced = await _runBackendMutation(() {
      return BackendMutationService.instance.createMealPlan(
        residentId: residentId,
        plan: planToSave,
      );
    });
    if (!synced) return;
    mealPlans.add(planToSave);
    notifyListeners();
    unawaited(syncBackendData());
  }

  Future<void> deleteMealPlan(String residentName) async {
    final id = mealPlanIdsByResidentName[residentName];
    if (id == null || id.isEmpty) {
      backendSyncError = 'لا يوجد mealPlanId من السيرفر لحذف خطة $residentName';
      notifyListeners();
      return;
    }
    final synced = await _runBackendMutation(() {
      return BackendMutationService.instance.deleteMealPlan(id);
    });
    if (!synced) return;
    mealPlans.removeWhere((p) => p.residentName == residentName);
    notifyListeners();
    unawaited(syncBackendData());
  }

  Future<void> addActivitySession(ActivitySession session) async {
    final synced = await _runBackendMutation(() {
      return BackendMutationService.instance.createActivitySession(session);
    });
    if (!synced) return;
    activitySessions.add(session);
    notifyListeners();
    unawaited(syncBackendData());
  }

  Future<void> deleteActivitySession(String id) async {
    final synced = await _runBackendMutation(() {
      return BackendMutationService.instance.deleteActivity(id);
    });
    if (!synced) return;
    activitySessions.removeWhere((s) => s.id == id);
    notifyListeners();
    unawaited(syncBackendData());
  }

  Future<void> deleteMedicalSession(String id) async {
    final synced = await _runBackendMutation(() {
      return BackendMutationService.instance.deleteMedicalSession(id);
    });
    if (!synced) return;
    medicalSessions.removeWhere((s) => s.id == id);
    notifyListeners();
    unawaited(syncBackendData());
  }

  Future<void> deletePrescription(String id) async {
    final synced = await _runBackendMutation(() {
      return BackendMutationService.instance.deletePrescription(id);
    });
    if (!synced) return;
    medicalPrescriptions.removeWhere((p) => p.id == id);
    notifyListeners();
    unawaited(syncBackendData());
  }

  Future<void> addSentReport(SentReport report) async {
    final synced = await _runBackendMutation(() {
      return BackendMutationService.instance.sendNursingReport(
        reportType: report.title,
        recipients: [
          if (currentAccount?.email.isNotEmpty == true) currentAccount!.email,
        ],
      );
    });
    if (!synced) return;
    sentReports.insert(0, report);
    notifyListeners();
    unawaited(syncBackendData());
  }

  void addReview(Review review) {
    reviews.insert(0, review);
    notifyListeners();
  }

  Future<void> addHandoff(ShiftHandoff handoff) {
    return submitHandoff(handoff);
  }

  Future<void> updateInventoryStock(String id, int change) async {
    final idx = inventoryItems.indexWhere((i) => i.id == id);
    if (idx != -1) {
      final newStock = inventoryItems[idx].currentStock + change;
      final synced = await _runBackendMutation(() {
        return BackendMutationService.instance.updateInventoryStock(
          id: id,
          currentStock: newStock,
        );
      });
      if (!synced) return;
      final newItem = InventoryItem(
        id: inventoryItems[idx].id,
        name: inventoryItems[idx].name,
        category: inventoryItems[idx].category,
        currentStock: newStock,
        minRequired: inventoryItems[idx].minRequired,
        unit: inventoryItems[idx].unit,
      );
      inventoryItems[idx] = newItem;
      notifyListeners();
      unawaited(syncBackendData());
    }
  }

  Future<void> updateMealPlan(MealPlan plan) async {
    final resident = findResidentForNutrition(plan.residentName);
    final residentName = resident?.name ?? plan.residentName.trim();
    final planToSave = _mealPlanWithResidentName(plan, residentName);
    final idx = mealPlans.indexWhere((p) => p.residentName == residentName);
    final id = mealPlanIdsByResidentName[residentName];
    if (id == null || id.isEmpty) {
      await addMealPlan(planToSave);
      return;
    }
    final synced = await _runBackendMutation(() {
      return BackendMutationService.instance.updateMealPlan(
        id: id,
        plan: planToSave,
      );
    });
    if (!synced) return;
    if (idx != -1) {
      mealPlans[idx] = planToSave;
    } else {
      mealPlans.add(planToSave);
    }
    notifyListeners();
    unawaited(syncBackendData());
  }

  MealPlan _mealPlanWithResidentName(MealPlan plan, String residentName) {
    return MealPlan(
      residentName: residentName,
      breakfast: plan.breakfast,
      lunch: plan.lunch,
      dinner: plan.dinner,
      snacks: plan.snacks,
      specialInstructions: plan.specialInstructions,
      isAiGenerated: plan.isAiGenerated,
      aiRationale: plan.aiRationale,
    );
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

    final idx = socialResidentScores.indexWhere((r) => r.id == residentId);
    if (idx != -1) {
      final r = socialResidentScores[idx];

      final updatedScores = Map<String, double>.from(r.scores);
      newScores.forEach((key, value) {
        updatedScores[key] = value;
      });

      socialResidentScores[idx] = SocialSpecialistResidentScore(
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
      unawaited(syncBackendData());
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

  Future<void> submitComplaint(
      String message, String type, String fromRole) async {
    final residentId =
        _looksLikeBackendId(backendResidentId) ? backendResidentId : null;
    try {
      await ComplaintsService.instance.create(
        category: _backendComplaintCategory(type),
        subject: type,
        description: message,
        priority: 'high',
        residentId: residentId,
      );
      backendSyncError = null;
    } catch (e) {
      backendSyncError = e.toString();
      notifyListeners();
      return;
    }

    final complaint = SocialSpecialistComplaint(
      id: 'comp_${DateTime.now().millisecondsSinceEpoch}',
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

    triggerNotification(
      title: 'تم إرسال طلبك بنجاح ✅',
      body: 'قام فريقنا باستلام طلبك بخصوص "$type" وسيتم التعامل معه فوراً.',
      type: 'system',
      targetRole: fromRole,
    );
    notifyListeners();
    unawaited(syncBackendData());
  }

  Future<void> requestConsultation(String type) async {
    final residentId =
        _looksLikeBackendId(backendResidentId) ? backendResidentId : null;
    try {
      await ComplaintsService.instance.create(
        category: 'general',
        subject: 'طلب استشارة $type',
        description: 'طلب استشارة مرسل من التطبيق',
        priority: 'medium',
        residentId: residentId,
      );
      backendSyncError = null;
    } catch (e) {
      backendSyncError = e.toString();
      notifyListeners();
      return;
    }

    triggerNotification(
      title: 'طلب استشارة مرسل 💬',
      body:
          'تم تحويل طلب الاستشارة الـ $type إلى الفريق المختص، سيتم التواصل معك قريباً.',
      type: 'medical',
      targetRole: 'أسرة',
    );
    notifyListeners();
    unawaited(syncBackendData());
  }

  Future<void> addVolunteerOpportunity(VolunteerOpportunity opp) async {
    final synced = await _runBackendMutation(() {
      return BackendMutationService.instance.createVolunteerOpportunity(opp);
    });
    if (!synced) return;
    volunteerOpportunities.insert(0, opp);

    triggerNotification(
      title: 'تم نشر الفرصة بنجاح 🌟',
      body: 'أصبحت فرصة "${opp.title}" متاحة الآن للمتطوعين.',
      type: 'system',
      targetRole: 'إدارة',
    );

    notifyListeners();
    unawaited(syncBackendData());
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
    unawaited(syncBackendData());
  }

  Future<bool> approveVolunteerApplication(String applicationId) async {
    final synced = await _runBackendMutation(() {
      return BackendMutationService.instance
          .approveVolunteerApplication(applicationId);
    });
    if (!synced) return false;
    final idx = volunteerApplications.indexWhere((a) => a.id == applicationId);
    if (idx != -1) {
      final a = volunteerApplications[idx];
      volunteerApplications[idx] = VolunteerApplication(
        id: a.id,
        opportunityId: a.opportunityId,
        opportunityTitle: a.opportunityTitle,
        volunteerName: a.volunteerName,
        status: 'confirmed',
        createdAt: a.createdAt,
      );
      notifyListeners();
    }
    return true;
  }

  Future<bool> rejectVolunteerApplication(String applicationId) async {
    final synced = await _runBackendMutation(() {
      return BackendMutationService.instance
          .rejectVolunteerApplication(applicationId);
    });
    if (!synced) return false;
    final idx = volunteerApplications.indexWhere((a) => a.id == applicationId);
    if (idx != -1) {
      final a = volunteerApplications[idx];
      volunteerApplications[idx] = VolunteerApplication(
        id: a.id,
        opportunityId: a.opportunityId,
        opportunityTitle: a.opportunityTitle,
        volunteerName: a.volunteerName,
        status: 'cancelled',
        createdAt: a.createdAt,
      );
      notifyListeners();
    }
    return true;
  }

  Future<void> rateVolunteerSession(String volunteerId, int ratingScore,
      {String comment = ''}) async {
    final synced = await _runBackendMutation(() {
      return BackendMutationService.instance.createVolunteerReview(
        toName: volunteerId,
        session: comment.isEmpty ? 'جلسة تطوع' : comment,
        score: ratingScore.toDouble(),
      );
    });
    if (!synced) return;

    if (ratingScore == 3) {
      addPoints(15);
    } else if (ratingScore == 2) {
      addPoints(5);
    }

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

    triggerNotification(
      title: 'شكراً لتقييمك! 💖',
      body: 'رأيك يهمنا جداً في تحسين جودة الرعاية المقدمة لك.',
      type: 'system',
      targetRole: 'مسن',
    );

    notifyListeners();
    unawaited(syncBackendData());
  }

  void sendEncouragementMessage(String messageType, {String? text}) {
    final familySenderName = (currentAccount?.name.trim().isNotEmpty ?? false)
        ? currentAccount!.name.trim()
        : 'العائلة';
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
      title: messageType == 'voice'
          ? 'رسالة صوتية من $familySenderName'
          : 'رسالة من $familySenderName',
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
    unawaited(_saveLocalAlbums());
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

  void sendFamilyMedicationReminder(Medication medication) {
    _familyRemindedMedicationKeys.add(_familyMedicationReminderKey(medication));
    sendMedicationReminder(medication.name);
  }

  Future<void> toggleMedicationTaken(String id) async {
    final index = medications.indexWhere((m) => m.id == id);
    if (index != -1) {
      bool newState = !medications[index].isTaken;
      await _syncMedicationDose(
          medications[index], newState ? 'given' : 'missed');
      if (backendSyncError != null) return;
      medications[index].isTaken = newState;
      medications[index].isElderlyConfirmed = newState;
      notifyListeners();
      unawaited(syncBackendData());
    }
  }
}
