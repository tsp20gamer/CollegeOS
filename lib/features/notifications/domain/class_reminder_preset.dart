/// Bounds for a class reminder's lead time, in minutes before the class start.
///
/// Mirrored by the `reminder_minutes_before` CHECK constraint on
/// `timetable_entries`, so the database, the form and backups agree on exactly
/// one range.
const int minClassReminderLeadMinutes = 0;
const int maxClassReminderLeadMinutes = 7 * 24 * 60;

/// How far ahead CollegeOS looks for a class's next occurrence.
///
/// A weekly class always has an occurrence inside two weeks unless the semester
/// or a long closure interrupts it, and each scheduled alarm is rebuilt the next
/// time the app runs.
const int maxClassReminderLookaheadDays = 21;

/// Reminder choices offered for a timetable class.
enum ClassReminderPreset {
  off,
  atStart,
  fiveMinutesBefore,
  tenMinutesBefore,
  fifteenMinutesBefore,
  thirtyMinutesBefore,
  oneHourBefore,
  custom,
}

extension ClassReminderPresetLabel on ClassReminderPreset {
  String get label => switch (this) {
    ClassReminderPreset.off => 'Off',
    ClassReminderPreset.custom => 'Custom…',
    _ => formatClassReminderLead(minutesBefore!),
  };

  /// Lead time this preset stores, or `null` for [off] and [custom].
  int? get minutesBefore => switch (this) {
    ClassReminderPreset.atStart => 0,
    ClassReminderPreset.fiveMinutesBefore => 5,
    ClassReminderPreset.tenMinutesBefore => 10,
    ClassReminderPreset.fifteenMinutesBefore => 15,
    ClassReminderPreset.thirtyMinutesBefore => 30,
    ClassReminderPreset.oneHourBefore => 60,
    ClassReminderPreset.off || ClassReminderPreset.custom => null,
  };
}

/// Preset that matches a stored lead time, falling back to [custom] for any
/// other value so an existing reminder is never silently rounded.
ClassReminderPreset inferClassReminderPreset(int? minutesBefore) {
  if (minutesBefore == null) return ClassReminderPreset.off;
  if (minutesBefore < minClassReminderLeadMinutes ||
      minutesBefore > maxClassReminderLeadMinutes) {
    return ClassReminderPreset.custom;
  }
  for (final preset in ClassReminderPreset.values) {
    if (preset.minutesBefore == minutesBefore) return preset;
  }
  return ClassReminderPreset.custom;
}

/// Lead time in words: `At class start`, `5 min before`, `1 h 15 min before`.
String formatClassReminderLead(int minutesBefore) {
  if (minutesBefore <= 0) return 'At class start';
  final hours = minutesBefore ~/ 60;
  final minutes = minutesBefore % 60;
  if (hours == 0) return '$minutes min before';
  if (minutes == 0) return '$hours h before';
  return '$hours h $minutes min before';
}
