import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mre_fields/mre_fields.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_notice.dart';
import '../../../core/widgets/app_page_scaffold.dart';
import '../../settings/application/digits_provider.dart';
import '../application/place_search_provider.dart';
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
  final TextEditingController _searchController = TextEditingController();
  PrayerPlace? _selected;
  LatLng? _cameraTarget;
  List<PrayerPlace> _searchResults = const [];
  bool _mapInteractionStarted = false;
  bool _restoredSavedPlace = false;
  bool _searching = false;

  /// Whether the last search found no place at all. A search that found one
  /// and moved the map there is not a failed search.
  bool _notFound = false;
  PrayerResult _locationResult = PrayerResult.ok;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final formatDigits = ref.watch(displayDigitsFormatterProvider);
    final stored = ref.watch(prayerProvider).value?.place;
    final selected = _selected ?? stored;
    final initial = selected == null
        ? _world
        : LatLng(selected.latitude, selected.longitude);
    if (stored != null && !_restoredSavedPlace) {
      _restoredSavedPlace = true;
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _restoreSavedPlace(stored),
      );
    }
    final results = _searchResults;
    return AppPageScaffold(
      title: l10n.prayerMapTitle,
      // The search bar above and the save panel below sit beside the map, not
      // over it, so the map's own buttons and the pin are never covered.
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(
                AppTokens.gutterCompact,
                AppTokens.spaceSmall,
                AppTokens.gutterCompact,
                AppTokens.spaceSmall,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: MRETextField(
                      controller: _searchController,
                      hintText: l10n.prayerMapSearchHint,
                      prefixIcon: const Icon(Icons.search),
                      showClearButton: true,
                      textInputAction: TextInputAction.search,
                      onFieldSubmitted: (_) => _search(),
                    ),
                  ),
                  const SizedBox(width: AppTokens.spaceSmall),
                  IconButton.filledTonal(
                    tooltip: l10n.prayerMapCurrentLocation,
                    onPressed: _useDeviceLocation,
                    icon: const Icon(Icons.my_location_outlined),
                  ),
                ],
              ),
            ),
          ),
          if (_searching) const LinearProgressIndicator(),
          Expanded(
            child: Stack(
              children: [
                RepaintBoundary(
                  child: GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: initial,
                      zoom: selected == null ? _worldZoom : _placeZoom,
                    ),
                    // Only what choosing a point needs: no 3D buildings,
                    // indoor maps, traffic, tilt, or rotation to draw.
                    buildingsEnabled: false,
                    indoorViewEnabled: false,
                    tiltGesturesEnabled: false,
                    rotateGesturesEnabled: false,
                    compassEnabled: false,
                    mapToolbarEnabled: false,
                    myLocationButtonEnabled: false,
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
                    // The pin sits on the camera target, the centre of the
                    // map; nothing covers the map, so no offset is needed.
                    child: Icon(Icons.location_pin, size: AppTokens.minTarget),
                  ),
                ),
                if (_notFound || results.isNotEmpty)
                  Align(
                    alignment: AlignmentDirectional.topCenter,
                    child: Padding(
                      padding: const EdgeInsetsDirectional.all(
                        AppTokens.gutterCompact,
                      ),
                      child: AppCard(
                        child: _notFound
                            ? AppNotice(l10n.prayerMapNoResults, error: true)
                            : Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  for (final result in results)
                                    TextButton(
                                      onPressed: () =>
                                          _selectSearchResult(result),
                                      child: Text(
                                        l10n.prayerPlaceLine(
                                          _coordinate(
                                            result.latitude,
                                            formatDigits,
                                          ),
                                          _coordinate(
                                            result.longitude,
                                            formatDigits,
                                          ),
                                        ),
                                        textAlign: TextAlign.start,
                                      ),
                                    ),
                                ],
                              ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          SafeArea(
            top: false,
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
      await _animateTo(target);
    } else {
      setState(() => _locationResult = result);
    }
  }

  Future<void> _restoreSavedPlace(PrayerPlace place) async {
    if (!mounted || _mapInteractionStarted) return;
    final target = LatLng(place.latitude, place.longitude);
    setState(() {
      _selected = place;
      _cameraTarget = target;
    });
    await _animateTo(target);
  }

  Future<void> _search() async {
    final query = _searchController.text;
    if (query.trim().isEmpty || _searching) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _searching = true;
      _notFound = false;
      _searchResults = const [];
    });
    final results = await ref
        .read(placeSearchSourceProvider)
        .search(query, Localizations.localeOf(context));
    if (!mounted) return;
    setState(() {
      _searching = false;
      _notFound = results.isEmpty;
      _searchResults = results;
    });
    if (results.length == 1) await _selectSearchResult(results.single);
  }

  Future<void> _selectSearchResult(PrayerPlace place) async {
    final target = LatLng(place.latitude, place.longitude);
    setState(() {
      _selected = place;
      _cameraTarget = target;
      _searchResults = const [];
    });
    await _animateTo(target);
  }

  Future<void> _animateTo(LatLng target) async {
    final controller = await _mapController.future;
    if (!mounted) return;
    await controller.animateCamera(
      CameraUpdate.newLatLngZoom(target, _placeZoom),
    );
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

  /// Zoom that shows the whole world, before a place is chosen.
  static const double _worldZoom = 1.5;

  /// Zoom that shows a neighbourhood around a chosen place.
  static const double _placeZoom = 14;

  static String _coordinate(
    double value,
    String Function(String) formatDigits,
  ) => formatDigits(value.toStringAsFixed(2));
}
