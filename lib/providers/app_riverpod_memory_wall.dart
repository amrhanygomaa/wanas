// ignore_for_file: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
// حائط الذكريات (Memory Wall) للأسرة
// جزء (part) من مكتبة app_riverpod.dart — يوسّع AppRiverpod عبر extension.
part of 'app_riverpod.dart';

extension AppRiverpodMemoryWall on AppRiverpod {
  List<MemoryMoment> memoryWallMoments({String? residentId}) {
    final filtered = memoryMoments.where((moment) {
      final matchesResident = residentId == null ||
          residentId.isEmpty ||
          moment.residentId == residentId;
      return matchesResident && _hasDisplayableMemoryMoment(moment);
    }).toList();
    return _dedupeMemoryMoments(filtered);
  }

  bool _hasDisplayableMemoryMoment(MemoryMoment moment) {
    return _memoryMomentImageCandidates(moment).any(_hasDisplayableMemoryImage);
  }

  List<String> _memoryMomentImageCandidates(MemoryMoment moment) {
    final seen = <String>{};
    return [moment.imageUrl, moment.fallbackPath]
        .map((value) => value?.trim() ?? '')
        .where((value) => value.isNotEmpty)
        .where((value) => seen.add(value))
        .toList();
  }

  bool _hasDisplayableMemoryImage(String imageUrl) {
    final value = imageUrl.trim();
    if (value.isEmpty) return false;
    if (value.startsWith('http://') ||
        value.startsWith('https://') ||
        value.startsWith('blob:') ||
        value.startsWith('data:image') ||
        (value.startsWith('/') && !value.startsWith('//'))) {
      return true;
    }
    return File(value).existsSync();
  }

  void upsertMemoryMoment(
    MemoryMoment moment, {
    String? replaceId,
    bool notify = true,
    bool save = true,
  }) {
    final existingIndex = memoryMoments.indexWhere((m) {
      if (replaceId != null && m.id == replaceId) return true;
      if (m.id == moment.id) return true;
      return m.imageUrl.trim().isNotEmpty &&
          moment.imageUrl.trim().isNotEmpty &&
          m.imageUrl == moment.imageUrl;
    });
    if (existingIndex == -1) {
      memoryMoments.insert(0, moment);
    } else {
      final existing = memoryMoments[existingIndex];
      memoryMoments[existingIndex] =
          replaceId != null && existing.id == replaceId
              ? moment
              : _preferDisplayableMemoryMoment(existing, moment);
    }
    _upsertMemoryItemFromMoment(moment, replaceId: replaceId);
    memoryMoments = _dedupeMemoryMoments(memoryMoments);
    if (notify) notifyListeners();
    if (save) unawaited(_saveLocalAlbums());
  }

  void _upsertMemoryItemFromMoment(MemoryMoment moment, {String? replaceId}) {
    if (!_hasDisplayableMemoryMoment(moment)) return;
    final itemId = 'wall_${moment.id}';
    final replaceItemId = replaceId == null ? null : 'wall_$replaceId';
    final existingIndex = memoriesList.indexWhere((item) =>
        item.id == itemId ||
        (replaceItemId != null && item.id == replaceItemId) ||
        (item.assetPath.isNotEmpty && item.assetPath == moment.imageUrl));
    final imageCandidates = _memoryMomentImageCandidates(moment);
    final item = MemoryItem(
      id: itemId,
      category: 'أسرة',
      title: moment.activityTitle,
      date: moment.date,
      type: 'image',
      assetPath: imageCandidates.first,
      content: imageCandidates.length > 1 ? imageCandidates[1] : null,
    );
    if (existingIndex == -1) {
      memoriesList.insert(0, item);
    } else {
      memoriesList[existingIndex] = item;
    }
  }

