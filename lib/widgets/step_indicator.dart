import 'package:flutter/material.dart';
import '../constants.dart';
import '../svg_icons.dart';

class StepIndicator extends StatefulWidget {
  final int currentStep;
  final int totalSteps;
  final List<String> labels;

  const StepIndicator({
    super.key,
    required this.currentStep,
    this.totalSteps = 3,
    required this.labels,
  });

  @override
  State<StepIndicator> createState() => _StepIndicatorState();
}

class _StepIndicatorState extends State<StepIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _progressController;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _progressController.forward();
    });
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant StepIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentStep != widget.currentStep) {
      _progressController.reset();
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) _progressController.forward();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(children: _buildSteps()),
        const SizedBox(height: 1),
        Row(
          children: widget.labels.map((label) {
            final index = widget.labels.indexOf(label);
            final isActive = index == widget.currentStep - 1;
            return Expanded(
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 8,
                  color: isActive ? AppColors.primary : AppColors.textSecondary,
                  fontWeight: isActive ? FontWeight.w500 : FontWeight.normal,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  List<Widget> _buildSteps() {
    List<Widget> steps = [];
    for (int i = 0; i < widget.totalSteps; i++) {
      final stepNum = i + 1;
      final isDone = stepNum < widget.currentStep;
      final isActive = stepNum == widget.currentStep;

      steps.add(
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDone ? AppColors.primary : null,
            border: Border.all(
              color: isDone || isActive
                  ? AppColors.primary
                  : AppColors.borderInput,
              width: 1.5,
            ),
          ),
          child: Center(
            child: isDone
                ? AppIcons.check(size: 9)
                : Text(
                    _arabicNumber(stepNum),
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w500,
                      color: isActive ? AppColors.primary : AppColors.textHint,
                    ),
                  ),
          ),
        ),
      );

      if (i < widget.totalSteps - 1) {
        steps.add(
          Expanded(
            child: Container(
              height: 2,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: AppColors.bgInput,
                borderRadius: BorderRadius.circular(2),
              ),
              child: isActive
                  ? AnimatedBuilder(
                      animation: _progressController,
                      builder: (context, child) {
                        return FractionallySizedBox(
                          alignment: Alignment.centerRight,
                          widthFactor: _progressController.value,
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        );
                      },
                    )
                  : isDone
                      ? Container(
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        )
                      : null,
            ),
          ),
        );
      }
    }
    return steps;
  }

  String _arabicNumber(int num) {
    const arabicNums = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    return arabicNums[num];
  }
}
