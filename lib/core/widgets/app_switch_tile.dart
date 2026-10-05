import 'package:flutter/material.dart';

/// Shared on/off row. Uses the platform switch (Cupertino on iOS, Material 3 on
/// Android) with the app's colour roles so both match the theme.
class AppSwitchTile extends StatelessWidget {
  /// Creates a switch row.
  const AppSwitchTile({
    super.key,
    required this.value,
    required this.onChanged,
    required this.title,
    this.subtitle,
    this.icon,
  });

  /// Whether the switch is on.
  final bool value;

  /// Called with the new value.
  final ValueChanged<bool> onChanged;

  /// Row title.
  final String title;

  /// Optional description under the title.
  final String? subtitle;

  /// Optional leading icon.
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SwitchListTile.adaptive(
      value: value,
      onChanged: onChanged,
      activeTrackColor: scheme.primary,
      inactiveTrackColor: scheme.surfaceContainerHighest,
      title: Text(title),
      subtitle: subtitle == null ? null : Text(subtitle!),
      secondary: icon == null ? null : Icon(icon, color: scheme.primary),
    );
  }
}
