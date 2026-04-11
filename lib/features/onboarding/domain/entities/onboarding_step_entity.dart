import 'package:freezed_annotation/freezed_annotation.dart';

part 'onboarding_step_entity.freezed.dart';

enum OnboardingStepType { name, currency, categories, accounts, personalising }

@freezed
abstract class OnboardingStepEntity with _$OnboardingStepEntity {
  const factory OnboardingStepEntity({
    required OnboardingStepType type,
    required String title,
    required String subtitle,
    required String lottieAsset,
    required bool isSkippable,
    required bool isFinal,
  }) = _OnboardingStepEntity;
}

/// The ordered list of onboarding steps.
///
/// To add, remove, or reorder steps, edit this list only.
const List<OnboardingStepEntity> kOnboardingSteps = [
  OnboardingStepEntity(
    type: OnboardingStepType.name,
    title: 'What should we call you?',
    subtitle: 'Helps us make Track feel like yours',
    lottieAsset: 'lottie/Loop.lottie',
    isSkippable: false,
    isFinal: false,
  ),
  OnboardingStepEntity(
    type: OnboardingStepType.currency,
    title: 'Pick your currency',
    subtitle: 'You can always add more later',
    lottieAsset: 'lottie/currency.lottie',
    isSkippable: false,
    isFinal: false,
  ),
  OnboardingStepEntity(
    type: OnboardingStepType.categories,
    title: 'Choose your categories',
    subtitle: 'Select what spending areas matter to you',
    lottieAsset: 'lottie/Loop.lottie',
    isSkippable: true,
    isFinal: false,
  ),
  OnboardingStepEntity(
    type: OnboardingStepType.accounts,
    title: 'Add your accounts',
    subtitle: 'Where does your money live?',
    lottieAsset: 'lottie/chat with machine.lottie',
    isSkippable: true,
    isFinal: false,
  ),
  OnboardingStepEntity(
    type: OnboardingStepType.personalising,
    title: 'Setting things up\u2026',
    subtitle: 'Making Track feel like yours',
    lottieAsset: 'lottie/LOADING.lottie',
    isSkippable: false,
    isFinal: true,
  ),
];
