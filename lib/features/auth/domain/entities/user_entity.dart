import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_entity.freezed.dart';

@freezed
abstract class UserEntity with _$UserEntity {
  const factory UserEntity({
    required String uid,
    required String email,
    required bool isAnonymous,
    String? displayName,
    String? photoUrl,
  }) = _UserEntity;
}
