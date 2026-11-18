import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/layout/adaptive_layout.dart';
import '../../../core/theme/app_platform.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_notice.dart';
import '../../../core/widgets/app_page_scaffold.dart';
import '../../../core/widgets/app_tile_card.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../application/home_widgets_providers.dart';
import '../domain/home_widget.dart';

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

    return AppPageScaffold(
      title: l10n.widgetsTitle,
      body: Builder(
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
              HomeWidget.tasbih || HomeWidget.dhikr => l10n.widgetSizeFlexible,
              _ => l10n.widgetSizeSmall,
            };
            final subtitle = [
              _description(l10n, widget),
              if (!context.isCupertino) size,
              if (context.isCupertino && widget == HomeWidget.tasbih)
                l10n.widgetIosTasbihHint,
            ].join('\n');
            final folder = Localizations.localeOf(context).languageCode == 'ar'
                ? 'drawable-ar-nodpi'
                : 'drawable-nodpi';
            final filename = switch (widget) {
              HomeWidget.prayerCard => 'prayer_card',
              HomeWidget.nextPrayer => 'prayer',
              HomeWidget.prayerSchedule => 'prayer_schedule',
              HomeWidget.tasbih => 'tasbih',
              HomeWidget.dhikr => 'adhkar',
            };
            return Column(
              children: [
                ExcludeSemantics(
                  child: Image.asset(
                    'android/app/src/main/res/$folder/${filename}_widget_preview.png',
                    height: AppTokens.widgetPreviewHeight,
                    fit: BoxFit.contain,
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
                const SizedBox(height: AppTokens.spaceMedium),
              ],
            );
          },
        ),
      ),
    );
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
