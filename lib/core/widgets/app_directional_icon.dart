import 'package:flutter/material.dart';

/// A chevron pointing the way reading goes: right in English, left in
/// Arabic.
///
/// Material's chevrons mirror themselves in a right-to-left language, so the
/// icon is the same in every language. Choosing the opposite icon by hand as
/// well would turn it back the wrong way.
class AppForwardChevron extends StatelessWidget {
  /// Creates a forward chevron.
  const AppForwardChevron({super.key});

  @override
  Widget build(BuildContext context) => const Icon(Icons.chevron_right);
}

/// A chevron pointing against [AppForwardChevron]: back the way reading came.
class AppBackChevron extends StatelessWidget {
  /// Creates a back chevron.
  const AppBackChevron({super.key});

  @override
  Widget build(BuildContext context) => const Icon(Icons.chevron_left);
}
