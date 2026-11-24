import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mre_fields/mre_fields.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/layout/adaptive_layout.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/time/ticking_clock.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_group_card.dart';
import '../../../core/widgets/app_notice.dart';
import '../../../core/widgets/app_page_scaffold.dart';
import '../../../core/widgets/app_section_header.dart';
import '../../../core/widgets/app_segmented_control.dart';
import '../../../core/widgets/app_shimmer.dart';
import '../../../core/widgets/app_stepper.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../settings/application/digits_provider.dart';
import '../application/prayer_provider.dart';
import '../domain/hijri_date.dart';
import '../domain/prayer_alerts.dart';
import '../domain/prayer_times.dart';
import '../domain/prayer_tuning.dart';
import 'prayer_labels.dart';

/// Where the person moves the times away from the calculation, because the
/// calculation is not always the truth where they are: some minutes for each
/// prayer, summer time, the height above sea level, and the Hijri date.
class PrayerTuningPage extends ConsumerWidget {
  /// Creates the page.
  const PrayerTuningPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final state = ref.watch(prayerProvider);
    return AppPageScaffold(
      title: l10n.prayerTuningTitle,
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
                    SkeletonBox(height: 280),
                    SizedBox(height: 12),
                    SkeletonBox(height: 120),
                  ],
                ),
              ),
            );
          }
          if (data.place == null) {
            return ContentContainer(
              child: ListView(
                padding: padding,
                children: [AppNotice(l10n.prayerTuningNeedsPlace)],
              ),
            );
          }
          return ContentContainer(
            child: ListView(
              padding: padding,
              children: [
                _OffsetsSection(state: data),
                const SizedBox(height: 24),
                _DaylightSection(settings: data.settings),
                const SizedBox(height: 24),
                _ElevationSection(state: data),
                const SizedBox(height: 24),
                _HijriSection(shift: data.settings.hijriShift),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Minutes added to each prayer, with the time that results.
class _OffsetsSection extends ConsumerWidget {
  const _OffsetsSection({required this.state});

  final PrayerState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final day = ref.watch(prayerDayProvider);
    final digits = ref.watch(digitsFormatterProvider);
    final displayDigits = ref.watch(displayDigitsFormatterProvider);
    final notifier = ref.read(prayerProvider.notifier);
    final offsets = state.settings.offsets;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSectionHeader(
          title: l10n.prayerTuningOffsetsTitle,
          subtitle: l10n.prayerTuningOffsetsHint,
        ),
        AppGroupCard(
          children: [
            for (final prayer in DailyPrayer.values)
              _OffsetRow(
                prayer: prayer,
                time: day == null
                    ? null
                    : formatPrayerTime(context, day.of(prayer), displayDigits),
                minutes: offsets[prayer] ?? 0,
                digits: digits,
                onChanged: (minutes) => notifier.setOffset(prayer, minutes),
              ),
          ],
        ),
        if (offsets.isNotEmpty)
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton.icon(
              onPressed: notifier.resetOffsets,
              icon: const Icon(Icons.restart_alt),
              label: Text(l10n.prayerTuningResetAll),
            ),
          ),
      ],
    );
  }
}

class _OffsetRow extends StatelessWidget {
  const _OffsetRow({
    required this.prayer,
    required this.time,
    required this.minutes,
    required this.digits,
    required this.onChanged,
  });

  final DailyPrayer prayer;
  final String? time;
  final int minutes;
  final String Function(int) digits;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    const limit = PrayerTuning.maxOffset;
    final label = switch (minutes) {
      0 => l10n.prayerTuningAsCalculated,
      < 0 => l10n.prayerTuningEarlier(
        l10n.minutesCount(-minutes, digits(-minutes)),
      ),
      _ => l10n.prayerTuningLater(l10n.minutesCount(minutes, digits(minutes))),
    };
    final stacked =
        MediaQuery.textScalerOf(context).scale(1) >= AppTokens.stackTextScale;
    final icon = Icon(prayerIcon(prayer), color: theme.colorScheme.primary);
    final name = Text(
      prayerName(l10n, prayer),
      style: theme.textTheme.titleMedium,
    );
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(16, 8, 16, 8),
      child: Column(
        children: [
          // With large text the time goes under the name, so neither is
          // squeezed.
          if (stacked) ...[
            Row(
              children: [
                icon,
                const SizedBox(width: 12),
                Expanded(child: name),
              ],
            ),
            if (time != null)
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(time!, style: theme.textTheme.titleMedium),
              ),
          ] else
            Row(
              children: [
                icon,
                const SizedBox(width: 12),
                Expanded(child: name),
                if (time != null)
                  Text(time!, style: theme.textTheme.titleMedium),
              ],
            ),
          const SizedBox(height: 4),
          AppStepper(
            label: label,
            highlighted: minutes != 0,
            decreaseLabel: l10n.prayerTuningEarlierButton,
            increaseLabel: l10n.prayerTuningLaterButton,
            onDecrease: minutes > -limit ? () => onChanged(minutes - 1) : null,
            onIncrease: minutes < limit ? () => onChanged(minutes + 1) : null,
          ),
        ],
      ),
    );
  }
}

/// Summer time: follow the phone, or say what the place is on.
class _DaylightSection extends ConsumerWidget {
  const _DaylightSection({required this.settings});

