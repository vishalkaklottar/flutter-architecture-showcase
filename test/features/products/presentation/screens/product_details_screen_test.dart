import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_architecture_showcase/features/products/application/commands/create_product_command.dart';
import 'package:flutter_architecture_showcase/features/products/application/commands/delete_product_command.dart';
import 'package:flutter_architecture_showcase/features/products/application/commands/update_product_command.dart';
import 'package:flutter_architecture_showcase/features/products/application/queries/watch_products_query.dart';
import 'package:flutter_architecture_showcase/features/products/domain/entities/product.dart';
import 'package:flutter_architecture_showcase/features/products/presentation/cubit/product_cubit.dart';
import 'package:flutter_architecture_showcase/features/products/presentation/screens/product_details_screen.dart';
import 'package:flutter_architecture_showcase/features/products/presentation/screens/product_form_screen.dart';
import 'package:mocktail/mocktail.dart';

class MockCreateProductCommand extends Mock implements CreateProductCommand {}

class MockUpdateProductCommand extends Mock implements UpdateProductCommand {}

class MockDeleteProductCommand extends Mock implements DeleteProductCommand {}

class MockWatchProductsQuery extends Mock implements WatchProductsQuery {}

void main() {
  late MockCreateProductCommand createProduct;
  late MockUpdateProductCommand updateProduct;
  late MockDeleteProductCommand deleteProduct;
  late MockWatchProductsQuery watchProducts;

  late StreamController<List<Product>> productsController;
  late ProductCubit cubit;

  final product = Product(
    id: 'product-1',
    name: 'Mechanical Keyboard',
    price: 2499.50,
    description: 'RGB mechanical keyboard',
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 2),
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
      child: MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => ProductDetailsScreen(product: product),
                      ),
                    );
                  },
                  child: const Text('Open details'),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> openDetails(WidgetTester tester) async {
    await tester.pumpWidget(createWidget());

    await cubit.loadProducts();
    productsController.add([product]);
    await tester.pump();

    await tester.tap(find.text('Open details'));
    await tester.pumpAndSettle();
  }

  group('ProductDetailsScreen', () {
    testWidgets('displays product information', (tester) async {
      await openDetails(tester);

      expect(find.text('Product Details'), findsOneWidget);
      expect(find.text('Mechanical Keyboard'), findsOneWidget);
      expect(find.text('₹2499.50'), findsOneWidget);
      expect(find.text('RGB mechanical keyboard'), findsOneWidget);
      expect(find.text('Product ID'), findsOneWidget);
      expect(find.text('product-1'), findsOneWidget);
      expect(find.text('Created'), findsOneWidget);
      expect(find.text('Last updated'), findsOneWidget);
    });

    testWidgets('displays fallback when description is empty', (tester) async {
      await openDetails(tester);

      productsController.add([
        Product(
          id: product.id,
          name: product.name,
          price: product.price,
          description: '',
          createdAt: product.createdAt,
          updatedAt: product.updatedAt,
        ),
      ]);

      await tester.pumpAndSettle();

      expect(find.text('No description available.'), findsOneWidget);
    });

    testWidgets('shows unavailable message when product is removed', (
      tester,
    ) async {
      await openDetails(tester);

      productsController.add([]);
      await tester.pumpAndSettle();

      expect(find.text('Product is no longer available.'), findsOneWidget);
      expect(find.byTooltip('Edit product'), findsNothing);
      expect(find.byTooltip('Delete product'), findsNothing);
    });

    testWidgets('updates displayed information when product changes', (
      tester,
    ) async {
      await openDetails(tester);

      final updatedProduct = Product(
        id: product.id,
        name: 'Updated Keyboard',
        price: 2999,
        description: 'Updated description',
        createdAt: product.createdAt,
        updatedAt: DateTime(2026, 1, 3),
      );

      productsController.add([updatedProduct]);
      await tester.pumpAndSettle();

      expect(find.text('Updated Keyboard'), findsOneWidget);
      expect(find.text('₹2999.00'), findsOneWidget);
      expect(find.text('Updated description'), findsOneWidget);

      expect(find.text('Mechanical Keyboard'), findsNothing);
    });

    testWidgets('opens edit form with current product', (tester) async {
      await openDetails(tester);

      await tester.tap(find.byTooltip('Edit product'));
      await tester.pumpAndSettle();

      expect(find.byType(ProductFormScreen), findsOneWidget);
      expect(find.text('Edit Product'), findsOneWidget);
      expect(find.text('Save Changes'), findsOneWidget);
    });

    testWidgets('shows delete confirmation dialog', (tester) async {
      await openDetails(tester);

      await tester.tap(find.byTooltip('Delete product'));
      await tester.pumpAndSettle();

      expect(find.text('Delete product?'), findsOneWidget);
      expect(
        find.text(
          'Are you sure you want to delete "Mechanical Keyboard"? '
          'This action cannot be undone.',
        ),
        findsOneWidget,
      );
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);
    });

    testWidgets('does not delete product when confirmation is cancelled', (
      tester,
    ) async {
      await openDetails(tester);

      await tester.tap(find.byTooltip('Delete product'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      verifyNever(() => deleteProduct.execute(any()));

      expect(find.text('Mechanical Keyboard'), findsOneWidget);
    });

    testWidgets('deletes product after confirmation', (tester) async {
      when(() => deleteProduct.execute('product-1')).thenAnswer((_) async {});

      await openDetails(tester);

      await tester.tap(find.byTooltip('Delete product'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      verify(() => deleteProduct.execute('product-1')).called(1);

      // Successful deletion closes the details route.
      expect(find.text('Open details'), findsOneWidget);
      expect(find.text('Mechanical Keyboard'), findsNothing);
    });

    testWidgets('shows error when deletion fails', (tester) async {
      when(() => deleteProduct.execute('product-1'))
          .thenThrow(Exception('Database error'));

      await openDetails(tester);

      await tester.tap(find.byTooltip('Delete product'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(find.text('Mechanical Keyboard'), findsOneWidget);
      expect(find.textContaining('Database error'), findsOneWidget);
    });

    testWidgets('shows loading indicator while deleting', (tester) async {
      final completer = Completer<void>();

      when(() => deleteProduct.execute('product-1'))
          .thenAnswer((_) => completer.future);

      await openDetails(tester);

      await tester.tap(find.byTooltip('Delete product'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Delete'));
      await tester.pump();

      expect(find.byTooltip('Delete product'), findsOneWidget);

      completer.complete();

      await tester.pumpAndSettle();

      expect(find.text('Open details'), findsOneWidget);
    });
  });
}
