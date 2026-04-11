import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:track/core/error/failures.dart';
import 'package:track/features/onboarding/domain/entities/onboarding_step_entity.dart';

part 'onboarding_state.freezed.dart';

@freezed
abstract class OnboardingState with _$OnboardingState {
  const factory OnboardingState({
    @Default([]) List<OnboardingStepEntity> steps,
    @Default(0) int currentStepIndex,
    @Default('') String displayName,
    @Default('USD') String selectedCurrency,
    @Default([]) List<int> selectedCategoryIds,
    @Default(false) bool isLoading,
    @Default(false) bool isCompleted,
    @Default('') String userId,
    Failure? failure,
  }) = _OnboardingState;
}

extension OnboardingStateX on OnboardingState {
  OnboardingStepEntity? get currentStep =>
      steps.isEmpty ? null : steps[currentStepIndex];

  double get progress =>
      steps.isEmpty ? 0 : (currentStepIndex + 1) / steps.length;

  bool get isFirstStep => currentStepIndex == 0;

  bool get isLastDataStep =>
      steps.isNotEmpty && currentStepIndex == steps.length - 2;

  bool get canProceed {
    final step = currentStep;
    if (step == null) return false;
    return switch (step.type) {
      OnboardingStepType.name => displayName.trim().isNotEmpty,
      OnboardingStepType.currency => selectedCurrency.isNotEmpty,
      _ => true,
    };
  }
}
