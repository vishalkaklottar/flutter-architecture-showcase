import 'package:flutter_architecture_showcase/core/database/database_connection.dart';
import 'package:injectable/injectable.dart';

import 'app_drift_database.dart';

@module
abstract class DatabaseModule {
  @lazySingleton
  AppDriftDatabase get database => AppDriftDatabase(createDatabaseConnection());
}
