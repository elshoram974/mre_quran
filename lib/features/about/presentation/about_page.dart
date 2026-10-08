import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/layout/adaptive_layout.dart';
import '../../../core/widgets/app_page_scaffold.dart';

/// Attribution and content-source information.
class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AppPageScaffold(
      title: l10n.creditsTitle,
      body: Builder(
        builder: (context) => ListView(
          padding: pagePadding(context),
          children: [
            Text(l10n.creditsTanzil),
            const SizedBox(height: 16),
            Text(l10n.creditsQuranFont),
            const SizedBox(height: 16),
            Text(l10n.creditsAdhkar),
            const SizedBox(height: 16),
            Text(l10n.creditsFonts),
            const SizedBox(height: 16),
            Text(l10n.creditsImages),
          ],
        ),
      ),
    );
  }
}
