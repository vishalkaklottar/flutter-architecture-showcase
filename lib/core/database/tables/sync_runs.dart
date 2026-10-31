import 'package:drift/drift.dart';

@DataClassName('SyncRunEntry')
class SyncRuns extends Table {
  TextColumn get id => text()();

  TextColumn get trigger => text()();

  TextColumn get status => text()();

  IntColumn get startedAt => integer()();

  IntColumn get completedAt => integer().nullable()();

  TextColumn get summary => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  List<Set<Column<Object>>> get indexes => [
    {startedAt},
  ];
}
