import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/hints/hints.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/widgets/app_hint_sheet.dart';
import '../../adhan/application/adhan_providers.dart';
import '../../../core/layout/adaptive_layout.dart';
import '../../../core/notifications/reminder_scheduler_provider.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/time/ticking_clock.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_hero_card.dart';
import '../../../core/widgets/app_icon_badge.dart';
import '../../../core/widgets/app_tile_card.dart';
import '../../../core/widgets/app_notice.dart';
import '../../../core/widgets/app_select_field.dart';
import '../../../core/widgets/app_shimmer.dart';
import '../../../core/widgets/app_switch_tile.dart';
import '../../../core/widgets/empty_state.dart';
import '../../settings/application/digits_provider.dart';
import '../application/prayer_provider.dart';
import '../domain/prayer_alerts.dart';
import '../domain/prayer_times.dart';
import 'location_problem_notice.dart';
import 'prayer_labels.dart';
import 'prayer_no_place.dart';
import '../../adhan/presentation/adhan_battery_notice.dart';
import '../../home_widgets/presentation/widget_hint.dart';

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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => unawaited(_offerWidgetsOnOpen()),
    );
  }

  /// Runs [action]. When it turns the first alert on ([enabling]), the
  /// permissions it asks for are said first, once ever; once the alerts are
  /// on, the adhan is offered to try.
  Future<void> _run(
    Future<PrayerResult> Function() action, {
    bool enabling = false,
  }) async {
    final l10n = context.l10n;
    final first =
        enabling &&
        (ref.read(prayerProvider).value?.settings.alerts.isEmpty ?? true);
    if (first) {
      await showAppHint(
        context,
        ref,
        hint: AppHint.permissions,
        icon: Icons.verified_user_outlined,
        title: l10n.hintPermissionsTitle,
        body: l10n.hintPermissionsBody,
        action: l10n.hintPermissionsAction,
        once: true,
      );
      if (!mounted) return;
    }
    final result = await action();
    if (!mounted) return;
    setState(() => _result = result);
    final on = ref.read(prayerProvider).value?.settings.alerts.isNotEmpty;
    if (!first || result != PrayerResult.ok || on != true) return;
    final exact = await ref.read(reminderSchedulerProvider).canScheduleExact();
    if (!mounted) return;
    if (!exact) {
      final allow = await showAppHint(
        context,
        ref,
        hint: AppHint.exactPrayerTiming,
        icon: Icons.alarm_outlined,
        title: l10n.prayerChannelName,
        body: l10n.prayerExactNote,
        action: l10n.prayerExactAllow,
      );
      if (!mounted) return;
      if (allow) {
        await ref.read(prayerProvider.notifier).allowExactAlarms();
        if (!mounted) return;
        ref.invalidate(exactAlarmsAllowedProvider);
      }
    }
    final tried = await showAppHint(
      context,
      ref,
      hint: AppHint.tryAdhan,
      icon: Icons.volume_up_outlined,
      title: l10n.hintTryAdhanTitle,
      body: l10n.hintTryAdhanBody,
      action: l10n.hintTryAdhanAction,
    );
    if (!mounted) return;
    if (tried) {
      await ref.read(adhanTesterProvider)(l10n);
      // While it plays: the home-screen widgets are the next thing to try.
      await Future<void>.delayed(const Duration(seconds: 6));
      if (!mounted) return;
    }
    // Whether or not the adhan was tried.
    await offerWidgets(context, ref);
  }

  /// Once the times are shown, the home-screen widgets are offered (while
  /// none is on the home screen), whatever was tried before.
  Future<void> _offerWidgetsOnOpen() async {
    final PrayerState state;
    try {
      state = await ref.read(prayerProvider.future);
    } on Object {
      return;
    }
    if (state.place == null || !mounted) return;
    await offerWidgets(context, ref);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = ref.watch(prayerProvider);
    // A tab: the shell draws the bar and the navigation around it.
    return Builder(
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
                    onChooseMap: () =>
                        context.push(AppRoute.prayerLocationPicker.path),
                  )
                : _Content(state: data, result: _result, onRun: _run),
          ),
        );
      },
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
  final Future<void> Function(Future<PrayerResult> Function(), {bool enabling})
  onRun;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final formatDisplayDigits = ref.watch(displayDigitsFormatterProvider);
    final day = ref.watch(prayerDayProvider);
    final next = ref.watch(nextPrayerProvider);
    final iqama = ref.watch(iqamaWaitProvider);
    final notifier = ref.read(prayerProvider.notifier);
    final settings = state.settings;
    final method = state.method!;
    final place = state.place!;
    final exact = ref.watch(exactAlarmsAllowedProvider).value ?? true;
    // Kept while the page is open: the battery notice below scrolls out of
    // view, and without this the system was asked again each time it came
    // back, and the notice popped in under the finger.
    ref.listen(adhanBatteryUnrestrictedProvider, (_, _) {});
    final allAlerts = settings.alerts.length == DailyPrayer.values.length;
    return ListView(
      padding: pagePadding(context),
      children: [
        // After the adhan, until the iqama: how long is left to it.
        if (iqama != null) ...[
          _IqamaCard(wait: iqama),
          const SizedBox(height: 12),
        ],
        if (next != null) _NextCard(next: next),
        const SizedBox(height: 12),
        if (day != null)
          AppCard(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              children: [
                _TimeRow(
                  icon: prayerIcon(DailyPrayer.fajr),
                  name: l10n.prayerFajr,
                  time: formatPrayerTime(
                    context,
                    day.fajr,
                    formatDisplayDigits,
                  ),
                  alert: settings.alerts.contains(DailyPrayer.fajr),
                  highlighted: next?.prayer == DailyPrayer.fajr,
                  onAlert: (on) => onRun(
                    () => notifier.setAlert(DailyPrayer.fajr, on),
                    enabling: on,
                  ),
                ),
                _TimeRow(
                  icon: sunriseIcon,
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
                    icon: prayerIcon(prayer),
                    name: prayerName(l10n, prayer),
                    time: formatPrayerTime(
                      context,
                      day.of(prayer),
                      formatDisplayDigits,
                    ),
                    alert: settings.alerts.contains(prayer),
                    highlighted: next?.prayer == prayer,
                    onAlert: (on) => onRun(
                      () => notifier.setAlert(prayer, on),
                      enabling: on,
                    ),
                  ),
              ],
            ),
          ),
        const SizedBox(height: 12),
        AppTileCard(
          icon: Icons.tune,
          title: l10n.prayerTuningTitle,
          subtitle: l10n.prayerTuningTileSubtitle,
          onTap: () => context.push(AppRoute.prayerTuning.path),
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
        AppTileCard(
          icon: Icons.record_voice_over_outlined,
          title: l10n.iqamaPageTitle,
          subtitle: l10n.iqamaTileSubtitle,
          onTap: () => context.push(AppRoute.iqama.path),
        ),
        const SizedBox(height: 12),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppSwitchTile(
                value: allAlerts,
                onChanged: (on) =>
                    onRun(() => notifier.setAllAlerts(on), enabling: on),
                title: l10n.prayerAlertsAll,
                subtitle: l10n.prayerAlertsHint,
                icon: Icons.notifications_active_outlined,
              ),
              if (settings.alerts.isNotEmpty && !exact)
                Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(16, 0, 16, 8),
                  // Red and boxed: without it the alerts can come late.
                  child: AppNotice(
                    l10n.prayerExactNote,
                    important: true,
                    action: FilledButton(
                      onPressed: () async {
                        await notifier.allowExactAlarms();
                        ref.invalidate(exactAlarmsAllowedProvider);
                      },
                      child: Text(l10n.prayerExactAllow),
                    ),
                  ),
                ),
              // The adhan plays at the prayers that alert: battery saving
              // must not hold it back.
              if (settings.alerts.isNotEmpty)
                const Padding(
                  padding: EdgeInsetsDirectional.fromSTEB(16, 0, 16, 8),
                  child: AdhanBatteryNotice(),
                ),
              // The reminder before a prayer comes with its alert.
              if (settings.alerts.isNotEmpty) ...[
                AppSwitchTile(
                  value: settings.beforeReminder,
                  onChanged: notifier.setBeforeReminder,
                  title: l10n.prayerSoonSwitch,
                  subtitle: l10n.prayerSoonHint,
                  icon: Icons.alarm_outlined,
                ),
                if (settings.beforeReminder)
                  Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(16, 0, 16, 8),
                    child: AppSelectField<int>(
                      label: l10n.prayerSoonMinutes,
                      value: settings.beforeMinutes,
                      options: [
                        for (final minutes in PrayerSettings.beforeChoices)
                          AppSelectOption(
                            value: minutes,
                            label: l10n.minutesCount(
                              minutes,
                              ref.watch(digitsFormatterProvider)(minutes),
                            ),
                          ),
                      ],
                      onChanged: notifier.setBeforeMinutes,
                    ),
                  ),
                if (settings.beforeReminder)
                  AppSwitchTile(
                    value: settings.beforeSound,
                    onChanged: notifier.setBeforeSound,
                    title: l10n.prayerSoonSoundSwitch,
                    subtitle: l10n.prayerSoonSoundHint,
                    icon: Icons.volume_up_outlined,
                  ),
                // Android counts down in the notification itself.
                if (settings.beforeReminder &&
                    defaultTargetPlatform == TargetPlatform.android)
                  AppSwitchTile(
                    value: settings.beforeCountdown,
                    onChanged: notifier.setBeforeCountdown,
                    title: l10n.prayerSoonCountdownSwitch,
                    subtitle: l10n.prayerSoonCountdownHint,
                    icon: Icons.timer_outlined,
                  ),
              ],
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
                // What the place is called, once it is known; the numbers
                // only until then.
                place.name != null
                    ? l10n.prayerPlaceNamed(place.name!)
                    : l10n.prayerPlaceLine(
                        formatPrayerCoordinate(
                          place.latitude,
                          formatDisplayDigits,
                        ),
                        formatPrayerCoordinate(
                          place.longitude,
                          formatDisplayDigits,
                        ),
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
        const SizedBox(height: 8),
        AppTileCard(
          icon: Icons.map_outlined,
          title: l10n.prayerChooseMap,
          subtitle: l10n.prayerChooseMapHint,
          onTap: () => context.push(AppRoute.prayerLocationPicker.path),
        ),
        if (result != PrayerResult.ok)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: result == PrayerResult.locationDenied
                ? LocationProblemNotice(fallback: l10n.adhkarLocationDenied)
                : AppNotice(l10n.adhkarPermissionDenied, error: true),
          ),
      ],
    );
  }

  static const String _auto = 'auto';
}

