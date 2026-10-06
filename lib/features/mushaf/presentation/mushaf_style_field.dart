import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/widgets/app_select_field.dart';
import '../../settings/application/settings_provider.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../settings/domain/app_settings.dart';

/// The name of the printed Mushaf edition shown for [style].
String mushafStyleLabel(AppLocalizations l10n, MushafStyle style) =>
    switch (style) {
      MushafStyle.madinah => l10n.mushafStyleMadinah,
      MushafStyle.tajweed => l10n.mushafStyleTajweed,
      MushafStyle.madinahHd => l10n.mushafStyleMadinahHd,
    };

/// Picker for the printed Mushaf edition, shared by the reader's display
/// options and the settings page.
class MushafStyleField extends ConsumerWidget {
  /// Creates the picker.
  const MushafStyleField({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final settings = ref.watch(settingsProvider).value ?? const AppSettings();
    return AppSelectField<MushafStyle>(
      label: l10n.mushafStyle,
      value: settings.mushafStyle,
      options: [
        AppSelectOption(
          value: MushafStyle.madinah,
          label: l10n.mushafStyleMadinah,
          icon: Icons.menu_book_outlined,
        ),
        AppSelectOption(
          value: MushafStyle.tajweed,
          label: l10n.mushafStyleTajweed,
          icon: Icons.palette_outlined,
        ),
        AppSelectOption(
          value: MushafStyle.madinahHd,
          label: l10n.mushafStyleMadinahHd,
          icon: Icons.high_quality_outlined,
        ),
      ],
      onChanged: (value) => ref
          .read(settingsProvider.notifier)
          .save(settings.copyWith(mushafStyle: value)),
    );
  }
}
