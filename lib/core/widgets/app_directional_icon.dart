import 'package:flutter/material.dart';

/// A navigation chevron that follows the app's text direction.
class AppForwardChevron extends StatelessWidget {
  /// Creates a forward chevron.
  const AppForwardChevron({super.key});

  @override
  Widget build(BuildContext context) => Icon(
    Directionality.of(context) == TextDirection.rtl
        ? Icons.chevron_left
        : Icons.chevron_right,
  );
}

/// A navigation chevron that points opposite [AppForwardChevron].
class AppBackChevron extends StatelessWidget {
  /// Creates a back chevron.
  const AppBackChevron({super.key});

  @override
  Widget build(BuildContext context) => Icon(
    Directionality.of(context) == TextDirection.rtl
        ? Icons.chevron_right
        : Icons.chevron_left,
  );
}
