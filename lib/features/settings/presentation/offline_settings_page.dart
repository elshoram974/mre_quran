import 'package:material_ui/material_ui.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/layout/adaptive_layout.dart';
import '../../../core/widgets/app_page_scaffold.dart';
import '../../mushaf/presentation/offline_packs_section.dart';

/// The printed Mushaf's pages, kept on the device to read without internet.
class OfflineSettingsPage extends StatelessWidget {
  /// Creates the page.
  const OfflineSettingsPage({super.key});

  @override
  Widget build(BuildContext context) => AppPageScaffold(
    title: context.l10n.offlineMushaf,
    body: ListView(
      padding: pagePadding(context),
      children: const [OfflinePacksSection()],
    ),
  );
}
