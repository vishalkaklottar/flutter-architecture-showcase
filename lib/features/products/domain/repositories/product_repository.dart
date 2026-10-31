import '../entities/product.dart';

abstract interface class ProductRepository {
  /// Returns all locally stored products.
  Future<List<Product>> getProducts();

  /// Observes local product changes.
  Stream<List<Product>> watchProducts();

  /// Returns a locally stored product by ID.
  Future<Product?> getProductById(String id);

  /// Creates a product locally and queues it for synchronization.
  Future<void> createProduct(Product product);

  /// Updates a product locally and queues it for synchronization.
  Future<void> updateProduct(Product product);

  /// Deletes a product locally and queues it for synchronization.
  Future<void> deleteProduct(String id);
}
