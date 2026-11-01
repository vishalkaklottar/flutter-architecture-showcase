import 'dart:async';

import 'package:injectable/injectable.dart';

import '../../models/product_model.dart';
import 'product_remote_data_source.dart';

@LazySingleton(as: ProductRemoteDataSource)
class MockProductRemoteDataSource implements ProductRemoteDataSource {
  MockProductRemoteDataSource();

  static const _networkDelay = Duration(milliseconds: 300);

  final Map<String, ProductModel> _products = {
    for (final product in _initialProducts) product.id: product,
  };

  @override
  Future<List<ProductModel>> getProducts({
    required int start,
    required int limit,
  }) async {
    await Future<void>.delayed(_networkDelay);

    if (start < 0 || limit <= 0) {
      throw ArgumentError('Invalid pagination parameters.');
    }

    final products = _products.values.toList()
      ..sort((a, b) => a.id.compareTo(b.id));

    return products.skip(start).take(limit).toList();
  }

  @override
  Future<ProductModel> createProduct(ProductModel product) async {
    await Future<void>.delayed(_networkDelay);

    final existing = _products[product.id];

    if (existing != null) {
      return existing;
    }

    final createdProduct = ProductModel.fromJson({
      ...product.toJson(),
      'createdAt': DateTime.now().toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    });

    _products[product.id] = createdProduct;

    return createdProduct;
  }

  @override
  Future<ProductModel> updateProduct(ProductModel product) async {
    await Future<void>.delayed(_networkDelay);

    if (!_products.containsKey(product.id)) {
      throw StateError('Product ${product.id} does not exist remotely.');
    }

    final updatedProduct = ProductModel.fromJson({
      ...product.toJson(),
      'updatedAt': DateTime.now().toIso8601String(),
    });

    _products[product.id] = updatedProduct;

    return updatedProduct;
  }

  @override
  Future<void> deleteProduct(String id) async {
    await Future<void>.delayed(_networkDelay);

    // DELETE is idempotent: deleting an absent product is also successful.
    _products.remove(id);
  }

  static final List<ProductModel> _initialProducts = [
    ProductModel.fromJson({
      'id': '1',
      'name': 'Wireless Headphones',
      'price': 2499.0,
      'description': 'Over-ear wireless headphones',
      'createdAt': '2026-01-10T10:00:00.000Z',
      'updatedAt': '2026-01-10T10:00:00.000Z',
    }),
    ProductModel.fromJson({
      'id': '2',
      'name': 'Mechanical Keyboard',
      'price': 3999.0,
      'description': 'Mechanical keyboard with tactile switches',
      'createdAt': '2026-01-11T10:00:00.000Z',
      'updatedAt': '2026-01-11T10:00:00.000Z',
    }),
    ProductModel.fromJson({
      'id': '3',
      'name': 'USB-C Hub',
      'price': 1499.0,
      'description': 'Multi-port USB-C adapter',
      'createdAt': '2026-01-12T10:00:00.000Z',
      'updatedAt': '2026-01-12T10:00:00.000Z',
    }),
  ];
}
