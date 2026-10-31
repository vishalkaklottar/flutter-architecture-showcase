import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';

import '../../../database/app_drift_database.dart';
import '../mappers/sync_operation_mapper.dart';
import '../../domain/entities/sync_operation.dart';
import '../../domain/repositories/sync_queue_repository.dart';

@LazySingleton(as: SyncQueueRepository)
final class DriftSyncQueueRepository implements SyncQueueRepository {
  DriftSyncQueueRepository(this._database);

  final AppDriftDatabase _database;

  @override
  Future<void> enqueue(SyncOperation operation) async {
    if (operation.status != SyncOperationStatus.pending) {
      throw ArgumentError('New operations must have pending status.');
    }

    await _database.transaction(() async {
      final pendingOperation =
          await (_database.select(_database.syncQueue)..where(
                (row) =>
                    row.entityType.equals(operation.entityType) &
                    row.entityId.equals(operation.entityId) &
                    row.status.equals(SyncOperationStatus.pending.name),
              ))
              .getSingleOrNull();

      if (pendingOperation == null) {
        await _database
            .into(_database.syncQueue)
            .insert(SyncOperationMapper.toCompanion(operation));
        return;
      }

      final existingType = SyncOperationType.values.byName(
        pendingOperation.operation,
      );

      final incomingType = operation.operation;

      if (existingType == SyncOperationType.create &&
          incomingType == SyncOperationType.delete) {
        await (_database.delete(
          _database.syncQueue,
        )..where((row) => row.id.equals(pendingOperation.id))).go();

        return;
      }

      final mergedType = switch (existingType) {
        SyncOperationType.create => switch (incomingType) {
          SyncOperationType.create ||
          SyncOperationType.update => SyncOperationType.create,
          SyncOperationType.delete => throw StateError('Unreachable state'),
        },
        SyncOperationType.update => switch (incomingType) {
          SyncOperationType.update => SyncOperationType.update,
          SyncOperationType.delete => SyncOperationType.delete,
          SyncOperationType.create => throw StateError(
            'Cannot create an entity with an existing pending update.',
          ),
        },
        SyncOperationType.delete => switch (incomingType) {
          SyncOperationType.create => SyncOperationType.create,
          SyncOperationType.delete => SyncOperationType.delete,
          SyncOperationType.update => throw StateError(
            'Cannot update an entity with a pending deletion.',
          ),
        },
      };

      await (_database.update(
        _database.syncQueue,
      )..where((row) => row.id.equals(pendingOperation.id))).write(
        SyncQueueCompanion(
          operation: Value(mergedType.name),
          payload: Value(
            mergedType == SyncOperationType.delete ? null : operation.payload,
          ),
          attemptCount: const Value(0),
          nextRetryAt: const Value(null),
          lastError: const Value(null),
          updatedAt: Value(operation.updatedAt.millisecondsSinceEpoch),
        ),
      );
    });
  }

  @override
  Future<List<SyncOperation>> getPendingOperations({
    required String entityType,
    required int limit,
  }) async {
    if (limit <= 0) return [];

    final now = DateTime.now().millisecondsSinceEpoch;

    final query = _database.select(_database.syncQueue)
      ..where(
        (row) =>
            row.entityType.equals(entityType) &
            row.status.equals(SyncOperationStatus.pending.name) &
            (row.nextRetryAt.isNull() |
                row.nextRetryAt.isSmallerOrEqualValue(now)),
      )
      ..orderBy([(row) => OrderingTerm.asc(row.createdAt)])
      ..limit(limit);

    final entries = await query.get();

    return entries.map(SyncOperationMapper.fromData).toList();
  }

  @override
  Future<bool> markProcessing(String operationId) async {
    final updatedRows =
        await (_database.update(_database.syncQueue)..where(
              (row) =>
                  row.id.equals(operationId) &
                  row.status.equals(SyncOperationStatus.pending.name),
            ))
            .write(
              SyncQueueCompanion(
                status: Value(SyncOperationStatus.processing.name),
                updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
              ),
            );

    return updatedRows == 1;
  }

  @override
  Future<void> markCompleted(String operationId) async {
    await (_database.delete(_database.syncQueue)..where(
          (row) =>
              row.id.equals(operationId) &
              row.status.equals(SyncOperationStatus.processing.name),
        ))
        .go();
  }

  @override
  Future<void> markFailed(String operationId, {required String error}) async {
    await (_database.update(_database.syncQueue)..where(
          (row) =>
              row.id.equals(operationId) &
              row.status.equals(SyncOperationStatus.processing.name),
        ))
        .write(
          SyncQueueCompanion(
            status: Value(SyncOperationStatus.failed.name),
            lastError: Value(error),
            updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
          ),
        );
  }

  @override
  Future<void> scheduleRetry(
    String operationId, {
    required DateTime nextRetryAt,
    required String error,
  }) async {
    await _database.transaction(() async {
      final entry =
          await (_database.select(_database.syncQueue)..where(
                (row) =>
                    row.id.equals(operationId) &
                    row.status.equals(SyncOperationStatus.processing.name),
              ))
              .getSingleOrNull();

      if (entry == null) return;

      await (_database.update(
        _database.syncQueue,
      )..where((row) => row.id.equals(operationId))).write(
        SyncQueueCompanion(
          status: Value(SyncOperationStatus.pending.name),
          attemptCount: Value(entry.attemptCount + 1),
          nextRetryAt: Value(nextRetryAt.millisecondsSinceEpoch),
          lastError: Value(error),
          updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
        ),
      );
    });
  }

  @override
  Future<void> recoverInterruptedOperations() async {
    await (_database.update(_database.syncQueue)..where(
          (row) => row.status.equals(SyncOperationStatus.processing.name),
        ))
        .write(
          SyncQueueCompanion(
            status: Value(SyncOperationStatus.pending.name),
            updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
          ),
        );
  }
}
