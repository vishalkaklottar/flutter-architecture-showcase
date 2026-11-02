import 'package:flutter/material.dart';

import '../../domain/entities/product.dart';
import 'product_card.dart';

class ProductListView extends StatelessWidget {
  const ProductListView({
    super.key,
    required this.products,
    required this.onProductTap,
  });

  final List<Product> products;
  final ValueChanged<Product> onProductTap;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: products.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final product = products[index];

        return ProductCard(
          product: product,
          onTap: () => onProductTap(product),
        );
      },
    );
  }
}
