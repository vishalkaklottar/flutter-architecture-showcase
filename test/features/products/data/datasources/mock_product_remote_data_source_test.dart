import 'package:flutter_architecture_showcase/features/products/data/datasources/remote/mock_product_remote_data_source.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_architecture_showcase/features/products/data/models/product_model.dart';

void main() {
  late MockProductRemoteDataSource dataSource;

  setUp(() {
    dataSource = MockProductRemoteDataSource();
  });

  group('MockProductRemoteDataSource', () {
    test('returns initial products', () async {
      final products = await dataSource.getProducts(start: 0, limit: 20);

      expect(products, hasLength(3));
      expect(products.map((product) => product.id), ['1', '2', '3']);
    });

    test('supports pagination', () async {
      final firstPage = await dataSource.getProducts(start: 0, limit: 2);

      final secondPage = await dataSource.getProducts(start: 2, limit: 2);

      expect(firstPage, hasLength(2));
      expect(secondPage, hasLength(1));
      expect(firstPage.map((product) => product.id), ['1', '2']);
      expect(secondPage.single.id, '3');
    });

    test('returns empty list when offset exceeds available products', () async {
      final products = await dataSource.getProducts(start: 100, limit: 20);

      expect(products, isEmpty);
    });

    test('rejects invalid pagination parameters', () async {
      expect(
        () => dataSource.getProducts(start: -1, limit: 20),
        throwsArgumentError,
      );

      expect(
        () => dataSource.getProducts(start: 0, limit: 0),
        throwsArgumentError,
      );
    });

    test('creates a product with the same ID', () async {
      final product = _product(id: 'local-100');

      final created = await dataSource.createProduct(product);

      expect(created.id, product.id);
      expect(created.name, product.name);
      expect(created.price, product.price);

      final remoteProducts = await dataSource.getProducts(start: 0, limit: 20);

      expect(
        remoteProducts.where((item) => item.id == product.id),
        hasLength(1),
      );
    });

    test('create is idempotent for the same product ID', () async {
      final product = _product(id: 'local-101');

      final first = await dataSource.createProduct(product);
      final second = await dataSource.createProduct(product);

      expect(first.id, second.id);

      final remoteProducts = await dataSource.getProducts(start: 0, limit: 20);

      expect(
        remoteProducts.where((item) => item.id == product.id),
        hasLength(1),
      );
    });

    test('updates an existing product', () async {
      final original = await dataSource.getProducts(start: 0, limit: 1);

      final updatedProduct = ProductModel(
        id: original.first.id,
        name: 'Updated Headphones',
        price: 2999,
        description: 'Updated description',
        createdAt: original.first.createdAt,
        updatedAt: DateTime.now(),
      );

      final result = await dataSource.updateProduct(updatedProduct);

      expect(result.id, updatedProduct.id);
      expect(result.name, 'Updated Headphones');
      expect(result.price, 2999);

      final stored = await dataSource.getProducts(start: 0, limit: 20);

      final matching = stored.firstWhere(
        (product) => product.id == updatedProduct.id,
      );

      expect(matching.name, 'Updated Headphones');
      expect(matching.price, 2999);
    });

    test('throws when updating a product that does not exist', () {
      expect(
        () => dataSource.updateProduct(_product(id: 'missing')),
        throwsStateError,
      );
    });

    test('deletes an existing product', () async {
      await dataSource.deleteProduct('1');

      final products = await dataSource.getProducts(start: 0, limit: 20);

      expect(products.any((product) => product.id == '1'), isFalse);
    });

    test('deleting a missing product is idempotent', () async {
      await expectLater(dataSource.deleteProduct('missing'), completes);
    });
  });
}

ProductModel _product({required String id}) {
  final now = DateTime.now();

  return ProductModel(
    id: id,
    name: 'Test Product',
    price: 1999,
    description: 'Test description',
    createdAt: now,
    updatedAt: now,
  );
}
