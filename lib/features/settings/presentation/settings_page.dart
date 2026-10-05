import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/layout/adaptive_layout.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_select_field.dart';

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
      padding: pagePadding(context),
      children: [
        Text(l10n.appearance, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        AppSelectField<AppThemePreference>(
          label: l10n.theme,
          value: settings.theme,
          options: [
            AppSelectOption(
              value: AppThemePreference.system,
              label: l10n.themeSystem,
              icon: Icons.brightness_auto_outlined,
            ),
            AppSelectOption(
              value: AppThemePreference.light,
              label: l10n.themeLight,
              icon: Icons.light_mode_outlined,
            ),
            AppSelectOption(
              value: AppThemePreference.dark,
              label: l10n.themeDark,
              icon: Icons.dark_mode_outlined,
            ),
            AppSelectOption(
              value: AppThemePreference.sepia,
              label: l10n.themeSepia,
              icon: Icons.auto_stories_outlined,
            ),
          ],
          onChanged: (value) => notifier.save(settings.copyWith(theme: value)),
        ),
        const SizedBox(height: 12),
        AppSelectField<String>(
          label: l10n.language,
          value: settings.localeCode,
          options: [
            AppSelectOption(value: 'ar', label: l10n.languageArabic),
            AppSelectOption(value: 'en', label: l10n.languageEnglish),
          ],
          onChanged: (value) =>
              notifier.save(settings.copyWith(localeCode: value)),
        ),
        const SizedBox(height: 12),
        _SettingsCard(
          child: SwitchListTile.adaptive(
            value: settings.reduceMotion,
            onChanged: (value) =>
                notifier.save(settings.copyWith(reduceMotion: value)),
            title: Text(l10n.reduceMotion),
            subtitle: Text(l10n.reduceMotionDescription),
          ),
        ),
        const SizedBox(height: 12),
        _SettingsCard(
          child: SwitchListTile.adaptive(
            value: settings.useArabicDigits,
            onChanged: (value) =>
                notifier.save(settings.copyWith(useArabicDigits: value)),
            title: Text(l10n.arabicDigits),
            subtitle: Text(l10n.arabicDigitsDescription),
          ),
        ),
        const SizedBox(height: 28),
        Text(l10n.privacy, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        _SettingsCard(
          child: SwitchListTile.adaptive(
            value: settings.crashReportsEnabled,
            onChanged: (value) =>
                notifier.save(settings.copyWith(crashReportsEnabled: value)),
            secondary: const Icon(Icons.shield_outlined),
            title: Text(l10n.crashReports),
            subtitle: Text(l10n.crashReportsDescription),
          ),
        ),
        const SizedBox(height: 12),
        _SettingsCard(
          child: ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text(l10n.about),
            trailing: const Icon(Icons.chevron_right),
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
  Widget build(BuildContext context) => AppCard(child: child);
}
