abstract interface class SyncMetadataRepository {
  Future<String?> getCursor(String category);

  Future<void> updateCursor({
    required String category,
    required String? cursor,
  });

  Future<void> markPullCompleted({
    required String category,
    required DateTime completedAt,
  });

  Future<void> markSyncCompleted({
    required String category,
    required DateTime completedAt,
  });
}
