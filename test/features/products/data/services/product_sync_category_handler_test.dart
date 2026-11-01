import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_architecture_showcase/core/sync/domain/entities/sync_failure.dart';
import 'package:flutter_architecture_showcase/core/sync/domain/entities/sync_operation.dart';
import 'package:flutter_architecture_showcase/core/sync/domain/repositories/sync_metadata_repository.dart';
import 'package:flutter_architecture_showcase/features/products/data/datasources/local/product_local_datasource.dart';
import 'package:flutter_architecture_showcase/features/products/data/datasources/remote/product_remote_data_source.dart';
import 'package:flutter_architecture_showcase/features/products/data/models/product_model.dart';
import 'package:flutter_architecture_showcase/features/products/data/services/product_sync_category_handler.dart';

void main() {
  late _FakeProductLocalDataSource localDataSource;
  late _FakeProductRemoteDataSource remoteDataSource;
  late _FakeSyncMetadataRepository metadataRepository;
  late ProductSyncCategoryHandler handler;

  setUp(() {
    localDataSource = _FakeProductLocalDataSource();
    remoteDataSource = _FakeProductRemoteDataSource();
    metadataRepository = _FakeSyncMetadataRepository();

    handler = ProductSyncCategoryHandler(
      localDataSource: localDataSource,
      remoteDataSource: remoteDataSource,
      metadataRepository: metadataRepository,
    );
  });

  group('ProductSyncCategoryHandler', () {
    group('category', () {
      test('returns product', () {
        expect(handler.category, 'product');
      });
    });

    group('pull', () {
      test('inserts remote products that do not exist locally', () async {
        remoteDataSource.products = [_product(id: '1'), _product(id: '2')];

        await handler.pull();

        expect(localDataSource.products, hasLength(2));
        expect(localDataSource.products.containsKey('1'), isTrue);
        expect(localDataSource.products.containsKey('2'), isTrue);
        expect(metadataRepository.cursor, isNull);
        expect(metadataRepository.pullCompletedAt, isNotNull);
      });

      test('updates products that already exist locally', () async {
        localDataSource.products['1'] = _product(id: '1', name: 'Old name');

        remoteDataSource.products = [_product(id: '1', name: 'Updated name')];

        await handler.pull();

        expect(localDataSource.products['1']?.name, 'Updated name');
      });

      test('paginates through all remote products', () async {
        remoteDataSource.products = List.generate(
          21,
          (index) => _product(id: 'product_$index'),
        );

        await handler.pull();

        expect(localDataSource.products, hasLength(21));
        expect(remoteDataSource.requestedOffsets, [0, 20]);
        expect(metadataRepository.cursor, isNull);
        expect(metadataRepository.pullCompletedAt, isNotNull);
      });

      test('resumes pull from saved cursor', () async {
        metadataRepository.cursor = '20';

        remoteDataSource.products = List.generate(
          21,
          (index) => _product(id: 'product_$index'),
        );

        await handler.pull();

        expect(remoteDataSource.requestedOffsets, [20]);
        expect(localDataSource.products.containsKey('product_20'), isTrue);
        expect(metadataRepository.cursor, isNull);
      });

      test('saves cursor after a full page', () async {
        remoteDataSource.products = List.generate(
          20,
          (index) => _product(id: 'product_$index'),
        );

        await handler.pull();

        expect(metadataRepository.cursor, isNull);
        expect(remoteDataSource.requestedOffsets, [0, 20]);
      });

      test('does not advance cursor when remote pull fails', () async {
        metadataRepository.cursor = '20';

        remoteDataSource.onGetProducts = (_, _) async {
          throw Exception('Network unavailable');
        };

        await expectLater(handler.pull(), throwsA(isA<SyncFailure>()));

        expect(metadataRepository.cursor, '20');
        expect(metadataRepository.pullCompletedAt, isNull);
      });

      test(
        'does not mark pull completed when local persistence fails',
        () async {
          remoteDataSource.products = [_product(id: '1')];

          localDataSource.onInsertProduct = (_) async {
            throw Exception('Database failure');
          };

          await expectLater(handler.pull(), throwsA(isA<SyncFailure>()));

          expect(metadataRepository.pullCompletedAt, isNull);
        },
      );
    });

    group('push', () {
      test('pushes CREATE operation', () async {
        final product = _product(id: '1');

        await handler.push(
          _operation(
            id: 'operation_1',
            operation: SyncOperationType.create,
            product: product,
          ),
        );

        expect(remoteDataSource.createdProducts, hasLength(1));
        expect(remoteDataSource.createdProducts.single.id, '1');
      });

      test('pushes UPDATE operation', () async {
        final product = _product(id: '1', name: 'Updated product');

        await handler.push(
          _operation(
            id: 'operation_2',
            operation: SyncOperationType.update,
            product: product,
          ),
        );

        expect(remoteDataSource.updatedProducts, hasLength(1));
        expect(remoteDataSource.updatedProducts.single.name, 'Updated product');
      });

      test('pushes DELETE operation', () async {
        await handler.push(
          _operation(id: 'operation_3', operation: SyncOperationType.delete),
        );

        expect(remoteDataSource.deletedIds, ['1']);
      });

      test('classifies invalid JSON payload as permanent failure', () async {
        await expectLater(
          handler.push(
            _operation(
              id: 'operation_4',
              operation: SyncOperationType.create,
              payload: '{invalid-json',
            ),
          ),
          throwsA(
            isA<SyncFailure>().having(
              (failure) => failure.type,
              'type',
              SyncFailureType.permanent,
            ),
          ),
        );

        expect(remoteDataSource.createdProducts, isEmpty);
      });

      test('classifies missing payload as permanent failure', () async {
        await expectLater(
          handler.push(
            _operation(id: 'operation_5', operation: SyncOperationType.create),
          ),
          throwsA(
            isA<SyncFailure>().having(
              (failure) => failure.type,
              'type',
              SyncFailureType.permanent,
            ),
          ),
        );
      });

      test('classifies remote failures as retryable', () async {
        remoteDataSource.onCreateProduct = (_) async {
          throw Exception('Server unavailable');
        };

        await expectLater(
          handler.push(
            _operation(
              id: 'operation_6',
              operation: SyncOperationType.create,
              product: _product(id: '1'),
            ),
          ),
          throwsA(
            isA<SyncFailure>().having(
              (failure) => failure.type,
              'type',
              SyncFailureType.retryable,
            ),
          ),
        );
      });

      test('preserves an existing SyncFailure', () async {
        const failure = SyncFailure(
          message: 'Permanent remote failure',
          type: SyncFailureType.permanent,
        );

        remoteDataSource.onCreateProduct = (_) async {
          throw failure;
        };

        await expectLater(
          handler.push(
            _operation(
              id: 'operation_7',
              operation: SyncOperationType.create,
              product: _product(id: '1'),
            ),
          ),
          throwsA(
            isA<SyncFailure>()
                .having((value) => value.message, 'message', failure.message)
                .having((value) => value.type, 'type', failure.type),
          ),
        );
      });
    });
  });
}

