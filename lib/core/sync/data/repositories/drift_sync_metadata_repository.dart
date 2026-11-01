import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';

import '../../../database/app_drift_database.dart';
import '../../domain/repositories/sync_metadata_repository.dart';

@LazySingleton(as: SyncMetadataRepository)
class DriftSyncMetadataRepository implements SyncMetadataRepository {
  DriftSyncMetadataRepository(this._database);

  final AppDriftDatabase _database;

  @override
  Future<String?> getCursor(String category) async {
    final query = _database.select(_database.syncMetadata)
      ..where((table) => table.category.equals(category));

    final metadata = await query.getSingleOrNull();

    return metadata?.cursor;
  }

  @override
  Future<void> updateCursor({
    required String category,
    required String? cursor,
  }) async {
    await _database
        .into(_database.syncMetadata)
        .insertOnConflictUpdate(
          SyncMetadataCompanion.insert(
            category: category,
            cursor: Value(cursor),
          ),
        );
  }

  @override
  Future<void> markPullCompleted({
    required String category,
    required DateTime completedAt,
  }) async {
    final existing = await _getOrCreate(category);

    await _database
        .into(_database.syncMetadata)
        .insertOnConflictUpdate(
          existing.copyWith(
            lastSuccessfulPullAt: Value(completedAt.millisecondsSinceEpoch),
          ),
        );
  }

  @override
  Future<void> markSyncCompleted({
    required String category,
    required DateTime completedAt,
  }) async {
    final existing = await _getOrCreate(category);

    await _database
        .into(_database.syncMetadata)
        .insertOnConflictUpdate(
          existing.copyWith(
            lastSuccessfulSyncAt: Value(completedAt.millisecondsSinceEpoch),
          ),
        );
  }

  Future<SyncMetadataEntry> _getOrCreate(String category) async {
    final query = _database.select(_database.syncMetadata)
      ..where((table) => table.category.equals(category));

    final existing = await query.getSingleOrNull();

    if (existing != null) {
      return existing;
    }

    await _database
        .into(_database.syncMetadata)
        .insert(SyncMetadataCompanion.insert(category: category));

    return (await query.getSingle());
  }
}
