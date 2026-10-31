import 'package:drift/drift.dart';

import '../../../database/app_drift_database.dart';
import '../../domain/entities/sync_operation.dart';

abstract final class SyncOperationMapper {
  static SyncOperation fromData(SyncQueueEntry data) {
    return SyncOperation(
      id: data.id,
      entityType: data.entityType,
      entityId: data.entityId,
      operation: SyncOperationType.values.byName(data.operation),
      status: SyncOperationStatus.values.byName(data.status),
      attemptCount: data.attemptCount,
      payload: data.payload,
      nextRetryAt: data.nextRetryAt == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(data.nextRetryAt!),
      lastError: data.lastError,
      createdAt: DateTime.fromMillisecondsSinceEpoch(data.createdAt),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(data.updatedAt),
    );
  }

  static SyncQueueCompanion toCompanion(SyncOperation operation) {
    return SyncQueueCompanion.insert(
      id: operation.id,
      entityType: operation.entityType,
      entityId: operation.entityId,
      operation: operation.operation.name,
      payload: Value(operation.payload),
      status: Value(operation.status.name),
      attemptCount: Value(operation.attemptCount),
      nextRetryAt: Value(operation.nextRetryAt?.millisecondsSinceEpoch),
      lastError: Value(operation.lastError),
      createdAt: operation.createdAt.millisecondsSinceEpoch,
      updatedAt: operation.updatedAt.millisecondsSinceEpoch,
    );
  }
}
