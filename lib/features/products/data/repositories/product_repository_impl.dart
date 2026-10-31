import 'dart:convert';
import 'dart:math';

import 'package:injectable/injectable.dart';

import '../../../../core/database/app_drift_database.dart';
import '../../../../core/sync/domain/entities/sync_operation.dart';
import '../../../../core/sync/domain/repositories/sync_queue_repository.dart';
import '../../domain/entities/product.dart';
import '../../domain/repositories/product_repository.dart';
import '../datasources/local/product_local_datasource.dart';
import '../models/product_model.dart';

@LazySingleton(as: ProductRepository)
class ProductRepositoryImpl implements ProductRepository {
  ProductRepositoryImpl(
    this._database,
    this._localDataSource,
    this._syncQueueRepository,
  );

  final AppDriftDatabase _database;
  final ProductLocalDataSource _localDataSource;
  final SyncQueueRepository _syncQueueRepository;

  static const String _entityType = 'product';

  String _generateOperationId() {
    final random = Random.secure();

    final timestamp = DateTime.now().microsecondsSinceEpoch;
    final randomPart = List.generate(
      16,
      (_) => random.nextInt(16).toRadixString(16),
    ).join();

    return 'product_$timestamp$randomPart';
  }

  @override
  Future<List<Product>> getProducts() {
    return _localDataSource.getProducts();
  }

  @override
  Stream<List<Product>> watchProducts() {
    return _localDataSource.watchProducts();
  }

  @override
  Future<Product?> getProductById(String id) {
    return _localDataSource.getProductById(id);
  }

  @override
  Future<void> createProduct(Product product) async {
    final model = _toModel(product);

    await _database.transaction(() async {
      await _localDataSource.insertProduct(model);

      await _syncQueueRepository.enqueue(
        _createOperation(product: model, operation: SyncOperationType.create),
      );
    });
  }

  @override
  Future<void> updateProduct(Product product) async {
    final model = _toModel(product);

    await _database.transaction(() async {
      final existing = await _localDataSource.getProductById(model.id);

      if (existing == null) {
        throw StateError('Product ${model.id} does not exist.');
      }

      await _localDataSource.updateProduct(model);

      await _syncQueueRepository.enqueue(
        _createOperation(product: model, operation: SyncOperationType.update),
      );
    });
  }

  @override
  Future<void> deleteProduct(String id) async {
    await _database.transaction(() async {
      final existing = await _localDataSource.getProductById(id);

      if (existing == null) {
        return;
      }

      await _localDataSource.deleteProduct(id);

      await _syncQueueRepository.enqueue(
        SyncOperation(
          id: _generateOperationId(),
          entityType: _entityType,
          entityId: id,
          operation: SyncOperationType.delete,
          status: SyncOperationStatus.pending,
          attemptCount: 0,
          payload: null,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
    });
  }

  ProductModel _toModel(Product product) {
    return ProductModel(
      id: product.id,
      name: product.name,
      price: product.price,
      description: product.description,
      createdAt: product.createdAt,
      updatedAt: product.updatedAt,
    );
  }

  SyncOperation _createOperation({
    required ProductModel product,
    required SyncOperationType operation,
  }) {
    final now = DateTime.now();

    return SyncOperation(
      id: _generateOperationId(),
      entityType: _entityType,
      entityId: product.id,
      operation: operation,
      status: SyncOperationStatus.pending,
      attemptCount: 0,
      payload: jsonEncode(product.toJson()),
      createdAt: now,
      updatedAt: now,
    );
  }
}
