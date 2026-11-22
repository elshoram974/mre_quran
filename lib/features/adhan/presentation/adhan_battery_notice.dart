import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/widgets/app_notice.dart';
import '../application/adhan_providers.dart';

/// Says, in red, that battery saving can stop the adhan, while the adhan is
/// on and the phone restricts the app's battery use; with a button to the
/// app's settings, where the person makes it unrestricted. It looks again
/// each time the app comes back, so it goes once that is done. Nothing
/// shows otherwise.
class AdhanBatteryNotice extends ConsumerStatefulWidget {
  /// Creates the notice.
  const AdhanBatteryNotice({super.key});

  @override
  ConsumerState<AdhanBatteryNotice> createState() => _AdhanBatteryNoticeState();
}

class _AdhanBatteryNoticeState extends ConsumerState<AdhanBatteryNotice> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(
      onResume: () => ref.invalidate(adhanBatteryUnrestrictedProvider),
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final playing =
        ref.watch(adhanSupportedProvider).value == true &&
        (ref.watch(adhanSettingsProvider).value?.playAdhan ?? false);
    final unrestricted =
        ref.watch(adhanBatteryUnrestrictedProvider).value ?? true;
    if (!playing || unrestricted) return const SizedBox.shrink();
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsetsDirectional.only(top: 8),
      child: AppNotice(
        l10n.adhanBatteryNote,
        important: true,
        icon: Icons.battery_alert_outlined,
        action: FilledButton(
          onPressed: () => ref.read(adhanPlatformProvider).openAppSettings(),
          child: Text(l10n.adhanBatteryAction),
        ),
      ),
    );
  }
}
