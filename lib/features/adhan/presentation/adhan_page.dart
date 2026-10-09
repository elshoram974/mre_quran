import 'package:flutter/material.dart';
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
import '../application/adhan_providers.dart';
import '../data/adhan_platform.dart';
import '../domain/adhan_settings.dart';
import '../domain/adhan_voice.dart';
import 'custom_voice_card.dart';
import 'voice_card.dart';

/// Whether exact alarms are allowed (always true off Android).
final adhanExactAllowedProvider = FutureProvider.autoDispose<bool>(
  (ref) => ref.watch(reminderSchedulerProvider).canScheduleExact(),
);

/// How the adhan sounds and behaves: the voice, whether it plays by itself
/// like a call, and whether turning the phone over stops it.
class AdhanPage extends ConsumerWidget {
  /// Creates the page.
  const AdhanPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final supported = ref.watch(adhanSupportedProvider);
    final settings = ref.watch(adhanSettingsProvider);
    final voices = ref.watch(adhanVoicesProvider);
    return AppPageScaffold(
      title: l10n.adhanTitle,
      body: Builder(
        builder: (context) {
          final padding = pagePadding(context);
          if (supported.value == false) {
            return ContentContainer(
              child: Padding(
                padding: padding,
                child: AppNotice(l10n.adhanUnsupported),
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
          final state = voices.value;
          if (current == null || state == null) {
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
                for (final voice in state.voices) ...[
                  VoiceCard(
                    voice: voice,
                    status: state.statusOf(voice.id),
                    chosen: voice.id == current.voiceId,
                    listening: voice.id == state.listening,
                  ),
                  const SizedBox(height: 12),
                ],
                CustomVoiceCard(
                  settings: current,
                  listening: state.listening == AdhanVoice.customId,
                ),
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
          ],
        ),
        if (settings.playAdhan && !exact) ...[
          const SizedBox(height: 8),
          AppNotice(l10n.prayerExactNote),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton(
              onPressed: () async {
                await ref.read(reminderSchedulerProvider).requestExact();
                ref.invalidate(adhanExactAllowedProvider);
              },
              child: Text(l10n.prayerExactAllow),
            ),
          ),
        ],
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
    final config = await buildAdhanConfig(
      settings: settings,
      voices: await ref.read(adhanCatalogProvider.future),
      store: ref.read(voiceStoreProvider),
      l10n: l10n,
    );
    await ref
        .read(adhanPlatformProvider)
        .test(
          AdhanAlarm(
            id: 0,
            at: DateTime.now(),
            title: l10n.adhanTestTitle,
            body: l10n.adhanTestBody,
          ),
          config,
        );
  }
}
