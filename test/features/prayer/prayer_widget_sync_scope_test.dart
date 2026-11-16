import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mre_quran/features/prayer/application/prayer_provider.dart';
import 'package:mre_quran/features/prayer/domain/prayer_alerts.dart';
import 'package:mre_quran/features/prayer/presentation/prayer_widget_sync_scope.dart';
import 'package:mre_quran/features/settings/application/settings_provider.dart';
import 'package:mre_quran/features/settings/domain/app_settings.dart';
import 'package:mre_quran/l10n/generated/app_localizations.dart';

import '../../helpers/memory_settings_repository.dart';

/// Prayer state that never finishes loading.
class _Loading extends PrayerNotifier {
  @override
  Future<PrayerState> build() => Completer<PrayerState>().future;
}

/// Prayer state that loaded with no place chosen.
class _NoPlace extends PrayerNotifier {
  @override
  Future<PrayerState> build() async =>
      const PrayerState(settings: PrayerSettings());
}

void main() {
  /// Pumps the scope over [prayer] and returns what it sent to the widgets:
  /// one entry per update, null for "clear".
  Future<List<Object?>> sent(
    WidgetTester tester,
    PrayerNotifier Function() prayer,
  ) async {
    final updates = <Object?>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('net.mrecode.mre_quran/prayer_widget'),
      (call) async {
        updates.add(call.arguments);
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('net.mrecode.mre_quran/prayer_widget'),
        null,
      ),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          settingsRepositoryProvider.overrideWithValue(
            MemorySettingsRepository()..settings = const AppSettings(),
          ),
          prayerProvider.overrideWith(prayer),
        ],
        child: const MaterialApp(
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: PrayerWidgetSyncScope(child: SizedBox()),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    return updates;
  }

  testWidgets('while the app is still loading, the widgets keep their times', (
    tester,
  ) async {
    expect(await sent(tester, _Loading.new), isEmpty);
  });

  testWidgets('once loaded with no place, the widgets are cleared', (
    tester,
  ) async {
    expect(await sent(tester, _NoPlace.new), contains(null));
  });
}
