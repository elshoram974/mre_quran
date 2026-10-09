import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/layout/adaptive_layout.dart';
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
  PrayerPlace? _selected;
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
      body: ContentContainer(
        child: Padding(
          padding: pagePadding(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppNotice(l10n.prayerMapHint),
              const SizedBox(height: 12),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppTokens.radiusCard),
                  child: GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: initial,
                      zoom: selected == null ? 1.5 : 10,
                    ),
                    markers: selected == null
                        ? const {}
                        : {
                            Marker(
                              markerId: const MarkerId('prayer-place'),
                              position: LatLng(
                                selected.latitude,
                                selected.longitude,
                              ),
                            ),
                          },
                    myLocationButtonEnabled: false,
                    compassEnabled: true,
                    onTap: (point) => setState(
                      () => _selected = PrayerPlace(
                        point.latitude,
                        point.longitude,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (selected == null)
                Text(
                  l10n.prayerMapSelect,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                )
              else
                Text(
                  l10n.prayerPlaceLine(
                    _coordinate(selected.latitude, formatDigits),
                    _coordinate(selected.longitude, formatDigits),
                  ),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              if (_locationResult == PrayerResult.locationDenied) ...[
                const SizedBox(height: 8),
                AppNotice(l10n.adhkarLocationDenied, error: true),
              ],
              const SizedBox(height: 12),
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                runSpacing: 8,
                spacing: 8,
                children: [
                  TextButton.icon(
                    onPressed: _useDeviceLocation,
                    icon: const Icon(Icons.my_location_outlined),
                    label: Text(l10n.prayerMapCurrentLocation),
                  ),
                  FilledButton(
                    onPressed: selected == null ? null : _save,
                    child: Text(l10n.prayerMapSave),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _useDeviceLocation() async {
    final result = await ref.read(prayerProvider.notifier).locate();
    if (!mounted) return;
    if (result == PrayerResult.ok) {
      context.pop();
    } else {
      setState(() => _locationResult = result);
    }
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
