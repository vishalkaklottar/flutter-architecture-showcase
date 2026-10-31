import 'package:drift/native.dart';
import 'package:flutter_architecture_showcase/core/sync/domain/entities/sync_operation.dart';
import 'package:flutter_architecture_showcase/core/sync/domain/repositories/sync_queue_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_architecture_showcase/core/database/app_drift_database.dart';
import 'package:flutter_architecture_showcase/core/sync/data/repositories/drift_sync_queue_repository.dart';
import 'package:flutter_architecture_showcase/features/products/data/datasources/local/drift_product_local_datasource.dart';
import 'package:flutter_architecture_showcase/features/products/data/mappers/product_mapper.dart';
import 'package:flutter_architecture_showcase/features/products/data/models/product_model.dart';
import 'package:flutter_architecture_showcase/features/products/data/repositories/product_repository_impl.dart';

void main() {
  late AppDriftDatabase database;
  late ProductRepositoryImpl repository;

  setUp(() {
    database = AppDriftDatabase.forTesting(
      NativeDatabase.memory(
        setup: (database) {
          database.execute('PRAGMA foreign_keys = ON');
        },
      ),
    );

    final localDataSource = DriftProductLocalDataSource(database);
    final syncQueueRepository = DriftSyncQueueRepository(database);

    repository = ProductRepositoryImpl(
      database,
      localDataSource,
      syncQueueRepository,
    );
  });

  tearDown(() async {
    await database.close();
  });

  ProductModel createProduct({
    String id = 'product-1',
    String name = 'Test Product',
    double price = 100,
  }) {
    final now = DateTime.now();

    return ProductModel(
      id: id,
      name: name,
      price: price,
      description: 'Test description',
      createdAt: now,
      updatedAt: now,
    );
  }

  group('createProduct', () {
    test('persists product and queues CREATE operation', () async {
      final product = createProduct();

      await repository.createProduct(product);

      final storedProduct = await repository.getProductById(product.id);
      final operations = await database.select(database.syncQueue).get();

      expect(storedProduct, isNotNull);
      expect(storedProduct!.id, product.id);
      expect(storedProduct.name, product.name);

      expect(operations, hasLength(1));
      expect(operations.single.entityType, 'product');
      expect(operations.single.entityId, product.id);
      expect(operations.single.operation, 'create');
      expect(operations.single.status, 'pending');
    });
  });

  group('updateProduct', () {
    test('updates local product and queues UPDATE operation', () async {
      final original = createProduct();

      await database
          .into(database.products)
          .insert(ProductMapper.toCompanion(original));

      final updated = createProduct(name: 'Updated Product', price: 250);

      await repository.updateProduct(updated);

      final storedProduct = await repository.getProductById(updated.id);
      final operations = await database.select(database.syncQueue).get();

      expect(storedProduct, isNotNull);
      expect(storedProduct!.name, 'Updated Product');
      expect(storedProduct.price, 250);

      expect(operations, hasLength(1));
      expect(operations.single.operation, 'update');
      expect(operations.single.entityId, updated.id);
    });

    test('throws when product does not exist', () async {
      final product = createProduct();

      expect(
        () => repository.updateProduct(product),
        throwsA(isA<StateError>()),
      );

      expect(await database.select(database.products).get(), isEmpty);
      expect(await database.select(database.syncQueue).get(), isEmpty);
    });
  });

  group('deleteProduct', () {
    test('deletes local product and queues DELETE operation', () async {
      final product = createProduct();

      await database
          .into(database.products)
          .insert(ProductMapper.toCompanion(product));

      await repository.deleteProduct(product.id);

      final storedProduct = await repository.getProductById(product.id);
      final operations = await database.select(database.syncQueue).get();

      expect(storedProduct, isNull);

      expect(operations, hasLength(1));
      expect(operations.single.operation, 'delete');
      expect(operations.single.entityId, product.id);
      expect(operations.single.payload, isNull);
    });

    test('does nothing when product does not exist', () async {
      await repository.deleteProduct('missing-product');

      expect(await database.select(database.products).get(), isEmpty);
      expect(await database.select(database.syncQueue).get(), isEmpty);
    });
  });

  group('transaction integrity', () {
    test('rolls back product insertion when queue insertion fails', () async {
      final failingRepository = ProductRepositoryImpl(
        database,
        DriftProductLocalDataSource(database),
        FailingSyncQueueRepository(),
      );

      final product = createProduct(id: 'rollback-product');

      await expectLater(
        failingRepository.createProduct(product),
        throwsA(isA<StateError>()),
      );

      final storedProduct = await failingRepository.getProductById(product.id);

      expect(storedProduct, isNull);

      final operations = await database.select(database.syncQueue).get();

      expect(operations, isEmpty);
    });

    test('create followed by update keeps one CREATE operation', () async {
      final product = createProduct();

      await repository.createProduct(product);

      await repository.updateProduct(
        createProduct(name: 'Updated Product', price: 200),
      );

      final operations = await database.select(database.syncQueue).get();
      final storedProduct = await repository.getProductById(product.id);

      expect(operations, hasLength(1));
      expect(operations.single.operation, 'create');
      expect(storedProduct!.name, 'Updated Product');
      expect(storedProduct.price, 200);
    });
    test('create followed by delete removes pending operation', () async {
      final product = createProduct();

      await repository.createProduct(product);
      await repository.deleteProduct(product.id);

      final operations = await database.select(database.syncQueue).get();
      final storedProduct = await repository.getProductById(product.id);

      expect(operations, isEmpty);
      expect(storedProduct, isNull);
    });

    test('update followed by delete keeps one DELETE operation', () async {
      final product = createProduct();

      await database
          .into(database.products)
          .insert(ProductMapper.toCompanion(product));

      await repository.updateProduct(createProduct(name: 'Updated Product'));

      await repository.deleteProduct(product.id);

      final operations = await database.select(database.syncQueue).get();
      final storedProduct = await repository.getProductById(product.id);

      expect(operations, hasLength(1));
      expect(operations.single.operation, 'delete');
      expect(operations.single.payload, isNull);
      expect(storedProduct, isNull);
    });
  });
}

class FailingSyncQueueRepository implements SyncQueueRepository {
  @override
  Future<void> enqueue(SyncOperation operation) async {
    throw StateError('Simulated queue insertion failure');
  }

  @override
  Future<List<SyncOperation>> getPendingOperations({
    required String entityType,
    required int limit,
  }) async {
    return [];
  }

  @override
  Future<bool> markProcessing(String operationId) async => false;

  @override
  Future<void> markCompleted(String operationId) async {}

  @override
  Future<void> scheduleRetry(
    String operationId, {
    required DateTime nextRetryAt,
    required String error,
  }) async {}

  @override
  Future<void> markFailed(String operationId, {required String error}) async {}

  @override
  Future<void> recoverInterruptedOperations() async {}
}
