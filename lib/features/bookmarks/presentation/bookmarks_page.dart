import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/widgets/empty_state.dart';

class BookmarksPage extends StatelessWidget {
  const BookmarksPage({super.key});

  @override
  Widget build(BuildContext context) => EmptyState(
    icon: Icons.bookmark_border,
    title: context.l10n.noBookmarksTitle,
    message: context.l10n.noBookmarksBody,
  );
}
