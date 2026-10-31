import 'package:drift/drift.dart';

import 'tables/sync_metadata.dart';
import 'tables/sync_queue.dart';
import 'tables/sync_run_categories.dart';
import 'tables/sync_runs.dart';

part 'app_drift_database.g.dart';

@DriftDatabase(tables: [SyncMetadata, SyncQueue, SyncRuns, SyncRunCategories])
class AppDriftDatabase extends _$AppDriftDatabase {
  AppDriftDatabase(super.e);

  AppDriftDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 1;
}
