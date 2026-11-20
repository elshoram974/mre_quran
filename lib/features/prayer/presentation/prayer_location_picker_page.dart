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
import 'prayer_labels.dart';
import 'location_problem_notice.dart';

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
  PrayerPlace? _deviceFix;
  LatLng? _cameraTarget;
  List<PrayerPlace> _searchResults = const [];
  bool _mapInteractionStarted = false;
  bool _restoredSavedPlace = false;
  bool _searching = false;
  bool _locating = false;

  /// Whether the chosen place is being saved: the alerts are planned again for
  /// it, which takes a moment, and the page says so rather than seem stuck.
  bool _saving = false;

  /// What the chosen place is called, found in the background as it is chosen.
  String? _selectedName;
  PrayerPlace? _selectedNameFor;
  Timer? _nameTimer;

  /// What the places a search found are called, as they are found.
  final Map<PrayerPlace, String> _resultNames = {};

  /// Whether the last search found no place at all. A search that found one
  /// and moved the map there is not a failed search.
  bool _notFound = false;
  PrayerResult _locationResult = PrayerResult.ok;

  @override
  void dispose() {
    _nameTimer?.cancel();
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
              child: MRETextField(
                controller: _searchController,
                hintText: l10n.prayerMapSearchHint,
                suffixIcon: IconButton(
                  tooltip: l10n.prayerMapSearch,
                  onPressed: _searching ? null : _search,
                  icon: const Icon(Icons.search),
                ),
                showClearButton: true,
                textInputAction: TextInputAction.search,
                onFieldSubmitted: (_) => _search(),
              ),
            ),
          ),
          if (_searching || _locating || _saving)
            const LinearProgressIndicator(),
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
                const IgnorePointer(child: Center(child: _MapPin())),
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
                                  for (final result in results.take(
                                    _maxResults,
                                  ))
                                    _ResultTile(
                                      name: _resultNames[result],
                                      coordinates: l10n.prayerPlaceLine(
                                        formatPrayerCoordinate(
                                          result.latitude,
                                          formatDigits,
                                        ),
                                        formatPrayerCoordinate(
                                          result.longitude,
                                          formatDigits,
                                        ),
                                      ),
                                      onTap: () => _selectSearchResult(result),
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
            child: ConstrainedBox(
              // Small screens and large text: the panel scrolls rather than
              // push the map away.
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * 0.5,
              ),
              child: SingleChildScrollView(
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
                    _ChosenPlace(
                      hint: l10n.prayerMapHint,
                      online: l10n.prayerMapOnline,
                      place: selected == null
                          ? l10n.prayerMapNoPlace
                          // The name once it is found, else the numbers.
                          : selected.name != null ||
                                _selectedNameFor == selected
                          ? l10n.prayerPlaceNamed(
                              selected.name ?? _selectedName!,
                            )
                          : l10n.prayerPlaceLine(
                              formatPrayerCoordinate(
                                selected.latitude,
                                formatDigits,
                              ),
                              formatPrayerCoordinate(
                                selected.longitude,
                                formatDigits,
                              ),
                            ),
                      chosen: selected != null,
                    ),
                    if (_locationResult == PrayerResult.locationDenied) ...[
                      const SizedBox(height: AppTokens.spaceSmall),
                      LocationProblemNotice(
                        fallback: l10n.prayerLocationUnavailable,
                      ),
                    ],
                    const SizedBox(height: AppTokens.spaceSmall),
                    // A button with words: the way to the phone's own
                    // location is not left to an icon.
                    FilledButton.tonalIcon(
                      onPressed: _locating || _saving
                          ? null
                          : _useDeviceLocation,
                      icon: const Icon(Icons.my_location_outlined),
                      label: Text(l10n.prayerMapCurrentLocation),
                    ),
                    const SizedBox(height: AppTokens.spaceSmall),
                    FilledButton(
                      onPressed: selected == null || _saving ? null : _save,
                      child: _saving
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                  ),
                                ),
                                const SizedBox(width: AppTokens.spaceSmall),
                                Text(l10n.prayerMapSaving),
                              ],
                            )
                          : Text(l10n.prayerMapSave),
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
    if (_locating) return;
    setState(() => _locating = true);
    final place = await ref
        .read(prayerProvider.notifier)
        .previewDeviceLocation();
    if (!mounted) return;
    setState(() => _locating = false);
    if (place != null) {
      final target = LatLng(place.latitude, place.longitude);
      setState(() {
        _selected = place;
        _deviceFix = place;
        _cameraTarget = target;
        _locationResult = PrayerResult.ok;
      });
      _nameSelected(place);
      await _animateTo(target);
    } else {
      setState(() => _locationResult = PrayerResult.locationDenied);
    }
  }

  /// Looks up what [place] is called, a moment after the map stops moving, so
  /// panning does not ask for a name at every step.
  void _nameSelected(PrayerPlace place) {
    _nameTimer?.cancel();
    if (place.name != null) return;
    _nameTimer = Timer(const Duration(milliseconds: 500), () async {
      final locale = Localizations.localeOf(context);
      final name = await ref
          .read(placeNameSourceProvider)
          .nameOf(place, locale);
      if (!mounted || _selected != place || name == null) return;
      setState(() {
        _selectedName = name;
        _selectedNameFor = place;
      });
    });
  }

  Future<void> _restoreSavedPlace(PrayerPlace place) async {
    if (!mounted || _mapInteractionStarted) return;
    final target = LatLng(place.latitude, place.longitude);
    setState(() {
      _selected = place;
      _cameraTarget = target;
    });
    _nameSelected(place);
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
      _resultNames.clear();
    });
    if (results.length == 1) {
      await _selectSearchResult(results.single);
    } else {
      _nameResults(results);
    }
  }

  /// Looks up what each place found is called, so the list reads as names
  /// rather than numbers; a name that is not found leaves the numbers.
  void _nameResults(List<PrayerPlace> results) {
    final locale = Localizations.localeOf(context);
    final source = ref.read(placeNameSourceProvider);
    for (final place in results.take(_maxResults)) {
      unawaited(
        source.nameOf(place, locale).then((name) {
          if (!mounted || name == null || !_searchResults.contains(place)) {
            return;
          }
          setState(() => _resultNames[place] = name);
        }),
      );
    }
  }

  Future<void> _selectSearchResult(PrayerPlace place) async {
    final target = LatLng(place.latitude, place.longitude);
    setState(() {
      _selected = place;
      _deviceFix = null;
      _cameraTarget = target;
      _searchResults = const [];
    });
    _nameSelected(place);
    await _animateTo(target);
  }

  Future<void> _animateTo(LatLng target) async {
    final controller = await _mapController.future;
    if (!mounted) return;
    final update = CameraUpdate.newLatLngZoom(target, _placeZoom);
    if (MediaQuery.disableAnimationsOf(context)) {
      await controller.moveCamera(update);
    } else {
      await controller.animateCamera(update);
    }
  }

  void _selectCameraTarget() {
    final target = _cameraTarget;
    if (target == null || !_mapInteractionStarted) return;
    final place = PrayerPlace(target.latitude, target.longitude);
    setState(() => _selected = place);
    _nameSelected(place);
  }

  Future<void> _save() async {
    final selected = _selected;
    if (selected == null || _saving) return;
    setState(() => _saving = true);
    // Keep the name found for it, so the prayer page can say it at once.
    final named = selected.name == null && _selectedNameFor == selected
        ? selected.withName(_selectedName)
        : selected;
    try {
      await ref
          .read(prayerProvider.notifier)
          .setPlace(named, automaticLocation: selected == _deviceFix);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
    if (mounted) context.pop();
  }

  static const LatLng _world = LatLng(20, 0);

  /// The most places a search lists.
  static const int _maxResults = 5;

  /// Zoom that shows the whole world, before a place is chosen.
  static const double _worldZoom = 1.5;

  /// Zoom that shows a neighbourhood around a chosen place.
  static const double _placeZoom = 14;
}

