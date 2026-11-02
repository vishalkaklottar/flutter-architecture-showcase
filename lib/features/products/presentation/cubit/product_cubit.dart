import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../application/commands/create_product_command.dart';
import '../../application/commands/delete_product_command.dart';
import '../../application/commands/update_product_command.dart';
import '../../application/queries/watch_products_query.dart';
import '../../domain/entities/product.dart';
import 'product_state.dart';

@injectable
class ProductCubit extends Cubit<ProductState> {
  ProductCubit({
    required this._createProduct,
    required this._updateProduct,
    required this._deleteProduct,
    required this._watchProducts,
  }) : super(const ProductState());

  final CreateProductCommand _createProduct;
  final UpdateProductCommand _updateProduct;
  final DeleteProductCommand _deleteProduct;
  final WatchProductsQuery _watchProducts;

  StreamSubscription<List<Product>>? _productsSubscription;

  Future<void> loadProducts() async {
    emit(state.copyWith(status: ProductStatus.loading, clearError: true));

    await _productsSubscription?.cancel();

    if (isClosed) return;

    _productsSubscription = _watchProducts.execute().listen(
      (products) {
        if (isClosed) return;

        emit(
          state.copyWith(
            status: ProductStatus.success,
            products: products,
            clearError: true,
          ),
        );
      },
      onError: (Object error) {
        if (isClosed) return;

        emit(
          state.copyWith(
            status: ProductStatus.failure,
            errorMessage: error.toString(),
          ),
        );
      },
    );
  }

  Future<bool> addProduct({
    required String name,
    required double price,
    String? description,
  }) {
    return _performMutation(
      () => _createProduct.execute(
        name: name,
        price: price,
        description: description,
      ),
    );
  }

  Future<bool> updateProduct({
    required String productId,
    required String name,
    required double price,
    String? description,
  }) {
    return _performMutation(
      () => _updateProduct.execute(
        productId: productId,
        name: name,
        price: price,
        description: description,
      ),
    );
  }

  Future<bool> deleteProduct(String id) {
    return _performMutation(() => _deleteProduct.execute(id));
  }

  Future<bool> _performMutation(Future<void> Function() action) async {
    if (state.isMutating || isClosed) return false;

    emit(state.copyWith(isMutating: true, clearError: true));

    try {
      await action();
      return true;
    } catch (error) {
      if (!isClosed) {
        emit(state.copyWith(errorMessage: error.toString()));
      }

      return false;
    } finally {
      if (!isClosed) {
        emit(state.copyWith(isMutating: false));
      }
    }
  }

  @override
  Future<void> close() async {
    await _productsSubscription?.cancel();
    return super.close();
  }
}
