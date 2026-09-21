enum ReminderOption {
  off,
  atTime,
  tenMinutesBefore,
  thirtyMinutesBefore,
  oneHourBefore,
  oneDayBefore,
  custom,
}

extension ReminderOptionLabel on ReminderOption {
  String get label => switch (this) {
    ReminderOption.off => 'Off',
    ReminderOption.atTime => 'At time',
    ReminderOption.tenMinutesBefore => '10 minutes before',
    ReminderOption.thirtyMinutesBefore => '30 minutes before',
    ReminderOption.oneHourBefore => '1 hour before',
    ReminderOption.oneDayBefore => '1 day before',
    ReminderOption.custom => 'Custom',
  };
}

DateTime? calculateReminderTime({
  required ReminderOption option,
  required DateTime eventTime,
  DateTime? customTime,
}) => switch (option) {
  ReminderOption.off => null,
  ReminderOption.atTime => eventTime,
  ReminderOption.tenMinutesBefore => eventTime.subtract(
    const Duration(minutes: 10),
  ),
  ReminderOption.thirtyMinutesBefore => eventTime.subtract(
    const Duration(minutes: 30),
  ),
  ReminderOption.oneHourBefore => eventTime.subtract(const Duration(hours: 1)),
  ReminderOption.oneDayBefore => eventTime.subtract(const Duration(days: 1)),
  ReminderOption.custom => customTime,
};

ReminderOption inferReminderOption(DateTime? reminder, DateTime eventTime) {
  if (reminder == null) return ReminderOption.off;
  final difference = eventTime.difference(reminder);
  if (difference == Duration.zero) return ReminderOption.atTime;
  if (difference == const Duration(minutes: 10)) {
    return ReminderOption.tenMinutesBefore;
  }
  if (difference == const Duration(minutes: 30)) {
    return ReminderOption.thirtyMinutesBefore;
  }
  if (difference == const Duration(hours: 1)) {
    return ReminderOption.oneHourBefore;
  }
  if (difference == const Duration(days: 1)) {
    return ReminderOption.oneDayBefore;
  }
  return ReminderOption.custom;
}
