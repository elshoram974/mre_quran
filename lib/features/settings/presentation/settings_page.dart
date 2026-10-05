import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:liquidify/liquidify.dart';

import '../../../app/router.dart';
import '../../../core/l10n/l10n.dart';
import '../application/settings_provider.dart';
import '../domain/app_settings.dart';

/// Allows readers to choose visual and language preferences.
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    return settings.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) =>
          _SettingsError(onRetry: () => ref.invalidate(settingsProvider)),
      data: (value) => _SettingsContent(settings: value),
    );
  }
}

class _SettingsError extends StatelessWidget {
  const _SettingsError({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(context.l10n.settingsLoadError, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          FilledButton(onPressed: onRetry, child: Text(context.l10n.retry)),
        ],
      ),
    ),
  );
}

class _SettingsContent extends ConsumerWidget {
  const _SettingsContent({required this.settings});
  final AppSettings settings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final notifier = ref.read(settingsProvider.notifier);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 112),
      children: [
        Text(l10n.appearance, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        _SettingsCard(
          child: DropdownButtonFormField<AppThemePreference>(
            initialValue: settings.theme,
            isExpanded: true,
            decoration: InputDecoration(labelText: l10n.theme),
            items: [
              DropdownMenuItem(
                value: AppThemePreference.system,
                child: Text(l10n.themeSystem),
              ),
              DropdownMenuItem(
                value: AppThemePreference.light,
                child: Text(l10n.themeLight),
              ),
              DropdownMenuItem(
                value: AppThemePreference.dark,
                child: Text(l10n.themeDark),
              ),
              DropdownMenuItem(
                value: AppThemePreference.sepia,
                child: Text(l10n.themeSepia),
              ),
            ],
            onChanged: (value) {
              if (value != null) {
                notifier.update(settings.copyWith(theme: value));
              }
            },
          ),
        ),
        const SizedBox(height: 12),
        _SettingsCard(
          child: DropdownButtonFormField<String>(
            initialValue: settings.localeCode,
            isExpanded: true,
            decoration: InputDecoration(labelText: l10n.language),
            items: [
              DropdownMenuItem(value: 'ar', child: Text(l10n.languageArabic)),
              DropdownMenuItem(value: 'en', child: Text(l10n.languageEnglish)),
            ],
            onChanged: (value) {
              if (value != null) {
                notifier.update(settings.copyWith(localeCode: value));
              }
            },
          ),
        ),
        const SizedBox(height: 12),
        _SettingsCard(
          child: SwitchListTile.adaptive(
            value: settings.reduceMotion,
            onChanged: (value) =>
                notifier.update(settings.copyWith(reduceMotion: value)),
            title: Text(l10n.reduceMotion),
            subtitle: Text(l10n.reduceMotionDescription),
          ),
        ),
        const SizedBox(height: 12),
        _SettingsCard(
          child: SwitchListTile.adaptive(
            value: settings.useArabicDigits,
            onChanged: (value) =>
                notifier.update(settings.copyWith(useArabicDigits: value)),
            title: Text(l10n.arabicDigits),
            subtitle: Text(l10n.arabicDigitsDescription),
          ),
        ),
        const SizedBox(height: 28),
        Text(l10n.privacy, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        _SettingsCard(
          child: ListTile(
            leading: const Icon(Icons.shield_outlined),
            title: Text(l10n.crashReports),
            subtitle: Text(l10n.crashReportsDescription),
          ),
        ),
        const SizedBox(height: 12),
        _SettingsCard(
          child: ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text(l10n.about),
            trailing: const Icon(Icons.chevron_left),
            onTap: () => context.push(AppRoute.about.path),
          ),
        ),
      ],
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) =>
      Card(
        child: Padding(padding: const EdgeInsets.all(8), child: child),
      ).liquidGlass(
        options: LiquidGlassOptions.frosted(
          blur: 10,
          interactive: !MediaQuery.disableAnimationsOf(context),
        ),
      );
}
