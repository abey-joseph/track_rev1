import 'package:freezed_annotation/freezed_annotation.dart';

part 'bookmarks_event.freezed.dart';

@freezed
sealed class BookmarksEvent with _$BookmarksEvent {
  const factory BookmarksEvent.loadRequested({
    required String userId,
  }) = BookmarksLoadRequested;

  const factory BookmarksEvent.sortChanged({
    required BookmarkSortField sortField,
    required bool ascending,
  }) = BookmarksSortChanged;

  const factory BookmarksEvent.removeRequested({
    required int transactionId,
  }) = BookmarksRemoveRequested;
}

enum BookmarkSortField { date, amount }
