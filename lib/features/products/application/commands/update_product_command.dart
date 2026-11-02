import 'package:injectable/injectable.dart';

import '../../domain/entities/product.dart';
import '../../domain/repositories/product_repository.dart';

@lazySingleton
class UpdateProductCommand {
  const UpdateProductCommand(this._repository);

  final ProductRepository _repository;

  Future<void> execute({
    required String productId,
    required String name,
    required double price,
    String? description,
  }) async {
    final existing = await _repository.getProductById(productId);

    if (existing == null) {
      throw StateError('Product $productId does not exist.');
    }

    final updatedProduct = Product(
      id: existing.id,
      name: name,
      price: price,
      description: description,
      createdAt: existing.createdAt,
      updatedAt: DateTime.now(),
    );

    await _repository.updateProduct(updatedProduct);
  }
}
