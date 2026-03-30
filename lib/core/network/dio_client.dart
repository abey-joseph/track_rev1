import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:talker_dio_logger/talker_dio_logger.dart';
import 'package:track/core/network/api_constants.dart';

@module
abstract class NetworkModule {
  @lazySingleton
  Dio dio(TalkerDioLogger talkerDioLogger) {
    final dio = Dio(
      BaseOptions(
        connectTimeout: ApiConstants.connectTimeout,
        receiveTimeout: ApiConstants.receiveTimeout,
      ),
    );
    dio.interceptors.add(talkerDioLogger);
    return dio;
  }
}
