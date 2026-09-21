import 'package:college_os/core/database/app_database.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'generated/schema.dart';

void main() {
  late SchemaVerifier verifier;

  setUpAll(() {
    verifier = SchemaVerifier(GeneratedHelper());
  });

  test('all historical schemas migrate to every later version', () async {
    const versions = GeneratedHelper.versions;
    for (final (index, fromVersion) in versions.indexed) {
      for (final toVersion in versions.skip(index + 1)) {
        final schema = await verifier.schemaAt(fromVersion);
        final database = AppDatabase.forTesting(schema.newConnection());
        await verifier.migrateAndValidate(database, toVersion);
        await database.close();
        schema.close();
      }
    }
  });
}
