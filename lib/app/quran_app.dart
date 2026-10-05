import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/l10n/l10n.dart';
import '../core/theme/app_theme.dart';
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
      ),
    );
  }
}
