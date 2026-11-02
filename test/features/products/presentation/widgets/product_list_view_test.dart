import 'package:flutter/material.dart';
import 'package:flutter_architecture_showcase/features/products/domain/entities/product.dart';
import 'package:flutter_architecture_showcase/features/products/presentation/widgets/product_list_view.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final products = [
    Product(
      id: 'product-1',
      name: 'Keyboard',
      price: 2499,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    ),
    Product(
      id: 'product-2',
      name: 'Mouse',
      price: 799,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    ),
    Product(
      id: 'product-3',
      name: 'Monitor',
      price: 12000,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    ),
  ];

  Widget createWidget({
    required List<Product> products,
    required ValueChanged<Product> onProductTap,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: ProductListView(products: products, onProductTap: onProductTap),
      ),
    );
  }

  group('ProductListView', () {
    testWidgets('displays all products', (tester) async {
      await tester.pumpWidget(
        createWidget(products: products, onProductTap: (_) {}),
      );

      expect(find.text('Keyboard'), findsOneWidget);
      expect(find.text('Mouse'), findsOneWidget);
      expect(find.text('Monitor'), findsOneWidget);
    });

    testWidgets('displays products in the supplied order', (tester) async {
      await tester.pumpWidget(
        createWidget(products: products, onProductTap: (_) {}),
      );

      final keyboardPosition = tester.getTopLeft(find.text('Keyboard')).dy;
      final mousePosition = tester.getTopLeft(find.text('Mouse')).dy;
      final monitorPosition = tester.getTopLeft(find.text('Monitor')).dy;

      expect(keyboardPosition, lessThan(mousePosition));
      expect(mousePosition, lessThan(monitorPosition));
    });

    testWidgets('calls onProductTap with the selected product', (tester) async {
      Product? selectedProduct;

      await tester.pumpWidget(
        createWidget(
          products: products,
          onProductTap: (product) => selectedProduct = product,
        ),
      );

      await tester.tap(find.text('Mouse'));

      expect(selectedProduct, isNotNull);
      expect(selectedProduct!.id, 'product-2');
    });

    testWidgets('renders an empty list without errors', (tester) async {
      await tester.pumpWidget(
        createWidget(products: const [], onProductTap: (_) {}),
      );

      expect(find.byType(ListView), findsOneWidget);
      expect(find.byType(ListTile), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });
}
