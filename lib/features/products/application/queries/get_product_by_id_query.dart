import 'package:injectable/injectable.dart';

import '../../domain/entities/product.dart';
import '../../domain/repositories/product_repository.dart';

@lazySingleton
class GetProductByIdQuery {
  const GetProductByIdQuery(this._repository);

  final ProductRepository _repository;

  Future<Product?> execute(String productId) {
    return _repository.getProductById(productId);
  }
}
