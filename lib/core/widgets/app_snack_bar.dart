import 'package:material_ui/material_ui.dart';

import 'app_mark.dart';

/// The app's own snack bar: the message on the dark surface, with the app's
/// mark ahead of it, so every short word the app says looks like the app's.
/// Floating, rounded and coloured by the theme; give it an [action] to offer
/// one thing to do.
class AppSnackBar extends SnackBar {
  /// Creates a snack bar saying [message].
  AppSnackBar(String message, {super.key, super.action, super.duration})
    : super(content: _Message(message));
}

class _Message extends StatelessWidget {
  const _Message(this.message);

  final String message;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      AppMark(size: 22, color: Theme.of(context).colorScheme.inversePrimary),
      const SizedBox(width: 12),
      Expanded(child: Text(message)),
    ],
  );
}