class _NextCard extends ConsumerWidget {
  const _NextCard({required this.next});

  final NextPrayer next;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final text = Theme.of(context).textTheme;
    final digits = ref.watch(digitsFormatterProvider);
    final formatDisplayDigits = ref.watch(displayDigitsFormatterProvider);
    return AppHeroCard(
      watermark: Icons.mosque_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppIconBadge(
                prayerIcon(next.prayer),
                size: AppIconBadgeSize.small,
                emphasized: true,
              ),
              const SizedBox(width: AppTokens.spaceMedium),
              Expanded(child: Text(l10n.prayerNext, style: text.labelLarge)),
            ],
          ),
          const SizedBox(height: AppTokens.spaceMedium),
          Text(prayerName(l10n, next.prayer), style: text.headlineMedium),
          const SizedBox(height: 4),
          _Countdown(
            to: next.at,
            digits: digits,
            format: context.l10n.prayerIn,
            style: text.titleMedium,
          ),
          const SizedBox(height: 2),
          Text(
            formatPrayerTime(context, next.at, formatDisplayDigits),
            style: text.bodyMedium,
          ),
        ],
      ),
    );
  }
}

/// The iqama being waited for: its prayer, the time left to it to the second,
/// and when it comes. Shown from the adhan until the iqama.
class _IqamaCard extends ConsumerWidget {
  const _IqamaCard({required this.wait});

