import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_architecture_showcase/features/products/application/commands/create_product_command.dart';
import 'package:flutter_architecture_showcase/features/products/application/commands/delete_product_command.dart';
import 'package:flutter_architecture_showcase/features/products/application/commands/update_product_command.dart';
import 'package:flutter_architecture_showcase/features/products/application/queries/watch_products_query.dart';
import 'package:flutter_architecture_showcase/features/products/domain/entities/product.dart';
import 'package:flutter_architecture_showcase/features/products/presentation/cubit/product_cubit.dart';
import 'package:flutter_architecture_showcase/features/products/presentation/cubit/product_state.dart';
import 'package:flutter_architecture_showcase/features/products/presentation/screens/product_details_screen.dart';
import 'package:flutter_architecture_showcase/features/products/presentation/screens/product_form_screen.dart';
import 'package:flutter_architecture_showcase/features/products/presentation/screens/products_screen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockCreateProductCommand extends Mock implements CreateProductCommand {}

class MockUpdateProductCommand extends Mock implements UpdateProductCommand {}

class MockDeleteProductCommand extends Mock implements DeleteProductCommand {}

class MockWatchProductsQuery extends Mock implements WatchProductsQuery {}

void main() {
  late ProductCubit cubit;
  late MockCreateProductCommand createProduct;
  late MockUpdateProductCommand updateProduct;
  late MockDeleteProductCommand deleteProduct;
  late MockWatchProductsQuery watchProducts;
  late StreamController<List<Product>> productsController;

  final product = Product(
    id: 'product-1',
    name: 'Laptop',
    price: 75000,
    description: 'Test laptop',
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );

  setUp(() {
    createProduct = MockCreateProductCommand();
    updateProduct = MockUpdateProductCommand();
    deleteProduct = MockDeleteProductCommand();
    watchProducts = MockWatchProductsQuery();
    productsController = StreamController<List<Product>>.broadcast();

    when(() => watchProducts.execute())
        .thenAnswer((_) => productsController.stream);

    cubit = ProductCubit(
      createProduct: createProduct,
      updateProduct: updateProduct,
      deleteProduct: deleteProduct,
      watchProducts: watchProducts,
    );
  });

  tearDown(() async {
    await cubit.close();
    await productsController.close();
  });

  Widget createWidget() {
    return BlocProvider.value(
      value: cubit,
      child: const MaterialApp(home: ProductsScreen()),
    );
  }

  Future<void> emitProducts(WidgetTester tester, List<Product> products) async {
    productsController.add(products);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }

  testWidgets('shows loading indicator initially', (tester) async {
    await tester.pumpWidget(createWidget());

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Products'), findsOneWidget);
  });

  testWidgets('displays products after stream emission', (tester) async {
    await tester.pumpWidget(createWidget());

    await emitProducts(tester, [product]);

    expect(find.text('Laptop'), findsOneWidget);
  });

  testWidgets('displays empty state when no products exist', (tester) async {
    await tester.pumpWidget(createWidget());

    await emitProducts(tester, []);

    expect(find.text('Add Product'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('displays error and retry button when loading fails', (
    tester,
  ) async {
    await tester.pumpWidget(createWidget());

    productsController.addError(Exception('Unable to load products'));
    await tester.pump();

    expect(find.textContaining('Unable to load products'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets('retry subscribes again and displays products', (tester) async {
    await tester.pumpWidget(createWidget());

    productsController.addError(Exception('Network error'));
    await tester.pump();

    expect(find.text('Retry'), findsOneWidget);

    await tester.tap(find.text('Retry'));
    await tester.pump();

    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });

    await tester.pump();

    productsController.add([product]);

    await tester.pump();

    expect(cubit.state.status, ProductStatus.success);
    expect(cubit.state.products, contains(product));
    expect(find.text('Laptop'), findsOneWidget);
  });

  testWidgets('opens product form when Add Product is tapped', (tester) async {
    await tester.pumpWidget(createWidget());

    await tester.tap(find.text('Add Product'));
    await tester.pumpAndSettle();

    expect(find.byType(ProductFormScreen), findsOneWidget);
  });

  testWidgets('opens product details when a product is tapped', (tester) async {
    await tester.pumpWidget(createWidget());

    await emitProducts(tester, [product]);

    await tester.tap(find.text('Laptop'));
    await tester.pumpAndSettle();

    expect(find.byType(ProductDetailsScreen), findsOneWidget);
  });

  testWidgets('updates product list when stream emits changed data', (
    tester,
  ) async {
    await tester.pumpWidget(createWidget());

    await emitProducts(tester, [product]);

    expect(find.text('Laptop'), findsOneWidget);

    final updatedProduct = Product(
      id: product.id,
      name: 'Updated Laptop',
      price: 80000,
      description: product.description,
      createdAt: product.createdAt,
      updatedAt: DateTime(2026, 2, 1),
    );

    await emitProducts(tester, [updatedProduct]);

    expect(find.text('Updated Laptop'), findsOneWidget);
    expect(find.text('Laptop'), findsNothing);
  });
}
