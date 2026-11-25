import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/widgets/app_notice.dart';
import '../../../core/widgets/app_segmented_control.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../../core/widgets/text_size_slider.dart';
import '../../settings/application/settings_provider.dart';
import '../../settings/domain/app_settings.dart';
import '../../settings/presentation/theme_pickers.dart';
import 'mushaf_edition_field.dart';
import 'page_turn_field.dart';
import 'reader_orientation.dart';
import 'reader_page_layout_field.dart';
import 'surah_frame_field.dart';

/// Opens the reading display options: reading mode, text size or page
/// layout, orientation, page turn, and theme.
Future<void> showDisplayOptions(BuildContext context) => AppSheet.show<void>(
  context: context,
  builder: (_) => const _DisplayOptions(),
);

class _DisplayOptions extends ConsumerWidget {
  const _DisplayOptions();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final settings = ref.watch(settingsProvider).value ?? const AppSettings();
    final notifier = ref.read(settingsProvider.notifier);
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(20, 0, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.displayOptions,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          Text(l10n.readerMode, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          AppSegmentedControl<ReaderMode>(
            value: settings.readerMode,
            onChanged: notifier.chooseReaderMode,
            segments: {
              ReaderMode.text: l10n.readerModeText,
              ReaderMode.printed: l10n.readerModePrinted,
            },
          ),
          const SizedBox(height: 4),
          Text(
            l10n.readerModeDescription,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (settings.textUntilOnline &&
              settings.readerMode == ReaderMode.text) ...[
            const SizedBox(height: 8),
            AppNotice(
              l10n.readerTextUntilOnline,
              icon: Icons.cloud_off_outlined,
            ),
          ],
          AnimatedSize(
            duration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : const Duration(milliseconds: 200),
            child: settings.readerMode == ReaderMode.printed
                ? const Padding(
                    padding: EdgeInsetsDirectional.only(top: 16, bottom: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        MushafEditionField(),
                        SizedBox(height: 12),
                        ReaderPageLayoutField(),
                      ],
                    ),
                  )
                : _TextSize(settings: settings),
          ),
          const SizedBox(height: 16),
          const SurahFrameField(),
          const SizedBox(height: 12),
          const PageTurnField(),
          // On a phone only; it brings its own gap.
          const ReaderOrientationTile(),
          const SizedBox(height: 12),
          const ThemePickers(),
        ],
      ),
    );
  }
}

/// Text size slider; only the typeset reader has a text size.
class _TextSize extends ConsumerWidget {
  const _TextSize({required this.settings});

  final AppSettings settings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(settingsProvider.notifier);
    return Padding(
      padding: const EdgeInsetsDirectional.only(top: 16),
      child: TextSizeSlider(
        title: context.l10n.textSize,
        hint: context.l10n.textSizeHint,
        value: settings.readerFontScale,
        min: AppSettings.minReaderFontScale,
        max: AppSettings.maxReaderFontScale,
        onChanged: (value) =>
            notifier.save(settings.copyWith(readerFontScale: value)),
      ),
    );
  }
}
