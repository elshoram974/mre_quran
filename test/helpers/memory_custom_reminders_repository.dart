import 'package:mre_quran/features/reminders/data/custom_reminders_repository.dart';
import 'package:mre_quran/features/reminders/domain/custom_reminder.dart';

/// Keeps the reminders the person made in memory.
class MemoryCustomRemindersRepository implements CustomRemindersRepository {
  List<CustomReminder> reminders = [];

  @override
  Future<List<CustomReminder>> load() async => reminders;

  @override
  Future<void> save(List<CustomReminder> value) async => reminders = value;
}
