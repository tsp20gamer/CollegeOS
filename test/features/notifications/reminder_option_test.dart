import 'package:college_os/features/notifications/domain/reminder_option.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final event = DateTime(2026, 8, 20, 10);

  test('calculates every relative reminder without date boundary bugs', () {
    expect(
      calculateReminderTime(option: ReminderOption.off, eventTime: event),
      isNull,
    );
    expect(
      calculateReminderTime(option: ReminderOption.atTime, eventTime: event),
      event,
    );
    expect(
      calculateReminderTime(
        option: ReminderOption.tenMinutesBefore,
        eventTime: event,
      ),
      DateTime(2026, 8, 20, 9, 50),
    );
    expect(
      calculateReminderTime(
        option: ReminderOption.thirtyMinutesBefore,
        eventTime: event,
      ),
      DateTime(2026, 8, 20, 9, 30),
    );
    expect(
      calculateReminderTime(
        option: ReminderOption.oneHourBefore,
        eventTime: event,
      ),
      DateTime(2026, 8, 20, 9),
    );
    expect(
      calculateReminderTime(
        option: ReminderOption.oneDayBefore,
        eventTime: event,
      ),
      DateTime(2026, 8, 19, 10),
    );
    final custom = DateTime(2026, 8, 18, 16, 45);
    expect(
      calculateReminderTime(
        option: ReminderOption.custom,
        eventTime: event,
        customTime: custom,
      ),
      custom,
    );
  });

  test('infers preset and custom reminder choices', () {
    expect(inferReminderOption(null, event), ReminderOption.off);
    expect(inferReminderOption(event, event), ReminderOption.atTime);
    expect(
      inferReminderOption(event.subtract(const Duration(minutes: 30)), event),
      ReminderOption.thirtyMinutesBefore,
    );
    expect(
      inferReminderOption(DateTime(2026, 8, 18, 16, 45), event),
      ReminderOption.custom,
    );
  });
}
