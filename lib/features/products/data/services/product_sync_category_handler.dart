import 'dart:convert';

import 'package:injectable/injectable.dart';

import '../../../../core/sync/domain/entities/sync_failure.dart';
import '../../../../core/sync/domain/entities/sync_operation.dart';
import '../../../../core/sync/domain/handlers/sync_category_handler.dart';
import '../../../../core/sync/domain/repositories/sync_metadata_repository.dart';
import '../datasources/local/product_local_datasource.dart';
import '../datasources/remote/product_remote_data_source.dart';
import '../models/product_model.dart';

@lazySingleton
class ProductSyncCategoryHandler implements SyncCategoryHandler {
  ProductSyncCategoryHandler({
    required this._localDataSource,
    required this._remoteDataSource,
    required this._metadataRepository,
  });

  static const int _pageSize = 20;

  final ProductLocalDataSource _localDataSource;
  final ProductRemoteDataSource _remoteDataSource;
  final SyncMetadataRepository _metadataRepository;

  @override
  String get category => 'product';

  @override
  Future<void> pull() async {
    var offset =
        int.tryParse(await _metadataRepository.getCursor(category) ?? '0') ?? 0;

    while (true) {
      final products = await _execute(
        () => _remoteDataSource.getProducts(start: offset, limit: _pageSize),
      );

      await _execute(
        () => _localDataSource.transaction(() async {
          for (final product in products) {
            final existing = await _localDataSource.getProductById(product.id);

            if (existing == null) {
              await _localDataSource.insertProduct(product);
            } else {
              await _localDataSource.updateProduct(product);
            }
          }

          offset += products.length;

          if (products.length < _pageSize) {
            await _metadataRepository.updateCursor(
              category: category,
              cursor: null,
            );

            await _metadataRepository.markPullCompleted(
              category: category,
              completedAt: DateTime.now(),
            );
          } else {
            await _metadataRepository.updateCursor(
              category: category,
              cursor: offset.toString(),
            );
          }
        }),
      );

      if (products.length < _pageSize) {
        return;
      }
    }
  }

  @override
  Future<void> push(SyncOperation operation) async {
    await _execute(() async {
      switch (operation.operation) {
        case SyncOperationType.create:
          final product = _decodeProduct(operation);
          await _remoteDataSource.createProduct(product);
          break;

        case SyncOperationType.update:
          final product = _decodeProduct(operation);
          await _remoteDataSource.updateProduct(product);
          break;

        case SyncOperationType.delete:
          await _remoteDataSource.deleteProduct(operation.entityId);
          break;
      }
    });
  }

  ProductModel _decodeProduct(SyncOperation operation) {
    final payload = operation.payload;

    if (payload == null || payload.isEmpty) {
      throw const SyncFailure(
        message: 'Product operation has no payload.',
        type: SyncFailureType.permanent,
      );
    }

    try {
      final decoded = jsonDecode(payload);

      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Invalid product payload.');
      }

      return ProductModel.fromJson(decoded);
    } on FormatException catch (error) {
      throw SyncFailure(
        message: 'Invalid product payload: ${error.message}',
        type: SyncFailureType.permanent,
      );
    } on TypeError catch (error) {
      throw SyncFailure(
        message: 'Invalid product fields: $error',
        type: SyncFailureType.permanent,
      );
    }
  }

  Future<T> _execute<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on SyncFailure {
      rethrow;
    } on FormatException catch (error) {
      throw SyncFailure(
        message: error.message,
        type: SyncFailureType.permanent,
      );
    } catch (error) {
      throw SyncFailure(
        message: error.toString(),
        type: SyncFailureType.retryable,
      );
    }
  }
}
