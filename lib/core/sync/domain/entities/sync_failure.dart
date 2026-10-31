enum SyncFailureType { retryable, permanent }

class SyncFailure implements Exception {
  const SyncFailure({required this.message, required this.type});

  final String message;
  final SyncFailureType type;

  bool get isRetryable => type == SyncFailureType.retryable;

  @override
  String toString() => 'SyncFailure($type): $message';
}
