import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:track/core/error/failures.dart';
import 'package:track/features/onboarding/domain/entities/onboarding_step_entity.dart';
import 'package:track/features/onboarding/presentation/bloc/onboarding_event.dart';
import 'package:track/features/onboarding/presentation/bloc/onboarding_state.dart';
import 'package:track/features/settings/domain/usecases/complete_onboarding.dart';

@injectable
class OnboardingBloc extends Bloc<OnboardingEvent, OnboardingState> {
  OnboardingBloc(this._completeOnboarding) : super(const OnboardingState()) {
    on<OnboardingStarted>(_onStarted);
    on<OnboardingNextPressed>(_onNextPressed);
    on<OnboardingBackPressed>(_onBackPressed);
    on<OnboardingStepSkipped>(_onStepSkipped);
    on<OnboardingNameChanged>(_onNameChanged);
    on<OnboardingCurrencySelected>(_onCurrencySelected);
    on<OnboardingCategoriesConfirmed>(_onCategoriesConfirmed);
    on<OnboardingAccountsConfirmed>(_onAccountsConfirmed);
    on<OnboardingFinalizationRequested>(_onFinalizationRequested);
  }

  final CompleteOnboarding _completeOnboarding;

  void _onStarted(OnboardingStarted event, Emitter<OnboardingState> emit) {
    emit(
      state.copyWith(
        steps: kOnboardingSteps,
        userId: event.userId,
        currentStepIndex: 0,
      ),
    );
  }

  void _onNextPressed(
    OnboardingNextPressed event,
    Emitter<OnboardingState> emit,
  ) {
    final step = state.currentStep;
    if (step == null) return;
    if (step.isFinal) return;

    // If next step is the personalising (last) step, advance first then
    // dispatch finalization automatically via the step widget.
    final nextIndex = state.currentStepIndex + 1;
    emit(state.copyWith(currentStepIndex: nextIndex, failure: null));
  }

  void _onBackPressed(
    OnboardingBackPressed event,
    Emitter<OnboardingState> emit,
  ) {
    if (state.isFirstStep) return;
    emit(
      state.copyWith(
        currentStepIndex: state.currentStepIndex - 1,
        failure: null,
      ),
    );
  }

  void _onStepSkipped(
    OnboardingStepSkipped event,
    Emitter<OnboardingState> emit,
  ) {
    final step = state.currentStep;
    if (step == null || !step.isSkippable) return;
    final nextIndex = state.currentStepIndex + 1;
    emit(state.copyWith(currentStepIndex: nextIndex, failure: null));
  }

  void _onNameChanged(
    OnboardingNameChanged event,
    Emitter<OnboardingState> emit,
  ) {
    emit(state.copyWith(displayName: event.name));
  }

  void _onCurrencySelected(
    OnboardingCurrencySelected event,
    Emitter<OnboardingState> emit,
  ) {
    emit(state.copyWith(selectedCurrency: event.currencyCode));
  }

  void _onCategoriesConfirmed(
    OnboardingCategoriesConfirmed event,
    Emitter<OnboardingState> emit,
  ) {
    emit(state.copyWith(selectedCategoryIds: event.selectedCategoryIds));
  }

  void _onAccountsConfirmed(
    OnboardingAccountsConfirmed event,
    Emitter<OnboardingState> emit,
  ) {
    // No additional state mutation needed — accounts are handled via defaults.
  }

  Future<void> _onFinalizationRequested(
    OnboardingFinalizationRequested event,
    Emitter<OnboardingState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, failure: null));

    final params = CompleteOnboardingParams(
      userId: state.userId,
      displayName:
          state.displayName.trim().isEmpty ? 'You' : state.displayName.trim(),
      currencyCode: state.selectedCurrency,
    );

    // Enforce a minimum 7-second wait to give the animation time to play.
    Either<Failure, Unit>? either;
    await Future.wait<void>([
      _completeOnboarding(params).then((result) => either = result),
      Future<void>.delayed(const Duration(seconds: 7)),
    ]);

    either!.fold(
      (failure) => emit(
        state.copyWith(isLoading: false, failure: failure),
      ),
      (_) => emit(
        state.copyWith(isLoading: false, isCompleted: true),
      ),
    );
  }
}