ProductModel _product({required String id, String name = 'Test Product'}) {
  final now = DateTime.utc(2026, 1, 1);

  return ProductModel(
    id: id,
    name: name,
    price: 1999,
    description: 'Test description',
    createdAt: now,
    updatedAt: now,
  );
}

SyncOperation _operation({
  required String id,
  required SyncOperationType operation,
  ProductModel? product,
  String? payload,
}) {
  final now = DateTime.now();

  return SyncOperation(
    id: id,
    entityType: 'product',
    entityId: product?.id ?? '1',
    operation: operation,
    status: SyncOperationStatus.pending,
    attemptCount: 0,
    payload: payload ?? (product == null ? null : jsonEncode(product.toJson())),
    createdAt: now,
    updatedAt: now,
  );
}

class _FakeProductLocalDataSource implements ProductLocalDataSource {
  final Map<String, ProductModel> products = {};

  Future<void> Function(ProductModel product)? onInsertProduct;

  @override
  Future<T> transaction<T>(Future<T> Function() action) {
    return action();
  }

  @override
  Future<List<ProductModel>> getProducts() async {
    return products.values.toList();
  }

  @override
  Stream<List<ProductModel>> watchProducts() {
    return Stream.value(products.values.toList());
  }

  @override
  Future<ProductModel?> getProductById(String id) async {
    return products[id];
  }

  @override
  Future<void> insertProduct(ProductModel product) async {
    await onInsertProduct?.call(product);
    products[product.id] = product;
  }

  @override
  Future<void> updateProduct(ProductModel product) async {
    products[product.id] = product;
  }

  @override
  Future<void> deleteProduct(String id) async {
    products.remove(id);
  }
}

class _FakeProductRemoteDataSource implements ProductRemoteDataSource {
  List<ProductModel> products = [];

  final List<int> requestedOffsets = [];
  final List<ProductModel> createdProducts = [];
  final List<ProductModel> updatedProducts = [];
  final List<String> deletedIds = [];

  Future<List<ProductModel>> Function(int start, int limit)? onGetProducts;

  Future<ProductModel> Function(ProductModel product)? onCreateProduct;

  Future<ProductModel> Function(ProductModel product)? onUpdateProduct;

  Future<void> Function(String id)? onDeleteProduct;

  @override
  Future<List<ProductModel>> getProducts({
    required int start,
    required int limit,
  }) async {
    requestedOffsets.add(start);

    if (onGetProducts != null) {
      return onGetProducts!(start, limit);
    }

    return products.skip(start).take(limit).toList();
  }

  @override
  Future<ProductModel> createProduct(ProductModel product) async {
    if (onCreateProduct != null) {
      return onCreateProduct!(product);
    }

    createdProducts.add(product);
    return product;
  }

  @override
  Future<ProductModel> updateProduct(ProductModel product) async {
    if (onUpdateProduct != null) {
      return onUpdateProduct!(product);
    }

    updatedProducts.add(product);
    return product;
  }

  @override
  Future<void> deleteProduct(String id) async {
    if (onDeleteProduct != null) {
      return onDeleteProduct!(id);
    }

    deletedIds.add(id);
  }
}

class _FakeSyncMetadataRepository implements SyncMetadataRepository {
  String? cursor;

  DateTime? pullCompletedAt;
  DateTime? syncCompletedAt;

  @override
  Future<String?> getCursor(String category) async => cursor;

  @override
  Future<void> updateCursor({
    required String category,
    required String? cursor,
  }) async {
    this.cursor = cursor;
  }

  @override
  Future<void> markPullCompleted({
    required String category,
    required DateTime completedAt,
  }) async {
    pullCompletedAt = completedAt;
  }

  @override
  Future<void> markSyncCompleted({
    required String category,
    required DateTime completedAt,
  }) async {
    syncCompletedAt = completedAt;
  }
}
