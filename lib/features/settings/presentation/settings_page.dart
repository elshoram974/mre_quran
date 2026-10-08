import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/haptics/haptics.dart';
import '../../../core/haptics/haptics_provider.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/layout/adaptive_layout.dart';
import '../../../core/widgets/app_group_card.dart';
import '../../../core/widgets/app_section_header.dart';
import '../../../core/widgets/app_select_field.dart';
import '../../../core/widgets/app_switch_tile.dart';
import '../../../core/widgets/app_tile_card.dart';

import '../../adhkar/presentation/reminders_sheet.dart';
import '../application/settings_provider.dart';
import '../../mushaf/presentation/mushaf_style_field.dart';
import '../../mushaf/presentation/reader_page_layout_field.dart';
import '../../mushaf/presentation/offline_packs_section.dart';
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

  static const double _gap = 12;
  static const double _sectionGap = 28;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final notifier = ref.read(settingsProvider.notifier);
    final hapticsSupported = ref.watch(hapticsSupportedProvider).value ?? true;
    return ListView(
      padding: pagePadding(context),
      children: [
        AppSectionHeader(title: l10n.appearance),
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
        const SizedBox(height: _gap),
        AppSelectField<String>(
          label: l10n.language,
          value: settings.localeCode,
          options: [
            AppSelectOption(
              value: 'ar',
              label: l10n.languageArabic,
              icon: Icons.translate,
            ),
            AppSelectOption(
              value: 'en',
              label: l10n.languageEnglish,
              icon: Icons.translate,
            ),
          ],
          onChanged: (value) =>
              notifier.save(settings.copyWith(localeCode: value)),
        ),
        const SizedBox(height: _gap),
        AppGroupCard(
          children: [
            AppSwitchTile(
              value: settings.useArabicDigits,
              onChanged: (value) =>
                  notifier.save(settings.copyWith(useArabicDigits: value)),
              icon: Icons.onetwothree,
              title: l10n.arabicDigits,
              subtitle: l10n.arabicDigitsDescription,
            ),
            AppSwitchTile(
              value: settings.reduceMotion,
              onChanged: (value) =>
                  notifier.save(settings.copyWith(reduceMotion: value)),
              icon: Icons.motion_photos_off_outlined,
              title: l10n.reduceMotion,
              subtitle: l10n.reduceMotionDescription,
            ),
          ],
        ),
        const SizedBox(height: _sectionGap),
        AppSectionHeader(title: l10n.settingsReading),
        AppSelectField<StartupBehavior>(
          label: l10n.startup,
          value: settings.startupBehavior,
          options: [
            AppSelectOption(
              value: StartupBehavior.lastTab,
              label: l10n.startupLastTab,
              icon: Icons.history,
            ),
            AppSelectOption(
              value: StartupBehavior.reader,
              label: l10n.startupMushaf,
              icon: Icons.menu_book_outlined,
            ),
          ],
          onChanged: (value) =>
              notifier.save(settings.copyWith(startupBehavior: value)),
        ),
        const SizedBox(height: _gap),
        AppSelectField<ReaderMode>(
          label: l10n.readerMode,
          value: settings.readerMode,
          options: [
            AppSelectOption(
              value: ReaderMode.text,
              label: l10n.readerModeText,
              icon: Icons.text_fields,
            ),
            AppSelectOption(
              value: ReaderMode.printed,
              label: l10n.readerModePrinted,
              icon: Icons.menu_book_outlined,
            ),
          ],
          onChanged: (value) =>
              notifier.save(settings.copyWith(readerMode: value)),
        ),
        const SizedBox(height: _gap),
        const MushafStyleField(),
        const SizedBox(height: _gap),
        const ReaderPageLayoutField(),
        const SizedBox(height: _gap),
        AppGroupCard(
          children: [
            AppSwitchTile(
              value: settings.realisticPageTurn,
              onChanged: (value) =>
                  notifier.save(settings.copyWith(realisticPageTurn: value)),
              icon: Icons.auto_stories_outlined,
              title: l10n.realisticPageTurn,
              subtitle: l10n.realisticPageTurnDescription,
            ),
          ],
        ),
        const SizedBox(height: _sectionGap),
        const OfflinePacksSection(),
        const SizedBox(height: _sectionGap),
        AppSectionHeader(title: l10n.settingsAlerts),
        AppTileCard(
          icon: Icons.access_time_rounded,
          title: l10n.prayerTimesTitle,
          onTap: () => context.push(AppRoute.prayerTimes.path),
        ),
        const SizedBox(height: _gap),
        AppTileCard(
          icon: Icons.notifications_none_outlined,
          title: l10n.adhkarReminders,
          onTap: () => RemindersSheet.show(context),
        ),
        const SizedBox(height: _gap),
        AppGroupCard(
          children: [
            AppSwitchTile(
              value: hapticsSupported && settings.hapticsEnabled,
              // A device with no vibration motor gets a switch that says so.
              onChanged: hapticsSupported
                  ? (value) {
                      notifier.save(settings.copyWith(hapticsEnabled: value));
                      // Let the person feel what they just turned on.
                      Haptics.enabled = value;
                      if (value) Haptics.step();
                    }
                  : null,
              icon: Icons.vibration,
              title: l10n.settingsHaptics,
              subtitle: hapticsSupported
                  ? l10n.settingsHapticsHint
                  : l10n.settingsHapticsUnsupported,
            ),
          ],
        ),
        const SizedBox(height: _sectionGap),
        AppSectionHeader(title: l10n.privacy),
        AppGroupCard(
          children: [
            AppSwitchTile(
              value: settings.crashReportsEnabled,
              onChanged: (value) =>
                  notifier.save(settings.copyWith(crashReportsEnabled: value)),
              icon: Icons.shield_outlined,
              title: l10n.crashReports,
              subtitle: l10n.crashReportsDescription,
            ),
          ],
        ),
        const SizedBox(height: _gap),
        AppTileCard(
          icon: Icons.info_outline,
          title: l10n.about,
          onTap: () => context.push(AppRoute.about.path),
        ),
      ],
    );
  }
}
