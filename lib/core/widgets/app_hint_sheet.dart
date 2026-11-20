import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../hints/hints.dart';
import '../l10n/l10n.dart';
import '../theme/app_tokens.dart';
import 'app_icon_badge.dart';
import 'app_sheet.dart';

/// Shows [hint] in a sheet, when it may be shown (not turned off for good,
/// not shown yet this run): its icon, title and words, a main [action] and
/// "later", and a "don't remind me again" box, left clear. Returns whether
/// the person took the action. With [once] the hint never comes again,
/// whatever they choose, and the box is not offered.
///
/// A second way out can be offered beside the main one: [secondaryAction] is
/// its label and [onSecondary] runs when it is chosen. [dismissLabel] words
/// the button that just closes the hint ("Later" unless given).
Future<bool> showAppHint(
  BuildContext context,
  WidgetRef ref, {
  required AppHint hint,
  required IconData icon,
  required String title,
  required String body,
  required String action,
  bool once = false,
  String? secondaryAction,
  VoidCallback? onSecondary,
  String? dismissLabel,
}) async {
  final notifier = ref.read(hintsProvider.notifier);
  if (!await notifier.take(hint) || !context.mounted) return false;
  final answer = await AppSheet.show<_HintAnswer>(
    context: context,
    builder: (_) => _HintBody(
      icon: icon,
      title: title,
      body: body,
      action: action,
      offerNever: !once,
      secondaryAction: secondaryAction,
      dismissLabel: dismissLabel,
    ),
  );
  if (once || (answer?.never ?? false)) await notifier.dismiss(hint);
  if (answer?.secondary ?? false) onSecondary?.call();
  return answer?.acted ?? false;
}

typedef _HintAnswer = ({bool acted, bool never, bool secondary});

class _HintBody extends StatefulWidget {
  const _HintBody({
    required this.icon,
    required this.title,
    required this.body,
    required this.action,
    required this.offerNever,
    this.secondaryAction,
    this.dismissLabel,
  });

  final IconData icon;
  final String title;
  final String body;
  final String action;
  final bool offerNever;
  final String? secondaryAction;
  final String? dismissLabel;

  @override
  State<_HintBody> createState() => _HintBodyState();
}

class _HintBodyState extends State<_HintBody> {
  bool _never = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    void close(bool acted, {bool secondary = false}) =>
        Navigator.of(context)
            .pop((acted: acted, never: _never, secondary: secondary));
    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(
        AppTokens.gutterCompact + 4,
        0,
        AppTokens.gutterCompact + 4,
        MediaQuery.paddingOf(context).bottom + AppTokens.gutterCompact,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: AppIconBadge(widget.icon, emphasized: true),
          ),
          const SizedBox(height: AppTokens.spaceMedium),
          Text(widget.title, style: theme.textTheme.titleLarge),
          const SizedBox(height: AppTokens.spaceSmall),
          Text(widget.body, style: theme.textTheme.bodyLarge),
          if (widget.offerNever) ...[
            const SizedBox(height: AppTokens.spaceSmall),
            CheckboxListTile(
              contentPadding: EdgeInsetsDirectional.zero,
              controlAffinity: ListTileControlAffinity.leading,
              value: _never,
              onChanged: (value) => setState(() => _never = value ?? false),
              title: Text(l10n.hintNever),
            ),
          ],
          const SizedBox(height: AppTokens.spaceSmall),
          FilledButton(
            onPressed: () => close(true),
            child: Text(widget.action),
          ),
          if (widget.secondaryAction case final secondary?) ...[
            const SizedBox(height: AppTokens.spaceSmall),
            OutlinedButton(
              onPressed: () => close(false, secondary: true),
              child: Text(secondary),
            ),
          ],
          TextButton(
            onPressed: () => close(false),
            child: Text(widget.dismissLabel ?? l10n.hintLater),
          ),
        ],
      ),
    );
  }
}
