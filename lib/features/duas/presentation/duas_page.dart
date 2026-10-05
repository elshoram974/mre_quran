import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/widgets/empty_state.dart';

/// Duas and adhkar tab. Content arrives once a licensed source is approved.
class DuasPage extends StatelessWidget {
  const DuasPage({super.key});

  @override
  Widget build(BuildContext context) => EmptyState(
    icon: Icons.volunteer_activism_outlined,
    title: context.l10n.duasEmptyTitle,
    message: context.l10n.duasEmptyBody,
  );
}
