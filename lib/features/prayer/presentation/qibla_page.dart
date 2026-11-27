import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/layout/adaptive_layout.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_notice.dart';
import '../../../core/widgets/app_page_scaffold.dart';
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
///
/// The page is drawn at once, before the place has loaded: the dial and the
/// hints are in their places, dimmed and inert, and the bar says it is
/// loading. It comes alive where it stands when the place arrives.
class QiblaPage extends ConsumerStatefulWidget {
  /// Creates the page.
  const QiblaPage({super.key});

  @override
  ConsumerState<QiblaPage> createState() => _QiblaPageState();
}

/// What the page shows, so a change from one to another cross-fades.
enum _View { compass, noPlace, error }

class _QiblaPageState extends ConsumerState<QiblaPage> {
  PrayerResult _result = PrayerResult.ok;
  bool _locating = false;

  Future<void> _locate() async {
    setState(() => _locating = true);
    try {
      final result = await ref.read(prayerProvider.notifier).locate();
      if (mounted) setState(() => _result = result);
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = ref.watch(prayerProvider);
    final data = state.value;
    final place = data?.place;
    final Widget body;
    if (state.hasError) {
      body = EmptyState(
        key: const ValueKey(_View.error),
        icon: Icons.error_outline,
        title: l10n.adhkarLoadError,
        message: '',
        actionLabel: l10n.retry,
        onAction: () => ref.invalidate(prayerProvider),
      );
    } else if (data != null && place == null) {
      body = ContentContainer(
        key: const ValueKey(_View.noPlace),
        child: PrayerNoPlace(
          denied: _result == PrayerResult.locationDenied,
          onLocate: _locate,
          onChooseMap: () => context.push(AppRoute.prayerLocationPicker.path),
        ),
      );
    } else {
      // Loading or loaded, it is the same compass: it comes alive in place.
      body = ContentContainer(
        key: const ValueKey(_View.compass),
        child: _Compass(qibla: place == null ? null : qiblaBearing(place)),
      );
    }
    return AppPageScaffold(
      title: l10n.qiblaTitle,
      // Also while the place the person asked for is being read.
      loading: state.isLoading || (_locating && place == null),
      body: AnimatedSwitcher(
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : AppTokens.motionMedium,
        child: body,
      ),
    );
  }
}

class _Compass extends ConsumerWidget {
  const _Compass({required this.qibla});

