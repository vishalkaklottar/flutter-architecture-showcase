import 'package:flutter_architecture_showcase/features/products/application/commands/create_product_command.dart';
import 'package:flutter_architecture_showcase/features/products/domain/entities/product.dart';
import 'package:flutter_architecture_showcase/features/products/domain/repositories/product_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockProductRepository extends Mock implements ProductRepository {}

class FakeProduct extends Fake implements Product {}

void main() {
  late MockProductRepository repository;
  late CreateProductCommand command;

  setUpAll(() {
    registerFallbackValue(FakeProduct());
  });

  setUp(() {
    repository = MockProductRepository();
    command = CreateProductCommand(repository);
  });

  group('CreateProductCommand', () {
    test('creates product with generated ID and correct details', () async {
      when(() => repository.createProduct(any())).thenAnswer((_) async {});

      await command.execute(
        name: 'Laptop',
        price: 75000,
        description: 'Development laptop',
      );

      final captured =
          verify(() => repository.createProduct(captureAny())).captured.single
              as Product;

      expect(captured.id, isNotEmpty);
      expect(captured.name, 'Laptop');
      expect(captured.price, 75000);
      expect(captured.description, 'Development laptop');
      expect(captured.createdAt, isA<DateTime>());
      expect(captured.updatedAt, isA<DateTime>());
      expect(captured.createdAt, captured.updatedAt);
    });

    test('generates unique IDs for different products', () async {
      when(() => repository.createProduct(any())).thenAnswer((_) async {});

      await command.execute(name: 'Laptop', price: 75000);

      await command.execute(name: 'Monitor', price: 25000);

      final captured = verify(() => repository.createProduct(captureAny()))
          .captured
          .cast<Product>();

      expect(captured, hasLength(2));
      expect(captured[0].id, isNot(captured[1].id));
    });

    test('passes null description when not provided', () async {
      when(() => repository.createProduct(any())).thenAnswer((_) async {});

      await command.execute(name: 'Laptop', price: 75000);

      final captured =
          verify(() => repository.createProduct(captureAny())).captured.single
              as Product;

      expect(captured.description, isNull);
    });

    test('propagates repository failures', () async {
      when(() => repository.createProduct(any()))
          .thenThrow(Exception('Database failure'));

      expect(
        () => command.execute(name: 'Laptop', price: 75000),
        throwsA(isA<Exception>()),
      );
    });
  });
}
