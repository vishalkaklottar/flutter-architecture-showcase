import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_architecture_showcase/core/database/app_drift_database.dart';

void main() {
  late AppDriftDatabase database;

  setUp(() {
    database = AppDriftDatabase.forTesting(
      NativeDatabase.memory(
        setup: (database) {
          database.execute('PRAGMA foreign_keys = ON');
        },
      ),
    );
  });

  tearDown(() async {
    await database.close();
  });

  group('SyncMetadata', () {
    test('stores and retrieves category sync metadata', () async {
      await database
          .into(database.syncMetadata)
          .insert(
            SyncMetadataCompanion.insert(
              category: 'products',
              cursor: const Value('cursor-123'),
              lastSuccessfulPullAt: const Value(1000),
              lastSuccessfulSyncAt: const Value(2000),
              currentGeneration: const Value(1),
            ),
          );

      final result = await database.select(database.syncMetadata).getSingle();

      expect(result.category, 'products');
      expect(result.cursor, 'cursor-123');
      expect(result.lastSuccessfulPullAt, 1000);
      expect(result.lastSuccessfulSyncAt, 2000);
      expect(result.currentGeneration, 1);
    });
  });

  group('SyncQueue', () {
    test('stores an operation with default retry state', () async {
      await database
          .into(database.syncQueue)
          .insert(
            SyncQueueCompanion.insert(
              id: 'operation-1',
              entityType: 'products',
              entityId: 'product-1',
              operation: 'create',
              payload: const Value('{"name":"Product"}'),
              createdAt: 1000,
              updatedAt: 1000,
            ),
          );

      final result = await database.select(database.syncQueue).getSingle();

      expect(result.id, 'operation-1');
      expect(result.status, 'pending');
      expect(result.attemptCount, 0);
      expect(result.payload, '{"name":"Product"}');
    });
  });

  group('SyncRun history', () {
    test('stores a sync run with its category execution', () async {
      await database
          .into(database.syncRuns)
          .insert(
            SyncRunsCompanion.insert(
              id: 'run-1',
              trigger: 'manual',
              status: 'syncing',
              startedAt: 1000,
            ),
          );

      await database
          .into(database.syncRunCategories)
          .insert(
            SyncRunCategoriesCompanion.insert(
              id: 'run-category-1',
              syncRunId: 'run-1',
              category: 'products',
              pullStatus: 'completed',
              pushStatus: 'pending',
              startedAt: 1000,
            ),
          );

      final run = await database.select(database.syncRuns).getSingle();
      final categories = await database
          .select(database.syncRunCategories)
          .get();

      expect(run.id, 'run-1');
      expect(run.trigger, 'manual');
      expect(categories, hasLength(1));
      expect(categories.single.category, 'products');
    });

    test('deleting a sync run cascades to its category history', () async {
      await database
          .into(database.syncRuns)
          .insert(
            SyncRunsCompanion.insert(
              id: 'run-2',
              trigger: 'startup',
              status: 'completed',
              startedAt: 1000,
            ),
          );

      await database
          .into(database.syncRunCategories)
          .insert(
            SyncRunCategoriesCompanion.insert(
              id: 'run-category-2',
              syncRunId: 'run-2',
              category: 'products',
              pullStatus: 'completed',
              pushStatus: 'completed',
              startedAt: 1000,
            ),
          );

      await (database.delete(
        database.syncRuns,
      )..where((table) => table.id.equals('run-2'))).go();

      final remainingCategories = await database
          .select(database.syncRunCategories)
          .get();

      expect(remainingCategories, isEmpty);
    });

    test('deleting sync history preserves queue and metadata', () async {
      await database
          .into(database.syncRuns)
          .insert(
            SyncRunsCompanion.insert(
              id: 'run-3',
              trigger: 'manual',
              status: 'completed',
              startedAt: 1000,
            ),
          );

      await database
          .into(database.syncQueue)
          .insert(
            SyncQueueCompanion.insert(
              id: 'operation-3',
              entityType: 'products',
              entityId: 'product-3',
              operation: 'create',
              createdAt: 1000,
              updatedAt: 1000,
            ),
          );

      await database
          .into(database.syncMetadata)
          .insert(
            SyncMetadataCompanion.insert(
              category: 'products',
              cursor: const Value('cursor-3'),
            ),
          );

      await (database.delete(
        database.syncRuns,
      )..where((table) => table.id.equals('run-3'))).go();

      expect(await database.select(database.syncQueue).get(), hasLength(1));
      expect(await database.select(database.syncMetadata).get(), hasLength(1));
    });
  });
}
