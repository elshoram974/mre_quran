import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import 'app_sheet.dart';

/// Number of options above which [AppSelectField] shows a search field.
const int appSelectSearchThreshold = 5;

/// One choice in an [AppSelectField].
@immutable
class AppSelectOption<T extends Object> {
  /// Creates an option with a [value] and the [label] shown to the reader.
  const AppSelectOption({
    required this.value,
    required this.label,
    this.subtitle,
    this.icon,
  });

  /// Value returned when this option is chosen.
  final T value;

  /// Localized text shown for this option.
  final String label;

  /// Optional secondary line shown under [label].
  final String? subtitle;

  /// Optional leading icon.
  final IconData? icon;
}

/// Shared single-choice picker used across the app.
///
/// Shows a labelled field that opens a themed bottom sheet. When there are more
/// than [appSelectSearchThreshold] options the sheet includes a search field.
class AppSelectField<T extends Object> extends StatelessWidget {
  /// Creates a picker for [options] with the current [value] selected.
  const AppSelectField({
    super.key,
    required this.label,
    required this.options,
    required this.onChanged,
    this.value,
    this.sheetTitle,
  });

  /// Field label, also used as the sheet title unless [sheetTitle] is set.
  final String label;

  /// Available choices.
  final List<AppSelectOption<T>> options;

  /// Currently selected value, or null when nothing is chosen.
  final T? value;

  /// Called with the newly chosen value.
  final ValueChanged<T> onChanged;

  /// Optional sheet title that overrides [label].
  final String? sheetTitle;

  AppSelectOption<T>? get _selected {
    for (final option in options) {
      if (option.value == value) return option;
    }
    return null;
  }

  Future<void> _open(BuildContext context) async {
    final searchable = options.length > appSelectSearchThreshold;
    final chosen = await AppSheet.show<T>(
      context: context,
      initialSize: searchable ? 0.62 : 0.5,
      builder: (_, controller) => _SelectSheet<T>(
        title: sheetTitle ?? label,
        options: options,
        value: value,
        controller: controller,
      ),
    );
    if (chosen != null && chosen != value) onChanged(chosen);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selected = _selected;
    return Semantics(
      button: true,
      label: label,
      value: selected?.label,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _open(context),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: label,
              suffixIcon: const Icon(Icons.keyboard_arrow_down_rounded),
            ),
            isEmpty: selected == null,
            child: Row(
              children: [
                if (selected?.icon != null) ...[
                  Icon(
                    selected!.icon,
                    size: 20,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(
                    selected?.label ?? context.l10n.selectOption,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyLarge,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SelectSheet<T extends Object> extends StatefulWidget {
  const _SelectSheet({
    required this.title,
    required this.options,
    required this.value,
    required this.controller,
  });

  final String title;
  final List<AppSelectOption<T>> options;
  final T? value;
  final ScrollController controller;

  @override
  State<_SelectSheet<T>> createState() => _SelectSheetState<T>();
}

class _SelectSheetState<T extends Object> extends State<_SelectSheet<T>> {
  static final RegExp _arabicMarks = RegExp('[\u064B-\u0652\u0670\u0640]');
  String _query = '';

  bool get _searchable => widget.options.length > appSelectSearchThreshold;

  static String _normalize(String text) =>
      text.replaceAll(_arabicMarks, '').toLowerCase().trim();

  List<AppSelectOption<T>> get _visible {
    final query = _normalize(_query);
    if (query.isEmpty) return widget.options;
    return [
      for (final option in widget.options)
        if (_normalize(option.label).contains(query)) option,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final visible = _visible;
    return CustomScrollView(
      controller: widget.controller,
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            children: [
              const AppSheetHandle(),
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(24, 4, 24, 8),
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Semantics(
                    header: true,
                    child: Text(
                      widget.title,
                      style: theme.textTheme.titleLarge,
                    ),
                  ),
                ),
              ),
              if (_searchable)
                Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(16, 4, 16, 8),
                  child: TextField(
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: l10n.searchOptions,
                      prefixIcon: const Icon(Icons.search),
                    ),
                    onChanged: (text) => setState(() => _query = text),
                  ),
                ),
            ],
          ),
        ),
        if (visible.isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Text(
                l10n.noResults,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge,
              ),
            ),
          )
        else
          SliverList.builder(
            itemCount: visible.length,
            itemBuilder: (context, index) {
              final option = visible[index];
              final selected = option.value == widget.value;
              return ListTile(
                key: ValueKey<Object>(option.value),
                minVerticalPadding: 12,
                selected: selected,
                leading: option.icon == null
                    ? null
                    : Icon(
                        option.icon,
                        color: selected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                title: Text(option.label),
                subtitle: option.subtitle == null
                    ? null
                    : Text(option.subtitle!),
                trailing: selected ? const Icon(Icons.check_rounded) : null,
                onTap: () => Navigator.of(context).pop(option.value),
              );
            },
          ),
        SliverToBoxAdapter(
          child: SizedBox(height: MediaQuery.viewInsetsOf(context).bottom + 16),
        ),
      ],
    );
  }
}
