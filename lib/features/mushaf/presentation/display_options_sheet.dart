import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/widgets/app_segmented_control.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../../core/widgets/app_switch_tile.dart';
import '../../settings/application/settings_provider.dart';
import '../../settings/domain/app_settings.dart';

/// Opens the reading display options: text size and theme.
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
          Text(l10n.textSize, style: Theme.of(context).textTheme.titleSmall),
          Row(
            children: [
              const Icon(Icons.text_decrease, size: 20),
              Expanded(
                child: Slider.adaptive(
                  value: settings.readerFontScale,
                  min: 0.8,
                  max: 1.6,
                  divisions: 8,
                  label: '${(settings.readerFontScale * 100).round()}%',
                  onChanged: (value) =>
                      notifier.save(settings.copyWith(readerFontScale: value)),
                ),
              ),
              const Icon(Icons.text_increase, size: 20),
            ],
          ),
          const SizedBox(height: 4),
          AppSwitchTile(
            value: settings.realisticPageTurn,
            onChanged: (value) =>
                notifier.save(settings.copyWith(realisticPageTurn: value)),
            title: l10n.realisticPageTurn,
            subtitle: l10n.realisticPageTurnDescription,
          ),
          const SizedBox(height: 12),
          Text(l10n.theme, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          AppSegmentedControl<AppThemePreference>(
            value: settings.theme,
            onChanged: (value) =>
                notifier.save(settings.copyWith(theme: value)),
            segments: {
              AppThemePreference.light: l10n.themeLight,
              AppThemePreference.sepia: l10n.themeSepia,
              AppThemePreference.dark: l10n.themeDark,
              AppThemePreference.system: l10n.themeSystem,
            },
          ),
        ],
      ),
    );
  }
}
