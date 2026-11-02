import '../../domain/entities/product.dart';

enum ProductStatus { initial, loading, success, failure }

class ProductState {
  const ProductState({
    this.status = ProductStatus.initial,
    this.products = const [],
    this.isMutating = false,
    this.errorMessage,
  });

  final ProductStatus status;
  final List<Product> products;
  final bool isMutating;
  final String? errorMessage;

  ProductState copyWith({
    ProductStatus? status,
    List<Product>? products,
    bool? isMutating,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ProductState(
      status: status ?? this.status,
      products: products ?? this.products,
      isMutating: isMutating ?? this.isMutating,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}