/// The pin over the middle of the map. Its tip, not its centre, is the place:
/// a dot under the tip shows exactly where.
class _MapPin extends StatelessWidget {
  const _MapPin();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = scheme.error;
    const dot = 8.0;
    return Stack(
      alignment: AlignmentDirectional.center,
      clipBehavior: Clip.none,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: 0.35),
          ),
          child: const SizedBox.square(dimension: dot),
        ),
        Transform.translate(
          // The pin's tip, rather than its centre, on the camera target at
          // the centre of the map.
          offset: const Offset(0, -AppTokens.minTarget / 2),
          child: Icon(
            Icons.location_pin,
            size: AppTokens.minTarget,
            color: color,
            shadows: [
              Shadow(
                blurRadius: 4,
                color: scheme.shadow.withValues(alpha: 0.35),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// One place a search found: its name when it is known, always its numbers.
class _ResultTile extends StatelessWidget {
  const _ResultTile({
    required this.name,
    required this.coordinates,
    required this.onTap,
  });

  final String? name;
  final String coordinates;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      dense: name == null,
      leading: const Icon(Icons.place_outlined),
      title: Text(name ?? coordinates),
      subtitle: name == null ? null : Text(coordinates),
      subtitleTextStyle: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
      onTap: onTap,
    );
  }
}

/// What to do on the map, the place now chosen, and what the map needs.
class _ChosenPlace extends StatelessWidget {
  const _ChosenPlace({
    required this.hint,
    required this.online,
    required this.place,
    required this.chosen,
  });

  final String hint;
  final String online;
  final String place;
  final bool chosen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.touch_app_outlined, size: 20, color: scheme.primary),
              const SizedBox(width: AppTokens.spaceSmall),
              Expanded(child: Text(hint, style: theme.textTheme.titleSmall)),
            ],
          ),
          const SizedBox(height: AppTokens.spaceSmall),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                chosen ? Icons.location_on : Icons.location_off_outlined,
                size: 20,
                color: chosen ? scheme.primary : scheme.onSurfaceVariant,
              ),
              const SizedBox(width: AppTokens.spaceSmall),
              Expanded(
                child: Text(
                  place,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: chosen ? FontWeight.w700 : null,
                    color: chosen ? null : scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTokens.spaceSmall),
          Text(
            online,
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
