import 'package:flutter/services.dart';

import '../../../core/diagnostics/app_logger.dart';
import '../domain/prayer_times.dart';

/// Data rendered by the platform's next-prayer home-screen widget.
class PrayerWidgetData {
  /// Creates widget data from the already calculated next prayer.
  const PrayerWidgetData({
    required this.prayer,
    required this.label,
    required this.title,
    required this.time,
    required this.at,
    required this.useArabicDigits,
  });

  final DailyPrayer prayer;
  final String label;
  final String title;
  final String time;
  final DateTime at;
  final bool useArabicDigits;

  Map<String, Object> toMap() => {
    'prayer': prayer.name,
    'label': label,
    'title': title,
    'time': time,
    'at': at.millisecondsSinceEpoch,
    'useArabicDigits': useArabicDigits,
  };
}

/// Shares prayer data with native Android and iOS widgets.
///
/// The widgets render independently of Flutter. This bridge only writes fresh
/// data after the app calculates a new next prayer.
final class PrayerWidgetSync {
  PrayerWidgetSync._();

  static const _channel = MethodChannel('net.mrecode.mre_quran/prayer_widget');

  /// Replaces the widget's data, or clears it when no prayer place exists.
  static Future<void> update(PrayerWidgetData? data) async {
    try {
      await _channel.invokeMethod<void>('update', data?.toMap());
    } on MissingPluginException {
      // Widgets exist only on Android and iOS.
    } on PlatformException catch (error) {
      AppLogger.debug('Prayer widget update failed: ${error.code}');
    }
  }
}
