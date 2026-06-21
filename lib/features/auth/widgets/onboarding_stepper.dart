import 'package:flutter/material.dart';

class OnboardingStepper extends StatelessWidget {
  const OnboardingStepper({
    super.key,
    this.currentStep = 1,
    this.stepCount = 6,
    this.completedSteps = 0,
  });

  final int currentStep;
  final int stepCount;
  final int completedSteps;

  static const _gold = Color(0xFFF5B81F);
  static const _field = Color(0xFF0B111D);
  static const _border = Color(0xFF303541);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(stepCount * 2 - 1, (index) {
        if (index.isOdd) {
          final completed = index < (completedSteps * 2);
          return Expanded(
            child: Container(
              height: 3,
              margin: const EdgeInsets.symmetric(horizontal: 5),
              decoration: BoxDecoration(
                color: completed ? const Color(0xFF24B36B) : _border,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          );
        }

        final step = (index ~/ 2) + 1;
        final active = step == currentStep;
        final completed = step <= completedSteps;
        return Container(
          width: 43,
          height: 43,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: completed
                ? const Color(0xFF24B36B)
                : active
                ? _gold
                : _field.withValues(alpha: 0.88),
            border: Border.all(
              color: completed
                  ? const Color(0xFF24B36B)
                  : active
                  ? _gold
                  : _border,
              width: 1.4,
            ),
          ),
          child: completed
              ? const Icon(Icons.check_rounded, color: Colors.white, size: 23)
              : Text(
                  '$step',
                  style: TextStyle(
                    color: active ? Colors.black : Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
        );
      }),
    );
  }
}
