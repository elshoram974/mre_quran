import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/layout/adaptive_layout.dart';
import '../../../core/links/link_opener.dart';
import '../../../core/widgets/app_group_card.dart';
import '../../../core/widgets/app_page_scaffold.dart';
import '../../../core/widgets/app_switch_tile.dart';
import '../../../core/widgets/app_tile_card.dart';
import '../application/settings_provider.dart';
import 'settings_body.dart';

/// What the app sends, the policy that says so, and the licences of what it
/// holds.
class PrivacySettingsPage extends ConsumerWidget {
  /// Creates the page.
  const PrivacySettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final notifier = ref.read(settingsProvider.notifier);
    return AppPageScaffold(
      title: l10n.privacy,
      body: SettingsBody(
        builder: (context, settings) => ListView(
          padding: pagePadding(context),
          children: [
            AppGroupCard(
              children: [
                AppSwitchTile(
                  value: settings.crashReportsEnabled,
                  onChanged: (value) => notifier.save(
                    settings.copyWith(crashReportsEnabled: value),
                  ),
                  icon: Icons.shield_outlined,
                  title: l10n.crashReports,
                  subtitle: l10n.crashReportsDescription,
                ),
              ],
            ),
            if (ref.watch(privacyPolicyProvider) case final policy?) ...[
              const SizedBox(height: settingsGap),
              AppTileCard(
                icon: Icons.policy_outlined,
                title: l10n.privacyPolicy,
                subtitle: l10n.privacyPolicyDescription,
                onTap: () => ref.read(linkOpenerProvider).open(policy),
              ),
            ],
            // The licences sit with the policy: both say on what terms the
            // app holds what it holds.
            const SizedBox(height: settingsGap),
            AppTileCard(
              icon: Icons.verified_outlined,
              title: l10n.licencesTitle,
              subtitle: l10n.licencesTileHint,
              onTap: () => context.push(AppRoute.licences.path),
            ),
          ],
        ),
      ),
    );
  }
}
