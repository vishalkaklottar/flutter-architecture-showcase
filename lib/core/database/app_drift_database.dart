import 'package:drift/drift.dart';

part 'app_drift_database.g.dart';

@DriftDatabase(tables: [])
class AppDriftDatabase extends _$AppDriftDatabase {
  AppDriftDatabase(super.e);

  AppDriftDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 1;
}
