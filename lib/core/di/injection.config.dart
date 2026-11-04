// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes

import 'package:dio/dio.dart' as _i361;
import 'package:flutter_architecture_showcase/core/database/app_drift_database.dart'
    as _i666;
import 'package:flutter_architecture_showcase/core/database/database_module.dart'
    as _i640;
import 'package:flutter_architecture_showcase/core/network/network_module.dart'
    as _i728;
import 'package:flutter_architecture_showcase/core/sync/data/repositories/drift_sync_metadata_repository.dart'
    as _i143;
import 'package:flutter_architecture_showcase/core/sync/data/repositories/drift_sync_queue_repository.dart'
    as _i844;
import 'package:flutter_architecture_showcase/core/sync/data/services/sync_coordinator_impl.dart'
    as _i808;
import 'package:flutter_architecture_showcase/core/sync/di/sync_module.dart'
    as _i492;
import 'package:flutter_architecture_showcase/core/sync/domain/entities/sync_retry_policy.dart'
    as _i39;
import 'package:flutter_architecture_showcase/core/sync/domain/handlers/sync_category_handler.dart'
    as _i839;
import 'package:flutter_architecture_showcase/core/sync/domain/repositories/sync_coordinator.dart'
    as _i228;
import 'package:flutter_architecture_showcase/core/sync/domain/repositories/sync_metadata_repository.dart'
    as _i676;
import 'package:flutter_architecture_showcase/core/sync/domain/repositories/sync_queue_repository.dart'
    as _i210;
import 'package:flutter_architecture_showcase/features/products/application/commands/create_product_command.dart'
    as _i238;
import 'package:flutter_architecture_showcase/features/products/application/commands/delete_product_command.dart'
    as _i380;
import 'package:flutter_architecture_showcase/features/products/application/commands/update_product_command.dart'
    as _i225;
import 'package:flutter_architecture_showcase/features/products/application/queries/get_product_by_id_query.dart'
    as _i230;
import 'package:flutter_architecture_showcase/features/products/application/queries/get_products_query.dart'
    as _i384;
import 'package:flutter_architecture_showcase/features/products/application/queries/watch_products_query.dart'
    as _i900;
import 'package:flutter_architecture_showcase/features/products/data/datasources/local/drift_product_local_datasource.dart'
    as _i22;
import 'package:flutter_architecture_showcase/features/products/data/datasources/local/product_local_datasource.dart'
    as _i321;
import 'package:flutter_architecture_showcase/features/products/data/datasources/remote/mock_product_remote_data_source.dart'
    as _i860;
import 'package:flutter_architecture_showcase/features/products/data/datasources/remote/product_remote_data_source.dart'
    as _i157;
import 'package:flutter_architecture_showcase/features/products/data/repositories/product_repository_impl.dart'
    as _i427;
import 'package:flutter_architecture_showcase/features/products/data/services/product_sync_category_handler.dart'
    as _i1034;
import 'package:flutter_architecture_showcase/features/products/domain/repositories/product_repository.dart'
    as _i600;
import 'package:flutter_architecture_showcase/features/products/presentation/cubit/product_cubit.dart'
    as _i193;
import 'package:flutter_architecture_showcase/features/sync/presentation/cubit/sync_cubit.dart'
    as _i592;
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  _i174.GetIt init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    final databaseModule = _$DatabaseModule();
    final networkModule = _$NetworkModule();
    final syncModule = _$SyncModule();
    gh.lazySingleton<_i666.AppDriftDatabase>(() => databaseModule.database);
    gh.lazySingleton<_i361.Dio>(() => networkModule.dio);
    gh.lazySingleton<_i39.SyncRetryPolicy>(() => syncModule.syncRetryPolicy);
    gh.lazySingleton<_i157.ProductRemoteDataSource>(
      () => _i860.MockProductRemoteDataSource(),
    );
    gh.lazySingleton<_i210.SyncQueueRepository>(
      () => _i844.DriftSyncQueueRepository(gh<_i666.AppDriftDatabase>()),
    );
    gh.lazySingleton<_i321.ProductLocalDataSource>(
      () => _i22.DriftProductLocalDataSource(gh<_i666.AppDriftDatabase>()),
    );
    gh.lazySingleton<_i676.SyncMetadataRepository>(
      () => _i143.DriftSyncMetadataRepository(gh<_i666.AppDriftDatabase>()),
    );
    gh.lazySingleton<_i600.ProductRepository>(
      () => _i427.ProductRepositoryImpl(
        gh<_i666.AppDriftDatabase>(),
        gh<_i321.ProductLocalDataSource>(),
        gh<_i210.SyncQueueRepository>(),
      ),
    );
    gh.lazySingleton<_i1034.ProductSyncCategoryHandler>(
      () => _i1034.ProductSyncCategoryHandler(
        localDataSource: gh<_i321.ProductLocalDataSource>(),
        remoteDataSource: gh<_i157.ProductRemoteDataSource>(),
        metadataRepository: gh<_i676.SyncMetadataRepository>(),
      ),
    );
    gh.lazySingleton<List<_i839.SyncCategoryHandler>>(
      () => syncModule.syncCategoryHandlers(
        gh<_i1034.ProductSyncCategoryHandler>(),
      ),
    );
    gh.lazySingleton<_i238.CreateProductCommand>(
      () => _i238.CreateProductCommand(gh<_i600.ProductRepository>()),
    );
    gh.lazySingleton<_i380.DeleteProductCommand>(
      () => _i380.DeleteProductCommand(gh<_i600.ProductRepository>()),
    );
    gh.lazySingleton<_i225.UpdateProductCommand>(
      () => _i225.UpdateProductCommand(gh<_i600.ProductRepository>()),
    );
    gh.lazySingleton<_i230.GetProductByIdQuery>(
      () => _i230.GetProductByIdQuery(gh<_i600.ProductRepository>()),
    );
    gh.lazySingleton<_i384.GetProductsQuery>(
      () => _i384.GetProductsQuery(gh<_i600.ProductRepository>()),
    );
    gh.lazySingleton<_i900.WatchProductsQuery>(
      () => _i900.WatchProductsQuery(gh<_i600.ProductRepository>()),
    );
    gh.lazySingleton<_i228.SyncCoordinator>(
      () => _i808.SyncCoordinatorImpl(
        queueRepository: gh<_i210.SyncQueueRepository>(),
        handlers: gh<List<_i839.SyncCategoryHandler>>(),
        retryPolicy: gh<_i39.SyncRetryPolicy>(),
      ),
    );
    gh.factory<_i193.ProductCubit>(
      () => _i193.ProductCubit(
        createProduct: gh<_i238.CreateProductCommand>(),
        updateProduct: gh<_i225.UpdateProductCommand>(),
        deleteProduct: gh<_i380.DeleteProductCommand>(),
        watchProducts: gh<_i900.WatchProductsQuery>(),
      ),
    );
    gh.factory<_i592.SyncCubit>(
      () => _i592.SyncCubit(gh<_i228.SyncCoordinator>()),
    );
    return this;
  }
}

class _$DatabaseModule extends _i640.DatabaseModule {}

class _$NetworkModule extends _i728.NetworkModule {}

class _$SyncModule extends _i492.SyncModule {}
