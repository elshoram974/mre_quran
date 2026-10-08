import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/l10n/l10n.dart';
import '../core/theme/app_theme.dart';
import '../features/adhkar/application/prayer_reminders_provider.dart';
import '../features/adhkar/application/reminders_provider.dart';
import '../features/settings/application/settings_provider.dart';
import '../features/settings/domain/app_settings.dart';
import '../l10n/generated/app_localizations.dart';
import 'router.dart';

class QuranApp extends ConsumerWidget {
  const QuranApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppSettings settings =
        ref.watch(settingsProvider).value ?? const AppSettings();
    ref.listen(settingsProvider, (_, next) {
      next.whenData((value) {
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
      ..listen(prayerRemindersProvider, (_, _) {})
      ..listen(reminderTapsProvider, (_, next) {
        final path = next.value == null
            ? null
            : AppRoute.fromReminderPayload(next.value!);
        if (path != null) unawaited(ref.read(routerProvider).push<void>(path));
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
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        theme: settings.theme == AppThemePreference.sepia
            ? AppTheme.sepia
            : AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: settings.materialThemeMode,
        routerConfig: ref.watch(routerProvider),
        builder: (context, child) => _SystemBars(child: child!),
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
