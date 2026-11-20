import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/haptics/haptics.dart';
import '../../../core/haptics/haptics_provider.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/layout/adaptive_layout.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_group_card.dart';
import '../../../core/widgets/app_page_scaffold.dart';
import '../../../core/widgets/app_section_header.dart';
import '../../../core/widgets/app_select_field.dart';
import '../../../core/widgets/app_switch_tile.dart';
import '../../../core/widgets/text_size_slider.dart';
import '../../mushaf/presentation/reader_page_layout_field.dart';
import '../../mushaf/presentation/surah_frame_field.dart';
import '../application/settings_provider.dart';
import '../domain/app_settings.dart';
import 'settings_body.dart';
import 'theme_pickers.dart';

/// Everything about how the app looks and reads, in one place: the colours,
/// the language and digits, how big the text is, how the Mushaf is shown, and
/// how the app moves and feels.
class ViewSettingsPage extends ConsumerWidget {
  /// Creates the page.
  const ViewSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final notifier = ref.read(settingsProvider.notifier);
    final hapticsSupported = ref.watch(hapticsSupportedProvider).value ?? true;
    return AppPageScaffold(
      title: l10n.displayOptions,
      body: SettingsBody(
        builder: (context, settings) => ListView(
          padding: pagePadding(context),
          children: [
            AppSectionHeader(title: l10n.appearance),
            const AppCard(
              padding: EdgeInsetsDirectional.all(AppTokens.cardPadding),
              child: ThemePickers(),
            ),
            const SizedBox(height: settingsGap),
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
            const SizedBox(height: settingsGap),
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
              ],
            ),
            const SizedBox(height: _sectionGap),
            AppSectionHeader(title: l10n.textSize),
            AppCard(
              padding: const EdgeInsetsDirectional.all(AppTokens.cardPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextSizeSlider(
                    title: l10n.textSizeMushaf,
                    value: settings.readerFontScale,
                    min: AppSettings.minReaderFontScale,
                    max: AppSettings.maxReaderFontScale,
                    onChanged: (value) => notifier.save(
                      settings.copyWith(readerFontScale: value),
                    ),
                  ),
                  const SizedBox(height: settingsGap),
                  TextSizeSlider(
                    title: l10n.textSizeAdhkar,
                    value: settings.adhkarFontScale,
                    min: AppSettings.minReaderFontScale,
                    max: AppSettings.maxReaderFontScale,
                    hint: l10n.textSizeHint,
                    onChanged: (value) => notifier.save(
                      settings.copyWith(adhkarFontScale: value),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: _sectionGap),
            AppSectionHeader(title: l10n.reader),
            AppSelectField<StartupBehavior>(
              label: l10n.startup,
              value: settings.startupBehavior,
              options: [
                AppSelectOption(
                  value: StartupBehavior.reader,
                  label: l10n.startupMushaf,
                  icon: Icons.menu_book_outlined,
                ),
                AppSelectOption(
                  value: StartupBehavior.lastTab,
                  label: l10n.startupLastTab,
                  icon: Icons.history,
                ),
              ],
              onChanged: (value) =>
                  notifier.save(settings.copyWith(startupBehavior: value)),
            ),
            const SizedBox(height: settingsGap),
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
            const SizedBox(height: settingsGap),
            const ReaderPageLayoutField(),
            const SizedBox(height: settingsGap),
            const SurahFrameField(),
            const SizedBox(height: settingsGap),
            AppGroupCard(
              children: [
                AppSwitchTile(
                  value: settings.realisticPageTurn,
                  onChanged: (value) => notifier.save(
                    settings.copyWith(realisticPageTurn: value),
                  ),
                  icon: Icons.auto_stories_outlined,
                  title: l10n.realisticPageTurn,
                  subtitle: l10n.realisticPageTurnDescription,
                ),
              ],
            ),
            const SizedBox(height: _sectionGap),
            AppSectionHeader(title: l10n.settingsFeel),
            AppGroupCard(
              children: [
                AppSwitchTile(
                  value: settings.reduceMotion,
                  onChanged: (value) =>
                      notifier.save(settings.copyWith(reduceMotion: value)),
                  icon: Icons.motion_photos_off_outlined,
                  title: l10n.reduceMotion,
                  subtitle: l10n.reduceMotionDescription,
                ),
                AppSwitchTile(
                  value: hapticsSupported && settings.hapticsEnabled,
                  // A device with no vibration motor gets a switch that says
                  // so.
                  onChanged: hapticsSupported
                      ? (value) {
                          notifier.save(
                            settings.copyWith(hapticsEnabled: value),
                          );
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
          ],
        ),
      ),
    );
  }

  static const double _sectionGap = 28;
}
