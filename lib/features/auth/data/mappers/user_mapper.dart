import 'package:track/features/auth/data/models/user_dto.dart';
import 'package:track/features/auth/domain/entities/user_entity.dart';

extension UserDtoToEntity on UserDto {
  UserEntity toEntity() => UserEntity(
    uid: uid,
    email: email,
    displayName: displayName,
    photoUrl: photoUrl,
    isAnonymous: isAnonymous,
  );
}

extension UserEntityToDto on UserEntity {
  UserDto toDto() => UserDto(
    uid: uid,
    email: email,
    displayName: displayName,
    photoUrl: photoUrl,
    isAnonymous: isAnonymous,
  );
}
