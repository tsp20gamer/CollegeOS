import 'package:college_os/core/database/app_database.dart';
import 'package:college_os/core/database/tables/app_settings.dart';
import 'package:drift/drift.dart';

part 'settings_dao.g.dart';

@DriftAccessor(tables: [AppSettings])
class SettingsDao extends DatabaseAccessor<AppDatabase>
    with _$SettingsDaoMixin {
  SettingsDao(super.attachedDatabase);

  Stream<AppSettingsRow> watchSettings() =>
      (select(appSettings)..where((row) => row.id.equals(1))).watchSingle();

  Future<AppSettingsRow> getSettings() =>
      (select(appSettings)..where((row) => row.id.equals(1))).getSingle();

  Future<void> save(AppSettingsCompanion settings) async {
    await into(
      appSettings,
    ).insertOnConflictUpdate(settings.copyWith(id: const Value(1)));
  }
}
