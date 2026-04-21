import 'package:dio/dio.dart';
import 'package:three_degress_of_doubt_frontend/core/config/backend_config.dart';

class DioClient {
  DioClient._();

  static final Dio instance = Dio(
    BaseOptions(
      connectTimeout: BackendConfig.connectTimeout,
      sendTimeout: BackendConfig.sendTimeout,
      receiveTimeout: BackendConfig.receiveTimeout,
    ),
  );
}
