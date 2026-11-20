import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/layout/adaptive_layout.dart';
import '../../../core/theme/app_platform.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_notice.dart';
import '../../../core/widgets/app_select_field.dart';
import '../../../core/widgets/app_page_scaffold.dart';
import '../../../core/widgets/app_tile_card.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../settings/application/settings_provider.dart';
import '../application/home_widgets_providers.dart';
import '../application/widget_preview_provider.dart';
import '../domain/home_widget.dart';
import 'prayer_schedule_options_section.dart';
import 'widget_previews.dart';

/// The app's home-screen widgets, each with what it shows. Where the
/// launcher takes the request (Android 8 and later), each has an "Add"
/// button that puts it on the home screen; elsewhere the page says how.
class HomeWidgetsPage extends ConsumerWidget {
  /// Creates the page.
  const HomeWidgetsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final canPin = ref.watch(canPinWidgetsProvider).value ?? false;
    final appearance = ref.watch(widgetAppearanceProvider).value;
    final settings = ref.watch(settingsProvider).value;
    final preview = ref.watch(widgetPreviewDataProvider).value;
    final messenger = ScaffoldMessenger.maybeOf(context);

    Future<void> add(HomeWidget widget) async {
      final asked = await ref.read(homeWidgetsPlatformProvider).pin(widget);
      if (messenger?.mounted != true) return;
      messenger!.showSnackBar(
        SnackBar(
          content: Text(asked ? l10n.widgetsAddAsked : l10n.hintWidgetsManual),
        ),
      );
    }

    final gallery = ContentContainer(
      child: Builder(
        builder: (context) => ListView.builder(
          padding: pagePadding(context),
          itemCount: HomeWidget.values.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.widgetsIntro,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: AppTokens.spaceSmall),
                  Text(
                    context.isCupertino
                        ? l10n.widgetPreviewIosHint
                        : l10n.widgetsPreviewHint,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  if (appearance case final style?) ...[
                    const SizedBox(height: AppTokens.spaceMedium),
                    AppSelectField<WidgetAppearance>(
                      label: l10n.widgetAppearance,
                      value: style,
                      options: [
                        AppSelectOption(
                          value: WidgetAppearance.automatic,
                          label: l10n.widgetDefaultStyle,
                        ),
                        AppSelectOption(
                          value: WidgetAppearance.navy,
                          label: l10n.themeDark,
                        ),
                        AppSelectOption(
                          value: WidgetAppearance.green,
                          label: l10n.themeGreen,
                        ),
                      ],
                      onChanged: (value) async {
                        final saved = await ref
                            .read(homeWidgetsPlatformProvider)
                            .setAppearance(value);
                        if (!context.mounted) return;
                        if (saved) {
                          ref.invalidate(widgetAppearanceProvider);
                        } else {
                          messenger?.showSnackBar(
                            SnackBar(content: Text(l10n.widgetStyleSaveFailed)),
                          );
                        }
                      },
                    ),
                  ],
                  if (settings != null) ...[
                    const SizedBox(height: AppTokens.spaceMedium),
                    AppSelectField<String>(
                      label: l10n.widgetLanguage,
                      value: settings.widgetLocaleCode,
                      options: [
                        AppSelectOption(
                          value: 'app',
                          label: l10n.widgetLanguageSameAsApp,
                        ),
                        AppSelectOption(
                          value: 'ar',
                          label: l10n.languageArabic,
                        ),
                        AppSelectOption(
                          value: 'en',
                          label: l10n.languageEnglish,
                        ),
                      ],
                      onChanged: (value) => ref
                          .read(settingsProvider.notifier)
                          .save(settings.copyWith(widgetLocaleCode: value)),
                    ),
                    const SizedBox(height: AppTokens.spaceSmall),
                    Text(
                      l10n.widgetLanguageHint,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                  if (!canPin) ...[
                    const SizedBox(height: AppTokens.spaceMedium),
                    AppNotice(
                      context.isCupertino
                          ? l10n.widgetsStepsIos
                          : l10n.hintWidgetsManual,
                      icon: Icons.touch_app_outlined,
                    ),
                  ],
                  const SizedBox(height: AppTokens.spaceMedium),
                ],
              );
            }
            final widget = HomeWidget.values[index - 1];
            final size = switch (widget) {
              HomeWidget.prayerCard => l10n.widgetSizeWide,
              HomeWidget.prayerSchedule => l10n.widgetSizeTall,

              _ => l10n.widgetSizeSmall,
            };
            final subtitle = [
              _description(l10n, widget),
              if (!context.isCupertino) size,
              if (context.isCupertino && widget == HomeWidget.tasbih)
                l10n.widgetIosTasbihHint,
            ].join('\n');
            return Column(
              children: [
                // The widget as it looks on the home screen, drawn here in the
                // language the widgets speak, at the size it has by default.
                ExcludeSemantics(
                  child: Center(
                    child: preview == null
                        ? SizedBox(
                            height: HomeWidgetPreview.sizeOf(widget).height,
                          )
                        : FittedBox(
                            fit: BoxFit.scaleDown,
                            child: HomeWidgetPreview(
                              widget: widget,
                              data: preview,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: AppTokens.spaceSmall),
                AppTileCard(
                  icon: _icon(widget),
                  title: _name(l10n, widget),
                  subtitle: subtitle,
                  trailing: canPin
                      ? FilledButton.tonal(
                          onPressed: () => add(widget),
                          child: Text(l10n.widgetsAdd),
                        )
                      : null,
                ),
                if (widget == HomeWidget.prayerSchedule) ...[
                  const SizedBox(height: AppTokens.spaceMedium),
                  const PrayerScheduleOptionsSection(),
                ],
                const SizedBox(height: AppTokens.spaceMedium),
              ],
            );
          },
        ),
      ),
    );
    return AppPageScaffold(title: l10n.widgetsTitle, body: gallery);
  }

  static IconData _icon(HomeWidget widget) => switch (widget) {
    HomeWidget.prayerCard => Icons.dashboard_outlined,
    HomeWidget.nextPrayer => Icons.mosque_outlined,
    HomeWidget.prayerSchedule => Icons.schedule_outlined,
    HomeWidget.tasbih => Icons.touch_app_outlined,
    HomeWidget.dhikr => Icons.volunteer_activism_outlined,
  };

  static String _name(AppLocalizations l10n, HomeWidget widget) =>
      switch (widget) {
        HomeWidget.prayerCard => l10n.widgetPrayerCard,
        HomeWidget.nextPrayer => l10n.widgetNextPrayer,
        HomeWidget.prayerSchedule => l10n.widgetPrayerSchedule,
        HomeWidget.tasbih => l10n.widgetTasbih,
        HomeWidget.dhikr => l10n.widgetDhikr,
      };

  static String _description(AppLocalizations l10n, HomeWidget widget) =>
      switch (widget) {
        HomeWidget.prayerCard => l10n.widgetPrayerCardDescription,
        HomeWidget.nextPrayer => l10n.widgetNextPrayerDescription,
        HomeWidget.prayerSchedule => l10n.widgetPrayerScheduleDescription,
        HomeWidget.tasbih => l10n.widgetTasbihDescription,
        HomeWidget.dhikr => l10n.widgetDhikrDescription,
      };
}
