import 'package:flutter/material.dart';

class PermissionDialog extends StatelessWidget {
  final VoidCallback onGranted;
  final VoidCallback onDenied;

  const PermissionDialog({
    super.key,
    required this.onGranted,
    required this.onDenied,
  });

  static void show(BuildContext context,
      {required VoidCallback onGranted, required VoidCallback onDenied}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) =>
          PermissionDialog(onGranted: onGranted, onDenied: onDenied),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, 10)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFFeef2ff),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.photo_library_rounded,
                  size: 48, color: Color(0xFF4338ca)),
            ),
            const SizedBox(height: 24),
            const Text(
              'طلب إذن الوصول 📸',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1e1b4b)),
            ),
            const SizedBox(height: 16),
            const Text(
              'نحتاج مساعدتك للوصول لصور الذكريات لكي تتمكن من رؤية صورك الجميلة مع أهلك وأحبائك في المسكن',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 16, color: Color(0xFF475569), height: 1.5),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      onDenied();
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('ليس الآن',
                        style: TextStyle(
                            fontSize: 16,
                            color: Color(0xFF94a3b8),
                            fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      onGranted();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4338ca),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('أوافق',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
