import 'package:three_degress_of_doubt_frontend/features/auth/data/auth_repository.dart';
import 'package:three_degress_of_doubt_frontend/features/home/data/stage_repository.dart';

class AppDependencies {
  AppDependencies._();

  static final AuthRepository authRepository = AuthRepository();
  static final StageRepository stageRepository = StageRepository();
}
