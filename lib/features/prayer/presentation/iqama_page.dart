import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/layout/adaptive_layout.dart';
import '../../../core/widgets/app_group_card.dart';
import '../../../core/widgets/app_notice.dart';
import '../../../core/widgets/app_page_scaffold.dart';
import '../../../core/widgets/app_section_header.dart';
import '../../../core/widgets/app_shimmer.dart';
import '../../../core/widgets/app_switch_tile.dart';
import '../../../core/widgets/empty_state.dart';
import '../../settings/application/digits_provider.dart';
import '../application/prayer_provider.dart';
import '../domain/prayer_alerts.dart';
import '../domain/prayer_times.dart';
import 'prayer_labels.dart';
import 'prayer_step_row.dart';

/// The iqama: a notice when each prayer is established («قد قامت الصلاة»),
/// a set time after its adhan that the person puts where their own mosque
/// has it.
class IqamaPage extends ConsumerStatefulWidget {
  /// Creates the page.
  const IqamaPage({super.key});

  @override
  ConsumerState<IqamaPage> createState() => _IqamaPageState();
}

class _IqamaPageState extends ConsumerState<IqamaPage> {
  PrayerResult _result = PrayerResult.ok;

  Future<void> _toggle(bool on) async {
    final result = await ref.read(prayerProvider.notifier).setIqamaReminder(on);
    if (mounted) setState(() => _result = result);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = ref.watch(prayerProvider);
    return AppPageScaffold(
      title: l10n.iqamaPageTitle,
      body: Builder(
        builder: (context) {
          final padding = pagePadding(context);
          if (state.hasError) {
            return EmptyState(
              icon: Icons.error_outline,
              title: l10n.adhkarLoadError,
              message: '',
              actionLabel: l10n.retry,
              onAction: () => ref.invalidate(prayerProvider),
            );
          }
          final data = state.value;
          if (data == null) {
            return Padding(
              padding: padding,
              child: const AppShimmer(
                child: Column(
                  children: [
                    SkeletonBox(height: 120),
                    SizedBox(height: 12),
                    SkeletonBox(height: 260),
                  ],
                ),
              ),
            );
          }
          final settings = data.settings;
          final notifier = ref.read(prayerProvider.notifier);
          return ContentContainer(
            child: ListView(
              padding: padding,
              children: [
                AppNotice(l10n.iqamaIntro, icon: Icons.info_outline),
                const SizedBox(height: 12),
                // Red and boxed, first: without them the switch promises what
                // cannot happen.
                if (_result == PrayerResult.notificationsDenied) ...[
                  AppNotice(l10n.adhkarPermissionDenied, important: true),
                  const SizedBox(height: 12),
                ],
                if (_result == PrayerResult.locationDenied) ...[
                  AppNotice(l10n.adhkarLocationDenied, error: true),
                  const SizedBox(height: 12),
                ],
                AppGroupCard(
                  children: [
                    AppSwitchTile(
                      value: settings.iqamaReminder,
                      onChanged: _toggle,
                      title: l10n.iqamaSwitch,
                      subtitle: l10n.iqamaSwitchHint,
                      icon: Icons.record_voice_over_outlined,
                    ),
                    if (settings.iqamaReminder)
                      AppSwitchTile(
                        value: settings.iqamaSound,
                        onChanged: notifier.setIqamaSound,
                        title: l10n.iqamaSoundSwitch,
                        subtitle: l10n.iqamaSoundHint,
                        icon: Icons.volume_up_outlined,
                      ),
                  ],
                ),
                if (settings.iqamaReminder) ...[
                  const SizedBox(height: 24),
                  AppSectionHeader(
                    title: l10n.iqamaTimesTitle,
                    subtitle: l10n.iqamaTimesHint,
                  ),
                  _TimesCard(settings: settings),
                  if (settings.iqamaMinutes.isNotEmpty)
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: TextButton.icon(
                        onPressed: notifier.resetIqamaMinutes,
                        icon: const Icon(Icons.restart_alt),
                        label: Text(l10n.iqamaResetAll),
                      ),
                    ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

/// The five prayers, each with its iqama and a stepper for the gap after its
/// adhan.
class _TimesCard extends ConsumerWidget {
  const _TimesCard({required this.settings});

  final PrayerSettings settings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final day = ref.watch(prayerDayProvider);
    final digits = ref.watch(digitsFormatterProvider);
    final displayDigits = ref.watch(displayDigitsFormatterProvider);
    final notifier = ref.read(prayerProvider.notifier);
    return AppGroupCard(
      children: [
        for (final prayer in DailyPrayer.values)
          Builder(
            builder: (context) {
              final minutes = settings.iqamaAfter(prayer);
              final adhan = day?.of(prayer);
              return PrayerStepRow(
                prayer: prayer,
                time: adhan == null
                    ? null
                    : l10n.iqamaAt(
                        formatPrayerTime(
                          context,
                          adhan.add(Duration(minutes: minutes)),
                          displayDigits,
                        ),
                      ),
                label: l10n.iqamaAfterLine(
                  l10n.minutesCount(minutes, digits(minutes)),
                ),
                highlighted:
                    minutes != PrayerSettings.defaultIqamaMinutes[prayer],
                decreaseLabel: l10n.iqamaEarlierButton,
                increaseLabel: l10n.iqamaLaterButton,
                onDecrease: minutes > PrayerSettings.minIqama
                    ? () => notifier.setIqamaMinutes(prayer, minutes - 1)
                    : null,
                onIncrease: minutes < PrayerSettings.maxIqama
                    ? () => notifier.setIqamaMinutes(prayer, minutes + 1)
                    : null,
              );
            },
          ),
      ],
    );
  }
}
