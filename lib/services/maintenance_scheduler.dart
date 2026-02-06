import 'package:reeflynk/models/maintenance_task.dart';
import 'package:reeflynk/models/maintenance_completion.dart';

class MaintenanceScheduler {
  static DateTime getNextDueDate(MaintenanceTask task, MaintenanceCompletion? lastCompletion) {
    final timeParts = task.preferredTime.split(':');
    final hour = int.parse(timeParts[0]);
    final minute = int.parse(timeParts[1]);

    if (lastCompletion == null) {
      // No completion yet — due now at the preferred time
      final now = DateTime.now();
      var due = DateTime(now.year, now.month, now.day, hour, minute);
      if (due.isBefore(now)) {
        due = due.add(const Duration(days: 1));
      }
      return due;
    }

    final lastDone = lastCompletion.completedAt;
    DateTime nextDue;

    switch (task.frequency) {
      case 'daily':
        nextDue = DateTime(lastDone.year, lastDone.month, lastDone.day, hour, minute)
            .add(const Duration(days: 1));
        break;
      case 'weekly':
        nextDue = DateTime(lastDone.year, lastDone.month, lastDone.day, hour, minute)
            .add(const Duration(days: 7));
        if (task.preferredDay != null) {
          // Adjust to preferred day of week (1=Monday, 7=Sunday)
          while (nextDue.weekday != task.preferredDay) {
            nextDue = nextDue.add(const Duration(days: 1));
          }
        }
        break;
      case 'biweekly':
        nextDue = DateTime(lastDone.year, lastDone.month, lastDone.day, hour, minute)
            .add(const Duration(days: 14));
        if (task.preferredDay != null) {
          while (nextDue.weekday != task.preferredDay) {
            nextDue = nextDue.add(const Duration(days: 1));
          }
        }
        break;
      case 'monthly':
        var nextMonth = lastDone.month + 1;
        var nextYear = lastDone.year;
        if (nextMonth > 12) {
          nextMonth = 1;
          nextYear++;
        }
        final day = task.preferredDay ?? lastDone.day;
        final daysInMonth = DateTime(nextYear, nextMonth + 1, 0).day;
        nextDue = DateTime(nextYear, nextMonth, day.clamp(1, daysInMonth), hour, minute);
        break;
      default:
        nextDue = DateTime(lastDone.year, lastDone.month, lastDone.day, hour, minute)
            .add(const Duration(days: 7));
    }

    return nextDue;
  }

  static bool isOverdue(MaintenanceTask task, MaintenanceCompletion? lastCompletion) {
    final nextDue = getNextDueDate(task, lastCompletion);
    return nextDue.isBefore(DateTime.now());
  }

  static DateTime getReminderTime(MaintenanceTask task, MaintenanceCompletion? lastCompletion) {
    final nextDue = getNextDueDate(task, lastCompletion);
    return nextDue.subtract(Duration(hours: task.remindBeforeHours));
  }
}
