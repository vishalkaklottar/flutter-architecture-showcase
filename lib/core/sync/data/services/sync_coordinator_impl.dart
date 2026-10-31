import 'dart:async';

import 'package:injectable/injectable.dart';

import '../../domain/entities/sync_failure.dart';
import '../../domain/entities/sync_operation.dart';
import '../../domain/entities/sync_retry_policy.dart';
import '../../domain/handlers/sync_category_handler.dart';
import '../../domain/repositories/sync_coordinator.dart';
import '../../domain/repositories/sync_queue_repository.dart';

@LazySingleton(as: SyncCoordinator)
class SyncCoordinatorImpl implements SyncCoordinator {
  SyncCoordinatorImpl({
    required this._queueRepository,
    required List<SyncCategoryHandler> handlers,
    required this._retryPolicy,
  }) {
    for (final handler in handlers) {
      if (_handlers.containsKey(handler.category)) {
        throw ArgumentError(
          'Duplicate sync handler for category: ${handler.category}',
        );
      }

      _handlers[handler.category] = handler;
    }
  }

  static const int _batchSize = 50;

  final SyncQueueRepository _queueRepository;
  final SyncRetryPolicy _retryPolicy;

  final Map<String, SyncCategoryHandler> _handlers = {};

  Future<void>? _activeSync;
  final Map<String, Future<void>> _activeCategorySyncs = {};

  bool _interruptedOperationsRecovered = false;

  @override
  Future<void> synchronize() {
    final activeSync = _activeSync;

    if (activeSync != null) {
      return activeSync;
    }

    final syncFuture = _synchronizeAll();

    _activeSync = syncFuture;

    return syncFuture.whenComplete(() {
      if (identical(_activeSync, syncFuture)) {
        _activeSync = null;
      }
    });
  }

  Future<void> _synchronizeAll() async {
    await _recoverInterruptedOperations();

    final categories = _handlers.keys.toList(growable: false);

    await Future.wait(categories.map(synchronizeCategory));
  }

  @override
  Future<void> synchronizeCategory(String category) {
    final handler = _handlers[category];

    if (handler == null) {
      throw ArgumentError.value(
        category,
        'category',
        'No sync handler registered for this category.',
      );
    }

    final activeSync = _activeCategorySyncs[category];

    if (activeSync != null) {
      return activeSync;
    }

    final syncFuture = _synchronizeHandler(handler);

    _activeCategorySyncs[category] = syncFuture;

    return syncFuture.whenComplete(() {
      if (identical(_activeCategorySyncs[category], syncFuture)) {
        _activeCategorySyncs.remove(category);
      }
    });
  }

  Future<void> _synchronizeHandler(SyncCategoryHandler handler) async {
    await _recoverInterruptedOperations();

    // Push only after a successful pull.
    await handler.pull();

    await _pushPendingOperations(handler);
  }

  Future<void> _pushPendingOperations(SyncCategoryHandler handler) async {
    while (true) {
      final operations = await _queueRepository.getPendingOperations(
        entityType: handler.category,
        limit: _batchSize,
      );

      if (operations.isEmpty) {
        return;
      }

      for (final operation in operations) {
        await _processOperation(handler: handler, operation: operation);
      }

      // A full batch means more operations may be available.
      if (operations.length < _batchSize) {
        return;
      }
    }
  }

  Future<void> _processOperation({
    required SyncCategoryHandler handler,
    required SyncOperation operation,
  }) async {
    final claimed = await _queueRepository.markProcessing(operation.id);

    if (!claimed) {
      return;
    }

    try {
      await handler.push(operation);

      await _queueRepository.markCompleted(operation.id);
    } on SyncFailure catch (error) {
      await _handleFailure(operation: operation, error: error);
    } catch (error) {
      await _handleFailure(
        operation: operation,
        error: SyncFailure(
          message: error.toString(),
          type: SyncFailureType.retryable,
        ),
      );
    }
  }

  Future<void> _handleFailure({
    required SyncOperation operation,
    required SyncFailure error,
  }) async {
    final nextAttempt = operation.attemptCount + 1;

    if (!error.isRetryable || nextAttempt >= _retryPolicy.maxAttempts) {
      await _queueRepository.markFailed(operation.id, error: error.message);

      return;
    }

    final nextRetryAt = DateTime.now().add(_retryPolicy.getDelay(nextAttempt));

    await _queueRepository.scheduleRetry(
      operation.id,
      nextRetryAt: nextRetryAt,
      error: error.message,
    );
  }

  Future<void>? _recoveryFuture;

  Future<void> _recoverInterruptedOperations() {
    if (_interruptedOperationsRecovered) {
      return Future<void>.value();
    }

    return _recoveryFuture ??= _performRecovery();
  }

  Future<void> _performRecovery() async {
    try {
      await _queueRepository.recoverInterruptedOperations();
      _interruptedOperationsRecovered = true;
    } catch (_) {
      _recoveryFuture = null;
      rethrow;
    }
  }
}
