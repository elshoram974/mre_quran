import '../../../core/widgets/app_snack_bar.dart';

import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/config/app_config.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/layout/adaptive_layout.dart';
import '../../../core/config/store_links.dart';
import '../../../core/links/link_opener.dart';
import '../../../core/sharing/app_share_text.dart';
import '../../../core/sharing/sharer.dart';
import '../../../core/widgets/app_section_header.dart';
import '../../../core/widgets/app_tile_card.dart';
import 'settings_body.dart';

/// The settings, as a list of the things that can be set: each opens a page of
/// its own, so no page is long, and a person finds what they came for by its
/// name.
class SettingsPage extends ConsumerWidget {
  /// Creates the page.
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return ListView(
      padding: pagePadding(context),
      children: [
        AppTileCard(
          icon: Icons.palette_outlined,
          title: l10n.displayOptions,
          subtitle: l10n.settingsViewHint,
          onTap: () => context.push(AppRoute.settingsView.path),
        ),
        const SizedBox(height: settingsGap),
        AppTileCard(
          icon: Icons.volume_up_outlined,
          title: l10n.adhanTitle,
          subtitle: l10n.adhanTileSubtitle,
          onTap: () => context.push(AppRoute.adhan.path),
        ),
        const SizedBox(height: settingsGap),
        AppTileCard(
          icon: Icons.notifications_none_outlined,
          title: l10n.adhkarReminders,
          subtitle: l10n.settingsRemindersHint,
          onTap: () => context.push(AppRoute.reminders.path),
        ),
        const SizedBox(height: settingsGap),
        AppTileCard(
          icon: Icons.download_for_offline_outlined,
          title: l10n.offlineMushaf,
          subtitle: l10n.settingsOfflineHint,
          onTap: () => context.push(AppRoute.settingsOffline.path),
        ),
        const SizedBox(height: settingsGap),
        AppTileCard(
          icon: Icons.widgets_outlined,
          title: l10n.widgetsTitle,
          subtitle: l10n.widgetsIntro,
          onTap: () => context.push(AppRoute.widgets.path),
        ),
        const SizedBox(height: settingsGap),
        AppTileCard(
          icon: Icons.shield_outlined,
          title: l10n.privacy,
          subtitle: l10n.settingsPrivacyHint,
          onTap: () => context.push(AppRoute.settingsPrivacy.path),
        ),
        const SizedBox(height: 28),
        AppSectionHeader(title: l10n.contactUs),
        AppTileCard(
          icon: Icons.chat_outlined,
          title: l10n.contactWhatsApp,
          subtitle: '\u2066+${AppConfig.whatsAppNumber}\u2069',
          onTap: () => _open(context, ref, AppConfig.whatsApp),
        ),
        const SizedBox(height: settingsGap),
        AppTileCard(
          icon: Icons.mail_outline,
          title: l10n.contactEmail,
          subtitle: '\u2066${AppConfig.email}\u2069',
          onTap: () => _open(context, ref, AppConfig.mail),
        ),
        const SizedBox(height: settingsGap),
        // Only when a store has the app: otherwise there is nothing to send.
        if (appShareText(l10n, ref.watch(storeLinksProvider))
            case final text?) ...[
          AppTileCard(
            icon: Icons.ios_share_outlined,
            title: l10n.shareApp,
            subtitle: l10n.shareAppHint,
            onTap: () => unawaited(ref.read(sharerProvider).shareText(text)),
          ),
          const SizedBox(height: settingsGap),
        ],
        // The version, to quote when writing to us. The licences and sources
        // are under Privacy.
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppTokens.spaceSmall),
          child: Text(
            '${l10n.appTitle} · ${l10n.appVersion(AppConfig.version)}',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }

  /// Opens [uri] outside the app, and says so when nothing could.
  static Future<void> _open(
    BuildContext context,
    WidgetRef ref,
    Uri uri,
  ) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    final failed = context.l10n.contactFailed;
    if (await ref.read(linkOpenerProvider).open(uri)) return;
    messenger?.showSnackBar(AppSnackBar(failed));
  }
}
