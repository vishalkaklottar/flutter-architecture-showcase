// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_drift_database.dart';

// ignore_for_file: type=lint
abstract class _$AppDriftDatabase extends GeneratedDatabase {
  _$AppDriftDatabase(QueryExecutor e) : super(e);
  $AppDriftDatabaseManager get managers => $AppDriftDatabaseManager(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [];
}

class $AppDriftDatabaseManager {
  final _$AppDriftDatabase _db;
  $AppDriftDatabaseManager(this._db);
}
