import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/hints/hints.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/widgets/app_hint_sheet.dart';
import '../application/home_widgets_providers.dart';

/// Offers the home-screen widgets, while none of them is on the home screen
/// yet: at most once a run, until the person says not to remind them. Its
/// action opens the widgets page, which adds them (Android) or says how
/// (iOS).
Future<void> offerWidgets(BuildContext context, WidgetRef ref) async {
  if (await ref.read(homeWidgetsPlatformProvider).placed()) return;
  if (!context.mounted) return;
  final l10n = context.l10n;
  final acted = await showAppHint(
    context,
    ref,
    hint: AppHint.tryWidgets,
    icon: Icons.widgets_outlined,
    title: l10n.hintWidgetsTitle,
    body: l10n.hintWidgetsBody,
    action: l10n.hintWidgetsAction,
  );
  if (acted && context.mounted) await context.push(AppRoute.widgets.path);
}
