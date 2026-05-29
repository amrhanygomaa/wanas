import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_riverpod.dart';

class DraggableSOS extends ConsumerStatefulWidget {
  const DraggableSOS({super.key});

  @override
  ConsumerState<DraggableSOS> createState() => _DraggableSOSState();
}

class _DraggableSOSState extends ConsumerState<DraggableSOS> {
  double _dragPosition = 0;
  final double _triggerThreshold = 150.0;
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    final provider = ref.watch(appRiverpod);
    final size = MediaQuery.of(context).size;

    // لا يظهر إذا كانت حالة الطوارئ نشطة بالفعل لأن الواجهة الكاملة ستغطي الشاشة
    if (provider.isEmergencyActive) return const SizedBox.shrink();

    return AnimatedPositioned(
      duration: _isDragging ? Duration.zero : const Duration(milliseconds: 300),
      right: -_dragPosition, // المقبض ملتصق باليمين
      bottom:
          size.height * 0.15, // موقعه في الثلث السفلي لتسهيل الوصول بالإبهام
      child: GestureDetector(
        onHorizontalDragUpdate: (details) {
          setState(() {
            _isDragging = true;
            // السحب لليسار يزيد القيمة (نحن نطرحها من right، فكلما زادت تحرك لليسار)
            _dragPosition =
                (_dragPosition - details.delta.dx).clamp(0.0, size.width * 0.8);
          });
        },
        onHorizontalDragEnd: (details) {
          setState(() => _isDragging = false);
          if (_dragPosition > _triggerThreshold) {
            // تفعيل الطوارئ إذا تجاوز السحب المسافة المحددة
            provider.triggerSOS();
            _dragPosition = 0;
          } else {
            // العودة للمكان الأصلي إذا لم يكتمل السحب
            _dragPosition = 0;
          }
        },
        child: Container(
          height: 70,
          decoration: BoxDecoration(
            color: const Color(0xFFef4444),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(35),
              bottomLeft: Radius.circular(35),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 10,
                offset: const Offset(-2, 0),
              ),
            ],
            gradient: const LinearGradient(
              colors: [Color(0xFFef4444), Color(0xFFb91c1c)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // المقبض المرئي (الجزء الذي يبرز دائماً)
              Container(
                width: 40,
                alignment: Alignment.center,
                child: const Icon(
                  Icons.chevron_left_rounded,
                  color: Colors.white,
                  size: 30,
                ),
              ),
              // الجزء الذي يظهر عند السحب
              AnimatedContainer(
                duration: const Duration(milliseconds: 100),
                width: _dragPosition > 20 ? _dragPosition : 0,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const NeverScrollableScrollPhysics(),
                  child: Container(
                    padding: const EdgeInsets.only(right: 20),
                    child: const Row(
                      children: [
                        Icon(Icons.warning_amber_rounded,
                            color: Colors.white, size: 24),
                        SizedBox(width: 8),
                        Text(
                          'اسحب للطوارئ',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Cairo',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
