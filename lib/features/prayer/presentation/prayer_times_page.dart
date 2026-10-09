import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/layout/adaptive_layout.dart';
import '../../../core/notifications/reminder_scheduler_provider.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/time/ticking_clock.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_tile_card.dart';
import '../../../core/widgets/app_page_scaffold.dart';
import '../../../core/widgets/app_notice.dart';
import '../../../core/widgets/app_select_field.dart';
import '../../../core/widgets/app_shimmer.dart';
import '../../../core/widgets/app_switch_tile.dart';
import '../../../core/widgets/empty_state.dart';
import '../../settings/application/digits_provider.dart';
import '../application/prayer_provider.dart';
import '../domain/prayer_times.dart';
import 'prayer_labels.dart';
import 'prayer_no_place.dart';

/// Whether exact alarms are allowed (always true off Android).
final exactAlarmsAllowedProvider = FutureProvider.autoDispose<bool>(
  (ref) => ref.watch(reminderSchedulerProvider).canScheduleExact(),
);

/// Today's prayer times at the person's place, an alert for each prayer, and
/// how the times are worked out.
class PrayerTimesPage extends ConsumerStatefulWidget {
  /// Creates the page.
  const PrayerTimesPage({super.key});

  @override
  ConsumerState<PrayerTimesPage> createState() => _PrayerTimesPageState();
}

class _PrayerTimesPageState extends ConsumerState<PrayerTimesPage> {
  PrayerResult _result = PrayerResult.ok;

  Future<void> _run(Future<PrayerResult> Function() action) async {
    final result = await action();
    if (mounted) setState(() => _result = result);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = ref.watch(prayerProvider);
    return AppPageScaffold(
      title: l10n.prayerTimesTitle,
      body: Builder(
        builder: (context) {
          final padding = pagePadding(context);
          return state.when(
            loading: () => Padding(
              padding: padding,
              child: const AppShimmer(
                child: Column(
                  children: [
                    SkeletonBox(height: 120, radius: AppTokens.radiusCard),
                    SizedBox(height: 12),
                    SkeletonBox(height: 280, radius: AppTokens.radiusCard),
                  ],
                ),
              ),
            ),
            error: (_, _) => EmptyState(
              icon: Icons.error_outline,
              title: l10n.adhkarLoadError,
              message: '',
              actionLabel: l10n.retry,
              onAction: () => ref.invalidate(prayerProvider),
            ),
            data: (data) => ContentContainer(
              child: data.place == null
                  ? PrayerNoPlace(
                      denied: _result == PrayerResult.locationDenied,
                      onLocate: () =>
                          _run(ref.read(prayerProvider.notifier).locate),
                    )
                  : _Content(state: data, result: _result, onRun: _run),
            ),
          );
        },
      ),
    );
  }
}

class _Content extends ConsumerWidget {
  const _Content({
    required this.state,
    required this.result,
    required this.onRun,
  });

