import 'package:drift/drift.dart';

import 'sync_runs.dart';

@DataClassName('SyncRunCategoryEntry')
class SyncRunCategories extends Table {
  TextColumn get id => text()();

  TextColumn get syncRunId =>
      text().references(SyncRuns, #id, onDelete: KeyAction.cascade)();

  TextColumn get category => text()();

  TextColumn get pullStatus => text()();

  TextColumn get pushStatus => text()();

  IntColumn get startedAt => integer()();

  IntColumn get completedAt => integer().nullable()();

  TextColumn get error => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  List<Set<Column<Object>>> get indexes => [
    {syncRunId},
    {category, startedAt},
  ];
}
