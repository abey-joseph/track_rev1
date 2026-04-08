import 'package:freezed_annotation/freezed_annotation.dart';

part 'money_event.freezed.dart';

@freezed
sealed class MoneyEvent with _$MoneyEvent {
  const factory MoneyEvent.loadRequested({required String userId}) =
      MoneyLoadRequested;

  const factory MoneyEvent.refreshRequested() = MoneyRefreshRequested;
}
