import 'package:injectable/injectable.dart';

import '../../../../core/utils/id_generator.dart';
import '../../domain/entities/product.dart';
import '../../domain/repositories/product_repository.dart';

@lazySingleton
class CreateProductCommand {
  const CreateProductCommand(this._repository);

  final ProductRepository _repository;

  Future<void> execute({
    required String name,
    required double price,
    String? description,
  }) async {
    final now = DateTime.now();

    final product = Product(
      id: IdGenerator.generate(),
      name: name,
      price: price,
      description: description,
      createdAt: now,
      updatedAt: now,
    );

    await _repository.createProduct(product);
  }
}
