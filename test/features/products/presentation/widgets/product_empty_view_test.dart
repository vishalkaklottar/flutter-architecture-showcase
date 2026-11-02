import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_architecture_showcase/features/products/presentation/widgets/product_empty_view.dart';

void main() {
  Widget createWidget() {
    return const MaterialApp(home: Scaffold(body: ProductEmptyView()));
  }

  group('ProductEmptyView', () {
    testWidgets('displays empty state message', (tester) async {
      await tester.pumpWidget(createWidget());

      expect(find.text('No products yet'), findsOneWidget);
      expect(
        find.text('Add your first product to get started.'),
        findsOneWidget,
      );
    });

    testWidgets('displays inventory icon', (tester) async {
      await tester.pumpWidget(createWidget());

      expect(find.byIcon(Icons.inventory_2_outlined), findsOneWidget);
    });

    testWidgets('centers the empty state content', (tester) async {
      await tester.pumpWidget(createWidget());

      expect(find.byType(ProductEmptyView), findsOneWidget);
      expect(find.text('No products yet'), findsOneWidget);
      expect(
        find.text('Add your first product to get started.'),
        findsOneWidget,
      );
    });
  });
}
