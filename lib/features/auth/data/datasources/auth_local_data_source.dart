import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:injectable/injectable.dart';
import 'package:track/core/constants/storage_constants.dart';
import 'package:track/core/error/exceptions.dart';

abstract class AuthLocalDataSource {
  Future<String?> getToken();
  Future<void> saveToken(String token);
  Future<void> deleteToken();
  Future<String?> getUserId();
  Future<void> saveUserId(String userId);
  Future<void> clearAll();
}

@LazySingleton(as: AuthLocalDataSource)
class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  AuthLocalDataSourceImpl(this._secureStorage);

  final FlutterSecureStorage _secureStorage;

  @override
  Future<String?> getToken() async {
    try {
      return await _secureStorage.read(key: StorageConstants.authToken);
    } catch (e) {
      throw CacheException(message: e.toString());
    }
  }

  @override
  Future<void> saveToken(String token) async {
    try {
      await _secureStorage.write(key: StorageConstants.authToken, value: token);
    } catch (e) {
      throw CacheException(message: e.toString());
    }
  }

  @override
  Future<void> deleteToken() async {
    try {
      await _secureStorage.delete(key: StorageConstants.authToken);
    } catch (e) {
      throw CacheException(message: e.toString());
    }
  }

  @override
  Future<String?> getUserId() async {
    try {
      return await _secureStorage.read(key: StorageConstants.userId);
    } catch (e) {
      throw CacheException(message: e.toString());
    }
  }

  @override
  Future<void> saveUserId(String userId) async {
    try {
      await _secureStorage.write(key: StorageConstants.userId, value: userId);
    } catch (e) {
      throw CacheException(message: e.toString());
    }
  }

  @override
  Future<void> clearAll() async {
    try {
      await _secureStorage.deleteAll();
    } catch (e) {
      throw CacheException(message: e.toString());
    }
  }
}
