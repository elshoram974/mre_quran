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
Future<bool> showAppHint(
  BuildContext context,
  WidgetRef ref, {
  required AppHint hint,
  required IconData icon,
  required String title,
  required String body,
  required String action,
  bool once = false,
}) async {
  final notifier = ref.read(hintsProvider.notifier);
  if (!await notifier.take(hint) || !context.mounted) return false;
  final answer = await AppSheet.show<({bool acted, bool never})>(
    context: context,
    builder: (_) => _HintBody(
      icon: icon,
      title: title,
      body: body,
      action: action,
      offerNever: !once,
    ),
  );
  if (once || (answer?.never ?? false)) await notifier.dismiss(hint);
  return answer?.acted ?? false;
}

class _HintBody extends StatefulWidget {
  const _HintBody({
    required this.icon,
    required this.title,
    required this.body,
    required this.action,
    required this.offerNever,
  });

  final IconData icon;
  final String title;
  final String body;
  final String action;
  final bool offerNever;

  @override
  State<_HintBody> createState() => _HintBodyState();
}

class _HintBodyState extends State<_HintBody> {
  bool _never = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    void close(bool acted) =>
        Navigator.of(context).pop((acted: acted, never: _never));
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
          TextButton(
            onPressed: () => close(false),
            child: Text(l10n.hintLater),
          ),
        ],
      ),
    );
  }
}
