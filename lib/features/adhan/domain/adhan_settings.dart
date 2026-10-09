import 'package:flutter/foundation.dart';

import 'adhan_voice.dart';

/// How the alert at prayer time sounds and behaves.
@immutable
class AdhanSettings {
  /// Creates the settings.
  const AdhanSettings({
    this.voiceId = AdhanVoice.defaultId,
    this.playAdhan = true,
    this.stopWhenFlipped = true,
  });

  /// The chosen voice.
  final String voiceId;

  /// Whether the adhan plays on its own, with a notice that stays until it is
  /// stopped, like an incoming call. Otherwise it is a normal notification.
  final bool playAdhan;

  /// Whether turning the phone face down stops the adhan.
  final bool stopWhenFlipped;

  /// A copy with the given changes.
  AdhanSettings copyWith({
    String? voiceId,
    bool? playAdhan,
    bool? stopWhenFlipped,
  }) => AdhanSettings(
    voiceId: voiceId ?? this.voiceId,
    playAdhan: playAdhan ?? this.playAdhan,
    stopWhenFlipped: stopWhenFlipped ?? this.stopWhenFlipped,
  );

  @override
  bool operator ==(Object other) =>
      other is AdhanSettings &&
      other.voiceId == voiceId &&
      other.playAdhan == playAdhan &&
      other.stopWhenFlipped == stopWhenFlipped;

  @override
  int get hashCode => Object.hash(voiceId, playAdhan, stopWhenFlipped);
}
