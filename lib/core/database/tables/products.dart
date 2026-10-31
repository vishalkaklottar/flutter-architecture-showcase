import 'package:drift/drift.dart';

@DataClassName('ProductEntry')
class Products extends Table {
  TextColumn get id => text()();

  TextColumn get name => text()();

  RealColumn get price => real()();

  TextColumn get description => text().nullable()();

  IntColumn get createdAt => integer()();

  IntColumn get updatedAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  List<Set<Column<Object>>> get indexes => [
    {updatedAt},
  ];
}
