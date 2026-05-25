import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/app_models.dart';
import '../../providers/app_riverpod.dart';
import '../../services/family_media_service.dart';
import '../../widgets/taptaba_scaffold.dart';

// شاشة "جسر العائلة" - تتيح للأقارب التواصل مع المقيم عبر الصور والرسائل الصوتية
class FamilyBridgeScreen extends ConsumerStatefulWidget {
  const FamilyBridgeScreen({super.key});

  @override
  ConsumerState<FamilyBridgeScreen> createState() => _FamilyBridgeScreenState();
}

class _FamilyBridgeScreenState extends ConsumerState<FamilyBridgeScreen>
    with TickerProviderStateMixin {
  late AnimationController _floatController;
  late AnimationController _rotationController;
  bool _isUploading = false; // حالة الرفع الحالية
  double _uploadProgress = 0.0; // نسبة تقدم الرفع
  String _uploadStatus = ''; // نص حالة الرفع
  bool _showDoneAnimation = false; // هل نعرض أنيميشن الانتهاء؟
  bool _showDeleteAnimation = false; // هل نعرض أنيميشن الحذف؟
  bool _isLoadingMedia = false;
  List<BackendFamilyMedia> _mediaItems = [];

  @override
  void initState() {
    super.initState();
    _floatController =
        AnimationController(vsync: this, duration: const Duration(seconds: 3))
          ..repeat(reverse: true);
    _rotationController =
        AnimationController(vsync: this, duration: const Duration(seconds: 25))
          ..repeat();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadMedia());
  }

  @override
  void dispose() {
    _floatController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  // فتح المعرض واختيار صورة
  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      _showConfirmUpload('صورة', image: image);
    }
  }

  Future<void> _loadMedia() async {
    final provider = ref.read(appRiverpod);
    final residentId = provider.backendResidentId;
    if (residentId == null || residentId.isEmpty) return;

    setState(() => _isLoadingMedia = true);
    try {
      final items = await FamilyMediaService.instance.list(
        residentId: residentId,
      );
      if (!mounted) return;
      setState(() => _mediaItems = items);
    } catch (e) {
      if (mounted) {
        final msg = e.toString().contains('403') || e.toString().contains('linked')
            ? 'حسابك غير مرتبط بهذا المقيم. تواصل مع الإدارة لإضافة بريدك الإلكتروني.'
            : 'تعذّر تحميل الصور — تأكد من الاتصال بالإنترنت.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: Colors.redAccent,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoadingMedia = false);
    }
  }

  void _uploadMemory(String title, String type, {XFile? image}) async {
    final provider = ref.read(appRiverpod);
    final residentId = provider.backendResidentId;
    if (residentId == null || residentId.isEmpty || image == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('لا يوجد مقيم مرتبط من AWS لإرسال الذكرى'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.25;
      _uploadStatus = 'جاري تجهيز رابط S3...';
      _showDoneAnimation = false;
    });

    try {
      setState(() {
        _uploadProgress = 0.55;
        _uploadStatus = 'جاري رفع $type إلى S3...';
      });
      final uploaded = await FamilyMediaService.instance.uploadImage(
        residentId: residentId,
        image: image,
        caption: title,
      );
      if (!mounted) return;
      setState(() {
        _mediaItems.insert(0, uploaded);
        _uploadProgress = 1.0;
        _showDoneAnimation = true;
      });

      final residentName = provider.residentFiles.isNotEmpty
          ? provider.residentFiles.first.name
          : '';
      provider.insertFamilyBridgeMoment(MemoryMoment(
        id: 'fb_${uploaded.id}',
        residentId: uploaded.residentId,
        residentName: residentName,
        imageUrl: uploaded.mediaUrl ?? '',
        activityTitle: uploaded.caption ?? title,
        date: 'اليوم',
      ));

      await provider.triggerNotification(
        title: 'لحظة عائلية جديدة',
        body: 'تم رفع "$title" إلى معرض جسر العائلة.',
        type: 'social',
        targetRole: 'أخصائي',
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isUploading = false);
      final msg = e.toString().contains('403') || e.toString().contains('linked')
          ? 'حسابك غير مرتبط بهذا المقيم. تواصل مع الإدارة لإضافة بريدك الإلكتروني.'
          : 'فشل رفع الصورة — تأكد من الاتصال بالإنترنت.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: Colors.redAccent,
          duration: const Duration(seconds: 5),
        ),
      );
      return;
    }

    // إخفاء الأنيميشن بعد ثانيتين
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() {
        _isUploading = false;
        _showDoneAnimation = false;
      });
    }
  }

  // إظهار نافذة تأكيد قبل الرفع الفعلي
  void _showConfirmUpload(String type, {XFile? image}) {
    String title = type == 'صورة' ? 'صورة عائلية جديدة' : 'رسالة صوتية للأب';
    final provider = ref.read(appRiverpod);
    final residentName = provider.residentFiles.isNotEmpty
        ? provider.residentFiles.first.name
        : 'المقيم';
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: const Color(0xFFf1f5f9),
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 24),
            const Text('تأكيد الإرسال',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1e293b))),
            const SizedBox(height: 8),
            Text('هل تريد إرسال ال$type الآن إلى $residentName؟',
                style: const TextStyle(fontSize: 14, color: Color(0xFF64748b))),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _uploadMemory(title, type, image: image);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFea580c),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('تأكيد وإرسال',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: Color(0xFFe2e8f0)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('إلغاء',
                        style: TextStyle(color: Color(0xFF64748b))),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return TaptabaScaffold(
      title: 'جسر العائلة',
      overrideRole: 'عائلة',
      hideAppBar: true,
      body: Stack(
        children: [
          Column(
            children: [
              _buildHeader(),
              _buildUploadActions(), // أزرار الرفع (صوت وصورة)
              Expanded(child: _buildGallery(_mediaItems)),
            ],
          ),
          if (_isUploading) _buildUploadOverlay(), // واجهة التحميل عند الرفع
          if (_showDeleteAnimation) _buildDeleteOverlay(), // أنيميشن الحذف
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFea580c),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
        child: Stack(
          children: [
            Positioned.fill(child: _buildAnimatedBackground()),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: Colors.white, size: 22),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Text('جسر العائلة',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(width: 48),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedBackground() {
    return AnimatedBuilder(
      animation: Listenable.merge([_floatController, _rotationController]),
      builder: (context, child) {
        return Stack(
          children: [
            // Orb 1 - Top Right
            Positioned(
              top: -50 + (30 * _floatController.value),
              right: -40 + (20 * _floatController.value),
              child: _buildRealisticOrb(180, [
                const Color(0xFFfb923c).withValues(alpha: 0.35),
                const Color(0xFFea580c).withValues(alpha: 0.15),
                Colors.transparent,
              ]),
            ),
            // Orb 2 - Bottom Left
            Positioned(
              bottom: -30 + (40 * (1 - _floatController.value)),
              left: -40 + (25 * _floatController.value),
              child: _buildRealisticOrb(160, [
                const Color(0xFFfdba74).withValues(alpha: 0.3),
                const Color(0xFFf97316).withValues(alpha: 0.1),
                Colors.transparent,
              ]),
            ),
            // Orb 3 - Center
            Positioned(
              top: 40,
              left: 100,
              child: _buildRealisticOrb(70, [
                const Color(0xFFfb923c).withValues(alpha: 0.1),
                Colors.transparent,
              ]),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRealisticOrb(double size, List<Color> baseColors) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(shape: BoxShape.circle),
      child: ClipOval(
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: baseColors,
                  stops: const [0.0, 0.6, 1.0],
                ),
              ),
            ),
            RotationTransition(
              turns: _rotationController,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: SweepGradient(
                    colors: [
                      Colors.transparent,
                      Colors.white.withValues(alpha: 0.15),
                      Colors.transparent,
                      Colors.white.withValues(alpha: 0.08),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
                  ),
                ),
              ),
            ),
            Positioned(
              top: size * 0.1,
              left: size * 0.15,
              child: Container(
                width: size * 0.4,
                height: size * 0.2,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.1),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Container(
            width: 4,
            height: 18,
            decoration: BoxDecoration(
                color: const Color(0xFFea580c),
                borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 10),
        Text(title,
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1e293b))),
      ],
    );
  }

  // بناء أزرار التفاعل السريع للرفع
  Widget _buildUploadActions() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFf1f5f9))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _buildSectionHeader('شارك لحظة جديدة'),
          const SizedBox(height: 16),
          Row(
            children: [
              _uploadBtn(Icons.image_rounded, 'صورة جديدة',
                  const Color(0xFF0ea5e9), _pickAndUploadImage),
            ],
          ),
        ],
      ),
    );
  }

  // بناء زر الرفع الفردي بتصميم عصري
  Widget _uploadBtn(
      IconData icon, String label, Color color, VoidCallback onTap,
      {bool isRecording = false}) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: isRecording
                ? Colors.red.withValues(alpha: 0.1)
                : color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
                color: isRecording ? Colors.red : color.withValues(alpha: 0.3),
                width: 1.5),
          ),
          child: Column(
            children: [
              Icon(isRecording ? Icons.stop_circle_rounded : icon,
                  color: isRecording ? Colors.red : color, size: 32),
              const SizedBox(height: 8),
              Text(label,
                  style: TextStyle(
                      color: isRecording ? Colors.red : color,
                      fontWeight: FontWeight.bold,
                      fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, String id) {
    final messenger = ScaffoldMessenger.of(context);
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('حذف الصورة', textAlign: TextAlign.center),
        content: const Text(
            'هل أنت متأكد أنك تريد حذف هذه الصورة من حائط الذكريات؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(dialogContext); // Close dialog
              setState(() {
                _showDeleteAnimation = true;
              });

              try {
                await FamilyMediaService.instance.delete(id);
                if (mounted) {
                  setState(() {
                    _mediaItems.removeWhere((m) => m.id == id);
                  });
                }
              } catch (e) {
                if (mounted) {
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(e.toString()),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                }
              }

              await Future.delayed(const Duration(milliseconds: 1500));

              if (mounted) {
                setState(() {
                  _showDeleteAnimation = false;
                });
              }
            },
            child: const Text('حذف', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // بناء معرض الصور والرسائل المرفوعة (Grid View)
  Widget _buildGallery(List<BackendFamilyMedia> items) {
    if (_isLoadingMedia) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFea580c)),
      );
    }

    if (items.isEmpty) {
      return const Center(
        child: Text(
          'لا توجد صور عائلية مرفوعة بعد',
          style: TextStyle(color: Color(0xFF64748b)),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.85,
      ),
      itemCount: items.length,
      itemBuilder: (context, i) {
        final m = items[i];
        final imageUrl = m.mediaUrl ?? '';
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4))
            ],
            border: Border.all(color: const Color(0xFFf1f5f9)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(24)),
                        child: imageUrl.isEmpty
                            ? Container(
                                color: const Color(0xFFf8fafc),
                                child: const Icon(
                                  Icons.image_not_supported_outlined,
                                  color: Color(0xFF94a3b8),
                                ),
                              )
                            : Image.network(
                                imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  color: const Color(0xFFf8fafc),
                                  child: const Icon(
                                    Icons.broken_image_outlined,
                                    color: Color(0xFF94a3b8),
                                  ),
                                ),
                              ),
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: () {
                          _showDeleteConfirmation(context, m.id);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(color: Colors.black26, blurRadius: 4),
                            ],
                          ),
                          child: const Icon(Icons.close,
                              color: Colors.red, size: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(_mediaTitle(m),
                        style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1e293b))),
                    Text(_dateLabel(m.createdAt),
                        style: const TextStyle(
                            fontSize: 8, color: Color(0xFF94a3b8))),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // واجهة التغطية (Overlay) التي تظهر أثناء عملية الرفع
  Widget _buildUploadOverlay() {
    return Container(
      color: Colors.black.withValues(alpha: 0.7),
      width: double.infinity,
      height: double.infinity,
      child: Center(
        child: Container(
          width: 280,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(32)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: _showDoneAnimation
                ? [
                    const Icon(
                      Icons.check_circle_rounded,
                      color: Colors.green,
                      size: 70,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'تم بنجاح!',
                      style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                          fontSize: 18),
                    ),
                  ]
                : [
                    SizedBox(
                      width: 80,
                      height: 80,
                      child: CircularProgressIndicator(
                        value: _uploadProgress,
                        strokeWidth: 8,
                        backgroundColor: const Color(0xFFf1f5f9),
                        color: const Color(0xFFea580c),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(_uploadStatus,
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1e293b))),
                    const SizedBox(height: 8),
                    Text('${(_uploadProgress * 100).toInt()}% اكتمل',
                        style: const TextStyle(color: Color(0xFF64748b))),
                  ],
          ),
        ),
      ),
    );
  }

  Widget _buildDeleteOverlay() {
    return Container(
      color: Colors.black.withValues(alpha: 0.5),
      width: double.infinity,
      height: double.infinity,
      child: Center(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 600),
          curve: Curves.elasticOut,
          builder: (context, value, child) {
            return Transform.scale(
              scale: value,
              child: Container(
                width: 150,
                height: 150,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black26, blurRadius: 10, spreadRadius: 2),
                  ],
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.delete_forever_rounded,
                      color: Colors.red,
                      size: 70,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'تم الحذف!',
                      style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 16),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  String _mediaTitle(BackendFamilyMedia media) {
    final caption = media.caption?.trim();
    if (caption != null && caption.isNotEmpty) return caption;
    return media.fileName.isEmpty ? 'صورة عائلية' : media.fileName;
  }

  String _dateLabel(String value) {
    final parsed = DateTime.tryParse(value);
    if (parsed == null) return 'الآن';
    final now = DateTime.now();
    if (parsed.year == now.year &&
        parsed.month == now.month &&
        parsed.day == now.day) {
      return 'اليوم';
    }
    return '${parsed.year}/${parsed.month.toString().padLeft(2, '0')}/${parsed.day.toString().padLeft(2, '0')}';
  }
}
