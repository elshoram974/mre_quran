import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_select_field.dart';
import '../../settings/application/settings_provider.dart';
import '../../settings/domain/app_settings.dart';

/// Chooses the reading whose printed Mushaf the reader shows, and says what
/// a reading other than the app's own text cannot do.
class MushafEditionField extends ConsumerWidget {
  /// Creates the field.
  const MushafEditionField({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final settings = ref.watch(settingsProvider).value ?? const AppSettings();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppSelectField<MushafEdition>(
          label: l10n.mushafEdition,
          value: settings.mushafEdition,
          options: [
            for (final edition in MushafEditions.all)
              AppSelectOption(
                value: edition,
                label: edition.name(l10n.localeName),
                icon: Icons.menu_book_outlined,
              ),
          ],
          onChanged: (value) => ref
              .read(settingsProvider.notifier)
              .save(settings.copyWith(mushafEdition: value)),
        ),
        if (!settings.mushafEdition.matchesAppText)
          Padding(
            padding: const EdgeInsetsDirectional.only(
              top: AppTokens.spaceSmall,
            ),
            child: Text(
              l10n.editionLimitedNote,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
      ],
    );
  }
}
