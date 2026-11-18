import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/hints/hints.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/widgets/app_hint_sheet.dart';
import '../application/prayer_widget_sync.dart';

/// Offers the prayer card widget for the home screen, once it is the time
/// (after the adhan was tried). On Android the launcher is asked to add it;
/// where it cannot, the steps are said. iOS lets no app add a widget, so the
/// sheet says how.
Future<void> offerWidgets(BuildContext context, WidgetRef ref) async {
  final l10n = context.l10n;
  final ios = defaultTargetPlatform == TargetPlatform.iOS;
  final messenger = ScaffoldMessenger.maybeOf(context);
  final acted = await showAppHint(
    context,
    ref,
    hint: AppHint.tryWidgets,
    icon: Icons.widgets_outlined,
    title: l10n.hintWidgetsTitle,
    body: ios ? l10n.hintWidgetsBodyIos : l10n.hintWidgetsBody,
    action: ios ? l10n.hintWidgetsActionIos : l10n.hintWidgetsAction,
  );
  if (!acted || ios) return;
  if (!await PrayerWidgetSync.pin()) {
    messenger?.showSnackBar(SnackBar(content: Text(l10n.hintWidgetsManual)));
  }
}
