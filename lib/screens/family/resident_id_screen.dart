import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/app_models.dart';
import '../../providers/app_riverpod.dart';

class ResidentIdScreen extends ConsumerStatefulWidget {
  const ResidentIdScreen({super.key});

  @override
  ConsumerState<ResidentIdScreen> createState() => _ResidentIdScreenState();
}

class _ResidentIdScreenState extends ConsumerState<ResidentIdScreen>
    with TickerProviderStateMixin {
  late AnimationController _floatController;
  late AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _floatController =
        AnimationController(vsync: this, duration: const Duration(seconds: 3))
          ..repeat(reverse: true);
    _rotationController =
        AnimationController(vsync: this, duration: const Duration(seconds: 25))
          ..repeat();
  }

  @override
  void dispose() {
    _floatController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1e1b4b), // Dark elegant background
      appBar: AppBar(
        title: const Text('الهوية الرقمية',
            style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white, size: 24),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
          child: Column(
            children: [
              _buildDigitalCard(),
              const SizedBox(height: 48),
              _buildInstructions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDigitalCard() {
    final provider = ref.watch(appRiverpod);
    final resident =
        provider.residentFiles.isNotEmpty ? provider.residentFiles.first : null;
    final qrData =
        resident?.id ?? provider.currentAccount?.linkedResidentId ?? '';
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 40,
              offset: const Offset(0, 20))
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          _buildCardHeader(),
          Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                _buildQRCode(qrData),
                const SizedBox(height: 32),
                Text(resident?.name ?? 'لا توجد بيانات مقيم من السيرفر',
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1e1b4b))),
                Text(
                    resident == null
                        ? 'بانتظار المزامنة'
                        : 'الغرفة: ${resident.room}',
                    style: const TextStyle(
                        color: Color(0xFF64748b), fontSize: 13)),
                const SizedBox(height: 24),
                const Divider(color: Color(0xFFf1f5f9)),
                const SizedBox(height: 16),
                _buildInfoGrid(resident),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            width: double.infinity,
            color: const Color(0xFFea580c),
            child: const Center(
                child: Text('صالحة للزيارة اليوم',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold))),
          ),
        ],
      ),
    );
  }

  Widget _buildCardHeader() {
    return Container(
      height: 100,
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient:
            LinearGradient(colors: [Color(0xFFea580c), Color(0xFFf97316)]),
      ),
      child: Stack(
        children: [
          Positioned.fill(child: _buildAnimatedBackground()),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('ونس',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2)),
                    Text('تصريح دخول الأقارب',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
                Image.network(
                    'https://cdn-icons-png.flaticon.com/512/3665/3665922.png',
                    width: 35,
                    height: 35,
                    color: Colors.white),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedBackground() {
    return AnimatedBuilder(
      animation: Listenable.merge([_floatController, _rotationController]),
      builder: (context, child) {
        return Stack(
          children: [
            Positioned(
              top: -20 + (10 * _floatController.value),
              right: -10 + (10 * _floatController.value),
              child: _buildRealisticOrb(80, [
                const Color(0xFFfb923c).withValues(alpha: 0.3),
                const Color(0xFFea580c).withValues(alpha: 0.1),
                Colors.transparent,
              ]),
            ),
            Positioned(
              bottom: -10,
              left: 20 + (20 * _floatController.value),
              child: _buildRealisticOrb(60, [
                const Color(0xFFfdba74).withValues(alpha: 0.2),
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
          ],
        ),
      ),
    );
  }

  Widget _buildQRCode(String data) {
    final encoded =
        Uri.encodeComponent(data.isEmpty ? 'pending-aws-resident' : data);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFf1f5f9), width: 2)),
      child: Image.network(
          'https://api.qrserver.com/v1/create-qr-code/?size=200x200&data=$encoded',
          width: 160,
          height: 160),
    );
  }

  Widget _buildInfoGrid(SpecialistResidentFile? resident) {
    final primaryFamily = resident?.familyMembers.isNotEmpty == true
        ? resident!.familyMembers.first.name
        : '-';
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildMiniInfo(resident?.bloodType ?? '-', 'فصيلة الدم'),
        _buildDivider(),
        _buildMiniInfo(primaryFamily, 'جهة الاتصال'),
        _buildDivider(),
        _buildMiniInfo(resident?.age?.toString() ?? '-', 'العمر'),
      ],
    );
  }

  Widget _buildMiniInfo(String val, String label) {
    return Column(
      children: [
        Text(val,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        Text(label,
            style: const TextStyle(color: Color(0xFF94a3b8), fontSize: 9)),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(width: 1, height: 24, color: const Color(0xFFf1f5f9));
  }

  Widget _buildInstructions() {
    return const Column(
      children: [
        Icon(Icons.contactless_rounded, color: Color(0xFFfb923c), size: 32),
        SizedBox(height: 12),
        Text(
            'امسح الرمز عند مدخل الدار لتأكيد الهوية وتسهيل عملية الدخول المباشر للغرفة.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white60, fontSize: 12, height: 1.5)),
      ],
    );
  }
}
