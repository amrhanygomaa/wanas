// ignore_for_file: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
// تذكيرات أدوية الأسرة وبعض الـ getters المساعدة
// جزء (part) من مكتبة app_riverpod.dart — يوسّع AppRiverpod عبر extension.
part of 'app_riverpod.dart';

extension AppRiverpodFamilyReminders on AppRiverpod {
  String _familyMedicationReminderKey(Medication medication) {
    final scheduled = medication.scheduledTime;
    if (scheduled == null) return medication.id;
    final date =
        '${scheduled.year}-${scheduled.month.toString().padLeft(2, '0')}-${scheduled.day.toString().padLeft(2, '0')}';
    return '${medication.id}|$date';
  }

  void _pruneFamilyMedicationReminderKeys() {
    final activeKeys = medications.map(_familyMedicationReminderKey).toSet();
    _familyRemindedMedicationKeys
        .removeWhere((key) => !activeKeys.contains(key));
  }

  Medication? get familyMedicationReminder {
    _pruneFamilyMedicationReminderKeys();
    final now = DateTime.now();
    final dueMeds = medications.where((m) {
      final isDue = m.scheduledTime == null || !m.scheduledTime!.isAfter(now);
      return m.dayTag == 'اليوم' &&
          !m.isTaken &&
          !m.isElderlyConfirmed &&
          !m.isSkipped &&
          isDue &&
          !_familyRemindedMedicationKeys
              .contains(_familyMedicationReminderKey(m));
    }).toList()
      ..sort((a, b) {
        final aTime = a.scheduledTime ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bTime = b.scheduledTime ?? DateTime.fromMillisecondsSinceEpoch(0);
        return aTime.compareTo(bTime);
      });

    return dueMeds.isEmpty ? null : dueMeds.first;
  }

  int get remainingSecondsToNextFamilyReminder {
    _pruneFamilyMedicationReminderKeys();
    final now = DateTime.now();
    final upcomingMeds = medications.where((m) {
      return m.dayTag == 'اليوم' &&
          !m.isTaken &&
          !m.isElderlyConfirmed &&
          !m.isSkipped &&
          m.scheduledTime != null &&
          m.scheduledTime!.isAfter(now) &&
          !_familyRemindedMedicationKeys
              .contains(_familyMedicationReminderKey(m));
    }).toList()
      ..sort((a, b) => a.scheduledTime!.compareTo(b.scheduledTime!));

    if (upcomingMeds.isEmpty) return 0;
    return upcomingMeds.first.scheduledTime!.difference(now).inSeconds;
  }

  int get remainingSecondsToNextMed {
    final next = nextMedication;
    if (next == null || next.scheduledTime == null) return 0;
    final diff = next.scheduledTime!.difference(DateTime.now()).inSeconds;
    return diff > 0 ? diff : 0;
  }

  List<FamilyMember> get familyMembers => familyMembersList;

  String _activeResidentIdForFamilyCard(String? residentId) {
    final explicit = residentId?.trim() ?? '';
    if (_looksLikeBackendId(explicit)) return explicit;

    final backend = backendResidentId?.trim() ?? '';
    if (_looksLikeBackendId(backend)) return backend;

    final linked = currentAccount?.linkedResidentId?.trim() ?? '';
    if (_looksLikeBackendId(linked)) return linked;

    if (residentFiles.length == 1 &&
        _looksLikeBackendId(residentFiles.first.id)) {
      return residentFiles.first.id;
    }
    return '';
  }

  String _familyCardPreferenceKey(String? residentId) {
    final activeResidentId = _activeResidentIdForFamilyCard(residentId);
    if (activeResidentId.isNotEmpty) return activeResidentId;

    final accountKey = currentAccount?.email.trim();
    if (accountKey != null && accountKey.isNotEmpty) return accountKey;

    final userId = backendUserId?.trim() ?? '';
    if (userId.isNotEmpty) return userId;

    return 'default';
  }

  String _familyCardStorageKey(String preferenceKey, String suffix) {
    final safeKey =
        base64Url.encode(utf8.encode(preferenceKey)).replaceAll('=', '');
    return 'resident_family_card_${suffix}_$safeKey';
  }

  int _clampFamilyCardLimit(int value) {
    return value.clamp(1, AppRiverpod._maxFamilyCardLimit).toInt();
  }

  Future<void> loadFamilyCardPreferences({String? residentId}) async {
    final preferenceKey = _familyCardPreferenceKey(residentId);
    if (_loadedFamilyCardPreferenceKeys.contains(preferenceKey)) return;

    try {
      final favoritesRaw = await _storage.read(
        key: _familyCardStorageKey(preferenceKey, 'favorites'),
      );
      if (favoritesRaw != null && favoritesRaw.trim().isNotEmpty) {
        final decoded = jsonDecode(favoritesRaw);
        if (decoded is List) {
          _favoriteFamilyMemberIdsByResident[preferenceKey] = decoded
              .map((value) => value.toString().trim())
              .where((value) => value.isNotEmpty)
              .toSet();
        }
      }

      final limitRaw = await _storage.read(
        key: _familyCardStorageKey(preferenceKey, 'limit'),
      );
      final limit = int.tryParse(limitRaw ?? '');
      if (limit != null) {
        _familyCardLimitByResident[preferenceKey] =
            _clampFamilyCardLimit(limit);
      }

      _loadedFamilyCardPreferenceKeys.add(preferenceKey);
      _pruneFamilyCardFavorites(preferenceKey);
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to load family card preferences: $e');
    }
  }