  final IqamaWait wait;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final text = Theme.of(context).textTheme;
    final digits = ref.watch(digitsFormatterProvider);
    final formatDisplayDigits = ref.watch(displayDigitsFormatterProvider);
    return AppHeroCard(
      watermark: Icons.record_voice_over_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const AppIconBadge(
                Icons.record_voice_over_outlined,
                size: AppIconBadgeSize.small,
                emphasized: true,
              ),
              const SizedBox(width: AppTokens.spaceMedium),
              Expanded(
                child: Text(l10n.iqamaCardLabel, style: text.labelLarge),
              ),
            ],
          ),
          const SizedBox(height: AppTokens.spaceMedium),
          Text(
            prayerNameOn(l10n, wait.prayer, wait.adhan),
            style: text.headlineMedium,
          ),
          const SizedBox(height: 4),
          _Countdown(
            to: wait.at,
            digits: digits,
            format: l10n.iqamaIn,
            style: text.titleMedium,
          ),
          const SizedBox(height: 2),
          Text(
            l10n.iqamaCardWhen(
              formatPrayerTime(context, wait.at, formatDisplayDigits),
            ),
            style: text.bodyMedium,
          ),
        ],
      ),
    );
  }
}

/// The time left until [to], to the second: `بعد ٢:٠٥:٠٩`, worded by
/// [format]. It ticks only while it is on screen.
class _Countdown extends ConsumerStatefulWidget {
  const _Countdown({
    required this.to,
    required this.digits,
    required this.format,
    this.style,
  });

