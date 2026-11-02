import 'package:injectable/injectable.dart';

import '../../domain/entities/product.dart';
import '../../domain/repositories/product_repository.dart';

@lazySingleton
class GetProductsQuery {
  const GetProductsQuery(this._repository);

  final ProductRepository _repository;

  Future<List<Product>> execute() {
    return _repository.getProducts();
  }
}