  List<FamilyMember> familyMembersForCurrentResident({String? residentId}) {
    final activeResidentId = _activeResidentIdForFamilyCard(residentId);
    final byId = <String, FamilyMember>{};

    void addIfLinked(FamilyMember member) {
      final memberResidentId = member.residentId?.trim() ?? '';
      if (memberResidentId.isEmpty) return;
      if (activeResidentId.isNotEmpty && memberResidentId != activeResidentId) {
        return;
      }
      byId[member.id] = member;
    }

    for (final member in familyMembersList) {
      addIfLinked(member);
    }
    for (final resident in residentFiles) {
      if (activeResidentId.isNotEmpty && resident.id != activeResidentId) {
        continue;
      }
      for (final member in resident.familyMembers) {
        addIfLinked(member);
      }
    }

    return byId.values.toList();
  }

  Set<String> _defaultFamilyFavoriteIds(List<FamilyMember> members) {
    final pinnedIds = members
        .where((member) => member.isPinned)
        .map((member) => member.id)
        .where((id) => id.isNotEmpty)
        .toSet();
    if (pinnedIds.isNotEmpty) return pinnedIds;
    return members
        .map((member) => member.id)
        .where((id) => id.isNotEmpty)
        .toSet();
  }

  Set<String> _effectiveFamilyFavoriteIds(
    String preferenceKey,
    List<FamilyMember> members,
  ) {
    if (_favoriteFamilyMemberIdsByResident.containsKey(preferenceKey)) {
      return Set<String>.from(
          _favoriteFamilyMemberIdsByResident[preferenceKey]!);
    }
    return _defaultFamilyFavoriteIds(members);
  }

  List<FamilyMember> favoriteFamilyMembersForCurrentResident({
    String? residentId,
    bool ignoreLimit = false,
  }) {
    final members = familyMembersForCurrentResident(residentId: residentId);
    if (members.isEmpty) return const [];

    final preferenceKey = _familyCardPreferenceKey(residentId);
    final favoriteIds = _effectiveFamilyFavoriteIds(preferenceKey, members);
    final selected =
        members.where((member) => favoriteIds.contains(member.id)).toList();
    final limit = ignoreLimit
        ? selected.length
        : familyCardDisplayLimitForCurrentResident(residentId: residentId);
    return selected.take(limit).toList();
  }

  int familyCardDisplayLimitForCurrentResident({String? residentId}) {
    final preferenceKey = _familyCardPreferenceKey(residentId);
    return _familyCardLimitByResident[preferenceKey] ??
        AppRiverpod._defaultFamilyCardLimit;
  }

  bool isFamilyCardFavorite(String memberId, {String? residentId}) {
    final members = familyMembersForCurrentResident(residentId: residentId);
    final preferenceKey = _familyCardPreferenceKey(residentId);
    final favoriteIds = _effectiveFamilyFavoriteIds(preferenceKey, members);
    return favoriteIds.contains(memberId);
  }

  Future<void> setFamilyCardFavorite(
    String memberId,
    bool isFavorite, {
    String? residentId,
  }) async {
    final members = familyMembersForCurrentResident(residentId: residentId);
    final preferenceKey = _familyCardPreferenceKey(residentId);
    final favoriteIds = _effectiveFamilyFavoriteIds(preferenceKey, members);

    if (isFavorite) {
      favoriteIds.add(memberId);
    } else {
      favoriteIds.remove(memberId);
    }

    _favoriteFamilyMemberIdsByResident[preferenceKey] = favoriteIds;
    await _storage.write(
      key: _familyCardStorageKey(preferenceKey, 'favorites'),
      value: jsonEncode(favoriteIds.toList()),
    );
    notifyListeners();
  }

  Future<void> setFamilyCardDisplayLimit(
    int limit, {
    String? residentId,
  }) async {
    final preferenceKey = _familyCardPreferenceKey(residentId);
    final clamped = _clampFamilyCardLimit(limit);
    _familyCardLimitByResident[preferenceKey] = clamped;
    await _storage.write(
      key: _familyCardStorageKey(preferenceKey, 'limit'),
      value: clamped.toString(),
    );
    notifyListeners();
  }

  void _pruneFamilyCardFavorites(String preferenceKey) {
    if (!_favoriteFamilyMemberIdsByResident.containsKey(preferenceKey)) return;

    final validIds = familyMembersForCurrentResident(residentId: preferenceKey)
        .map((member) => member.id)
        .toSet();
    final favorites = _favoriteFamilyMemberIdsByResident[preferenceKey]!;
    final before = favorites.length;
    favorites.removeWhere((id) => !validIds.contains(id));
    if (favorites.length == before) return;

    unawaited(_storage.write(
      key: _familyCardStorageKey(preferenceKey, 'favorites'),
      value: jsonEncode(favorites.toList()),
    ));
  }

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
              final backendId = await BackendMutationService.instance
                  .createFamilyMemberFromPhone(
                residentId: backendResidentId!,
                name: name,
                phone: phone,
              );
              if (backendId != null && backendId.isNotEmpty) {
                memberId = backendId;
              }
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
            final backendId = await BackendMutationService.instance
                .createFamilyMemberFromPhone(
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
        positiveRatings: volunteerRatings.where((r) => r.score >= 4).length,
        totalHours: volunteerHours,
      );
}
