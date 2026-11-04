enum SyncStatus { initial, running, success, failure }

class SyncState {
  const SyncState({
    this.status = SyncStatus.initial,
    this.errorMessage,
    this.lastSyncedAt,
  });

  final SyncStatus status;
  final String? errorMessage;
  final DateTime? lastSyncedAt;

  bool get isRunning => status == SyncStatus.running;

  SyncState copyWith({
    SyncStatus? status,
    String? errorMessage,
    DateTime? lastSyncedAt,
    bool clearError = false,
  }) {
    return SyncState(
      status: status ?? this.status,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
    );
  }
}
