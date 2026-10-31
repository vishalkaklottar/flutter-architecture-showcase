enum SyncOperationType { create, update, delete }

enum SyncOperationStatus { pending, processing, completed, failed }

class SyncOperation {
  const SyncOperation({
    required this.id,
    required this.entityType,
    required this.entityId,
    required this.operation,
    required this.status,
    required this.attemptCount,
    required this.createdAt,
    required this.updatedAt,
    this.payload,
    this.nextRetryAt,
    this.lastError,
  });

  final String id;
  final String entityType;
  final String entityId;
  final SyncOperationType operation;
  final SyncOperationStatus status;
  final int attemptCount;
  final String? payload;
  final DateTime? nextRetryAt;
  final String? lastError;
  final DateTime createdAt;
  final DateTime updatedAt;

  SyncOperation copyWith({
    String? id,
    String? entityType,
    String? entityId,
    SyncOperationType? operation,
    SyncOperationStatus? status,
    int? attemptCount,
    String? payload,
    DateTime? nextRetryAt,
    String? lastError,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SyncOperation(
      id: id ?? this.id,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      operation: operation ?? this.operation,
      status: status ?? this.status,
      attemptCount: attemptCount ?? this.attemptCount,
      payload: payload ?? this.payload,
      nextRetryAt: nextRetryAt ?? this.nextRetryAt,
      lastError: lastError ?? this.lastError,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
