import 'package:dio/dio.dart';
import 'package:three_degress_of_doubt_frontend/core/network/dio_client.dart';
import 'package:three_degress_of_doubt_frontend/features/auth/data/auth_repository.dart';
import 'package:three_degress_of_doubt_frontend/features/home/data/stage_repository.dart';

class AppDependencies {
  AppDependencies._();

  static final Dio dio = DioClient.instance;
  static final AuthRepository authRepository = AuthRepository(dio: dio);
  static final StageRepository stageRepository = StageRepository(dio: dio);
}
