import 'package:flutter/foundation.dart';

import 'adhan_voice.dart';

/// Whose voice says the dua after the adhan.
enum AdhanDua {
  /// Sheikh Muhammad Metwalli Al-Shaarawy.
  shaarawy('dua_after_adhan_shaarawy'),

  /// Sheikh Mishary Rashid Alafasy, the voice of the bundled adhan.
  mishary('dua_after_adhan_mishary');

  const AdhanDua(this.recording);

  /// The bundled recording's name.
  final String recording;

  /// The dua stored as [name], or the default.
  static AdhanDua parse(String? name) => values.firstWhere(
    (dua) => dua.name == name,
    orElse: () => AdhanDua.shaarawy,
  );
}

/// How the alert at prayer time sounds and behaves.
@immutable
class AdhanSettings {
  /// Creates the settings.
  const AdhanSettings({
    this.voiceId = AdhanVoice.defaultId,
    this.fajrVoiceId = AdhanVoice.defaultFajrId,
    this.announce = true,
    this.duaAfter = true,
    this.dua = AdhanDua.shaarawy,
    this.playAdhan = true,
    this.stopWhenFlipped = true,
    this.customPath,
    this.customName,
  });

  /// The chosen voice: a catalogue id, or [AdhanVoice.customId].
  final String voiceId;

  /// The chosen Fajr voice: a catalogue id of a Fajr recording. Fajr has
  /// its own, as its adhan says "الصلاة خير من النوم".
  final String fajrVoiceId;

  /// Whether the prayer is announced before the adhan: "حان الآن موعد أذان
  /// الظهر".
  final bool announce;

  /// Whether the dua after the adhan is played after it.
  final bool duaAfter;

  /// Whose voice says it.
  final AdhanDua dua;

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
    String? fajrVoiceId,
    bool? announce,
    bool? duaAfter,
    AdhanDua? dua,
    bool? playAdhan,
    bool? stopWhenFlipped,
    String? customPath,
    String? customName,
    bool clearCustom = false,
  }) => AdhanSettings(
    voiceId: voiceId ?? this.voiceId,
    fajrVoiceId: fajrVoiceId ?? this.fajrVoiceId,
    announce: announce ?? this.announce,
    duaAfter: duaAfter ?? this.duaAfter,
    dua: dua ?? this.dua,
    playAdhan: playAdhan ?? this.playAdhan,
    stopWhenFlipped: stopWhenFlipped ?? this.stopWhenFlipped,
    customPath: clearCustom ? null : (customPath ?? this.customPath),
    customName: clearCustom ? null : (customName ?? this.customName),
  );

  @override
  bool operator ==(Object other) =>
      other is AdhanSettings &&
      other.voiceId == voiceId &&
      other.fajrVoiceId == fajrVoiceId &&
      other.announce == announce &&
      other.duaAfter == duaAfter &&
      other.dua == dua &&
      other.playAdhan == playAdhan &&
      other.stopWhenFlipped == stopWhenFlipped &&
      other.customPath == customPath &&
      other.customName == customName;

  @override
  int get hashCode => Object.hash(
    voiceId,
    fajrVoiceId,
    announce,
    duaAfter,
    dua,
    playAdhan,
    stopWhenFlipped,
    customPath,
    customName,
  );
}
