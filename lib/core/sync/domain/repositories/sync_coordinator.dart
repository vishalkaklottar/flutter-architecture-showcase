abstract interface class SyncCoordinator {
  Future<void> synchronize();

  Future<void> synchronizeCategory(String category);
}
