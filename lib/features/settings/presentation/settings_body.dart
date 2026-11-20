import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/layout/adaptive_layout.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_shimmer.dart';
import '../application/settings_provider.dart';
import '../domain/app_settings.dart';

/// Space between two controls on a settings page.
const double settingsGap = 12;

/// Gives [builder] the settings once they are read: a skeleton shows while
/// they are being read, and a retry when they cannot be.
class SettingsBody extends ConsumerWidget {
  /// Creates the body.
  const SettingsBody({super.key, required this.builder});

  /// Builds the page from the settings.
  final Widget Function(BuildContext context, AppSettings settings) builder;

  @override
  Widget build(BuildContext context, WidgetRef ref) => ref
      .watch(settingsProvider)
      .when(
        loading: () => const _SettingsSkeleton(),
        error: (_, _) =>
            _SettingsError(onRetry: () => ref.invalidate(settingsProvider)),
        data: (value) => builder(context, value),
      );
}

class _SettingsSkeleton extends StatelessWidget {
  const _SettingsSkeleton();

  @override
  Widget build(BuildContext context) => AppShimmer(
    child: ListView(
      padding: pagePadding(context),
      children: const [
        SkeletonBox(
          width: AppTokens.frameSampleMinWidth,
          height: AppTokens.iconSmall,
        ),
        SizedBox(height: AppTokens.spaceMedium),
        SkeletonBox(height: AppTokens.minTarget * 2),
        SizedBox(height: AppTokens.spaceMedium),
        SkeletonBox(height: AppTokens.minTarget),
        SizedBox(height: AppTokens.spaceMedium),
        SkeletonBox(height: AppTokens.minTarget * 2),
      ],
    ),
  );
}

class _SettingsError extends StatelessWidget {
  const _SettingsError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(context.l10n.settingsLoadError, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          FilledButton(onPressed: onRetry, child: Text(context.l10n.retry)),
        ],
      ),
    ),
  );
}
