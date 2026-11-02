import 'package:injectable/injectable.dart';

import '../../domain/entities/product.dart';
import '../../domain/repositories/product_repository.dart';

@lazySingleton
class WatchProductsQuery {
  const WatchProductsQuery(this._repository);

  final ProductRepository _repository;

  Stream<List<Product>> execute() {
    return _repository.watchProducts();
  }
}
