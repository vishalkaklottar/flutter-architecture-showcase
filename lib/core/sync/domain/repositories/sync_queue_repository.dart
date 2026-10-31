import '../entities/sync_operation.dart';

abstract interface class SyncQueueRepository {
  /// Adds a new operation to the persistent sync queue.
  Future<void> enqueue(SyncOperation operation);

  /// Returns pending operations for a specific entity category.
  Future<List<SyncOperation>> getPendingOperations({
    required String entityType,
    required int limit,
  });

  /// Marks an operation as currently being processed.
  Future<bool> markProcessing(String operationId);

  /// Marks an operation as completed and removes it from the queue.
  Future<void> markCompleted(String operationId);

  /// Marks an operation as permanently failed.
  Future<void> markFailed(String operationId, {required String error});

  /// Schedules an operation for another attempt.
  Future<void> scheduleRetry(
    String operationId, {
    required DateTime nextRetryAt,
    required String error,
  });

  /// Resets interrupted processing operations after application recovery.
  Future<void> recoverInterruptedOperations();
}