  final PrayerState state;
  final PrayerResult result;
  final Future<void> Function(Future<PrayerResult> Function()) onRun;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final formatDisplayDigits = ref.watch(displayDigitsFormatterProvider);
    final day = ref.watch(prayerDayProvider);
    final next = ref.watch(nextPrayerProvider);
    final notifier = ref.read(prayerProvider.notifier);
    final settings = state.settings;
    final method = state.method!;
    final place = state.place!;
    final exact = ref.watch(exactAlarmsAllowedProvider).value ?? true;
    final allAlerts = settings.alerts.length == DailyPrayer.values.length;
    return ListView(
      padding: pagePadding(context),
      children: [
        if (next != null) _NextCard(next: next),
        const SizedBox(height: 12),
        if (day != null)
          AppCard(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              children: [
                _TimeRow(
                  name: l10n.prayerFajr,
                  time: formatPrayerTime(
                    context,
                    day.fajr,
                    formatDisplayDigits,
                  ),
                  alert: settings.alerts.contains(DailyPrayer.fajr),
                  highlighted: next?.prayer == DailyPrayer.fajr,
                  onAlert: (on) =>
                      onRun(() => notifier.setAlert(DailyPrayer.fajr, on)),
                ),
                _TimeRow(
                  name: l10n.prayerSunrise,
                  time: formatPrayerTime(
                    context,
                    day.sunrise,
                    formatDisplayDigits,
                  ),
                  muted: true,
                ),
                for (final prayer in DailyPrayer.values.skip(1))
                  _TimeRow(
                    name: prayerName(l10n, prayer),
                    time: formatPrayerTime(
                      context,
                      day.of(prayer),
                      formatDisplayDigits,
                    ),
                    alert: settings.alerts.contains(prayer),
                    highlighted: next?.prayer == prayer,
                    onAlert: (on) => onRun(() => notifier.setAlert(prayer, on)),
                  ),
              ],
            ),
          ),
        const SizedBox(height: 12),
        AppTileCard(
          icon: Icons.explore_outlined,
          title: l10n.qiblaTitle,
          subtitle: l10n.qiblaTileSubtitle,
          onTap: () => context.push(AppRoute.qibla.path),
        ),
        const SizedBox(height: 12),
        AppTileCard(
          icon: Icons.volume_up_outlined,
          title: l10n.adhanTitle,
          subtitle: l10n.adhanTileSubtitle,
          onTap: () => context.push(AppRoute.adhan.path),
        ),
        const SizedBox(height: 12),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppSwitchTile(
                value: allAlerts,
                onChanged: (on) => onRun(() => notifier.setAllAlerts(on)),
                title: l10n.prayerAlertsAll,
                subtitle: l10n.prayerAlertsHint,
                icon: Icons.notifications_active_outlined,
              ),
              if (settings.alerts.isNotEmpty && !exact)
                Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(16, 0, 16, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppNotice(l10n.prayerExactNote),
                      TextButton(
                        onPressed: () async {
                          await notifier.allowExactAlarms();
                          ref.invalidate(exactAlarmsAllowedProvider);
                        },
                        child: Text(l10n.prayerExactAllow),
                      ),
                    ],
                  ),
                ),
              AppSwitchTile(
                value: settings.adhkarReminder,
                onChanged: (on) => onRun(() => notifier.setAdhkarReminder(on)),
                title: l10n.adhkarPrayerSwitch,
                icon: Icons.mosque_outlined,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        AppSelectField<String>(
          label: l10n.adhkarPrayerMethod,
          value: settings.method?.name ?? _auto,
          options: [
            AppSelectOption(
              value: _auto,
              label: l10n.prayerMethodAuto,
              subtitle: l10n.prayerMethodAutoWith(
                prayerMethodLabel(l10n, PrayerMethod.forPlace(place)),
              ),
            ),
            for (final item in PrayerMethod.values)
              AppSelectOption(
                value: item.name,
                label: prayerMethodLabel(l10n, item),
              ),
          ],
          onChanged: (value) =>
              notifier.setMethod(PrayerMethod.tryParse(value)),
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsetsDirectional.symmetric(horizontal: 4),
          child: Text(
            settings.method == null
                ? l10n.prayerMethodAutoWith(prayerMethodLabel(l10n, method))
                : prayerMethodLabel(l10n, method),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.prayerPlaceLine(
                  _coordinate(place.latitude, formatDisplayDigits),
                  _coordinate(place.longitude, formatDisplayDigits),
                ),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            TextButton.icon(
              onPressed: () => onRun(notifier.locate),
              icon: const Icon(Icons.my_location_outlined, size: 20),
              label: Text(l10n.prayerUpdateLocation),
            ),
          ],
        ),
        if (result != PrayerResult.ok)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: AppNotice(
              result == PrayerResult.locationDenied
                  ? l10n.adhkarLocationDenied
                  : l10n.adhkarPermissionDenied,
              error: true,
            ),
          ),
      ],
    );
  }

  static const String _auto = 'auto';

  static String _coordinate(
    double value,
    String Function(String) formatDigits,
  ) {
    final whole = value.truncate().abs();
    final fraction = ((value.abs() - whole) * 100).round().toString().padLeft(
      2,
      '0',
    );
    return formatDigits('${value < 0 ? '-' : ''}$whole.$fraction');
  }
}

class _NextCard extends ConsumerWidget {
  const _NextCard({required this.next});

  final NextPrayer next;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final digits = ref.watch(digitsFormatterProvider);
    final formatDisplayDigits = ref.watch(displayDigitsFormatterProvider);
    final now = ref.watch(tickingNowProvider);
    final until = next.at.difference(now);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(AppTokens.radiusCard),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.prayerNext,
            style: theme.textTheme.labelLarge?.copyWith(
              color: scheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            prayerName(l10n, next.prayer),
            style: theme.textTheme.headlineMedium?.copyWith(
              color: scheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${formatPrayerTime(context, next.at, formatDisplayDigits)} · '
            '${l10n.prayerIn(formatUntil(l10n, until, digits))}',
            style: theme.textTheme.titleMedium?.copyWith(
              color: scheme.onPrimaryContainer,
            ),
          ),
        ],
      ),
    );
  }
}

class _TimeRow extends StatelessWidget {
  const _TimeRow({
    required this.name,
    required this.time,
    this.alert = false,
    this.highlighted = false,
    this.muted = false,
    this.onAlert,
  });

  final String name;
  final String time;
  final bool alert;
  final bool highlighted;
  final bool muted;
  final ValueChanged<bool>? onAlert;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;
    final color = muted ? scheme.onSurfaceVariant : scheme.onSurface;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      padding: const EdgeInsetsDirectional.only(start: 16, end: 4),
      constraints: const BoxConstraints(minHeight: AppTokens.minTarget),
      decoration: BoxDecoration(
        color: highlighted ? scheme.secondaryContainer : null,
        borderRadius: BorderRadius.circular(AppTokens.radiusField),
      ),
      child: Row(
        children: [
          // A Wrap so the time drops under the name when large text leaves no
          // room beside it.
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 12,
                children: [
                  Text(
                    name,
                    style: theme.textTheme.titleMedium?.copyWith(color: color),
                  ),
                  Text(
                    time,
                    style: theme.textTheme.titleMedium?.copyWith(color: color),
                  ),
                ],
              ),
            ),
          ),
          if (onAlert != null)
            IconButton(
              tooltip: alert ? l10n.prayerAlertOn : l10n.prayerAlertOff,
              isSelected: alert,
              icon: const Icon(Icons.notifications_none_outlined),
              selectedIcon: Icon(
                Icons.notifications_active,
                color: scheme.primary,
              ),
              onPressed: () => onAlert!(!alert),
            )
          else
            const SizedBox(width: 48),
        ],
      ),
    );
  }
}
