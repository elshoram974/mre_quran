import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/haptics/haptics.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/layout/adaptive_layout.dart';
import '../../../core/widgets/app_notice.dart';
import '../../../core/widgets/app_page_scaffold.dart';
import '../../../core/widgets/app_shimmer.dart';
import '../../../core/widgets/empty_state.dart';
import '../../settings/application/digits_provider.dart';
import '../application/compass_provider.dart';
import '../application/prayer_provider.dart';
import '../domain/qibla.dart';
import 'prayer_labels.dart';
import 'prayer_no_place.dart';
import 'qibla_compass.dart';

/// How close to the Qibla, in degrees, counts as facing it.
const double qiblaTolerance = 4;

/// A compass that points to the Qibla from the person's approximate place.
/// Everything is worked out on the phone: the place stays on the device and
/// the sensors need no permission.
class QiblaPage extends ConsumerStatefulWidget {
  /// Creates the page.
  const QiblaPage({super.key});

  @override
  ConsumerState<QiblaPage> createState() => _QiblaPageState();
}

class _QiblaPageState extends ConsumerState<QiblaPage> {
  PrayerResult _result = PrayerResult.ok;
  bool _aligned = false;

  Future<void> _locate() async {
    final result = await ref.read(prayerProvider.notifier).locate();
    if (mounted) setState(() => _result = result);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = ref.watch(prayerProvider);
    return AppPageScaffold(
      title: l10n.qiblaTitle,
      body: state.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(16),
          child: AppShimmer(child: SkeletonBox(height: 320)),
        ),
        error: (_, _) => EmptyState(
          icon: Icons.error_outline,
          title: l10n.adhkarLoadError,
          message: '',
          actionLabel: l10n.retry,
          onAction: () => ref.invalidate(prayerProvider),
        ),
        data: (data) {
          final place = data.place;
          if (place == null) {
            return ContentContainer(
              child: PrayerNoPlace(
                denied: _result == PrayerResult.locationDenied,
                onLocate: _locate,
                onChooseMap: () =>
                    context.push(AppRoute.prayerLocationPicker.path),
              ),
            );
          }
          return ContentContainer(
            child: _Compass(qibla: qiblaBearing(place), onAligned: _setAligned),
          );
        },
      ),
    );
  }

  /// Ticks once when the phone comes round to the Qibla, not on every reading.
  void _setAligned(bool aligned) {
    if (aligned == _aligned) return;
    _aligned = aligned;
    if (aligned) Haptics.step();
  }
}

class _Compass extends ConsumerWidget {
  const _Compass({required this.qibla, required this.onAligned});

  final double qibla;
  final ValueChanged<bool> onAligned;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final digits = ref.watch(digitsFormatterProvider);
    final reading = ref.watch(compassHeadingProvider);
    final heading = reading.value;
    final noSensor = reading.hasError;
    final turn = heading == null ? null : angleBetween(heading, qibla);
    final aligned = turn != null && turn.abs() <= qiblaTolerance;
    // Report after the frame so the page does not rebuild while building.
    WidgetsBinding.instance.addPostFrameCallback((_) => onAligned(aligned));

    final degrees = digits(qibla.round());
    final point = compassPointName(l10n, CompassPoint.of(qibla));
    return LayoutBuilder(
      builder: (context, constraints) {
        final dial = math.min(constraints.maxWidth, 360.0);
        return ListView(
          padding: pagePadding(context),
          children: [
            Text(
              l10n.qiblaDirectionLine(degrees, point),
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Center(
              child: SizedBox.square(
                dimension: dial,
                child: QiblaCompass(
                  qibla: qibla,
                  heading: heading,
                  aligned: aligned,
                  letters: [
                    l10n.compassLetterNorth,
                    l10n.compassLetterEast,
                    l10n.compassLetterSouth,
                    l10n.compassLetterWest,
                  ],
                  semanticLabel: l10n.qiblaSemantics(degrees, point),
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (turn != null)
              Semantics(
                liveRegion: aligned,
                child: Text(
                  aligned
                      ? l10n.qiblaAligned
                      : turn > 0
                      ? l10n.qiblaTurnRight(digits(turn.abs().round()))
                      : l10n.qiblaTurnLeft(digits(turn.abs().round())),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: aligned ? theme.colorScheme.primary : null,
                  ),
                ),
              ),
            const SizedBox(height: 16),
            if (noSensor)
              AppNotice(l10n.qiblaNoSensor)
            else ...[
              AppNotice(l10n.qiblaHintFlat, icon: Icons.phone_android),
              const SizedBox(height: 8),
              AppNotice(l10n.qiblaHintCalibrate, icon: Icons.gesture),
            ],
            const SizedBox(height: 8),
            AppNotice(l10n.qiblaPlaceNote, icon: Icons.lock_outline),
          ],
        );
      },
    );
  }
}
