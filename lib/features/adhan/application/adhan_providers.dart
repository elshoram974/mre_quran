import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/notifications/reminder_payload.dart';
import '../../../core/notifications/reminder_tap.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../data/adhan_catalog.dart';
import '../data/adhan_platform.dart';
import '../data/adhan_repository.dart';
import '../data/voice_store.dart';
import '../domain/adhan_settings.dart';
import '../domain/adhan_voice.dart';

/// Provides the adhan choices store.
final adhanRepositoryProvider = Provider<AdhanRepository>(
  (ref) => LocalAdhanRepository(SharedPreferencesAsync()),
);

/// Provides the list of voices. Tests override it.
final adhanCatalogSourceProvider = Provider<AdhanCatalogSource>(
  (ref) => const AssetAdhanCatalog(),
);

/// Provides the saved recordings. Tests override it.
final voiceStoreProvider = Provider<VoiceStore>((ref) => FileVoiceStore());

/// Provides what only the platform can do. Tests override it.
final adhanPlatformProvider = Provider<AdhanPlatform>(
  (ref) => ChannelAdhanPlatform(),
);

/// What the adhan's notice opens when it is tapped: the one that started the
/// app (if any), then each tap while the app runs.
final adhanTapsProvider = StreamProvider<ReminderTap>((ref) async* {
  final platform = ref.watch(adhanPlatformProvider);
  final launch = await platform.takeLaunchPayload();
  if (launch != null) yield ReminderTap(launch);
  yield* platform.taps.map(ReminderTap.new);
});

/// Whether this phone can play the adhan by itself.
final adhanSupportedProvider = FutureProvider<bool>(
  (ref) => ref.watch(adhanPlatformProvider).isSupported(),
);

/// The voices the app knows about, the bundled one first.
final adhanCatalogProvider = FutureProvider<List<AdhanVoice>>(
  (ref) => ref.watch(adhanCatalogSourceProvider).load(),
);

/// How the alert behaves.
final adhanSettingsProvider =
    AsyncNotifierProvider<AdhanSettingsNotifier, AdhanSettings>(
      AdhanSettingsNotifier.new,
    );

/// Owns the saved adhan choices.
class AdhanSettingsNotifier extends AsyncNotifier<AdhanSettings> {
  @override
  Future<AdhanSettings> build() => ref.read(adhanRepositoryProvider).load();

  /// Applies [change] and saves the result.
  Future<void> change(AdhanSettings Function(AdhanSettings) change) async {
    final next = change(state.value ?? const AdhanSettings());
    state = AsyncData(next);
    await ref.read(adhanRepositoryProvider).save(next);
  }
}

/// Builds what the platform needs to play the adhan: the chosen recording's
/// file (null for the bundled one), the stop button's text, and what a tap on
/// the notice opens. Falls back to the bundled voice when the chosen file is
/// gone.
Future<AdhanAlertConfig> buildAdhanConfig({
  required AdhanSettings settings,
  required List<AdhanVoice> voices,
  required VoiceStore store,
  required AppLocalizations l10n,
}) async {
  String? path;
  if (settings.voiceId == AdhanVoice.customId) {
    final custom = settings.customPath;
    if (custom != null && File(custom).existsSync()) path = custom;
  } else if (settings.voiceId != AdhanVoice.defaultId) {
    for (final voice in voices) {
      if (voice.id == settings.voiceId) {
        path = (await store.fileOf(voice))?.path;
      }
    }
  }
  return AdhanAlertConfig(
    voicePath: path,
    stopWhenFlipped: settings.stopWhenFlipped,
    stopLabel: l10n.adhanStopAction,
    channelName: l10n.adhanChannelName,
    payload: ReminderPayload.prayerTimes,
  );
}

/// Where a voice's file stands on the phone.
@immutable
sealed class VoiceStatus {
  const VoiceStatus();
}

/// Not on the phone.
class VoiceAvailable extends VoiceStatus {
  /// Creates the status. [failure] says why the last try did not work.
  const VoiceAvailable({this.failure});

  /// Why the last download failed, if it did.
  final VoiceDownloadFailure? failure;
}

/// Coming down.
class VoiceDownloading extends VoiceStatus {
  /// Creates the status, [progress] being 0 to 1.
  const VoiceDownloading(this.progress);

  /// How much has arrived.
  final double progress;
}

/// On the phone (or bundled).
class VoiceReady extends VoiceStatus {
  /// Creates the status.
  const VoiceReady();
}

/// The voices, where each stands, and which one is being listened to.
@immutable
class VoicesState {
  /// Creates the state.
  const VoicesState({
    required this.voices,
    required this.statuses,
    this.listening,
  });

  /// The catalogue.
  final List<AdhanVoice> voices;

  /// By voice id.
  final Map<String, VoiceStatus> statuses;

  /// The id being previewed, if any.
  final String? listening;

  /// The status of [id].
  VoiceStatus statusOf(String id) => statuses[id] ?? const VoiceAvailable();

  /// A copy with the given changes.
  VoicesState copyWith({
    Map<String, VoiceStatus>? statuses,
    String? listening,
    bool clearListening = false,
  }) => VoicesState(
    voices: voices,
    statuses: statuses ?? this.statuses,
    listening: clearListening ? null : (listening ?? this.listening),
  );
}

/// Downloads, deletes, previews and chooses voices.
final adhanVoicesProvider =
    AsyncNotifierProvider.autoDispose<AdhanVoicesNotifier, VoicesState>(
      AdhanVoicesNotifier.new,
    );

