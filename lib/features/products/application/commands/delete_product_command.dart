import 'package:injectable/injectable.dart';

import '../../domain/repositories/product_repository.dart';

@lazySingleton
class DeleteProductCommand {
  const DeleteProductCommand(this._repository);

  final ProductRepository _repository;

  Future<void> execute(String productId) {
    return _repository.deleteProduct(productId);
  }
}
