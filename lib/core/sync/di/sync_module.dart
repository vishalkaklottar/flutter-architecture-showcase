import 'package:flutter_architecture_showcase/core/sync/domain/handlers/sync_category_handler.dart';
import 'package:injectable/injectable.dart';

import '../domain/entities/sync_retry_policy.dart';

@module
abstract class SyncModule {
  @lazySingleton
  SyncRetryPolicy get syncRetryPolicy => SyncRetryPolicy();

  @lazySingleton
  List<SyncCategoryHandler> syncCategoryHandlers() {
    return <SyncCategoryHandler>[];
  }
}
