import 'package:drift/native.dart';
import 'package:flutter_architecture_showcase/core/database/app_drift_database.dart';
import 'package:flutter_architecture_showcase/core/sync/data/repositories/drift_sync_queue_repository.dart';
import 'package:flutter_architecture_showcase/core/sync/domain/entities/sync_operation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDriftDatabase database;
  late DriftSyncQueueRepository repository;

  final now = DateTime(2026, 10, 31, 10);

  SyncOperation createOperation({
    String id = 'operation-1',
    String entityType = 'products',
    SyncOperationStatus status = SyncOperationStatus.pending,
    DateTime? nextRetryAt,
    int attemptCount = 0,
  }) {
    return SyncOperation(
      id: id,
      entityType: entityType,
      entityId: 'product-1',
      operation: SyncOperationType.create,
      status: status,
      attemptCount: attemptCount,
      payload: '{"name":"Product"}',
      nextRetryAt: nextRetryAt,
      createdAt: now,
      updatedAt: now,
    );
  }

  setUp(() {
    database = AppDriftDatabase(
      NativeDatabase.memory(
        setup: (database) {
          database.execute('PRAGMA foreign_keys = ON');
        },
      ),
    );

    repository = DriftSyncQueueRepository(database);
  });

  tearDown(() async {
    await database.close();
  });

  group('enqueue', () {
    test('persists an operation', () async {
      await repository.enqueue(createOperation());

      final operations = await repository.getPendingOperations(
        entityType: 'products',
        limit: 10,
      );

      expect(operations, hasLength(1));
      expect(operations.single.id, 'operation-1');
      expect(operations.single.payload, '{"name":"Product"}');
    });

    test('CREATE + UPDATE retains CREATE with latest payload', () async {
      await repository.enqueue(createOperation());

      await repository.enqueue(
        createOperation(
          id: 'operation-2',
          status: SyncOperationStatus.pending,
        ).copyWith(
          operation: SyncOperationType.update,
          payload: '{"name":"Updated Product"}',
        ),
      );

      final entries = await database.select(database.syncQueue).get();

      expect(entries, hasLength(1));
      expect(entries.single.id, 'operation-1');
      expect(entries.single.operation, 'create');
      expect(entries.single.payload, '{"name":"Updated Product"}');
    });

    test('UPDATE + UPDATE retains UPDATE with latest payload', () async {
      await repository.enqueue(
        createOperation().copyWith(operation: SyncOperationType.update),
      );

      await repository.enqueue(
        createOperation(id: 'operation-2').copyWith(
          operation: SyncOperationType.update,
          payload: '{"name":"Latest Product"}',
        ),
      );

      final entries = await database.select(database.syncQueue).get();

      expect(entries, hasLength(1));
      expect(entries.single.id, 'operation-1');
      expect(entries.single.operation, 'update');
      expect(entries.single.payload, '{"name":"Latest Product"}');
    });

    test('CREATE + DELETE removes pending operation', () async {
      await repository.enqueue(createOperation());

      await repository.enqueue(
        createOperation(id: 'operation-2')
            .copyWith(operation: SyncOperationType.delete, payload: null),
      );

      final entries = await database.select(database.syncQueue).get();

      expect(entries, isEmpty);
    });

    test('UPDATE + DELETE becomes DELETE', () async {
      await repository.enqueue(
        createOperation().copyWith(operation: SyncOperationType.update),
      );

      await repository.enqueue(
        createOperation(id: 'operation-2')
            .copyWith(operation: SyncOperationType.delete, payload: null),
      );

      final entries = await database.select(database.syncQueue).get();

      expect(entries, hasLength(1));
      expect(entries.single.id, 'operation-1');
      expect(entries.single.operation, 'delete');
      expect(entries.single.payload, isNull);
    });

    test('DELETE + CREATE becomes CREATE with latest payload', () async {
      await repository.enqueue(
        createOperation().copyWith(
          operation: SyncOperationType.delete,
          payload: null,
        ),
      );

      await repository.enqueue(createOperation(id: 'operation-2'));

      final entries = await database.select(database.syncQueue).get();

      expect(entries, hasLength(1));
      expect(entries.single.id, 'operation-1');
      expect(entries.single.operation, 'create');
      expect(entries.single.payload, '{"name":"Product"}');
    });

    test('does not coalesce with an existing processing operation', () async {
      await repository.enqueue(createOperation());

      await repository.markProcessing('operation-1');

      await repository.enqueue(
        createOperation(id: 'operation-2').copyWith(
          operation: SyncOperationType.update,
          payload: '{"name":"Updated Product"}',
        ),
      );

      final entries = await database.select(database.syncQueue).get();

      expect(entries, hasLength(2));

      final original = entries.firstWhere((entry) => entry.id == 'operation-1');

      final newer = entries.firstWhere((entry) => entry.id == 'operation-2');

      expect(original.status, 'processing');
      expect(original.operation, 'create');
      expect(newer.status, 'pending');
      expect(newer.operation, 'update');
    });
  });

  group('getPendingOperations', () {
    test(
      'returns only eligible operations for the requested category',
      () async {
        final currentTime = DateTime.now();

        await repository.enqueue(createOperation(id: 'eligible'));

        await repository.enqueue(
          createOperation(
            id: 'future-retry',
            nextRetryAt: currentTime.add(const Duration(hours: 1)),
          ),
        );

        await repository.enqueue(
          createOperation(id: 'other-category', entityType: 'categories'),
        );

        final operations = await repository.getPendingOperations(
          entityType: 'products',
          limit: 10,
        );

        expect(operations.map((operation) => operation.id).toList(), [
          'eligible',
        ]);
      },
    );

    test('returns an empty list when limit is zero', () async {
      await repository.enqueue(createOperation());

      final operations = await repository.getPendingOperations(
        entityType: 'products',
        limit: 0,
      );

      expect(operations, isEmpty);
    });
  });

  group('state transitions', () {
    test('marks a pending operation as processing', () async {
      await repository.enqueue(createOperation());

      await repository.markProcessing('operation-1');

      final entry = await database.select(database.syncQueue).getSingle();

      expect(entry.status, 'processing');
    });

    test('removes a processing operation after completion', () async {
      await repository.enqueue(createOperation());
      await repository.markProcessing('operation-1');

      await repository.markCompleted('operation-1');

      final entries = await database.select(database.syncQueue).get();

      expect(entries, isEmpty);
    });

    test('marks a processing operation as failed', () async {
      await repository.enqueue(createOperation());
      await repository.markProcessing('operation-1');

      await repository.markFailed('operation-1', error: 'Invalid request');

      final entry = await database.select(database.syncQueue).getSingle();

      expect(entry.status, 'failed');
      expect(entry.lastError, 'Invalid request');
    });

    test('schedules retry and increments attempt count', () async {
      await repository.enqueue(createOperation());
      await repository.markProcessing('operation-1');

      final retryAt = now.add(const Duration(minutes: 2));

      await repository.scheduleRetry(
        'operation-1',
        nextRetryAt: retryAt,
        error: 'Network timeout',
      );

      final entry = await database.select(database.syncQueue).getSingle();

      expect(entry.status, 'pending');
      expect(entry.attemptCount, 1);
      expect(entry.nextRetryAt, retryAt.millisecondsSinceEpoch);
      expect(entry.lastError, 'Network timeout');
    });

    test('recovers interrupted processing operations', () async {
      await repository.enqueue(createOperation());

      await repository.markProcessing('operation-1');

      await repository.recoverInterruptedOperations();

      final entry = await database.select(database.syncQueue).getSingle();

      expect(entry.status, 'pending');
    });
  });
}
