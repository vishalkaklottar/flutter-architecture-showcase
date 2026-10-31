import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';

import '../../../../../core/database/app_drift_database.dart';
import '../../mappers/product_mapper.dart';
import '../../models/product_model.dart';
import 'product_local_datasource.dart';

@LazySingleton(as: ProductLocalDataSource)
class DriftProductLocalDataSource implements ProductLocalDataSource {
  DriftProductLocalDataSource(this._database);

  final AppDriftDatabase _database;

  @override
  Future<List<ProductModel>> getProducts() async {
    final query = _database.select(_database.products)
      ..orderBy([(table) => OrderingTerm.desc(table.createdAt)]);

    final rows = await query.get();

    return rows.map(ProductMapper.fromData).toList();
  }

  @override
  Stream<List<ProductModel>> watchProducts() {
    final query = _database.select(_database.products)
      ..orderBy([(table) => OrderingTerm.desc(table.createdAt)]);

    return query.watch().map(
      (rows) => rows.map(ProductMapper.fromData).toList(),
    );
  }

  @override
  Future<ProductModel?> getProductById(String id) async {
    final query = _database.select(_database.products)
      ..where((table) => table.id.equals(id));

    final row = await query.getSingleOrNull();

    return row == null ? null : ProductMapper.fromData(row);
  }

  @override
  Future<T> transaction<T>(Future<T> Function() action) {
    return _database.transaction(action);
  }

  @override
  Future<void> insertProduct(ProductModel product) async {
    await _database
        .into(_database.products)
        .insert(ProductMapper.toCompanion(product));
  }

  @override
  Future<void> updateProduct(ProductModel product) async {
    await (_database.update(_database.products)
          ..where((table) => table.id.equals(product.id)))
        .write(ProductMapper.toCompanion(product));
  }

  @override
  Future<void> deleteProduct(String id) async {
    await (_database.delete(
      _database.products,
    )..where((table) => table.id.equals(id))).go();
  }
}
