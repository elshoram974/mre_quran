import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/layout/adaptive_layout.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_group_card.dart';
import '../../../core/widgets/app_page_scaffold.dart';
import '../../../core/widgets/app_select_field.dart';
import '../../../core/widgets/app_switch_tile.dart';
import '../application/settings_provider.dart';
import 'settings_body.dart';
import 'theme_pickers.dart';

/// The colours, the language, the digits, and the motion of the app.
class AppearanceSettingsPage extends ConsumerWidget {
  /// Creates the page.
  const AppearanceSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final notifier = ref.read(settingsProvider.notifier);
    return AppPageScaffold(
      title: l10n.appearance,
      body: SettingsBody(
        builder: (context, settings) => ListView(
          padding: pagePadding(context),
          children: [
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
          ],
        ),
      ),
    );
  }
}
