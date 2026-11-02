import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_architecture_showcase/features/products/application/commands/create_product_command.dart';
import 'package:flutter_architecture_showcase/features/products/application/commands/delete_product_command.dart';
import 'package:flutter_architecture_showcase/features/products/application/commands/update_product_command.dart';
import 'package:flutter_architecture_showcase/features/products/application/queries/watch_products_query.dart';
import 'package:flutter_architecture_showcase/features/products/domain/entities/product.dart';
import 'package:flutter_architecture_showcase/features/products/presentation/cubit/product_cubit.dart';
import 'package:flutter_architecture_showcase/features/products/presentation/screens/product_form_screen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
  late ProductCubit cubit;

  final existingProduct = Product(
    id: 'product-1',
    name: 'Keyboard',
    price: 2499,
    description: 'Mechanical keyboard',
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 2),
  );

  setUp(() {
    createProduct = MockCreateProductCommand();
    updateProduct = MockUpdateProductCommand();
    deleteProduct = MockDeleteProductCommand();
    watchProducts = MockWatchProductsQuery();

    when(() => watchProducts.execute()).thenAnswer((_) => const Stream.empty());

    cubit = ProductCubit(
      createProduct: createProduct,
      updateProduct: updateProduct,
      deleteProduct: deleteProduct,
      watchProducts: watchProducts,
    );
  });

  tearDown(() async {
    await cubit.close();
  });

  Widget createWidget({Product? product}) {
    return BlocProvider.value(
      value: cubit,
      child: MaterialApp(
        home: Builder(
          builder: (context) =>
              Scaffold(body: ProductFormScreen(product: product)),
        ),
      ),
    );
  }

  group('ProductFormScreen', () {
    testWidgets('displays create form by default', (tester) async {
      await tester.pumpWidget(createWidget());

      expect(find.text('New Product'), findsOneWidget);
      expect(find.text('Create Product'), findsOneWidget);
      expect(find.text('Product name'), findsOneWidget);
      expect(find.text('Price'), findsOneWidget);
      expect(find.text('Description'), findsOneWidget);
    });

    testWidgets('displays existing product details in edit mode', (
      tester,
    ) async {
      await tester.pumpWidget(createWidget(product: existingProduct));

      expect(find.text('Edit Product'), findsOneWidget);
      expect(find.text('Save Changes'), findsOneWidget);

      expect(
        tester
            .widget<TextFormField>(
              find.widgetWithText(TextFormField, 'Product name'),
            )
            .controller!
            .text,
        'Keyboard',
      );

      expect(
        tester
            .widget<TextFormField>(find.widgetWithText(TextFormField, 'Price'))
            .controller!
            .text,
        '2499.0',
      );

      expect(
        tester
            .widget<TextFormField>(
              find.widgetWithText(TextFormField, 'Description'),
            )
            .controller!
            .text,
        'Mechanical keyboard',
      );
    });

    testWidgets('shows validation errors for empty required fields', (
      tester,
    ) async {
      await tester.pumpWidget(createWidget());

      await tester.tap(find.text('Create Product'));
      await tester.pump();

      expect(find.text('Product name is required'), findsOneWidget);
      expect(
        find.text('Enter a valid price greater than zero'),
        findsOneWidget,
      );

      verifyNever(
        () => createProduct.execute(
          name: any(named: 'name'),
          price: any(named: 'price'),
          description: any(named: 'description'),
        ),
      );
    });

    testWidgets('rejects zero and negative prices', (tester) async {
      await tester.pumpWidget(createWidget());

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Product name'),
        'Keyboard',
      );

      final priceField = find.widgetWithText(TextFormField, 'Price');

      for (final price in ['0', '-10']) {
        await tester.enterText(priceField, price);
        await tester.tap(find.text('Create Product'));
        await tester.pump();

        expect(
          find.text('Enter a valid price greater than zero'),
          findsOneWidget,
        );
      }

      verifyNever(
        () => createProduct.execute(
          name: any(named: 'name'),
          price: any(named: 'price'),
          description: any(named: 'description'),
        ),
      );
    });

    testWidgets('rejects invalid price input', (tester) async {
      await tester.pumpWidget(createWidget());

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Product name'),
        'Keyboard',
      );

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Price'),
        'abc',
      );

      await tester.tap(find.text('Create Product'));
      await tester.pump();

      expect(
        find.text('Enter a valid price greater than zero'),
        findsOneWidget,
      );
    });

    testWidgets('creates product with trimmed values', (tester) async {
      when(
        () => createProduct.execute(
          name: any(named: 'name'),
          price: any(named: 'price'),
          description: any(named: 'description'),
        ),
      ).thenAnswer((_) async {});

      await tester.pumpWidget(createWidget());

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Product name'),
        '  Keyboard  ',
      );

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Price'),
        '2499.50',
      );

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Description'),
        '  Mechanical keyboard  ',
      );

      await tester.tap(find.text('Create Product'));
      await tester.pumpAndSettle();

      verify(
        () => createProduct.execute(
          name: 'Keyboard',
          price: 2499.50,
          description: 'Mechanical keyboard',
        ),
      ).called(1);

      expect(find.text('New Product'), findsNothing);
    });

    testWidgets('submits null description when description is empty', (
      tester,
    ) async {
      when(
        () => createProduct.execute(
          name: any(named: 'name'),
          price: any(named: 'price'),
          description: any(named: 'description'),
        ),
      ).thenAnswer((_) async {});

      await tester.pumpWidget(createWidget());

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Product name'),
        'Keyboard',
      );

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Price'),
        '100',
      );

      await tester.tap(find.text('Create Product'));
      await tester.pumpAndSettle();

      verify(
        () => createProduct.execute(
          name: 'Keyboard',
          price: 100,
          description: null,
        ),
      ).called(1);
    });

    testWidgets('updates existing product', (tester) async {
      when(
        () => updateProduct.execute(
          productId: any(named: 'productId'),
          name: any(named: 'name'),
          price: any(named: 'price'),
          description: any(named: 'description'),
        ),
      ).thenAnswer((_) async {});

      await tester.pumpWidget(createWidget(product: existingProduct));

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Product name'),
        'Updated Keyboard',
      );

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Price'),
        '2999',
      );

      await tester.tap(find.text('Save Changes'));
      await tester.pumpAndSettle();

      verify(
        () => updateProduct.execute(
          productId: 'product-1',
          name: 'Updated Keyboard',
          price: 2999,
          description: 'Mechanical keyboard',
        ),
      ).called(1);
    });

    testWidgets('shows error when creation fails', (tester) async {
      when(
        () => createProduct.execute(
          name: any(named: 'name'),
          price: any(named: 'price'),
          description: any(named: 'description'),
        ),
      ).thenThrow(Exception('Database error'));

      await tester.pumpWidget(createWidget());

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Product name'),
        'Keyboard',
      );

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Price'),
        '100',
      );

      await tester.tap(find.text('Create Product'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Database error'), findsOneWidget);
      expect(find.text('New Product'), findsOneWidget);
    });

    testWidgets('shows loading indicator while submitting', (tester) async {
      var completeCreation = false;

      when(
        () => createProduct.execute(
          name: any(named: 'name'),
          price: any(named: 'price'),
          description: any(named: 'description'),
        ),
      ).thenAnswer((_) async {
        await Future<void>.delayed(const Duration(seconds: 1));
        completeCreation = true;
      });

      await tester.pumpWidget(createWidget());

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Product name'),
        'Keyboard',
      );

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Price'),
        '100',
      );

      await tester.tap(find.text('Create Product'));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Create Product'), findsNothing);

      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      expect(completeCreation, isTrue);
    });
  });
}
