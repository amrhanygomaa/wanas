import 'dart:io';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';

class FullScreenImageScreen extends StatelessWidget {
  final String heroTag;
  final String? url;
  final String? assetPath;
  final AssetEntity? assetEntity;
  final String? label;

  const FullScreenImageScreen({
    super.key,
    required this.heroTag,
    this.url,
    this.assetPath,
    this.assetEntity,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white, size: 30),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          InteractiveViewer(
            panEnabled: true,
            minScale: 0.5,
            maxScale: 4.0,
            child: Center(
              child: Hero(
                tag: heroTag,
                child: Material(
                  color: Colors.transparent,
                  child: _buildImage(),
                ),
              ),
            ),
          ),
          if (label != null && label!.isNotEmpty)
            Positioned(
              bottom: 40,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.4),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Text(
                  label!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildImage() {
    if (url != null) {
      return Image.network(url!, fit: BoxFit.contain);
    } else if (assetEntity != null) {
      return AssetEntityImage(
        assetEntity!,
        isOriginal: true,
        fit: BoxFit.contain,
      );
    } else if (assetPath != null && assetPath!.isNotEmpty) {
      if (assetPath!.startsWith('assets/')) {
        return Image.asset(assetPath!, fit: BoxFit.contain);
      } else {
        return Image.file(File(assetPath!), fit: BoxFit.contain);
      }
    }
    return const Icon(Icons.broken_image, color: Colors.white, size: 50);
  }
}
