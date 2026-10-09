import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_notice.dart';
import '../../../core/widgets/app_page_scaffold.dart';
import '../../settings/application/digits_provider.dart';
import '../application/prayer_provider.dart';
import '../domain/prayer_times.dart';

/// Lets a person choose the coordinates used for prayer times without asking
/// for device-location permission.
class PrayerLocationPickerPage extends ConsumerStatefulWidget {
  /// Creates the Google Maps location picker.
  const PrayerLocationPickerPage({super.key});

  @override
  ConsumerState<PrayerLocationPickerPage> createState() =>
      _PrayerLocationPickerPageState();
}

class _PrayerLocationPickerPageState
    extends ConsumerState<PrayerLocationPickerPage> {
  final Completer<GoogleMapController> _mapController =
      Completer<GoogleMapController>();
  PrayerPlace? _selected;
  LatLng? _cameraTarget;
  bool _mapInteractionStarted = false;
  PrayerResult _locationResult = PrayerResult.ok;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final formatDigits = ref.watch(displayDigitsFormatterProvider);
    final stored = ref.watch(prayerProvider).value?.place;
    final selected = _selected ?? stored;
    final initial = selected == null
        ? _world
        : LatLng(selected.latitude, selected.longitude);
    return AppPageScaffold(
      title: l10n.prayerMapTitle,
      body: Stack(
        children: [
          RepaintBoundary(
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: initial,
                zoom: selected == null ? 1.5 : 14,
              ),
              myLocationButtonEnabled: false,
              compassEnabled: true,
              onMapCreated: (controller) {
                _mapController.complete(controller);
                _cameraTarget ??= initial;
              },
              onCameraMoveStarted: () => _mapInteractionStarted = true,
              onCameraMove: (position) => _cameraTarget = position.target,
              onCameraIdle: _selectCameraTarget,
            ),
          ),
          const IgnorePointer(
            child: Center(
              // The pin must sit on the camera target. Do not offset it for
              // controls below: the selected coordinates would be inaccurate.
              child: Icon(Icons.location_pin, size: AppTokens.minTarget),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsetsDirectional.all(AppTokens.gutterCompact),
              child: Align(
                alignment: AlignmentDirectional.topEnd,
                child: IconButton.filledTonal(
                  tooltip: l10n.prayerMapCurrentLocation,
                  onPressed: _useDeviceLocation,
                  icon: const Icon(Icons.my_location_outlined),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Align(
              alignment: AlignmentDirectional.bottomCenter,
              child: Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(
                  AppTokens.gutterCompact,
                  AppTokens.spaceMedium,
                  AppTokens.gutterCompact,
                  AppTokens.spaceMedium,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppNotice(
                      selected == null
                          ? l10n.prayerMapHint
                          : l10n.prayerPlaceLine(
                              _coordinate(selected.latitude, formatDigits),
                              _coordinate(selected.longitude, formatDigits),
                            ),
                    ),
                    if (_locationResult == PrayerResult.locationDenied) ...[
                      const SizedBox(height: AppTokens.spaceSmall),
                      AppNotice(l10n.adhkarLocationDenied, error: true),
                    ],
                    const SizedBox(height: AppTokens.spaceSmall),
                    FilledButton(
                      onPressed: selected == null ? null : _save,
                      child: Text(l10n.prayerMapSave),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _useDeviceLocation() async {
    final result = await ref.read(prayerProvider.notifier).locate();
    if (!mounted) return;
    if (result == PrayerResult.ok) {
      final place = ref.read(prayerProvider).value?.place;
      if (place == null) return;
      final target = LatLng(place.latitude, place.longitude);
      setState(() {
        _selected = place;
        _cameraTarget = target;
        _locationResult = PrayerResult.ok;
      });
      final controller = await _mapController.future;
      await controller.animateCamera(CameraUpdate.newLatLngZoom(target, 14));
    } else {
      setState(() => _locationResult = result);
    }
  }

  void _selectCameraTarget() {
    final target = _cameraTarget;
    if (target == null || !_mapInteractionStarted) return;
    setState(() => _selected = PrayerPlace(target.latitude, target.longitude));
  }

  Future<void> _save() async {
    final selected = _selected;
    if (selected == null) return;
    await ref.read(prayerProvider.notifier).setPlace(selected);
    if (mounted) context.pop();
  }

  static const LatLng _world = LatLng(20, 0);

  static String _coordinate(
    double value,
    String Function(String) formatDigits,
  ) => formatDigits(value.toStringAsFixed(2));
}
