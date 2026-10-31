import 'package:drift/drift.dart';

import '../../../../core/database/app_drift_database.dart';
import '../../domain/entities/product.dart';
import '../models/product_model.dart';

abstract final class ProductMapper {
  static ProductModel fromData(ProductEntry data) {
    return ProductModel(
      id: data.id,
      name: data.name,
      price: data.price,
      description: data.description,
      createdAt: DateTime.fromMillisecondsSinceEpoch(data.createdAt),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(data.updatedAt),
    );
  }

  static ProductsCompanion toCompanion(Product product) {
    return ProductsCompanion.insert(
      id: product.id,
      name: product.name,
      price: product.price,
      description: Value(product.description),
      createdAt: product.createdAt.millisecondsSinceEpoch,
      updatedAt: product.updatedAt.millisecondsSinceEpoch,
    );
  }
}
