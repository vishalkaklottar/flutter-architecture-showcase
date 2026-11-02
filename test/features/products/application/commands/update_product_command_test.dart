import 'package:flutter_architecture_showcase/features/products/application/commands/update_product_command.dart';
import 'package:flutter_architecture_showcase/features/products/domain/entities/product.dart';
import 'package:flutter_architecture_showcase/features/products/domain/repositories/product_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockProductRepository extends Mock implements ProductRepository {}

class FakeProduct extends Fake implements Product {}

void main() {
  late MockProductRepository repository;
  late UpdateProductCommand command;

  final existingProduct = Product(
    id: 'product-1',
    name: 'Laptop',
    price: 75000,
    description: 'Old description',
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );

  setUpAll(() {
    registerFallbackValue(FakeProduct());
  });

  setUp(() {
    repository = MockProductRepository();
    command = UpdateProductCommand(repository);
  });

  group('UpdateProductCommand', () {
    test('updates product while preserving ID and creation date', () async {
      when(() => repository.getProductById('product-1'))
          .thenAnswer((_) async => existingProduct);

      when(() => repository.updateProduct(any())).thenAnswer((_) async {});

      await command.execute(
        productId: 'product-1',
        name: 'Updated Laptop',
        price: 80000,
        description: 'Updated description',
      );

      final updatedProduct =
          verify(() => repository.updateProduct(captureAny())).captured.single
              as Product;

      expect(updatedProduct.id, existingProduct.id);
      expect(updatedProduct.name, 'Updated Laptop');
      expect(updatedProduct.price, 80000);
      expect(updatedProduct.description, 'Updated description');
      expect(updatedProduct.createdAt, existingProduct.createdAt);
      expect(
        updatedProduct.updatedAt.isAfter(existingProduct.updatedAt),
        isTrue,
      );
    });

    test('throws when product does not exist', () async {
      when(() => repository.getProductById('unknown'))
          .thenAnswer((_) async => null);

      expect(
        () => command.execute(
          productId: 'unknown',
          name: 'Updated Laptop',
          price: 80000,
        ),
        throwsA(isA<StateError>()),
      );

      verifyNever(() => repository.updateProduct(any()));
    });

    test('propagates repository update failure', () async {
      when(() => repository.getProductById('product-1'))
          .thenAnswer((_) async => existingProduct);

      when(() => repository.updateProduct(any()))
          .thenThrow(Exception('Update failed'));

      expect(
        () => command.execute(
          productId: 'product-1',
          name: 'Updated Laptop',
          price: 80000,
        ),
        throwsA(isA<Exception>()),
      );
    });
  });
}
