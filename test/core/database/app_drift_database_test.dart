import 'package:drift/native.dart';
import 'package:flutter_architecture_showcase/core/database/app_drift_database.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDriftDatabase database;

  setUp(() async {
    database = AppDriftDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await database.close();
  });

  test('uses schema version 1', () {
    expect(database.schemaVersion, 1);
  });

  test('executes SQLite queries successfully', () async {
    final result = await database.customSelect('SELECT 1 AS value').getSingle();

    expect(result.read<int>('value'), 1);
  });
}
