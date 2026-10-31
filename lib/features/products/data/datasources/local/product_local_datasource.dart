import '../../models/product_model.dart';

abstract interface class ProductLocalDataSource {
  Future<List<ProductModel>> getProducts();

  Stream<List<ProductModel>> watchProducts();

  Future<ProductModel?> getProductById(String id);

  Future<T> transaction<T>(Future<T> Function() action);

  Future<void> insertProduct(ProductModel product);

  Future<void> updateProduct(ProductModel product);

  Future<void> deleteProduct(String id);
}