/// Owns the state of the voices.
class AdhanVoicesNotifier extends AsyncNotifier<VoicesState> {
  final Map<String, VoiceDownloadToken> _tokens = {};

  VoiceStore get _store => ref.read(voiceStoreProvider);
  AdhanPlatform get _platform => ref.read(adhanPlatformProvider);

  @override
  Future<VoicesState> build() async {
    final voices = await ref.watch(adhanCatalogProvider.future);
    final ready = await _store.downloaded(voices);
    // Taken now: a provider cannot be read inside the callbacks below.
    final platform = _platform;
    final tokens = _tokens;
    final ended = platform.previewEnded.listen(
      (_) => _update((state) => state.copyWith(clearListening: true)),
    );
    ref.onDispose(() {
      unawaited(ended.cancel());
      for (final token in tokens.values) {
        token.cancel();
      }
      unawaited(platform.stopPreview());
    });
    return VoicesState(
      voices: voices,
      statuses: {for (final id in ready) id: const VoiceReady()},
    );
  }

  void _update(VoicesState Function(VoicesState) change) {
    final current = state.value;
    if (current != null) state = AsyncData(change(current));
  }

  void _setStatus(String id, VoiceStatus status) => _update(
    (state) => state.copyWith(statuses: {...state.statuses, id: status}),
  );

  /// Downloads [voice].
  Future<void> download(AdhanVoice voice) async {
    if (state.value?.statusOf(voice.id) is VoiceDownloading) return;
    final token = _tokens[voice.id] = VoiceDownloadToken();
    _setStatus(voice.id, const VoiceDownloading(0));
    try {
      await _store.download(
        voice,
        token: token,
        onProgress: (progress) =>
            _setStatus(voice.id, VoiceDownloading(progress)),
      );
      _setStatus(voice.id, const VoiceReady());
    } on VoiceDownloadException catch (error) {
      _setStatus(
        voice.id,
        VoiceAvailable(
          failure: error.failure == VoiceDownloadFailure.cancelled
              ? null
              : error.failure,
        ),
      );
    } finally {
      _tokens.remove(voice.id);
    }
  }

  /// Stops a download in progress.
  void cancel(AdhanVoice voice) => _tokens[voice.id]?.cancel();

  /// Removes the saved file. If it was the chosen voice, the bundled one is
  /// chosen instead.
  Future<void> delete(AdhanVoice voice) async {
    if (state.value?.listening == voice.id) await stopListening();
    await _store.delete(voice);
    _setStatus(voice.id, const VoiceAvailable());
    final settings = ref.read(adhanSettingsProvider).value;
    if (settings?.voiceId == voice.id) {
      await ref
          .read(adhanSettingsProvider.notifier)
          .change((value) => value.copyWith(voiceId: AdhanVoice.defaultId));
    }
  }

  /// Chooses [voice] for the alert. It must be on the phone.
  Future<void> choose(AdhanVoice voice) async {
    if (state.value?.statusOf(voice.id) is! VoiceReady) return;
    await ref
        .read(adhanSettingsProvider.notifier)
        .change((value) => value.copyWith(voiceId: voice.id));
  }

  /// Plays [voice], from the phone if it is there and from the network if not,
  /// or stops it when it is already playing.
  Future<void> toggleListening(AdhanVoice voice) async {
    final current = state.value;
    if (current == null) return;
    if (current.listening == voice.id) return stopListening();
    final AdhanPreviewSource source;
    if (voice.builtIn) {
      source = const BundledPreview();
    } else {
      final file = await _store.fileOf(voice);
      source = file != null
          ? FilePreview(file.path)
          : StreamPreview(voice.url!, HttpVoiceFetcher.userAgent);
    }
    _update((state) => state.copyWith(listening: voice.id));
    await _platform.preview(source);
  }

  /// Lets the person pick a recording from their phone, and uses it. Returns
  /// the pick so the page can say if the file was too large.
  Future<AudioPick?> pickCustom() async {
    final pick = await _platform.pickAudioFile();
    final path = pick?.path;
    final name = pick?.name;
    if (path != null && name != null) {
      await ref
          .read(adhanSettingsProvider.notifier)
          .change(
            (value) => value.copyWith(
              voiceId: AdhanVoice.customId,
              customPath: path,
              customName: name,
            ),
          );
    }
    return pick;
  }

  /// Forgets the picked file and deletes its copy. If it was in use, the
  /// bundled voice is used again.
  Future<void> deleteCustom() async {
    if (state.value?.listening == AdhanVoice.customId) await stopListening();
    final settings = ref.read(adhanSettingsProvider).value;
    final path = settings?.customPath;
    if (path != null) {
      final file = File(path);
      if (await file.exists()) await file.delete();
    }
    await ref
        .read(adhanSettingsProvider.notifier)
        .change(
          (value) => value.copyWith(
            clearCustom: true,
            voiceId: value.voiceId == AdhanVoice.customId
                ? AdhanVoice.defaultId
                : value.voiceId,
          ),
        );
  }

  /// Plays the picked file, or stops it when it is already playing.
  Future<void> toggleListeningCustom() async {
    final current = state.value;
    final path = ref.read(adhanSettingsProvider).value?.customPath;
    if (current == null || path == null) return;
    if (current.listening == AdhanVoice.customId) return stopListening();
    _update((state) => state.copyWith(listening: AdhanVoice.customId));
    await _platform.preview(FilePreview(path));
  }

  /// Stops the preview.
  Future<void> stopListening() async {
    _update((state) => state.copyWith(clearListening: true));
    await _platform.stopPreview();
  }
}
