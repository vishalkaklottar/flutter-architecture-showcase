import 'dart:async';

import 'package:flutter_architecture_showcase/features/products/application/queries/watch_products_query.dart';
import 'package:flutter_architecture_showcase/features/products/domain/entities/product.dart';
import 'package:flutter_architecture_showcase/features/products/domain/repositories/product_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockProductRepository extends Mock implements ProductRepository {}

void main() {
  late MockProductRepository repository;
  late WatchProductsQuery query;

  final product = Product(
    id: 'product-1',
    name: 'Laptop',
    price: 75000,
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );

  setUp(() {
    repository = MockProductRepository();
    query = WatchProductsQuery(repository);
  });

  group('WatchProductsQuery', () {
    test('returns repository product stream', () async {
      final products = [product];

      when(() => repository.watchProducts())
          .thenAnswer((_) => Stream.value(products));

      final result = await query.execute().first;

      expect(result, products);

      verify(() => repository.watchProducts()).called(1);
    });

    test('emits multiple product updates', () async {
      final controller = StreamController<List<Product>>();

      when(() => repository.watchProducts())
          .thenAnswer((_) => controller.stream);

      final emissions = <List<Product>>[];

      final subscription = query.execute().listen(emissions.add);

      controller.add([product]);

      final updatedProduct = Product(
        id: product.id,
        name: 'Updated Laptop',
        price: 80000,
        createdAt: product.createdAt,
        updatedAt: DateTime(2026, 2, 1),
      );

      controller.add([updatedProduct]);

      await Future<void>.delayed(Duration.zero);

      expect(emissions, hasLength(2));
      expect(emissions[0].first.name, 'Laptop');
      expect(emissions[1].first.name, 'Updated Laptop');

      await subscription.cancel();
      await controller.close();
    });

    test('propagates stream errors', () async {
      when(() => repository.watchProducts())
          .thenAnswer((_) => Stream.error(Exception('Stream failure')));

      expect(query.execute(), emitsError(isA<Exception>()));
    });
  });
}