  List<MemoryMoment> _dedupeMemoryMoments(List<MemoryMoment> moments) {
    final results = <MemoryMoment>[];
    final indexes = <String, int>{};
    for (final moment in moments) {
      final keys = _memoryMomentKeys(moment);
      final existingIndex =
          keys.map((key) => indexes[key]).whereType<int>().firstOrNull;
      if (existingIndex == null) {
        for (final key in keys) {
          indexes[key] = results.length;
        }
        results.add(moment);
      } else {
        results[existingIndex] =
            _preferDisplayableMemoryMoment(results[existingIndex], moment);
        for (final key in keys) {
          indexes[key] = existingIndex;
        }
      }
    }
    return results;
  }

  List<String> _memoryMomentKeys(MemoryMoment moment) {
    final keys = <String>[];
    if (moment.id.isNotEmpty) keys.add('id:${moment.id}');
    final imageUrl = moment.imageUrl.trim();
    if (imageUrl.isNotEmpty) keys.add('url:$imageUrl');
    final fallbackPath = moment.fallbackPath?.trim() ?? '';
    if (fallbackPath.isNotEmpty) keys.add('fallback:$fallbackPath');
    if (keys.isEmpty) {
      keys.add('${moment.residentId}|${moment.activityTitle}|${moment.date}');
    }
    return keys;
  }

  MemoryMoment _preferDisplayableMemoryMoment(
    MemoryMoment current,
    MemoryMoment candidate,
  ) {
    final currentHasImage = _hasDisplayableMemoryMoment(current);
    final candidateHasImage = _hasDisplayableMemoryMoment(candidate);
    if (!currentHasImage && candidateHasImage) {
      return candidate;
    }
    final currentFallback = current.fallbackPath?.trim() ?? '';
    final candidateFallback = candidate.fallbackPath?.trim() ?? '';
    if (currentFallback.isEmpty && candidateFallback.isNotEmpty) {
      return MemoryMoment(
        id: current.id,
        residentId: current.residentId,
        residentName: current.residentName,
        imageUrl: current.imageUrl,
        fallbackPath: candidateFallback,
        activityTitle: current.activityTitle.isNotEmpty
            ? current.activityTitle
            : candidate.activityTitle,
        date: current.date,
        appreciations: current.appreciations,
      );
    }
    return current;
  }

  Future<void> addMemoryMoment(MemoryMoment moment) async {
    setUploadState(uploading: true, progress: 0.1);
    final residentId = _looksLikeBackendId(moment.residentId)
        ? moment.residentId
        : _residentIdForName(moment.residentName);
    if (residentId == null) {
      setUploadState(
        uploading: false,
        error:
            'لا يوجد residentId من السيرفر لإضافة ذكرى لـ ${moment.residentName}',
      );
      backendSyncError = uploadError;
      notifyListeners();
      return;
    }
    setUploadState(uploading: true, progress: 0.6);
    final synced = await _runBackendMutation(() {
      return BackendMutationService.instance.createMemory(
        residentId: residentId,
        moment: moment,
      );
    });
    if (!synced) {
      setUploadState(uploading: false, error: backendSyncError);
      return;
    }
    setUploadState(uploading: false, progress: 1.0);
    upsertMemoryMoment(moment, notify: false, save: true);

    triggerNotification(
      title: 'لحظة سعادة جديدة 📸',
      body:
          'والدكم ${moment.residentName} يستمتع بوقته الآن في "${moment.activityTitle}".',
      type: 'social',
      targetRole: 'أهل',
    );

    notifyListeners();
    unawaited(syncBackendData());
  }

  void deleteMemoryMoment(String id) {
    memoryMoments.removeWhere((m) => m.id == id);
    memoriesList.removeWhere((m) => m.id == 'wall_$id');
    notifyListeners();
    unawaited(_saveLocalAlbums());
  }

  void addAppreciation(String momentId) {
    final idx = memoryMoments.indexWhere((m) => m.id == momentId);
    if (idx != -1) {
      final m = memoryMoments[idx];
      memoryMoments[idx] = MemoryMoment(
        id: m.id,
        residentId: m.residentId,
        residentName: m.residentName,
        imageUrl: m.imageUrl,
        fallbackPath: m.fallbackPath,
        activityTitle: m.activityTitle,
        date: m.date,
        appreciations: m.appreciations + 1,
      );

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
}
