import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/app_riverpod.dart';
import '../../models/app_models.dart';
import '../../services/ai_media_service.dart';
import 'package:image_picker/image_picker.dart';
import 'full_screen_image_screen.dart';

class AlbumDetailsScreen extends ConsumerWidget {
  final String albumName;

  const AlbumDetailsScreen({super.key, required this.albumName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = ref.watch(appRiverpod);
    bool hc = provider.isHighContrast;

    // الحصول على الصور الخاصة بهذا الألبوم
    List<dynamic> items = provider.getMemoriesByCategory(albumName);

    return Scaffold(
      backgroundColor: hc ? const Color(0xFF121212) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          albumName,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: hc ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
        iconTheme:
            IconThemeData(color: hc ? Colors.white : const Color(0xFF0F172A)),
      ),
      body: items.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.folder_open_rounded,
                      size: 80, color: Colors.grey.withValues(alpha: 0.5)),
                  const SizedBox(height: 16),
                  Text('الألبوم فارغ',
                      style: TextStyle(
                          fontSize: 20,
                          color: Colors.grey.withValues(alpha: 0.8),
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('اضغط على الزر أدناه لإضافة صور',
                      style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.withValues(alpha: 0.6))),
                ],
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              physics: const BouncingScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.85,
              ),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final mem = items[index];
                String type = 'image';
                String? url;
                String? label;
                String? assetPath;

                if (mem is MemoryItem) {
                  type = mem.type;
                  label = mem.title;
                  assetPath = mem.assetPath;
                } else if (mem is MemoryMoment) {
                  type = 'image';
                  url = mem.imageUrl;
                  label = mem.activityTitle;
                } else if (mem is String) {
                  type = 'image';
                  url = mem;
                }

                return _buildPhotoCell(
                    context, index, type, url, label, assetPath, hc, mem, ref);
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final ImagePicker picker = ImagePicker();
          final XFile? image =
              await picker.pickImage(source: ImageSource.gallery);
          if (image == null) return;

          final provider = ref.read(appRiverpod);
          final residentId = provider.backendResidentId ??
              (provider.residentFiles.isNotEmpty
                  ? provider.residentFiles.first.id
                  : null);
          try {
            final uploaded = await AiMediaService.instance.uploadFile(
              filePath: image.path,
              residentId: residentId,
            );
            final s3Url = uploaded.mediaUrl ?? image.path;
            provider.addPhotoToAlbum(albumName, s3Url);
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('فشل رفع الصورة: $e'),
                  backgroundColor: Colors.red.shade700,
                ),
              );
            }
          }
        },
        backgroundColor: const Color(0xFF6C63FF),
        icon: const Icon(Icons.add_a_photo_rounded, color: Colors.white),
        label: const Text('إضافة صورة',
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16)),
      ),
    );
  }

  Widget _buildPhotoCell(
      BuildContext context,
      int index,
      String type,
      String? url,
      String? label,
      String? assetPath,
      bool hc,
      dynamic mem,
      WidgetRef ref) {
    final gradients = [
      const [Color(0xFF8B5CF6), Color(0xFFC4B5FD)],
      const [Color(0xFFEC4899), Color(0xFFF9A8D4)],
      const [Color(0xFF3B82F6), Color(0xFF93C5FD)],
      const [Color(0xFF10B981), Color(0xFF6EE7B7)],
    ];
    final gradient = gradients[index % gradients.length];
    bool hasImage = url != null || (assetPath != null && assetPath.isNotEmpty);
    String heroTag = 'album_photo_${albumName}_$index';

    Widget cellContent = Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: hc ? const Color(0xFF1E1E1E) : Colors.white,
        gradient: !hasImage
            ? LinearGradient(
                colors: gradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight)
            : null,
        image: url != null
            ? DecorationImage(image: NetworkImage(url), fit: BoxFit.cover)
            : (assetPath != null && assetPath.isNotEmpty)
                ? (assetPath.startsWith('assets/')
                    ? DecorationImage(
                        image: AssetImage(assetPath), fit: BoxFit.cover)
                    : DecorationImage(
                        image: FileImage(File(assetPath)), fit: BoxFit.cover))
                : null,
        boxShadow: [
          BoxShadow(
            color:
                (hasImage ? Colors.black : gradient[0]).withValues(alpha: 0.15),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (hasImage)
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.1),
                      Colors.black.withValues(alpha: 0.7),
                    ],
                    stops: const [0.5, 0.8, 1.0],
                  ),
                ),
              ),
            if (type == 'video')
              Center(
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.5), width: 1.5),
                  ),
                  child: const Icon(Icons.play_arrow_rounded,
                      color: Colors.white, size: 28),
                ),
              )
            else if (!hasImage)
              Center(
                child: Icon(Icons.image_outlined,
                    color: Colors.white.withValues(alpha: 0.5), size: 40),
              ),
            if (label != null && label.isNotEmpty)
              Positioned(
                bottom: 12,
                right: 12,
                left: 12,
                child: Text(
                  label,
                  textAlign: TextAlign.right,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      height: 1.3),
                ),
              ),
          ],
        ),
      ),
    );

    return GestureDetector(
      onLongPress: () {
        showModalBottomSheet(
          context: context,
          backgroundColor: hc ? const Color(0xFF1E1E1E) : Colors.white,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (context) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2)),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading:
                      const Icon(Icons.image_rounded, color: Color(0xFF6C63FF)),
                  title: Text('تعيين كواجهة للألبوم',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: hc ? Colors.white : Colors.black)),
                  onTap: () {
                    String coverImg = url ?? assetPath ?? '';
                    if (coverImg.isNotEmpty) {
                      ref.read(appRiverpod).setAlbumCover(albumName, coverImg);
                    }
                    Navigator.pop(context);
                  },
                ),
                if (mem is MemoryItem)
                  ListTile(
                    leading:
                        const Icon(Icons.delete_rounded, color: Colors.red),
                    title: const Text('مسح الصورة',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.red)),
                    onTap: () {
                      ref.read(appRiverpod).deleteMemoryItem(mem.id);
                      Navigator.pop(context);
                    },
                  ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
      onTap: () {
        if (hasImage && type != 'video') {
          Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  FullScreenImageScreen(
                heroTag: heroTag,
                url: url,
                assetPath: assetPath,
                label: label,
              ),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                return FadeTransition(opacity: animation, child: child);
              },
            ),
          );
        }
      },
      child: Hero(
        tag: heroTag,
        child: Material(color: Colors.transparent, child: cellContent),
      ),
    );
  }
}
