import 'package:flutter_test/flutter_test.dart';
import 'package:mre_quran/app/router.dart';
import 'package:mre_quran/features/settings/domain/app_settings.dart';
import 'package:mre_quran/features/startup/application/startup_providers.dart';

void main() {
  group('resolveInitialLocation', () {
    test('opens the Mushaf when asked to, whatever was saved', () {
      expect(
        resolveInitialLocation(StartupBehavior.reader, AppRoute.settings.path),
        AppRoute.reader.path,
      );
    });

    test('reopens the last tab', () {
      expect(
        resolveInitialLocation(StartupBehavior.lastTab, AppRoute.duas.path),
        AppRoute.duas.path,
      );
    });

    test('falls back to the Mushaf with nothing or an unknown path saved', () {
      expect(
        resolveInitialLocation(StartupBehavior.lastTab, null),
        AppRoute.reader.path,
      );
      expect(
        resolveInitialLocation(StartupBehavior.lastTab, '/about'),
        AppRoute.reader.path,
      );
    });
  });
}
