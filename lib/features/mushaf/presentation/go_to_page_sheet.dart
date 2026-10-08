import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mre_fields/mre_fields.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_sheet.dart';

/// Asks which page to open, starting at [page], with a field and slider over
/// the [pageCount] pages. Returns the chosen page, or null.
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
  late final TextEditingController _controller = TextEditingController(
    text: widget.digits(widget.initial),
  );
  late int _page = widget.initial;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

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
          MRETextField(
            controller: _controller,
            labelText: l10n.goToPage,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.go,
            inputFormatters: [_PageNumberFormatter(widget.pageCount)],
            onChanged: _onPageTextChanged,
            onFieldSubmitted: (_) => _submit(context),
          ),
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
              onChanged: (value) => _setPage(value.round()),
            ),
          ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: _isValidInput ? () => _submit(context) : null,
            child: Text(l10n.goToPageAction),
          ),
        ],
      ),
    );
  }

  bool get _isValidInput => _parsePage(_controller.text) != null;

  void _onPageTextChanged(String value) {
    final page = _parsePage(value);
    setState(() {
      if (page != null) _page = page;
    });
  }

  void _setPage(int page) {
    final text = widget.digits(page);
    setState(() {
      _page = page;
      _controller.value = TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      );
    });
  }

  void _submit(BuildContext context) {
    final page = _parsePage(_controller.text);
    if (page != null) Navigator.of(context).pop(page);
  }

  int? _parsePage(String value) {
    if (value.isEmpty) return null;
    final page = int.tryParse(_normalizeDigits(value));
    return page != null && page >= 1 && page <= widget.pageCount ? page : null;
  }
}

class _PageNumberFormatter extends TextInputFormatter {
  _PageNumberFormatter(this.maximum);

  final int maximum;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;
    final page = int.tryParse(_normalizeDigits(newValue.text));
    if (page == null || page < 1 || page > maximum) return oldValue;
    return newValue;
  }
}

String _normalizeDigits(String value) => value
    .replaceAllMapped(
      RegExp('[٠-٩]'),
      (match) =>
          String.fromCharCode(match.group(0)!.codeUnitAt(0) - 0x630 + 0x30),
    )
    .replaceAllMapped(
      RegExp('[۰-۹]'),
      (match) =>
          String.fromCharCode(match.group(0)!.codeUnitAt(0) - 0x6f0 + 0x30),
    );
