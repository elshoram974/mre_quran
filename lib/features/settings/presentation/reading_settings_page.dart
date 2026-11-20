import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/layout/adaptive_layout.dart';
import '../../../core/widgets/app_group_card.dart';
import '../../../core/widgets/app_page_scaffold.dart';
import '../../../core/widgets/app_select_field.dart';
import '../../../core/widgets/app_switch_tile.dart';
import '../../mushaf/presentation/reader_page_layout_field.dart';
import '../../mushaf/presentation/surah_frame_field.dart';
import '../application/settings_provider.dart';
import '../domain/app_settings.dart';
import 'settings_body.dart';

/// How the Mushaf is shown, and what the app opens on.
class ReadingSettingsPage extends ConsumerWidget {
  /// Creates the page.
  const ReadingSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final notifier = ref.read(settingsProvider.notifier);
    return AppPageScaffold(
      title: l10n.settingsReading,
      body: SettingsBody(
        builder: (context, settings) => ListView(
          padding: pagePadding(context),
          children: [
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
          ],
        ),
      ),
    );
  }
}
