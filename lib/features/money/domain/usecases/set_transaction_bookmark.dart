import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:track/core/error/failures.dart';
import 'package:track/core/usecases/usecase.dart';
import 'package:track/features/money/domain/repositories/money_repository.dart';

@lazySingleton
class SetTransactionBookmark implements UseCase<void, BookmarkParams> {
  SetTransactionBookmark(this._repository);

  final MoneyRepository _repository;

  @override
  Future<Either<Failure, void>> call(BookmarkParams params) =>
      _repository.setBookmark(
        params.transactionId,
        isBookmarked: params.isBookmarked,
      );
}

class BookmarkParams extends Equatable {
  const BookmarkParams({
    required this.transactionId,
    required this.isBookmarked,
  });

  final int transactionId;
  final bool isBookmarked;

  @override
  List<Object?> get props => [transactionId, isBookmarked];
}
