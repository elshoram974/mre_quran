import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_sheet.dart';

/// Asks which page to open, starting at [page], with a slider over the
/// [pageCount] pages. Returns the chosen page, or null.
Future<int?> showGoToPage(
  BuildContext context, {
  required int page,
  required int pageCount,
  required String Function(int) digits,
}) => AppSheet.show<int>(
  context: context,
  builder: (_) =>
      _GoToPage(initial: page, pageCount: pageCount, digits: digits),
);

class _GoToPage extends StatefulWidget {
  const _GoToPage({
    required this.initial,
    required this.pageCount,
    required this.digits,
  });

  final int initial;
  final int pageCount;
  final String Function(int) digits;

  @override
  State<_GoToPage> createState() => _GoToPageState();
}

class _GoToPageState extends State<_GoToPage> {
  late int _page = widget.initial;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final digits = widget.digits;
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppTokens.gutterCompact,
        4,
        AppTokens.gutterCompact,
        20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.goToPage, style: theme.textTheme.titleLarge),
          const SizedBox(height: 16),
          Text(
            digits(_page),
            textAlign: TextAlign.center,
            style: theme.textTheme.displaySmall?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
          Text(
            l10n.pageOfTotal(digits(_page), digits(widget.pageCount)),
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          // The Mushaf runs right to left: page 1 at the right end.
          Directionality(
            textDirection: TextDirection.rtl,
            child: Slider(
              value: _page.toDouble(),
              min: 1,
              max: widget.pageCount.toDouble(),
              divisions: widget.pageCount - 1,
              label: digits(_page),
              semanticFormatterCallback: (value) => l10n.pageOfTotal(
                digits(value.round()),
                digits(widget.pageCount),
              ),
              onChanged: (value) => setState(() => _page = value.round()),
            ),
          ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(_page),
            child: Text(l10n.goToPageAction),
          ),
        ],
      ),
    );
  }
}