  final DateTime to;
  final String Function(int) digits;
  final String Function(String) format;
  final TextStyle? style;

  @override
  ConsumerState<_Countdown> createState() => _CountdownState();
}

class _CountdownState extends ConsumerState<_Countdown> {
  late final Timer _tick;

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _tick.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final left = widget.to.difference(ref.read(clockProvider)());
    final seconds = left.isNegative ? 0 : left.inSeconds;
    String two(int value) =>
        '${widget.digits(value ~/ 10)}${widget.digits(value % 10)}';
    final hours = seconds ~/ 3600;
    final clock = [
      if (hours > 0) widget.digits(hours),
      two(seconds % 3600 ~/ 60),
      two(seconds % 60),
    ].join(':');
    return Text(
      widget.format(clock),
      // Digits keep their width, so the line does not shake each second.
      style: widget.style?.copyWith(
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
  }
}

class _TimeRow extends StatelessWidget {
  const _TimeRow({
    required this.icon,
    required this.name,
    required this.time,
    this.alert = false,
    this.highlighted = false,
    this.muted = false,
    this.onAlert,
  });

  final IconData icon;
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
    final color = muted
        ? scheme.onSurfaceVariant
        : highlighted
        ? scheme.onPrimaryContainer
        : scheme.onSurface;
    final style = theme.textTheme.titleMedium?.copyWith(color: color);
    return AnimatedContainer(
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : AppTokens.motionMedium,
      margin: const EdgeInsetsDirectional.symmetric(
        horizontal: AppTokens.spaceSmall,
        vertical: 2,
      ),
      padding: const EdgeInsetsDirectional.only(
        start: AppTokens.spaceMedium,
        end: 4,
      ),
      constraints: const BoxConstraints(minHeight: AppTokens.minTarget),
      decoration: BoxDecoration(
        color: highlighted ? scheme.primaryContainer : null,
        borderRadius: BorderRadius.circular(AppTokens.radiusField),
      ),
      child: Row(
        children: [
          AppIconBadge(
            icon,
            size: AppIconBadgeSize.small,
            emphasized: highlighted,
          ),
          const SizedBox(width: AppTokens.spaceMedium),
          // A Wrap so the time drops under the name when large text leaves no
          // room beside it.
          Expanded(
            child: Padding(
              padding: const EdgeInsetsDirectional.symmetric(
                vertical: AppTokens.spaceSmall,
              ),
              child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: AppTokens.spaceMedium,
                children: [
                  Text(name, style: style),
                  Text(time, style: style),
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
            const SizedBox(width: AppTokens.minTarget),
        ],
      ),
    );
  }
}
