import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/haptics/haptics.dart';
import '../core/l10n/l10n.dart';
import '../core/theme/app_theme.dart';
import '../features/adhan/application/adhan_providers.dart';
import '../features/adhan/presentation/adhan_suggestion_scope.dart';
import '../features/startup/application/startup_providers.dart';
import '../features/startup/presentation/launch_gate.dart';
import '../features/adhkar/presentation/adhkar_widget_sync_scope.dart';
import '../features/fasting/application/fasting_reminders_provider.dart';
import '../features/prayer/application/prayer_provider.dart';
import '../features/prayer/presentation/prayer_widget_sync_scope.dart';
import '../features/adhkar/application/reminders_provider.dart';
import '../features/adhkar/application/weekly_reminders_provider.dart';
import '../features/settings/application/settings_provider.dart';
import '../features/settings/domain/app_settings.dart';
import '../l10n/generated/app_localizations.dart';
import 'app_shortcuts.dart';
import 'reminder_opener.dart';
import 'router.dart';
import '../core/notifications/reminder_scheduler_provider.dart';

class QuranApp extends ConsumerWidget {
  const QuranApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppSettings settings =
        ref.watch(settingsProvider).value ?? const AppSettings();
    ref.listen(settingsProvider, (_, next) {
      next.whenData((value) {
        Haptics.enabled = value.hapticsEnabled;
        unawaited(Haptics.syncWidgetSetting(value.hapticsEnabled));
        unawaited(
          ref
              .read(crashReporterProvider)
              .setCollectionEnabled(value.crashReportsEnabled),
        );
      });
    });
    // Keeps the reminder schedule in step with the saved choices and language
    // from the first frame, and opens the list of a tapped reminder.
    ref
      ..listen(remindersProvider, (_, _) {})
      ..listen(weeklyRemindersProvider, (_, _) {})
      ..listen(prayerProvider, (_, _) {})
      ..listen(fastingRemindersProvider, (_, _) {})
      ..listen(reminderTapsProvider, (_, next) {
        final tap = next.value;
        if (tap != null) {
          ref.read(opensOnReaderProvider.notifier).openedElsewhere();
          unawaited(
            openReminder(
              ref.read(routerProvider),
              tap.payload,
              openSurah: ref.read(reminderSurahOpenerProvider),
            ),
          );
        }
      })
      ..listen(adhanTapsProvider, (_, next) {
        final tap = next.value;
        if (tap != null) {
          ref.read(opensOnReaderProvider.notifier).openedElsewhere();
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) {
              unawaited(
                openReminder(
                  ref.read(routerProvider),
                  tap.payload,
                  openSurah: ref.read(reminderSurahOpenerProvider),
                ),
              );
            }
          });
          WidgetsBinding.instance.ensureVisualUpdate();
        }
      });
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        disableAnimations:
            MediaQuery.disableAnimationsOf(context) || settings.reduceMotion,
      ),
      child: MaterialApp.router(
        onGenerateTitle: (context) => context.l10n.appTitle,
        debugShowCheckedModeBanner: false,
        locale: settings.locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: appLocalizationsDelegates,
        // A change of paper or accent animates: MaterialApp interpolates
        // the themes, extensions included.
        theme: AppTheme.of(settings.theme.dayPaper, settings.accent),
        darkTheme: AppTheme.of(settings.theme.nightPaper, settings.accent),
        themeMode: settings.materialThemeMode,
        routerConfig: ref.watch(routerProvider),
        // The native launch screen stays until the first screen is ready.
        builder: (context, child) => _SystemBars(
          child: LaunchGate(
            child: AdhanSuggestionScope(
              child: AppShortcutsScope(
                child: AdhkarWidgetSyncScope(
                  child: PrayerWidgetSyncScope(child: child!),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The app draws edge to edge (required from Android 15): the status and
/// navigation bars are transparent over the app's own surface, with icons
/// that contrast with the current theme. Screens keep clear of the bars with
/// the system insets.
class _SystemBars extends StatelessWidget {
  const _SystemBars({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final icons = dark ? Brightness.light : Brightness.dark;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: icons,
        statusBarBrightness: dark ? Brightness.dark : Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarDividerColor: Colors.transparent,
        systemNavigationBarIconBrightness: icons,
        // No grey scrim behind the three-button bar: the paper shows through
        // and the buttons take the theme's contrast instead.
        systemNavigationBarContrastEnforced: false,
        systemStatusBarContrastEnforced: false,
      ),
      child: child,
    );
  }
}
