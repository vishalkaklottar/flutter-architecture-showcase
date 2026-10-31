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
import 'package:flutter_architecture_showcase/core/sync/data/repositories/drift_sync_queue_repository.dart'
    as _i844;
import 'package:flutter_architecture_showcase/core/sync/domain/repositories/sync_queue_repository.dart'
    as _i210;
import 'package:flutter_architecture_showcase/features/products/data/datasources/local/drift_product_local_datasource.dart'
    as _i22;
import 'package:flutter_architecture_showcase/features/products/data/datasources/local/product_local_datasource.dart'
    as _i321;
import 'package:flutter_architecture_showcase/features/products/data/repositories/product_repository_impl.dart'
    as _i427;
import 'package:flutter_architecture_showcase/features/products/domain/repositories/product_repository.dart'
    as _i600;
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
    gh.lazySingleton<_i666.AppDriftDatabase>(() => databaseModule.database);
    gh.lazySingleton<_i361.Dio>(() => networkModule.dio);
    gh.lazySingleton<_i210.SyncQueueRepository>(
      () => _i844.DriftSyncQueueRepository(gh<_i666.AppDriftDatabase>()),
    );
    gh.lazySingleton<_i321.ProductLocalDataSource>(
      () => _i22.DriftProductLocalDataSource(gh<_i666.AppDriftDatabase>()),
    );
    gh.lazySingleton<_i600.ProductRepository>(
      () => _i427.ProductRepositoryImpl(
        gh<_i666.AppDriftDatabase>(),
        gh<_i321.ProductLocalDataSource>(),
        gh<_i210.SyncQueueRepository>(),
      ),
    );
    return this;
  }
}

class _$DatabaseModule extends _i640.DatabaseModule {}

class _$NetworkModule extends _i728.NetworkModule {}
