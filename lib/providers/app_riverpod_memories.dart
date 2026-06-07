// ignore_for_file: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
// مزوّد فرعي: الذكريات والألبومات المحلية (Memories & local albums).
// جزء (part) من مكتبة app_riverpod.dart — يوسّع AppRiverpod عبر extension،
// فتظل كل الاستدعاءات عند المستهلكين كما هي دون أي تغيير في الـ imports.
part of 'app_riverpod.dart';

extension AppRiverpodMemories on AppRiverpod {
  List<String> get allAlbums {
    return [
      AppRiverpod.defaultPhotoAlbumName,
      ...customAlbums.where((name) => name != AppRiverpod.defaultPhotoAlbumName),
    ];
  }

  void createAlbum(String name) {
    final cleanName = name.trim();
    if (cleanName.isEmpty || cleanName == AppRiverpod.defaultPhotoAlbumName) return;
    if (!customAlbums.contains(cleanName)) {
      customAlbums.add(cleanName);
      notifyListeners();
      unawaited(_saveLocalAlbums());
    }
  }

  void renameAlbum(String oldName, String newName) {
    if (newName.trim().isEmpty || customAlbums.contains(newName)) return;
    int index = customAlbums.indexOf(oldName);
    if (index != -1) {
      customAlbums[index] = newName;
      for (var item in memoriesList) {
        if (item.category == oldName) {
          item.category = newName;
        }
      }
      if (albumCovers.containsKey(oldName)) {
        albumCovers[newName] = albumCovers.remove(oldName)!;
      }
      notifyListeners();
      unawaited(_saveLocalAlbums());
    }
  }

  void deleteAlbum(String name) {
    customAlbums.remove(name);
    memoriesList.removeWhere((item) => item.category == name);
    albumCovers.remove(name);
    notifyListeners();
    unawaited(_saveLocalAlbums());
  }

  String addPhotoToAlbum(String albumName, String photoPath,
      {String type = 'image'}) {
    final cleanAlbum =
        albumName.trim().isEmpty ? AppRiverpod.defaultPhotoAlbumName : albumName.trim();
    final newItem = MemoryItem(
      id: 'local_album_${DateTime.now().millisecondsSinceEpoch}',
      category: cleanAlbum,
      title: 'صورة جديدة',
      date:
          '${DateTime.now().day} / ${DateTime.now().month} / ${DateTime.now().year}',
      type: type,
      assetPath: photoPath,
    );
    memoriesList.insert(0, newItem);
    notifyListeners();
    unawaited(_saveLocalAlbums());
    return newItem.id;
  }

  Future<String> persistAlbumImage(String sourcePath) async {
    try {
      final source = File(sourcePath);
      if (!await source.exists()) return sourcePath;
      final dir = await getApplicationDocumentsDirectory();
      final albumDir = Directory('${dir.path}/album_images');
      if (!await albumDir.exists()) {
        await albumDir.create(recursive: true);
      }
      final extension = sourcePath.split('.').last.toLowerCase();
      final safeExtension = extension.length <= 5 ? extension : 'jpg';
      final fileName =
          'memory_${DateTime.now().millisecondsSinceEpoch}.$safeExtension';
      final copied = await source.copy('${albumDir.path}/$fileName');
      return copied.path;
    } catch (e) {
      debugPrint('Error persisting album image: $e');
      return sourcePath;
    }
  }

  void updateMemoryItemAssetPath(String id, String assetPath) {
    final index = memoriesList.indexWhere((item) => item.id == id);
    if (index == -1) return;
    final item = memoriesList[index];
    final currentPath = item.assetPath.trim();
    final currentFile = currentPath.isEmpty || currentPath.startsWith('http')
        ? null
        : File(currentPath);
    final hasLocalFallback = currentFile?.existsSync() == true;
    final localFallback =
        hasLocalFallback ? (item.content ?? currentPath) : item.content;
    memoriesList[index] = MemoryItem(
      id: item.id,
      category: item.category,
      title: item.title,
      date: item.date,
      type: item.type,
      assetPath: assetPath,
      content: localFallback,
    );
    notifyListeners();
    unawaited(_saveLocalAlbums());
  }

  void setAlbumCover(String albumName, String imagePath) {
    albumCovers[albumName] = imagePath;
    notifyListeners();
    unawaited(_saveLocalAlbums());
  }

  void deleteMemoryItem(String id) {
    memoriesList.removeWhere((item) => item.id == id);
    notifyListeners();
    unawaited(_saveLocalAlbums());
  }

