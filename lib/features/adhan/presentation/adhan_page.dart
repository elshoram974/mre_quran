import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/layout/adaptive_layout.dart';
import '../../../core/notifications/reminder_scheduler_provider.dart';
import '../../../core/widgets/app_group_card.dart';
import '../../../core/widgets/app_notice.dart';
import '../../../core/widgets/app_page_scaffold.dart';
import '../../../core/widgets/app_section_header.dart';
import '../../../core/widgets/app_shimmer.dart';
import '../../../core/widgets/app_switch_tile.dart';
import '../../../core/widgets/app_tile_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../../settings/application/digits_provider.dart';
import '../application/adhan_providers.dart';
import '../data/voice_store.dart';
import '../domain/adhan_settings.dart';
import '../domain/adhan_voice.dart';
import '../../home_widgets/presentation/widget_hint.dart';
import '../../prayer/application/prayer_provider.dart';
import 'adhan_battery_notice.dart';
import 'custom_voice_card.dart';
import 'voice_card.dart';

/// Whether exact alarms are allowed (always true off Android).
final adhanExactAllowedProvider = FutureProvider.autoDispose<bool>(
  (ref) => ref.watch(reminderSchedulerProvider).canScheduleExact(),
);

/// How the adhan sounds and behaves: the voice, and its own for Fajr;
/// whether it plays by itself like a call, with the prayer announced before
/// it and the dua after it; and whether turning the phone over stops it.
class AdhanPage extends ConsumerWidget {
  /// Creates the page.
  const AdhanPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final supported = ref.watch(adhanSupportedProvider);
    final settings = ref.watch(adhanSettingsProvider);
    // Kept while the page is open. The section that reads them scrolls out of
    // view, and without this they were asked of the system again each time it
    // came back, and their notices popped in under the finger.
    ref
      ..listen(adhanExactAllowedProvider, (_, _) {})
      ..listen(adhanBatteryUnrestrictedProvider, (_, _) {});
    // Only the list and whether it failed: each card watches its own state,
    // so a download's progress does not rebuild the page.
    final voices = ref.watch(
      adhanVoicesProvider.select(
        (state) => (hasError: state.hasError, voices: state.value?.voices),
      ),
    );
    return AppPageScaffold(
      title: l10n.adhanTitle,
      body: Builder(
        builder: (context) {
          final padding = pagePadding(context);
          // Where the adhan cannot play by itself (iOS): what happens
          // instead, and a way to hear it.
          if (supported.value == false) {
            return ContentContainer(
              child: ListView(
                padding: padding,
                children: [
                  AppNotice(l10n.adhanUnsupported),
                  const SizedBox(height: 12),
                  AppTileCard(
                    icon: Icons.notifications_active_outlined,
                    title: l10n.adhanTest,
                    subtitle: l10n.adhanTestHint,
                    trailing: const Icon(Icons.play_arrow),
                    onTap: () async {
                      await ref.read(adhanTesterProvider)(l10n);
                      await Future<void>.delayed(const Duration(seconds: 6));
                      if (context.mounted) await offerWidgets(context, ref);
                    },
                  ),
                ],
              ),
            );
          }
          final error = settings.hasError || voices.hasError;
          if (error) {
            return EmptyState(
              icon: Icons.error_outline,
              title: l10n.adhkarLoadError,
              message: '',
              actionLabel: l10n.retry,
              onAction: () {
                ref
                  ..invalidate(adhanSettingsProvider)
                  ..invalidate(adhanCatalogProvider)
                  ..invalidate(adhanVoicesProvider);
              },
            );
          }
          final current = settings.value;
          final list = voices.voices;
          if (current == null || list == null) {
            return Padding(
              padding: padding,
              child: const AppShimmer(
                child: Column(
                  children: [
                    SkeletonBox(height: 160),
                    SizedBox(height: 12),
                    SkeletonBox(height: 140),
                  ],
                ),
              ),
            );
          }
          return ContentContainer(
            child: ListView(
              padding: padding,
              children: [
                AppSectionHeader(title: l10n.adhanSectionAlert),
                _AlertSection(settings: current),
                const SizedBox(height: 24),
                AppSectionHeader(
                  title: l10n.adhanVoices,
                  subtitle: l10n.adhanVoicesHint,
                ),
                for (final voice in list)
                  if (voice.kind == AdhanKind.regular) ...[
                    _VoiceTile(
                      voice: voice,
                      chosen: voice.id == current.voiceId,
                    ),
                    const SizedBox(height: 12),
                  ],
                Consumer(
                  builder: (context, ref, _) => CustomVoiceCard(
                    settings: current,
                    listening: ref.watch(
                      adhanVoicesProvider.select(
                        (state) =>
                            state.value?.listening == AdhanVoice.customId,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                AppSectionHeader(
                  title: l10n.adhanFajrVoices,
                  subtitle: l10n.adhanFajrVoicesHint,
                ),
                for (final voice in list)
                  if (voice.isFajr) ...[
                    _VoiceTile(
                      voice: voice,
                      chosen: voice.id == current.fajrVoiceId,
                    ),
                    const SizedBox(height: 12),
                  ],
                const SizedBox(height: 16),
                AppNotice(l10n.adhanLicenseNote),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _AlertSection extends ConsumerWidget {
  const _AlertSection({required this.settings});

  final AdhanSettings settings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final notifier = ref.read(adhanSettingsProvider.notifier);
    final exact = ref.watch(adhanExactAllowedProvider).value ?? true;
    final announcements = ref.watch(adhanAnnouncementsProvider).value ?? false;
    // A chosen dua that is not on the phone (its file deleted) is not what
    // plays: the bundled one is, and is shown as in use.
    final chosenId = settings.dua.voiceId;
    final chosenReady = ref.watch(
      adhanVoicesProvider.select(
        (state) =>
            chosenId == null || state.value?.statusOf(chosenId) is VoiceReady,
      ),
    );
    final inUse = chosenReady ? settings.dua : AdhanDua.bundled;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppGroupCard(
          children: [
            AppSwitchTile(
              value: settings.playAdhan,
              onChanged: (on) =>
                  notifier.change((value) => value.copyWith(playAdhan: on)),
              title: l10n.adhanPlaySwitch,
              subtitle: l10n.adhanPlayHint,
              icon: Icons.call_outlined,
            ),
            AppSwitchTile(
              value: settings.stopWhenFlipped,
              onChanged: settings.playAdhan
                  ? (on) => notifier.change(
                      (value) => value.copyWith(stopWhenFlipped: on),
                    )
                  : null,
              title: l10n.adhanFlipSwitch,
              subtitle: l10n.adhanFlipHint,
              icon: Icons.screen_rotation_alt_outlined,
            ),
            // Offered once the app carries the announcement recordings.
            if (announcements)
              AppSwitchTile(
                value: settings.announce,
                onChanged: settings.playAdhan
                    ? (on) => notifier.change(
                        (value) => value.copyWith(announce: on),
                      )
                    : null,
                title: l10n.adhanAnnounceSwitch,
                subtitle: l10n.adhanAnnounceHint,
                icon: Icons.campaign_outlined,
              ),
            AppSwitchTile(
              value: settings.duaAfter,
              onChanged: settings.playAdhan
                  ? (on) =>
                        notifier.change((value) => value.copyWith(duaAfter: on))
                  : null,
              title: l10n.adhanDuaSwitch,
              subtitle: l10n.adhanDuaHint,
              icon: Icons.volunteer_activism_outlined,
            ),
            if (settings.playAdhan && settings.duaAfter)
              for (final dua in AdhanDua.values)
                _DuaChoice(dua: dua, chosen: inUse == dua),
          ],
        ),
        if (settings.playAdhan && !exact) ...[
          const SizedBox(height: 8),
          // Red and boxed: without it the adhan does not play at all.
          AppNotice(
            l10n.adhanExactNote,
            important: true,
            action: FilledButton(
              onPressed: () async {
                final allowed = await ref
                    .read(reminderSchedulerProvider)
                    .requestExact();
                if (!context.mounted) return;
                if (allowed) {
                  await ref.read(prayerProvider.notifier).reschedule();
                }
                if (context.mounted) ref.invalidate(adhanExactAllowedProvider);
              },
              child: Text(l10n.prayerExactAllow),
            ),
          ),
        ],
        // Red and boxed too: battery saving can hold the adhan back.
        const AdhanBatteryNotice(),
        const SizedBox(height: 12),
        AppTileCard(
          icon: Icons.notifications_active_outlined,
          title: l10n.adhanTest,
          subtitle: l10n.adhanTestHint,
          trailing: const Icon(Icons.play_arrow),
          onTap: () => _test(context, ref),
        ),
      ],
    );
  }

  Future<void> _test(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    await ref.read(adhanTesterProvider)(l10n);
    // While it plays: the home-screen widgets are the next thing to try.
    await Future<void>.delayed(const Duration(seconds: 6));
    if (context.mounted) await offerWidgets(context, ref);
  }
}

/// A [VoiceCard] that watches only its own voice's state.
class _VoiceTile extends ConsumerWidget {
  const _VoiceTile({required this.voice, required this.chosen});

  final AdhanVoice voice;
  final bool chosen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (status, listening, failed) = ref.watch(
      adhanVoicesProvider.select((state) {
        final value = state.value;
        return (
          value?.statusOf(voice.id) ?? const VoiceAvailable(),
          value?.listening == voice.id,
          value?.previewFailed == voice.id,
        );
      }),
    );
    return VoiceCard(
      voice: voice,
      status: status,
      chosen: chosen,
      listening: listening,
      previewFailed: failed,
    );
  }
}

/// One voice for the dua after the adhan: chosen with a tap, heard with its
/// play button. The bundled one is always there; the other is downloaded
/// when it is chosen (or with its download button), and can be heard from
/// the network first.
class _DuaChoice extends ConsumerWidget {
  const _DuaChoice({required this.dua, required this.chosen});

  final AdhanDua dua;
  final bool chosen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final digits = ref.watch(displayDigitsFormatterProvider);
    final notifier = ref.read(adhanVoicesProvider.notifier);
    final listenId = AdhanVoicesNotifier.listeningId(dua);
    final (voice, status, listening, failed) = ref.watch(
      adhanVoicesProvider.select((state) {
        final value = state.value;
        final voice = value?.voices
            .where((voice) => voice.id == dua.voiceId)
            .firstOrNull;
        return (
          voice,
          voice == null ? const VoiceReady() : value!.statusOf(voice.id),
          value?.listening == listenId,
          value?.previewFailed == listenId,
        );
      }),
    );
    // A dua to download that the catalogue does not list is not offered.
    if (dua.voiceId != null && voice == null) return const SizedBox.shrink();
    final size = voice == null
        ? ''
        : l10n.adhanSizeMb(digits((voice.bytes / 1000000).toStringAsFixed(1)));
    final failure = status is VoiceAvailable ? status.failure : null;
    final error = failed || failure != null;
    final subtitle = switch (status) {
      _ when failed => l10n.adhanPreviewFailed,
      VoiceAvailable(failure: VoiceDownloadFailure.integrity) =>
        l10n.adhanDownloadIntegrity,
      VoiceAvailable(failure: VoiceDownloadFailure.busy) =>
        l10n.adhanDownloadBusy,
      VoiceAvailable(failure: _?) => l10n.adhanDownloadNetwork,
      VoiceAvailable() => l10n.adhanDuaToDownload(size),
      VoiceDownloading(:final progress) => l10n.adhanDownloading(
        digits('${(progress * 100).round()}%'),
      ),
      VoiceReady() when voice == null => l10n.adhanBuiltIn,
      VoiceReady() => l10n.adhanDuaOnPhone(size),
    };
    final downloading = status is VoiceDownloading;
    return ListTile(
      contentPadding: const EdgeInsetsDirectional.only(start: 56, end: 8),
      selected: chosen,
      leading: switch (status) {
        VoiceDownloading(:final progress) => SizedBox.square(
          dimension: 24,
          child: CircularProgressIndicator(
            value: progress == 0 ? null : progress,
            strokeWidth: 3,
          ),
        ),
        _ => Icon(
          chosen ? Icons.check_circle_rounded : Icons.circle_outlined,
          color: chosen ? scheme.primary : scheme.outline,
        ),
      },
      title: Text(switch (dua) {
        AdhanDua.shaarawy => l10n.adhanDuaShaarawy,
        AdhanDua.mishary => l10n.adhanDuaMishary,
      }),
      subtitle: Text(
        subtitle,
        style: error ? TextStyle(color: scheme.error) : null,
      ),
      onTap: downloading ? null : () => notifier.chooseDua(dua),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: listening ? l10n.adhanStopListening : l10n.adhanListen,
            icon: Icon(
              listening
                  ? Icons.stop_circle_outlined
                  : Icons.play_circle_outline,
            ),
            onPressed: () => notifier.toggleListeningDua(dua),
          ),
          if (voice != null)
            switch (status) {
              VoiceDownloading() => IconButton(
                tooltip: l10n.adhanCancel,
                icon: const Icon(Icons.close),
                onPressed: () => notifier.cancel(voice),
              ),
              VoiceAvailable() => IconButton(
                tooltip: l10n.adhanDownload(size),
                icon: const Icon(Icons.download_outlined),
                onPressed: () => notifier.download(voice),
              ),
              VoiceReady() => IconButton(
                tooltip: l10n.adhanDelete,
                icon: const Icon(Icons.delete_outline),
                onPressed: () => notifier.delete(voice),
              ),
            },
        ],
      ),
    );
  }
}
