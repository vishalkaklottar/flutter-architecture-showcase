import 'dart:async';

import 'package:flutter_architecture_showcase/core/sync/data/services/sync_coordinator_impl.dart';
import 'package:flutter_architecture_showcase/core/sync/domain/entities/sync_failure.dart';
import 'package:flutter_architecture_showcase/core/sync/domain/entities/sync_operation.dart';
import 'package:flutter_architecture_showcase/core/sync/domain/entities/sync_retry_policy.dart';
import 'package:flutter_architecture_showcase/core/sync/domain/handlers/sync_category_handler.dart';
import 'package:flutter_architecture_showcase/core/sync/domain/repositories/sync_queue_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late _FakeSyncQueueRepository queueRepository;
  late _FakeSyncCategoryHandler handler;
  late SyncCoordinatorImpl coordinator;

  setUp(() {
    queueRepository = _FakeSyncQueueRepository();
    handler = _FakeSyncCategoryHandler();

    coordinator = SyncCoordinatorImpl(
      queueRepository: queueRepository,
      handlers: [handler],
      retryPolicy: SyncRetryPolicy(
        maxAttempts: 5,
        initialDelay: const Duration(seconds: 1),
        maxDelay: const Duration(minutes: 1),
      ),
    );
  });

  group('SyncCoordinatorImpl', () {
    test('pulls remote changes before pushing local operations', () async {
      final events = <String>[];

      handler.onPull = () async {
        events.add('pull');
      };

      handler.onPush = (_) async {
        events.add('push');
      };

      queueRepository.operations.add(_operation('1'));

      await coordinator.synchronizeCategory('product');

      expect(events, ['pull', 'push']);
      expect(queueRepository.operations, isEmpty);
    });

    test('does not push operations when pull fails', () async {
      queueRepository.operations.add(_operation('1'));

      handler.onPull = () async {
        throw Exception('Pull failed');
      };

      await expectLater(
        coordinator.synchronizeCategory('product'),
        throwsA(isA<Exception>()),
      );

      expect(handler.pushCount, 0);
      expect(
        queueRepository.operations.single.status,
        SyncOperationStatus.pending,
      );
    });

    test('marks an operation completed after successful push', () async {
      queueRepository.operations.add(_operation('1'));

      await coordinator.synchronizeCategory('product');

      expect(handler.pushCount, 1);
      expect(queueRepository.operations, isEmpty);
    });

    test('schedules retry for retryable failures', () async {
      queueRepository.operations.add(_operation('1'));

      handler.onPush = (_) async {
        throw const SyncFailure(
          message: 'Server unavailable',
          type: SyncFailureType.retryable,
        );
      };

      await coordinator.synchronizeCategory('product');

      final operation = queueRepository.operations.single;

      expect(operation.status, SyncOperationStatus.pending);
      expect(operation.attemptCount, 1);
      expect(operation.lastError, 'Server unavailable');
      expect(operation.nextRetryAt, isNotNull);
      expect(operation.nextRetryAt!.isAfter(DateTime.now()), isTrue);
    });

    test('marks an operation failed for permanent failures', () async {
      queueRepository.operations.add(_operation('1'));

      handler.onPush = (_) async {
        throw const SyncFailure(
          message: 'Invalid product data',
          type: SyncFailureType.permanent,
        );
      };

      await coordinator.synchronizeCategory('product');

      final operation = queueRepository.operations.single;

      expect(operation.status, SyncOperationStatus.failed);
      expect(operation.attemptCount, 0);
      expect(operation.lastError, 'Invalid product data');
    });

    test('marks an operation failed after maximum retry attempts', () async {
      queueRepository.operations.add(_operation('1', attemptCount: 4));

      handler.onPush = (_) async {
        throw const SyncFailure(
          message: 'Server unavailable',
          type: SyncFailureType.retryable,
        );
      };

      await coordinator.synchronizeCategory('product');

      final operation = queueRepository.operations.single;

      expect(operation.status, SyncOperationStatus.failed);
      expect(operation.attemptCount, 4);
      expect(operation.lastError, 'Server unavailable');
    });

    test('processes operations sequentially within a category', () async {
      queueRepository.operations
        ..add(_operation('1'))
        ..add(_operation('2'))
        ..add(_operation('3'));

      var activePushes = 0;
      var maxConcurrentPushes = 0;

      handler.onPush = (_) async {
        activePushes++;

        if (activePushes > maxConcurrentPushes) {
          maxConcurrentPushes = activePushes;
        }

        await Future<void>.delayed(const Duration(milliseconds: 10));

        activePushes--;
      };

      await coordinator.synchronizeCategory('product');

      expect(handler.pushCount, 3);
      expect(maxConcurrentPushes, 1);
      expect(queueRepository.operations, isEmpty);
    });

    test('coalesces concurrent synchronization requests', () async {
      final pullStarted = Completer<void>();
      final pullCompleter = Completer<void>();

      handler.onPull = () async {
        if (!pullStarted.isCompleted) {
          pullStarted.complete();
        }

        await pullCompleter.future;
      };

      final firstSync = coordinator.synchronizeCategory('product');
      final secondSync = coordinator.synchronizeCategory('product');

      // Wait until the first synchronization actually reaches pull().
      await pullStarted.future;

      expect(handler.pullCount, 1);

      // Allow the first synchronization to finish.
      pullCompleter.complete();

      await Future.wait([firstSync, secondSync]);

      expect(handler.pullCount, 1);
    });

    test('recovers interrupted operations before synchronization', () async {
      queueRepository.operations.add(
        _operation('1', status: SyncOperationStatus.processing),
      );

      await coordinator.synchronizeCategory('product');

      expect(queueRepository.recoveryCount, 1);
      expect(handler.pushCount, 1);
      expect(queueRepository.operations, isEmpty);
    });

    test('rejects an unknown category', () {
      expect(
        () => coordinator.synchronizeCategory('unknown'),
        throwsArgumentError,
      );
    });
  });
}