  Future<File> _localAlbumsFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/custom_albums.json');
  }

  Future<void> _saveLocalAlbums() async {
    try {
      final file = await _localAlbumsFile();
      final localPhotos = memoriesList
          .where(_shouldPersistMemoryItem)
          .map((m) => {
                'id': m.id,
                'category': m.category,
                'title': m.title,
                'date': m.date,
                'type': m.type,
                'assetPath': m.assetPath,
                if (m.content != null) 'content': m.content,
              })
          .toList();
      final localFamilyMoments = memoryMoments
          .where(_shouldPersistMemoryMoment)
          .map((m) => {
                'id': m.id,
                'residentId': m.residentId,
                'residentName': m.residentName,
                'imageUrl': m.imageUrl,
                if ((m.fallbackPath ?? '').trim().isNotEmpty)
                  'fallbackPath': m.fallbackPath,
                'activityTitle': m.activityTitle,
                'date': m.date,
                'appreciations': m.appreciations,
              })
          .toList();
      final data = {
        'albums': customAlbums,
        'photos': localPhotos,
        'familyMemoryMoments': localFamilyMoments,
        'albumCovers': albumCovers,
      };
      await file.writeAsString(jsonEncode(data));
    } catch (e) {
      debugPrint('Error saving local albums: $e');
    }
  }

  Future<void> loadLocalAlbums() async {
    try {
      final file = await _localAlbumsFile();
      if (!await file.exists()) return;
      final content = await file.readAsString();
      final data = jsonDecode(content) as Map<String, dynamic>;

      final albums = (data['albums'] as List?)?.cast<String>() ?? [];
      for (final album in albums) {
        if (!customAlbums.contains(album)) {
          customAlbums.add(album);
        }
      }

      final photos = (data['photos'] as List?) ?? [];
      for (final photo in photos) {
        if (photo is! Map) continue;
        final map = Map<String, dynamic>.from(photo);
        final id = map['id']?.toString() ?? '';
        if (id.isEmpty) continue;
        if (!memoriesList.any((m) => m.id == id)) {
          memoriesList.insert(
            0,
            MemoryItem(
              id: id,
              category: map['category']?.toString() ?? AppRiverpod.defaultPhotoAlbumName,
              title: map['title']?.toString() ?? 'صورة جديدة',
              date: map['date']?.toString() ?? 'اليوم',
              type: map['type']?.toString() ?? 'image',
              assetPath: map['assetPath']?.toString() ?? '',
              content: map['content']?.toString(),
            ),
          );
        }
      }

      final familyMoments = (data['familyMemoryMoments'] as List?) ?? [];
      for (final rawMoment in familyMoments) {
        if (rawMoment is! Map) continue;
        final map = Map<String, dynamic>.from(rawMoment);
        final id = map['id']?.toString() ?? '';
        final imageUrl = map['imageUrl']?.toString() ?? '';
        final fallbackPath = map['fallbackPath']?.toString();
        if (id.isEmpty || (imageUrl.isEmpty && (fallbackPath ?? '').isEmpty)) {
          continue;
        }
        upsertMemoryMoment(
          MemoryMoment(
            id: id,
            residentId: map['residentId']?.toString() ??
                currentAccount?.linkedResidentId ??
                backendResidentId ??
                '',
            residentName: map['residentName']?.toString() ??
                (residentFiles.isNotEmpty
                    ? residentFiles.first.name
                    : 'المقيم'),
            imageUrl: imageUrl,
            fallbackPath: fallbackPath,
            activityTitle: map['activityTitle']?.toString() ?? '',
            date: map['date']?.toString() ?? 'اليوم',
            appreciations: map['appreciations'] is num
                ? (map['appreciations'] as num).toInt()
                : 0,
          ),
          notify: false,
          save: false,
        );
      }

      final covers = (data['albumCovers'] as Map<String, dynamic>?) ?? {};
      albumCovers.addAll(covers.map((k, v) => MapEntry(k, v as String)));

      notifyListeners();
    } catch (e) {
      debugPrint('Error loading local albums: $e');
    }
  }

  bool _shouldPersistMemoryItem(MemoryItem item) {
    final isLocalItem = item.id.startsWith('local_album_') ||
        item.id.startsWith('wall_') ||
        item.id.startsWith('mem_custom_') ||
        item.id.startsWith('mem_med_');
    final isAlbumPhoto = item.category == AppRiverpod.defaultPhotoAlbumName ||
        customAlbums.contains(item.category);
    final isFamilyMessage = item.category == 'أسرة' &&
        (item.type == 'text' || item.type == 'voice');
    final isFamilyImage = item.category == 'أسرة' && item.type == 'image';
    return isLocalItem && (isAlbumPhoto || isFamilyMessage || isFamilyImage);
  }

  bool _shouldPersistMemoryMoment(MemoryMoment moment) {
    return _hasDisplayableMemoryMoment(moment) &&
        (moment.id.startsWith('local_family_') || moment.id.startsWith('fb_'));
  }
}
