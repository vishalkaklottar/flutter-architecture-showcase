import 'package:flutter_architecture_showcase/features/products/application/queries/get_products_query.dart';
import 'package:flutter_architecture_showcase/features/products/domain/entities/product.dart';
import 'package:flutter_architecture_showcase/features/products/domain/repositories/product_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockProductRepository extends Mock implements ProductRepository {}

void main() {
  late MockProductRepository repository;
  late GetProductsQuery query;

  final products = [
    Product(
      id: 'product-1',
      name: 'Laptop',
      price: 75000,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    ),
    Product(
      id: 'product-2',
      name: 'Monitor',
      price: 25000,
      createdAt: DateTime(2026, 1, 2),
      updatedAt: DateTime(2026, 1, 2),
    ),
  ];

  setUp(() {
    repository = MockProductRepository();
    query = GetProductsQuery(repository);
  });

  group('GetProductsQuery', () {
    test('returns products from repository', () async {
      when(() => repository.getProducts()).thenAnswer((_) async => products);

      final result = await query.execute();

      expect(result, products);
      expect(result, hasLength(2));

      verify(() => repository.getProducts()).called(1);
    });

    test('returns empty list when no products exist', () async {
      when(() => repository.getProducts()).thenAnswer((_) async => []);

      final result = await query.execute();

      expect(result, isEmpty);
    });

    test('propagates repository failure', () async {
      when(() => repository.getProducts())
          .thenThrow(Exception('Database failure'));

      expect(() => query.execute(), throwsA(isA<Exception>()));
    });
  });
}