  /// The Qibla's bearing, or null while the place is loading: everything is
  /// drawn in its place, inert.
  final double? qibla;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final qibla = this.qibla;
    final inert = qibla == null;
    final digits = ref.watch(digitsFormatterProvider);
    // The heading and the tilt change many times a second: only the dial and
    // the lines that follow them are rebuilt, not the whole page. Nothing is
    // read from the sensors before there is a bearing to turn to.
    final noSensor = !inert && ref.watch(compassMissingProvider);
    String? line;
    String? semanticLabel;
    String? noSensorNote;
    if (qibla != null) {
      final degrees = digits(qibla.round());
      final point = compassPointName(l10n, CompassPoint.of(qibla));
      line = l10n.qiblaDirectionLine(degrees, point);
      semanticLabel = l10n.qiblaSemantics(degrees, point);
      if (noSensor) {
        // The dial's angle is from true north; whoever finds north with a
        // hand compass needs it from magnetic north.
        final onCompass =
            ref.watch(magneticFieldProvider)?.magneticFromTrue(qibla) ?? qibla;
        noSensorNote = l10n.qiblaNoSensor(digits(onCompass.round() % 360));
      }
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final dial = math.min(constraints.maxWidth, 360.0);
        return IgnorePointer(
          ignoring: inert,
          child: AnimatedOpacity(
            opacity: inert ? AppTokens.inertOpacity : 1,
            duration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : AppTokens.motionMedium,
            child: ListView(
              padding: pagePadding(context),
              children: [
                _DirectionLine(line),
                const SizedBox(height: 16),
                Center(
                  child: SizedBox.square(
                    dimension: dial,
                    child: _Dial(
                      qibla: qibla,
                      letters: [
                        l10n.compassLetterNorth,
                        l10n.compassLetterEast,
                        l10n.compassLetterSouth,
                        l10n.compassLetterWest,
                      ],
                      semanticLabel: semanticLabel,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (!noSensor) _TurnLine(qibla: qibla),
                const SizedBox(height: 16),
                if (noSensorNote != null)
                  AppNotice(noSensorNote)
                else ...[
                  _FlatHint(live: !inert),
                  const SizedBox(height: 8),
                  AppNotice(l10n.qiblaHintCalibrate, icon: Icons.gesture),
                ],
                const SizedBox(height: 8),
                AppNotice(l10n.qiblaPlaceNote, icon: Icons.lock_outline),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// The Qibla's bearing in words. Its line is kept while the bearing is not
/// known, so nothing under it moves when the words arrive; where large text
/// needs a second line for them, the room for it eases open.
class _DirectionLine extends StatelessWidget {
  const _DirectionLine(this.text);

  final String? text;

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.disableAnimationsOf(context);
    final line = AnimatedSwitcher(
      duration: still ? Duration.zero : AppTokens.motionMedium,
      child: Text(
        text ?? '',
        key: ValueKey(text),
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.titleLarge,
      ),
    );
    // With animations off the room is simply there (and an AnimatedSize
    // cannot be given no time at all).
    if (still) return line;
    return AnimatedSize(
      duration: AppTokens.motionMedium,
      alignment: AlignmentDirectional.topCenter,
      child: line,
    );
  }
}

/// The dial, redrawn with each reading of the compass.
class _Dial extends ConsumerWidget {
  const _Dial({
    required this.qibla,
    required this.letters,
    required this.semanticLabel,
  });

  final double? qibla;
  final List<String> letters;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final qibla = this.qibla;
    final heading = qibla == null ? null : ref.watch(compassHeadingProvider);
    final tilt = qibla == null ? null : ref.watch(phoneTiltProvider);
    final turn = heading == null || qibla == null
        ? null
        : angleBetween(heading, qibla);
    return QiblaCompass(
      qibla: qibla,
      heading: heading,
      // Facing the Qibla is only claimed of a level phone, or of one that
      // cannot tell how it is held.
      aligned:
          turn != null && turn.abs() <= qiblaTolerance && (tilt?.level ?? true),
      tilt: tilt,
      letters: letters,
      semanticLabel: semanticLabel,
    );
  }
}

/// Which way to turn, and by how many degrees: rebuilt only when that whole
/// number, pointing at the Qibla, or being level changes. Its line is kept
/// before the first reading, so nothing under it moves when one comes.
class _TurnLine extends ConsumerWidget {
  const _TurnLine({required this.qibla});

  final double? qibla;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final qibla = this.qibla;
    final turn = qibla == null
        ? null
        : ref.watch(
            compassHeadingProvider.select((heading) {
              if (heading == null) return null;
              final turn = angleBetween(heading, qibla);
              return (
                degrees: turn.round(),
                pointing: turn.abs() <= qiblaTolerance,
              );
            }),
          );
    // Null where the phone cannot tell how it is held: nothing is asked of
    // it then.
    final level = qibla == null
        ? null
        : ref.watch(phoneTiltProvider.select((tilt) => tilt?.level));
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final digits = ref.watch(digitsFormatterProvider);
    final pointing = turn?.pointing ?? false;
    final aligned = pointing && (level ?? true);
    return Semantics(
      // Said aloud when the phone comes round to the Qibla, not at every
      // degree on the way.
      liveRegion: pointing,
      child: Text(
        turn == null
            ? ''
            : aligned
            ? l10n.qiblaAligned
            : pointing
            // Tilted, the dial cannot be trusted to the last few degrees.
            ? l10n.qiblaHoldFlat
            : turn.degrees > 0
            ? l10n.qiblaTurnRight(digits(turn.degrees.abs()))
            : l10n.qiblaTurnLeft(digits(turn.degrees.abs())),
        textAlign: TextAlign.center,
        style: theme.textTheme.titleMedium?.copyWith(
          color: aligned ? theme.colorScheme.primary : null,
        ),
      ),
    );
  }
}

/// "Hold the phone flat", made live where the phone can tell how it is held:
/// it confirms a level phone, and asks again of a tilted one. Rebuilt only
/// when that changes, not with every reading.
class _FlatHint extends ConsumerWidget {
  const _FlatHint({required this.live});

  /// Whether the page is live. Inert, the hint is only the advice.
  final bool live;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final level = live
        ? ref.watch(phoneTiltProvider.select((tilt) => tilt?.level))
        : null;
    final l10n = context.l10n;
    final advice = AppNotice(l10n.qiblaHintFlat, icon: Icons.phone_android);
    if (level == null) return advice;
    // Its words change only when the phone becomes level or stops being so,
    // and that is when screen readers say them.
    return Semantics(
      liveRegion: true,
      child: level ? AppNotice(l10n.qiblaLevel, confirmed: true) : advice,
    );
  }
}
