// ignore_for_file: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
// أذونات المعرض، تبويبات المسن، والوسائط
// جزء (part) من مكتبة app_riverpod.dart — يوسّع AppRiverpod عبر extension.
part of 'app_riverpod.dart';

extension AppRiverpodElderlyMedia on AppRiverpod {
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

  Future<void> uploadVolunteerDocument(String type, String fileName) async {
    if (type == 'cv') {
      volunteerProfile = volunteerProfile.copyWith(cvFileName: fileName);
    } else if (type == 'recommendation') {
      volunteerProfile =
          volunteerProfile.copyWith(recommendationFileName: fileName);
    }
    await updateVolunteerProfile(volunteerProfile);

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

  Future<void> acceptCall() async {
    isVideoCallActive = true;
    isIncomingCall = false;
    notifyListeners();
    final url = activeVideoCallJoinUrl;
    if ((url ?? '').isNotEmpty) await launchZoom(url);
  }

  void rejectCall() {
    isIncomingCall = false;
    notifyListeners();
  }

  void endVideoCall() {
    isVideoCallActive = false;
    notifyListeners();
  }

  Future<VoiceMessage?> sendVoiceMessageFromResident(
    String title, {
    String? audioPath,
    int durationSeconds = 0,
    String? recipientId,
    String? recipientName,
    String? familyMemberId,
  }) async {
    final residentId = _looksLikeBackendId(backendResidentId)
        ? backendResidentId
        : residentFiles.isNotEmpty
            ? residentFiles.first.id
            : null;
    if (residentId == null) {
      backendSyncError = 'لا يوجد residentId من السيرفر لإرسال الرسالة الصوتية';
      notifyListeners();
      return null;
    }
    final localId = DateTime.now().millisecondsSinceEpoch.toString();
    Map<String, dynamic>? backendMessage;
    try {
      final uploaded = await VoiceMessageService.instance.create(
        residentId: residentId,
        title: title,
        senderType: 'resident',
        recipientId: recipientId,
        familyMemberId: familyMemberId,
        filePath: audioPath,
        durationSeconds: durationSeconds,
      );
      backendMessage = uploaded.message;
      backendSyncError = null;
    } catch (e) {
      backendSyncError = e.toString();
      final failedMsg = VoiceMessage(
        id: localId,
        senderId: 'resident',
        title: title,
        timeDescription: 'الآن',
        audioUrl: audioPath,
        durationSeconds: durationSeconds,
        recipientId: recipientId ?? familyMemberId,
        recipientName: recipientName,
        deliveryStatus: 'failed',
        moderationStatus: 'pending',
      );
      voiceMessagesList.insert(0, failedMsg);
      notifyListeners();
      return failedMsg;
    }
    String field(List<String> keys, String fallback) {
      for (final key in keys) {
        final value = backendMessage?[key];
        if (value != null && value.toString().trim().isNotEmpty) {
          return value.toString();
        }
      }
      return fallback;
    }

    final newMsg = VoiceMessage(
      id: field(['id'], localId),
      senderId: 'resident', // Special ID for the resident themselves
      title: title,
      timeDescription: 'الآن',
      audioUrl: field([
        'audioUrl',
        'audio_url',
        'mediaUrl',
        'media_url',
        'downloadUrl',
        'download_url',
        'fileUrl',
        'file_url',
        'url',
      ], audioPath ?? '')
              .trim()
              .isEmpty
          ? audioPath
          : field([
              'audioUrl',
              'audio_url',
              'mediaUrl',
              'media_url',
              'downloadUrl',
              'download_url',
              'fileUrl',
              'file_url',
              'url',
            ], audioPath ?? ''),
      durationSeconds: durationSeconds,
      recipientId: recipientId ?? familyMemberId,
      recipientName: recipientName,
      deliveryStatus:
          field(['deliveryStatus', 'delivery_status', 'status'], 'sent'),
      moderationStatus: field(
        ['moderationStatus', 'moderation_status', 'approvalStatus'],
        'pending',
      ),
    );
    voiceMessagesList.insert(0, newMsg);
    await _deliverResidentVoiceMessageToFamilyChat(
      title: title,
      residentId: residentId,
      audioUrl: newMsg.audioUrl,
      durationSeconds: durationSeconds,
      requestedRecipientId: recipientId,
      requestedFamilyMemberId: familyMemberId,
    );

    // Add points for communicating!
    addPoints(15);

    triggerNotification(
      title: 'تم إرسال الرسالة! 🎙️',
      body: 'رسالتك الصوتية في طريقها لعائلتك الآن.',
      type: 'social',
      targetRole: 'مسن',
    );

    notifyListeners();
    unawaited(syncBackendData());
    return newMsg;
  }

  Future<void> _deliverResidentVoiceMessageToFamilyChat({
    required String title,
    required String residentId,
    required String? audioUrl,
    required int durationSeconds,
    String? requestedRecipientId,
    String? requestedFamilyMemberId,
  }) async {
    final cleanAudioUrl = audioUrl?.trim() ?? '';
    if (cleanAudioUrl.isEmpty) return;

    final recipients = <String>{};
    final cleanRequestedRecipientId = requestedRecipientId?.trim() ?? '';
    if (cleanRequestedRecipientId.isNotEmpty) {
      recipients.add(cleanRequestedRecipientId);
    } else if ((requestedFamilyMemberId ?? '').trim().isNotEmpty) {
      final member = familyMembersList
          .where((m) => m.id == requestedFamilyMemberId)
          .firstOrNull;
      final memberUserId = member?.userId?.trim() ?? '';
      if (memberUserId.isNotEmpty) recipients.add(memberUserId);
    } else {
      for (final member in familyMembersList) {
        final memberResidentId = member.residentId?.trim() ?? '';
        final belongsToResident =
            memberResidentId.isEmpty || memberResidentId == residentId;
        final memberUserId = member.userId?.trim() ?? '';
        if (belongsToResident && memberUserId.isNotEmpty) {
          recipients.add(memberUserId);
        }
      }
    }

    if (recipients.isEmpty) return;

    for (final familyUserId in recipients) {
      try {
        await MessagesService.instance.send(
          recipientId: familyUserId,
          body: 'رسالة صوتية من المقيم: $title',
          residentId: residentId,
          mediaUrl: cleanAudioUrl,
          mediaType: 'audio/mp4',
        );
      } catch (e) {
        backendSyncError = 'تم حفظ الرسالة الصوتية لكن تعذر توصيلها للشات: $e';
      }
    }

    unawaited(loadMessageInbox());
  }

  Future<void> sendVoiceMessageFromFamily(
    String title, {
    String? audioPath,
    int durationSeconds = 0,
  }) async {
    final residentId = _looksLikeBackendId(backendResidentId)
        ? backendResidentId
        : residentFiles.isNotEmpty
            ? residentFiles.first.id
            : null;
    if (residentId == null || !_looksLikeBackendId(residentId)) {
      backendSyncError = 'لا يوجد residentId من السيرفر لإرسال الرسالة الصوتية';
      notifyListeners();
      return;
    }
    try {
      await VoiceMessageService.instance.create(
        residentId: residentId,
        title: title,
        senderType: 'family',
        filePath: audioPath,
        durationSeconds: durationSeconds,
      );
      backendSyncError = null;
    } catch (e) {
      backendSyncError = e.toString();
      notifyListeners();
      return;
    }

    voiceMessagesList.insert(
      0,
      VoiceMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        senderId: 'family',
        title: title,
        timeDescription: 'الآن',
        durationSeconds: durationSeconds,
      ),
    );

    triggerNotification(
      title: 'رسالة صوتية من العائلة',
      body: title,
      type: 'family',
      targetRole: 'مسن',
    );

    notifyListeners();
    unawaited(syncBackendData());
  }
}
