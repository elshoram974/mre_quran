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
      messenger?.showSnackBar(
        SnackBar(
          content: Text(asked ? l10n.widgetsAddAsked : l10n.hintWidgetsManual),
        ),
      );
    }

    return AppPageScaffold(
      title: l10n.widgetsTitle,
      body: Builder(
        builder: (context) => ListView(
          padding: pagePadding(context),
          children: [
            Text(
              l10n.widgetsIntro,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppTokens.spaceMedium),
            if (!canPin) ...[
              AppNotice(
                context.isCupertino
                    ? l10n.widgetsStepsIos
                    : l10n.hintWidgetsManual,
                icon: Icons.touch_app_outlined,
              ),
              const SizedBox(height: AppTokens.spaceMedium),
            ],
            for (final widget in HomeWidget.values) ...[
              AppTileCard(
                icon: _icon(widget),
                title: _name(l10n, widget),
                subtitle: _description(l10n, widget),
                trailing: canPin
                    ? FilledButton.tonal(
                        onPressed: () => add(widget),
                        child: Text(l10n.widgetsAdd),
                      )
                    : null,
              ),
              const SizedBox(height: AppTokens.spaceSmall),
            ],
          ],
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
