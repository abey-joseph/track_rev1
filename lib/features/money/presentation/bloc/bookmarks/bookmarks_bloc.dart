import 'package:bloc/bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:track/core/error/failures.dart';
import 'package:track/features/money/domain/usecases/get_accounts.dart';
import 'package:track/features/money/domain/usecases/set_transaction_bookmark.dart';
import 'package:track/features/money/domain/usecases/watch_bookmarked_transactions.dart';
import 'package:track/features/money/presentation/bloc/bookmarks/bookmarks_event.dart';
import 'package:track/features/money/presentation/bloc/bookmarks/bookmarks_state.dart';

@injectable
class BookmarksBloc extends Bloc<BookmarksEvent, BookmarksState> {
  BookmarksBloc(this._watchBookmarked, this._setBookmark)
    : super(const BookmarksState()) {
    on<BookmarksLoadRequested>(_onLoad);
    on<BookmarksSortChanged>(_onSortChanged);
    on<BookmarksRemoveRequested>(_onRemove);
  }

  final WatchBookmarkedTransactions _watchBookmarked;
  final SetTransactionBookmark _setBookmark;

  Future<void> _onLoad(
    BookmarksLoadRequested event,
    Emitter<BookmarksState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, failure: null));
    await emit.forEach(
      _watchBookmarked(UserIdParams(userId: event.userId)),
      onData:
          (result) => result.fold(
            (failure) => state.copyWith(isLoading: false, failure: failure),
            (transactions) =>
                state.copyWith(isLoading: false, transactions: transactions),
          ),
      onError:
          (_, _) => state.copyWith(
            isLoading: false,
            failure: const Failure.cache(message: 'Failed to load bookmarks'),
          ),
    );
  }

  void _onSortChanged(
    BookmarksSortChanged event,
    Emitter<BookmarksState> emit,
  ) {
    emit(
      state.copyWith(
        sortField: event.sortField,
        sortAscending: event.ascending,
      ),
    );
  }

  Future<void> _onRemove(
    BookmarksRemoveRequested event,
    Emitter<BookmarksState> emit,
  ) async {
    await _setBookmark(
      BookmarkParams(transactionId: event.transactionId, isBookmarked: false),
    );
    // Stream auto-emits the updated list via emit.forEach in _onLoad.
  }
}
