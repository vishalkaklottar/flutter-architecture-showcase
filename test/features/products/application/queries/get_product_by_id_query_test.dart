import 'package:flutter_architecture_showcase/features/products/application/queries/get_product_by_id_query.dart';
import 'package:flutter_architecture_showcase/features/products/domain/entities/product.dart';
import 'package:flutter_architecture_showcase/features/products/domain/repositories/product_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockProductRepository extends Mock implements ProductRepository {}

void main() {
  late MockProductRepository repository;
  late GetProductByIdQuery query;

  final product = Product(
    id: 'product-1',
    name: 'Laptop',
    price: 75000,
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );

  setUp(() {
    repository = MockProductRepository();
    query = GetProductByIdQuery(repository);
  });

  group('GetProductByIdQuery', () {
    test('returns product for existing ID', () async {
      when(() => repository.getProductById('product-1'))
          .thenAnswer((_) async => product);

      final result = await query.execute('product-1');

      expect(result, product);

      verify(() => repository.getProductById('product-1')).called(1);
    });

    test('returns null when product does not exist', () async {
      when(() => repository.getProductById('unknown'))
          .thenAnswer((_) async => null);

      final result = await query.execute('unknown');

      expect(result, isNull);
    });

    test('propagates repository failure', () async {
      when(() => repository.getProductById('product-1'))
          .thenThrow(Exception('Database failure'));

      expect(() => query.execute('product-1'), throwsA(isA<Exception>()));
    });
  });
}
