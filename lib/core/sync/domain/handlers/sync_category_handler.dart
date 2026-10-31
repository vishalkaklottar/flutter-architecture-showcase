import '../entities/sync_operation.dart';

abstract interface class SyncCategoryHandler {
  /// Unique category identifier, e.g. "product".
  String get category;

  /// Fetch remote changes and persist them locally.
  /// The cursor must only advance after the local transaction succeeds.
  Future<void> pull();

  /// Push one pending local operation to the remote API.
  Future<void> push(SyncOperation operation);
}
