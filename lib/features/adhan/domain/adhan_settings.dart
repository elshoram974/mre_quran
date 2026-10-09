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
    this.customPath,
    this.customName,
  });

  /// The chosen voice: a catalogue id, or [AdhanVoice.customId].
  final String voiceId;

  /// Whether the adhan plays on its own, with a notice that stays until it is
  /// stopped, like an incoming call. Otherwise it is a normal notification.
  final bool playAdhan;

  /// Whether turning the phone face down stops the adhan.
  final bool stopWhenFlipped;

  /// Where the file the person picked from their phone was copied to.
  final String? customPath;

  /// That file's name, as the person knows it.
  final String? customName;

  /// Whether the person has picked a file of their own.
  bool get hasCustom => customPath != null;

  /// A copy with the given changes. [clearCustom] forgets the picked file.
  AdhanSettings copyWith({
    String? voiceId,
    bool? playAdhan,
    bool? stopWhenFlipped,
    String? customPath,
    String? customName,
    bool clearCustom = false,
  }) => AdhanSettings(
    voiceId: voiceId ?? this.voiceId,
    playAdhan: playAdhan ?? this.playAdhan,
    stopWhenFlipped: stopWhenFlipped ?? this.stopWhenFlipped,
    customPath: clearCustom ? null : (customPath ?? this.customPath),
    customName: clearCustom ? null : (customName ?? this.customName),
  );

  @override
  bool operator ==(Object other) =>
      other is AdhanSettings &&
      other.voiceId == voiceId &&
      other.playAdhan == playAdhan &&
      other.stopWhenFlipped == stopWhenFlipped &&
      other.customPath == customPath &&
      other.customName == customName;

  @override
  int get hashCode =>
      Object.hash(voiceId, playAdhan, stopWhenFlipped, customPath, customName);
}
