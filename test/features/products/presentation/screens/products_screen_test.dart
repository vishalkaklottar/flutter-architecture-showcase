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
import 'package:flutter_architecture_showcase/features/sync/presentation/cubit/sync_cubit.dart';
import 'package:flutter_architecture_showcase/features/sync/presentation/cubit/sync_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockCreateProductCommand extends Mock implements CreateProductCommand {}

class MockUpdateProductCommand extends Mock implements UpdateProductCommand {}

class MockDeleteProductCommand extends Mock implements DeleteProductCommand {}

class MockWatchProductsQuery extends Mock implements WatchProductsQuery {}

class MockSyncCubit extends Mock implements SyncCubit {}

void main() {
  late ProductCubit productCubit;
  late MockSyncCubit syncCubit;

  late MockCreateProductCommand createProduct;
  late MockUpdateProductCommand updateProduct;
  late MockDeleteProductCommand deleteProduct;
  late MockWatchProductsQuery watchProducts;

  late StreamController<List<Product>> productsController;
  late StreamController<SyncState> syncController;

  late SyncState syncState;

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
    syncController = StreamController<SyncState>.broadcast();

    syncCubit = MockSyncCubit();
    syncState = const SyncState();

    when(() => watchProducts.execute())
        .thenAnswer((_) => productsController.stream);

    when(() => syncCubit.state).thenAnswer((_) => syncState);
    when(() => syncCubit.stream).thenAnswer((_) => syncController.stream);
    when(() => syncCubit.synchronize()).thenAnswer((_) async {});

    productCubit = ProductCubit(
      createProduct: createProduct,
      updateProduct: updateProduct,
      deleteProduct: deleteProduct,
      watchProducts: watchProducts,
    );
  });

  tearDown(() async {
    await productCubit.close();
    await productsController.close();
    await syncController.close();
  });

  Widget createWidget() {
    return MultiBlocProvider(
      providers: [
        BlocProvider<ProductCubit>.value(value: productCubit),
        BlocProvider<SyncCubit>.value(value: syncCubit),
      ],
      child: const MaterialApp(home: ProductsScreen()),
    );
  }

  Future<void> emitProducts(WidgetTester tester, List<Product> products) async {
    productsController.add(products);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }

  Future<void> emitSyncState(WidgetTester tester, SyncState state) async {
    syncState = state;
    syncController.add(state);
    await tester.pump();
  }

  group('ProductsScreen', () {
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

      expect(productCubit.state.status, ProductStatus.success);
      expect(productCubit.state.products, contains(product));
      expect(find.text('Laptop'), findsOneWidget);
    });

    testWidgets('opens product form when Add Product is tapped', (
      tester,
    ) async {
      await tester.pumpWidget(createWidget());

      await tester.tap(find.text('Add Product'));
      await tester.pumpAndSettle();

      expect(find.byType(ProductFormScreen), findsOneWidget);
    });

    testWidgets('opens product details when a product is tapped', (
      tester,
    ) async {
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
  });

  group('Synchronization', () {
    testWidgets('shows sync button when synchronization is idle', (
      tester,
    ) async {
      await tester.pumpWidget(createWidget());

      expect(find.byTooltip('Sync now'), findsOneWidget);
    });

    testWidgets('triggers synchronization when sync button is tapped', (
      tester,
    ) async {
      await tester.pumpWidget(createWidget());

      await tester.tap(find.byTooltip('Sync now'));
      await tester.pump();

      verify(() => syncCubit.synchronize()).called(1);
    });

    testWidgets('shows progress indicator while synchronizing', (
        tester,
        ) async {
      await tester.pumpWidget(createWidget());

      await emitSyncState(
        tester,
        const SyncState(status: SyncStatus.running),
      );

      expect(find.byTooltip('Synchronizing...'), findsOneWidget);

      expect(
        find.descendant(
          of: find.ancestor(
            of: find.byTooltip('Synchronizing...'),
            matching: find.byType(IconButton),
          ),
          matching: find.byType(CircularProgressIndicator),
        ),
        findsOneWidget,
      );

      final iconButton = tester.widget<IconButton>(
        find.ancestor(
          of: find.byTooltip('Synchronizing...'),
          matching: find.byType(IconButton),
        ),
      );

      expect(iconButton.onPressed, isNull);
    });

    testWidgets('shows sync problem icon after synchronization failure', (
      tester,
    ) async {
      await tester.pumpWidget(createWidget());

      await emitSyncState(
        tester,
        const SyncState(
          status: SyncStatus.failure,
          errorMessage: 'Synchronization failed',
        ),
      );

      expect(find.byTooltip('Sync now'), findsOneWidget);
      expect(find.byIcon(Icons.sync_problem), findsOneWidget);
    });

    testWidgets('displays snackbar when synchronization fails', (tester) async {
      await tester.pumpWidget(createWidget());

      await emitSyncState(
        tester,
        const SyncState(
          status: SyncStatus.failure,
          errorMessage: 'Synchronization failed',
        ),
      );

      expect(find.text('Synchronization failed'), findsOneWidget);
    });
  });
}
