import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/quran_colors.dart';
import '../../settings/application/settings_provider.dart';
import '../../settings/domain/app_settings.dart';
import 'mushaf_ornaments.dart';

/// Chooses the frame drawn around each surah's name, from a drawing of
/// each.
class SurahFrameField extends ConsumerWidget {
  /// Creates the field.
  const SurahFrameField({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final settings = ref.watch(settingsProvider).value ?? const AppSettings();
    final names = {
      SurahFrameStyle.cartouche: l10n.surahFrameCartouche,
      SurahFrameStyle.classic: l10n.surahFrameClassic,
      SurahFrameStyle.arch: l10n.surahFrameArch,
      SurahFrameStyle.minimal: l10n.surahFrameMinimal,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.surahFrame, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: AppTokens.spaceSmall),
        LayoutBuilder(
          builder: (context, constraints) {
            // Two to a row on a phone, all four in one where they fit.
            final columns = constraints.maxWidth >= 560 ? 4 : 2;
            final width =
                (constraints.maxWidth - AppTokens.spaceSmall * (columns - 1)) /
                columns;
            return Wrap(
              spacing: AppTokens.spaceSmall,
              runSpacing: AppTokens.spaceSmall,
              children: [
                for (final style in SurahFrameStyle.values)
                  SizedBox(
                    width: width,
                    child: _FrameChoice(
                      style: style,
                      label: names[style]!,
                      selected: settings.surahFrame == style,
                      onTap: () => ref
                          .read(settingsProvider.notifier)
                          .save(settings.copyWith(surahFrame: style)),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

/// One frame to choose: its drawing, and its name under it.
class _FrameChoice extends StatelessWidget {
  const _FrameChoice({
    required this.style,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final SurahFrameStyle style;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = QuranColors.of(context);
    final radius = BorderRadius.circular(AppTokens.radiusBadge);
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: colors.paper,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(
            color: selected ? scheme.primary : scheme.outlineVariant,
            width: selected ? 2 : 1,
          ),
        ),
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsetsDirectional.all(AppTokens.spaceSmall),
            child: Column(
              children: [
                SizedBox(
                  height: 30,
                  width: double.infinity,
                  child: CustomPaint(
                    painter: SurahFramePainter(
                      style: style,
                      paper: colors.paper,
                      band: colors.ayahNumber.withValues(alpha: 0.12),
                      stroke: colors.ayahNumber.withValues(alpha: 0.85),
                    ),
                  ),
                ),
                const SizedBox(height: AppTokens.spaceSmall),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (selected) ...[
                      Icon(
                        Icons.check_rounded,
                        size: 16,
                        color: scheme.primary,
                      ),
                      const SizedBox(width: 4),
                    ],
                    Flexible(
                      child: Text(
                        label,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
