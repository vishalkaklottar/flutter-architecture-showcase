import 'package:drift/drift.dart';

@DataClassName('SyncMetadataEntry')
class SyncMetadata extends Table {
  TextColumn get category => text()();

  TextColumn get cursor => text().nullable()();

  IntColumn get lastSuccessfulPullAt => integer().nullable()();

  IntColumn get lastSuccessfulSyncAt => integer().nullable()();

  IntColumn get currentGeneration => integer().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {category};
}
