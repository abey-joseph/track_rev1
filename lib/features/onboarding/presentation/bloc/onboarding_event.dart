import 'package:freezed_annotation/freezed_annotation.dart';

part 'onboarding_event.freezed.dart';

@freezed
sealed class OnboardingEvent with _$OnboardingEvent {
  const factory OnboardingEvent.started({required String userId}) =
      OnboardingStarted;

  const factory OnboardingEvent.nextPressed() = OnboardingNextPressed;

  const factory OnboardingEvent.backPressed() = OnboardingBackPressed;

  const factory OnboardingEvent.stepSkipped() = OnboardingStepSkipped;

  const factory OnboardingEvent.nameChanged({required String name}) =
      OnboardingNameChanged;

  const factory OnboardingEvent.currencySelected({
    required String currencyCode,
  }) = OnboardingCurrencySelected;

  const factory OnboardingEvent.categoriesConfirmed({
    required List<int> selectedCategoryIds,
  }) = OnboardingCategoriesConfirmed;

  const factory OnboardingEvent.accountsConfirmed() =
      OnboardingAccountsConfirmed;

  const factory OnboardingEvent.finalizationRequested() =
      OnboardingFinalizationRequested;
}
