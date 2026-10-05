import 'package:flutter/material.dart';

import '../../core/l10n/l10n.dart';

/// One top-level destination of the app shell.
@immutable
class ShellDestination {
  /// Creates a destination with outlined and filled icons.
  const ShellDestination(this.label, this.icon, this.activeIcon);

  /// Localized label.
  final String label;

  /// Icon when unselected.
  final IconData icon;

  /// Icon when selected.
  final IconData activeIcon;

  /// Destinations in navigation order.
  static List<ShellDestination> of(BuildContext context) {
    final l10n = context.l10n;
    return [
      ShellDestination(l10n.reader, Icons.menu_book_outlined, Icons.menu_book),
      ShellDestination(
        l10n.duas,
        Icons.volunteer_activism_outlined,
        Icons.volunteer_activism,
      ),
      ShellDestination(l10n.bookmarks, Icons.bookmark_border, Icons.bookmark),
      ShellDestination(l10n.settings, Icons.settings_outlined, Icons.settings),
    ];
  }
}
