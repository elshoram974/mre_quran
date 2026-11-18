import 'package:mre_quran/core/hints/hints.dart';

/// Every hint turned off, for tests about something else: no hint sheet
/// covers the screen they check.
class NoHintsRepository implements HintsRepository {
  @override
  Future<Set<AppHint>> dismissed() async => AppHint.values.toSet();

  @override
  Future<void> dismiss(AppHint hint) async {}
}
