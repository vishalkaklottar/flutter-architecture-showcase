import 'package:flutter/material.dart';
import 'package:flutter_architecture_showcase/features/products/domain/entities/product.dart';
import 'package:flutter_architecture_showcase/features/products/presentation/widgets/product_card.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final product = Product(
    id: 'product-1',
    name: 'Mechanical Keyboard',
    price: 2499.50,
    description: 'A mechanical keyboard with RGB lighting.',
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 2),
  );

  Widget createWidget({required Product product, VoidCallback? onTap}) {
    return MaterialApp(
      home: Scaffold(
        body: ProductCard(product: product, onTap: onTap),
      ),
    );
  }

  group('ProductCard', () {
    testWidgets('displays product information', (tester) async {
      await tester.pumpWidget(createWidget(product: product));

      expect(find.text('Mechanical Keyboard'), findsOneWidget);
      expect(
        find.text('A mechanical keyboard with RGB lighting.'),
        findsOneWidget,
      );
      expect(find.text('₹2499.50'), findsOneWidget);
    });

    testWidgets('hides description when it is null', (tester) async {
      final productWithoutDescription = Product(
        id: 'product-2',
        name: 'Mouse',
        price: 799,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      await tester.pumpWidget(createWidget(product: productWithoutDescription));

      expect(find.text('Mouse'), findsOneWidget);
      expect(find.text('₹799.00'), findsOneWidget);
      expect(find.byType(Text), findsNWidgets(2));
    });

    testWidgets('hides description when it is empty', (tester) async {
      final productWithEmptyDescription = Product(
        id: 'product-3',
        name: 'Monitor',
        price: 12000,
        description: '',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      await tester.pumpWidget(
        createWidget(product: productWithEmptyDescription),
      );

      expect(find.text('Monitor'), findsOneWidget);
      expect(find.text(''), findsNothing);
    });

    testWidgets('calls onTap when tapped', (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        createWidget(product: product, onTap: () => tapped = true),
      );

      await tester.tap(find.byType(ListTile));

      expect(tapped, isTrue);
    });

    testWidgets('does not throw when onTap is null', (tester) async {
      await tester.pumpWidget(createWidget(product: product));

      await tester.tap(find.byType(ListTile));

      expect(tester.takeException(), isNull);
    });
  });
}
