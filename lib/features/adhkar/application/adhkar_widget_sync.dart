import 'package:flutter/services.dart';

import '../../../core/diagnostics/app_logger.dart';

/// Localized content rendered by the native suggested-dhikr home widget.
class AdhkarWidgetData {
  /// Creates the native widget payload.
  const AdhkarWidgetData({
    required this.label,
    required this.title,
    required this.done,
    required this.total,
    required this.payload,
    required this.rtl,
    this.progressLabel,
    this.useArabicDigits,
    this.tasbihLabel,
    this.tasbihResetLabel,
    this.tasbihCountLabel,
  });

  /// Whether this is a suggestion or an active list to resume.
  final String label;

  /// Localized collection title.
  final String title;

  /// Repetitions completed in the collection.
  final int done;

  /// Repetitions required to complete the collection.
  final int total;

  /// What a tap opens in the app.
  final String payload;

  /// Direction of the app's selected language.
  final bool rtl;

  /// Localized progress text using the app's digit preference.
  final String? progressLabel;

  /// Native tasbih presentation follows the app's digit preference.
  final bool? useArabicDigits;

  /// Localized native tasbih labels.
  final String? tasbihLabel;
  final String? tasbihResetLabel;
  final String? tasbihCountLabel;

  Map<String, Object> toMap() => {
    'label': label,
    'title': title,
    'done': done,
    'total': total,
    'payload': payload,
    'rtl': rtl,
    'progressLabel': ?progressLabel,
    'useArabicDigits': ?useArabicDigits,
    'tasbihLabel': ?tasbihLabel,
    'tasbihResetLabel': ?tasbihResetLabel,
    'tasbihCountLabel': ?tasbihCountLabel,
  };
}

/// Shares the current suggested adhkar list with Android and iOS widgets.
final class AdhkarWidgetSync {
  AdhkarWidgetSync._();

  static const _channel = MethodChannel('net.mrecode.mre_quran/adhkar_widget');

  /// Replaces native widget data, or clears it while adhkar are unavailable.
  static Future<void> update(AdhkarWidgetData? data) async {
    try {
      await _channel.invokeMethod<void>('update', data?.toMap());
    } on MissingPluginException {
      // Native home widgets exist only on Android and iOS.
    } on PlatformException catch (error) {
      AppLogger.debug('Adhkar widget update failed: ${error.code}');
    }
  }
}
