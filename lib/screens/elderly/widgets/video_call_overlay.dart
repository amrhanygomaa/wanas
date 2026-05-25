import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/app_riverpod.dart';

class VideoCallOverlay extends ConsumerStatefulWidget {
  const VideoCallOverlay({super.key});

  @override
  ConsumerState<VideoCallOverlay> createState() => _VideoCallOverlayState();
}

class _VideoCallOverlayState extends ConsumerState<VideoCallOverlay>
    with TickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final AnimationController _slideController;
  bool _isMuted = false;
  bool _isCameraOff = false;

  @override
  void initState() {
    super.initState();
    _pulseController =
        AnimationController(vsync: this, duration: const Duration(seconds: 2))
          ..repeat();
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    )..forward();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = ref.watch(appRiverpod);
    final name = provider.activeCallerName.trim().isEmpty
        ? 'مكالمة فيديو'
        : provider.activeCallerName.trim();
    final initials = provider.activeCallerInitials.trim().isEmpty
        ? '؟'
        : provider.activeCallerInitials.trim();
    final hasZoomLink = (provider.activeVideoCallJoinUrl ?? '').isNotEmpty;

    return Material(
      color: Colors.transparent,
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [
                Color(0xFF07111F),
                Color(0xFF111832),
                Color(0xFF123A36),
              ],
            ),
          ),
          child: SafeArea(
            child: FadeTransition(
              opacity: CurvedAnimation(
                parent: _slideController,
                curve: Curves.easeOut,
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  final height = constraints.maxHeight;
                  final avatarSize = min(max(width * 0.38, 116.0), 168.0);
                  final bottomGap = max(20.0, min(height * 0.045, 36.0));

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        const SizedBox(height: 14),
                        _buildTopBar(context, provider, hasZoomLink),
                        Expanded(
                          child: _buildCallerArea(
                            avatarSize: avatarSize,
                            initials: initials,
                            name: name,
                            hasZoomLink: hasZoomLink,
                          ),
                        ),
                        if (hasZoomLink) ...[
                          _buildOpenZoomButton(provider),
                          const SizedBox(height: 16),
                        ],
                        _buildControls(provider),
                        SizedBox(height: bottomGap),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(
    BuildContext context,
    AppRiverpod provider,
    bool hasZoomLink,
  ) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            ),
            child: Row(
              children: [
                Icon(
                  hasZoomLink
                      ? Icons.videocam_rounded
                      : Icons.wifi_calling_3_rounded,
                  color: const Color(0xFF9AE6B4),
                  size: 22,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    hasZoomLink ? 'مكالمة Zoom جارية' : 'جاري تجهيز المكالمة',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Semantics(
          button: true,
          label: 'إنهاء المكالمة',
          child: Tooltip(
            message: 'إنهاء المكالمة',
            child: InkResponse(
              onTap: provider.endVideoCall,
              radius: 28,
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.35),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.call_end_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCallerArea({
    required double avatarSize,
    required String initials,
    required String name,
    required bool hasZoomLink,
  }) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 0.08),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: avatarSize + 44,
            height: avatarSize + 44,
            child: Stack(
              alignment: Alignment.center,
              children: [
                ...List.generate(
                  3,
                  (index) => AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      final progress =
                          (_pulseController.value + index * 0.32) % 1.0;
                      final ringSize = avatarSize + 14 + (42 * progress);
                      return Container(
                        width: ringSize,
                        height: ringSize,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(
                              alpha: 0.22 * (1 - progress),
                            ),
                            width: 2,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Container(
                  width: avatarSize,
                  height: avatarSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                      colors: [
                        Color(0xFF8B5CF6),
                        Color(0xFF4F46E5),
                        Color(0xFF0EA5E9),
                      ],
                    ),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.16),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF4F46E5).withValues(alpha: 0.38),
                        blurRadius: 32,
                        offset: const Offset(0, 18),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          initials,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 64,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 34,
                fontWeight: FontWeight.w900,
                height: 1.1,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.09),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              hasZoomLink ? 'متصل عبر Zoom' : 'جاري إنشاء رابط Zoom',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.82),
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOpenZoomButton(AppRiverpod provider) {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: ElevatedButton.icon(
        onPressed: () => provider.launchZoom(provider.activeVideoCallJoinUrl),
        icon: const Icon(Icons.open_in_new_rounded, size: 24),
        label: const Text(
          'فتح Zoom',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF1E293B),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }

  Widget _buildControls(AppRiverpod provider) {
    return Row(
      children: [
        Expanded(
          child: _controlButton(
            label: _isCameraOff ? 'تشغيل الكاميرا' : 'إيقاف الكاميرا',
            icon: _isCameraOff
                ? Icons.videocam_off_rounded
                : Icons.videocam_rounded,
            background: Colors.white.withValues(alpha: 0.13),
            foreground: Colors.white,
            onTap: () => setState(() => _isCameraOff = !_isCameraOff),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _controlButton(
            label: 'إنهاء',
            icon: Icons.call_end_rounded,
            background: const Color(0xFFFF4D55),
            foreground: Colors.white,
            isPrimary: true,
            onTap: provider.endVideoCall,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _controlButton(
            label: _isMuted ? 'تشغيل الصوت' : 'كتم الصوت',
            icon: _isMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
            background: Colors.white.withValues(alpha: 0.13),
            foreground: Colors.white,
            onTap: () => setState(() => _isMuted = !_isMuted),
          ),
        ),
      ],
    );
  }

  Widget _controlButton({
    required String label,
    required IconData icon,
    required Color background,
    required Color foreground,
    required VoidCallback onTap,
    bool isPrimary = false,
  }) {
    return Semantics(
      button: true,
      label: label,
      child: Tooltip(
        message: label,
        child: InkResponse(
          onTap: onTap,
          radius: isPrimary ? 48 : 42,
          child: Container(
            height: isPrimary ? 82 : 74,
            constraints: const BoxConstraints(minWidth: 74),
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isPrimary
                    ? Colors.transparent
                    : Colors.white.withValues(alpha: 0.12),
              ),
              boxShadow: isPrimary
                  ? [
                      BoxShadow(
                        color: const Color(0xFFFF4D55).withValues(alpha: 0.35),
                        blurRadius: 24,
                        offset: const Offset(0, 12),
                      ),
                    ]
                  : null,
            ),
            child: Icon(icon, color: foreground, size: isPrimary ? 38 : 32),
          ),
        ),
      ),
    );
  }
}
