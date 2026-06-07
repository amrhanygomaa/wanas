// ignore_for_file: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
// إدارة الحسابات والتسجيل والمصادقة وإعدادات المستخدم
// جزء (part) من مكتبة app_riverpod.dart — يوسّع AppRiverpod عبر extension.
part of 'app_riverpod.dart';

extension AppRiverpodAuthAccounts on AppRiverpod {

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
}