  final PrayerSettings settings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final now = ref.watch(clockProvider)();
    final phoneOnSummer = DaylightSaving.deviceOnSummerTime(now);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSectionHeader(
          title: l10n.prayerTuningDaylightTitle,
          subtitle: l10n.prayerTuningDaylightHint,
        ),
        AppSegmentedControl<DaylightSaving>(
          segments: {
            DaylightSaving.automatic: l10n.prayerTuningDaylightAuto,
            DaylightSaving.summer: l10n.prayerTuningDaylightSummer,
            DaylightSaving.winter: l10n.prayerTuningDaylightWinter,
          },
          value: settings.daylight,
          onChanged: ref.read(prayerProvider.notifier).setDaylight,
        ),
        const SizedBox(height: 8),
        AppNotice(
          phoneOnSummer
              ? l10n.prayerTuningPhoneSummer
              : l10n.prayerTuningPhoneWinter,
          icon: Icons.schedule,
        ),
        if (settings.daylight.shiftOn(now) != 0)
          AppNotice(l10n.prayerTuningDaylightShifted, icon: Icons.update),
      ],
    );
  }
}

/// The height above sea level: the phone's reading, or the person's own.
class _ElevationSection extends ConsumerWidget {
  const _ElevationSection({required this.state});

  final PrayerState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final place = state.place!;
    final settings = state.settings;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSectionHeader(
          title: l10n.prayerTuningElevationTitle,
          subtitle: l10n.prayerTuningElevationHint,
        ),
        // New when the height or the phone's reading changes, so the field
        // shows the one now in use.
        _ElevationCard(
          key: ValueKey((settings.elevation, place.altitude)),
          state: state,
        ),
      ],
    );
  }
}

class _ElevationCard extends ConsumerStatefulWidget {
  const _ElevationCard({super.key, required this.state});

  final PrayerState state;

  @override
  ConsumerState<_ElevationCard> createState() => _ElevationCardState();
}

class _ElevationCardState extends ConsumerState<_ElevationCard> {
  late final TextEditingController _controller;
  bool _invalid = false;

  PrayerSettings get _settings => widget.state.settings;
  PrayerPlace get _place => widget.state.place!;

  @override
  void initState() {
    super.initState();
    final shown = _settings.elevation ?? _place.altitude?.round();
    _controller = TextEditingController(
      text: shown == null ? '' : ref.read(digitsFormatterProvider)(shown),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    final text = formatDisplayDigits(_controller.text.trim(), arabic: false);
    // Nothing typed means the phone's reading.
    if (text.isEmpty) {
      ref.read(prayerProvider.notifier).setElevation(null);
      return;
    }
    final metres = int.tryParse(text);
    if (metres == null || metres < 0 || metres > PrayerTuning.maxElevation) {
      setState(() => _invalid = true);
      return;
    }
    setState(() => _invalid = false);
    ref.read(prayerProvider.notifier).setElevation(metres);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final digits = ref.watch(digitsFormatterProvider);
    final displayDigits = ref.watch(displayDigitsFormatterProvider);
    String metres(int value) => l10n.metersCount(digits(value));
    final source = _settings.elevation != null
        ? l10n.prayerTuningElevationManual(metres(_settings.elevation!))
        : _place.altitude != null
        ? l10n.prayerTuningElevationDevice(metres(_place.altitude!.round()))
        : l10n.prayerTuningElevationNone;
    final used = widget.state.tuning.elevation;
    final shift = PrayerElevation.shift(
      _place,
      ref.watch(clockProvider)(),
      used,
    );
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            source,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          MRETextField(
            controller: _controller,
            labelText: l10n.prayerTuningElevationField,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp('[0-9٠-٩۰-۹]')),
            ],
            onFieldSubmitted: (_) => _save(),
          ),
          if (_invalid) ...[
            const SizedBox(height: 8),
            AppNotice(
              l10n.prayerTuningElevationInvalid(
                displayDigits('0'),
                displayDigits('${PrayerTuning.maxElevation}'),
              ),
              error: true,
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton(
                onPressed: _save,
                child: Text(l10n.prayerTuningElevationSave),
              ),
              if (_settings.elevation != null)
                TextButton(
                  onPressed: () =>
                      ref.read(prayerProvider.notifier).setElevation(null),
                  child: Text(l10n.prayerTuningElevationUseDevice),
                ),
            ],
          ),
          if (shift.sunset > 0) ...[
            const SizedBox(height: 8),
            AppNotice(
              l10n.prayerTuningElevationEffect(
                l10n.minutesCount(shift.sunset, digits(shift.sunset)),
              ),
              icon: Icons.landscape_outlined,
            ),
          ],
        ],
      ),
    );
  }
}

/// The Hijri date moved by a day or two.
class _HijriSection extends ConsumerWidget {
  const _HijriSection({required this.shift});

  final int shift;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final displayDigits = ref.watch(displayDigitsFormatterProvider);
    final notifier = ref.read(prayerProvider.notifier);
    final today = HijriDate.of(ref.watch(clockProvider)(), shift: shift);
    const limit = PrayerSettings.maxHijriShift;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSectionHeader(
          title: l10n.prayerTuningHijriTitle,
          subtitle: l10n.prayerTuningHijriHint,
        ),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppStepper(
                label: _label(l10n, shift),
                highlighted: shift != 0,
                decreaseLabel: l10n.prayerTuningHijriBackButton,
                increaseLabel: l10n.prayerTuningHijriForwardButton,
                onDecrease: shift > -limit
                    ? () => notifier.setHijriShift(shift - 1)
                    : null,
                onIncrease: shift < limit
                    ? () => notifier.setHijriShift(shift + 1)
                    : null,
              ),
              const SizedBox(height: 8),
              Text(
                l10n.prayerTuningHijriToday(
                  hijriLabel(l10n, today, displayDigits),
                ),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static String _label(AppLocalizations l10n, int shift) => switch (shift) {
    0 => l10n.prayerTuningHijriNone,
    < 0 => l10n.prayerTuningHijriBack(-shift),
    _ => l10n.prayerTuningHijriForward(shift),
  };
}
