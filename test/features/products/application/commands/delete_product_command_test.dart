import 'package:flutter_architecture_showcase/features/products/application/commands/delete_product_command.dart';
import 'package:flutter_architecture_showcase/features/products/domain/repositories/product_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockProductRepository extends Mock implements ProductRepository {}

void main() {
  late MockProductRepository repository;
  late DeleteProductCommand command;

  setUp(() {
    repository = MockProductRepository();
    command = DeleteProductCommand(repository);
  });

  group('DeleteProductCommand', () {
    test('deletes product using the supplied ID', () async {
      when(() => repository.deleteProduct('product-1'))
          .thenAnswer((_) async {});

      await command.execute('product-1');

      verify(() => repository.deleteProduct('product-1')).called(1);
    });

    test('propagates repository deletion failure', () async {
      when(() => repository.deleteProduct('product-1'))
          .thenThrow(Exception('Delete failed'));

      expect(() => command.execute('product-1'), throwsA(isA<Exception>()));
    });
  });
}