SyncOperation _operation(
  String id, {
  SyncOperationStatus status = SyncOperationStatus.pending,
  int attemptCount = 0,
}) {
  final now = DateTime.now();

  return SyncOperation(
    id: id,
    entityType: 'product',
    entityId: 'product_$id',
    operation: SyncOperationType.create,
    status: status,
    attemptCount: attemptCount,
    payload: '{"id":"product_$id"}',
    createdAt: now,
    updatedAt: now,
  );
}

class _FakeSyncCategoryHandler implements SyncCategoryHandler {
  @override
  String get category => 'product';

  int pullCount = 0;
  int pushCount = 0;

  Future<void> Function()? onPull;
  Future<void> Function(SyncOperation operation)? onPush;

  @override
  Future<void> pull() async {
    pullCount++;
    await onPull?.call();
  }

  @override
  Future<void> push(SyncOperation operation) async {
    pushCount++;
    await onPush?.call(operation);
  }
}

class _FakeSyncQueueRepository implements SyncQueueRepository {
  final List<SyncOperation> operations = [];

  int recoveryCount = 0;

  @override
  Future<void> enqueue(SyncOperation operation) async {
    operations.add(operation);
  }

  @override
  Future<List<SyncOperation>> getPendingOperations({
    required String entityType,
    required int limit,
  }) async {
    final now = DateTime.now();

    return operations
        .where(
          (operation) =>
              operation.entityType == entityType &&
              operation.status == SyncOperationStatus.pending &&
              (operation.nextRetryAt == null ||
                  !operation.nextRetryAt!.isAfter(now)),
        )
        .take(limit)
        .toList();
  }

  @override
  Future<bool> markProcessing(String operationId) async {
    final index = operations.indexWhere(
      (operation) => operation.id == operationId,
    );

    if (index == -1 ||
        operations[index].status != SyncOperationStatus.pending) {
      return false;
    }

    operations[index] = _copyOperation(
      operations[index],
      status: SyncOperationStatus.processing,
    );

    return true;
  }

  @override
  Future<void> markCompleted(String operationId) async {
    operations.removeWhere(
      (operation) =>
          operation.id == operationId &&
          operation.status == SyncOperationStatus.processing,
    );
  }

  @override
  Future<void> markFailed(String operationId, {required String error}) async {
    final index = operations.indexWhere(
      (operation) => operation.id == operationId,
    );

    if (index == -1) return;

    operations[index] = _copyOperation(
      operations[index],
      status: SyncOperationStatus.failed,
      lastError: error,
    );
  }

  @override
  Future<void> scheduleRetry(
    String operationId, {
    required DateTime nextRetryAt,
    required String error,
  }) async {
    final index = operations.indexWhere(
      (operation) => operation.id == operationId,
    );

    if (index == -1) return;

    final operation = operations[index];

    operations[index] = _copyOperation(
      operation,
      status: SyncOperationStatus.pending,
      attemptCount: operation.attemptCount + 1,
      nextRetryAt: nextRetryAt,
      lastError: error,
    );
  }

  @override
  Future<void> recoverInterruptedOperations() async {
    recoveryCount++;

    for (var index = 0; index < operations.length; index++) {
      if (operations[index].status == SyncOperationStatus.processing) {
        operations[index] = _copyOperation(
          operations[index],
          status: SyncOperationStatus.pending,
        );
      }
    }
  }
}

SyncOperation _copyOperation(
  SyncOperation operation, {
  SyncOperationStatus? status,
  int? attemptCount,
  DateTime? nextRetryAt,
  String? lastError,
}) {
  return SyncOperation(
    id: operation.id,
    entityType: operation.entityType,
    entityId: operation.entityId,
    operation: operation.operation,
    status: status ?? operation.status,
    attemptCount: attemptCount ?? operation.attemptCount,
    payload: operation.payload,
    nextRetryAt: nextRetryAt ?? operation.nextRetryAt,
    lastError: lastError ?? operation.lastError,
    createdAt: operation.createdAt,
    updatedAt: DateTime.now(),
  );
}
