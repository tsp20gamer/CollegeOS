import 'package:drift/drift.dart';

const _millisecondsPerDay = Duration.millisecondsPerDay;

/// Persists a local calendar date as an epoch-day integer.
///
/// Only the year, month, and day components are significant, so dates don't
/// shift when the device timezone changes.
final class EpochDayConverter extends TypeConverter<DateTime, int> {
  const EpochDayConverter();

  @override
  DateTime fromSql(int fromDb) {
    final utcDate = DateTime.fromMillisecondsSinceEpoch(
      fromDb * _millisecondsPerDay,
      isUtc: true,
    );
    return DateTime(utcDate.year, utcDate.month, utcDate.day);
  }

  @override
  int toSql(DateTime value) {
    return DateTime.utc(
          value.year,
          value.month,
          value.day,
        ).millisecondsSinceEpoch ~/
        _millisecondsPerDay;
  }
}

/// Persists a real instant as UTC milliseconds since the Unix epoch.
final class UtcDateTimeConverter extends TypeConverter<DateTime, int> {
  const UtcDateTimeConverter();

  @override
  DateTime fromSql(int fromDb) =>
      DateTime.fromMillisecondsSinceEpoch(fromDb, isUtc: true);

  @override
  int toSql(DateTime value) => value.toUtc().millisecondsSinceEpoch;
}

int currentUtcMilliseconds() => DateTime.now().toUtc().millisecondsSinceEpoch;
