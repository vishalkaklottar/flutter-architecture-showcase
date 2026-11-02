import 'dart:async';

import 'package:flutter_architecture_showcase/features/products/application/commands/create_product_command.dart';
import 'package:flutter_architecture_showcase/features/products/application/commands/delete_product_command.dart';
import 'package:flutter_architecture_showcase/features/products/application/commands/update_product_command.dart';
import 'package:flutter_architecture_showcase/features/products/application/queries/watch_products_query.dart';
import 'package:flutter_architecture_showcase/features/products/domain/entities/product.dart';
import 'package:flutter_architecture_showcase/features/products/presentation/cubit/product_cubit.dart';
import 'package:flutter_architecture_showcase/features/products/presentation/cubit/product_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockCreateProductCommand extends Mock implements CreateProductCommand {}

class MockUpdateProductCommand extends Mock implements UpdateProductCommand {}

class MockDeleteProductCommand extends Mock implements DeleteProductCommand {}

class MockWatchProductsQuery extends Mock implements WatchProductsQuery {}

void main() {
  late MockCreateProductCommand createProductCommand;
  late MockUpdateProductCommand updateProductCommand;
  late MockDeleteProductCommand deleteProductCommand;
  late MockWatchProductsQuery watchProductsQuery;

  late ProductCubit cubit;

  final product = Product(
    id: 'product-1',
    name: 'Laptop',
    price: 75000,
    description: 'Development laptop',
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );

  setUp(() {
    createProductCommand = MockCreateProductCommand();
    updateProductCommand = MockUpdateProductCommand();
    deleteProductCommand = MockDeleteProductCommand();
    watchProductsQuery = MockWatchProductsQuery();

    cubit = ProductCubit(
      createProduct: createProductCommand,
      updateProduct: updateProductCommand,
      deleteProduct: deleteProductCommand,
      watchProducts: watchProductsQuery,
    );
  });

  tearDown(() async {
    await cubit.close();
  });

  group('Initial state', () {
    test('has correct initial values', () {
      expect(cubit.state.status, ProductStatus.initial);
      expect(cubit.state.products, isEmpty);
      expect(cubit.state.isMutating, false);
      expect(cubit.state.errorMessage, isNull);
    });
  });

  group('loadProducts', () {
    late StreamController<List<Product>> controller;

    setUp(() {
      controller = StreamController<List<Product>>.broadcast();
      when(() => watchProductsQuery.execute())
          .thenAnswer((_) => controller.stream);
    });

    tearDown(() async {
      await controller.close();
    });

    test('subscribes to product stream and emits products', () async {
      await cubit.loadProducts();

      expect(cubit.state.status, ProductStatus.loading);

      controller.add([product]);

      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.status, ProductStatus.success);
      expect(cubit.state.products, [product]);
      expect(cubit.state.errorMessage, isNull);
    });

    test('handles product stream errors', () async {
      await cubit.loadProducts();

      controller.addError(Exception('Stream failure'));

      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.status, ProductStatus.failure);
      expect(cubit.state.errorMessage, contains('Stream failure'));
    });

    test('cancels previous subscription when loaded again', () async {
      await cubit.loadProducts();

      await cubit.loadProducts();

      verify(() => watchProductsQuery.execute()).called(2);
    });
  });

  group('addProduct', () {
    test('executes create command successfully', () async {
      when(
        () => createProductCommand.execute(
          name: 'Laptop',
          price: 75000,
          description: 'Development laptop',
        ),
      ).thenAnswer((_) async {});

      final result = await cubit.addProduct(
        name: 'Laptop',
        price: 75000,
        description: 'Development laptop',
      );

      expect(result, true);
      expect(cubit.state.isMutating, false);
      expect(cubit.state.errorMessage, isNull);

      verify(
        () => createProductCommand.execute(
          name: 'Laptop',
          price: 75000,
          description: 'Development laptop',
        ),
      ).called(1);
    });

    test('handles create command failure', () async {
      when(
        () => createProductCommand.execute(
          name: 'Laptop',
          price: 75000,
          description: null,
        ),
      ).thenThrow(Exception('Create failed'));

      final result = await cubit.addProduct(name: 'Laptop', price: 75000);

      expect(result, false);
      expect(cubit.state.isMutating, false);
      expect(cubit.state.errorMessage, contains('Create failed'));
    });
  });

  group('updateProduct', () {
    test('executes update command successfully', () async {
      when(
        () => updateProductCommand.execute(
          productId: 'product-1',
          name: 'Updated Laptop',
          price: 80000,
          description: 'Updated description',
        ),
      ).thenAnswer((_) async {});

      final result = await cubit.updateProduct(
        productId: 'product-1',
        name: 'Updated Laptop',
        price: 80000,
        description: 'Updated description',
      );

      expect(result, true);
      expect(cubit.state.isMutating, false);

      verify(
        () => updateProductCommand.execute(
          productId: 'product-1',
          name: 'Updated Laptop',
          price: 80000,
          description: 'Updated description',
        ),
      ).called(1);
    });

    test('handles update command failure', () async {
      when(
        () => updateProductCommand.execute(
          productId: 'product-1',
          name: 'Updated Laptop',
          price: 80000,
          description: null,
        ),
      ).thenThrow(StateError('Product not found'));

      final result = await cubit.updateProduct(
        productId: 'product-1',
        name: 'Updated Laptop',
        price: 80000,
      );

      expect(result, false);
      expect(cubit.state.isMutating, false);
      expect(cubit.state.errorMessage, contains('Product not found'));
    });
  });

  group('deleteProduct', () {
    test('executes delete command successfully', () async {
      when(() => deleteProductCommand.execute('product-1'))
          .thenAnswer((_) async {});

      final result = await cubit.deleteProduct('product-1');

      expect(result, true);
      expect(cubit.state.isMutating, false);

      verify(() => deleteProductCommand.execute('product-1')).called(1);
    });

    test('handles delete command failure', () async {
      when(() => deleteProductCommand.execute('product-1'))
          .thenThrow(Exception('Delete failed'));

      final result = await cubit.deleteProduct('product-1');

      expect(result, false);
      expect(cubit.state.isMutating, false);
      expect(cubit.state.errorMessage, contains('Delete failed'));
    });
  });

  group('Mutation concurrency', () {
    test('prevents concurrent mutations', () async {
      final completer = Completer<void>();

      when(
        () => createProductCommand.execute(
          name: 'Laptop',
          price: 75000,
          description: null,
        ),
      ).thenAnswer((_) => completer.future);

      final firstMutation = cubit.addProduct(name: 'Laptop', price: 75000);

      expect(cubit.state.isMutating, true);

      final secondMutation = await cubit.deleteProduct('product-1');

      expect(secondMutation, false);

      verifyNever(() => deleteProductCommand.execute('product-1'));

      completer.complete();

      expect(await firstMutation, true);
      expect(cubit.state.isMutating, false);
    });
  });
}
