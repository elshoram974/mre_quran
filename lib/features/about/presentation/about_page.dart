import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';

/// Attribution and content-source information.
class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.creditsTitle)),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            l10n.creditsTitle,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 24),
          Text(l10n.creditsTanzil),
          const SizedBox(height: 16),
          Text(l10n.creditsFonts),
          const SizedBox(height: 16),
          Text(l10n.creditsImages),
        ],
      ),
    );
  }
}
