import '../../l10n/generated/app_localizations.dart';
import '../config/store_links.dart';

/// What to put under anything the app shares: its name, and where to get it,
/// one line for each store that has the app. Null when no store has it yet:
/// there is nothing to point to, and a bare name would only be noise.
String? appShareFooter(AppLocalizations l10n, List<StoreLink> links) {
  if (links.isEmpty) return null;
  return [
    l10n.shareGetApp(l10n.appTitle),
    for (final link in links) '${link.store}: ${link.url}',
  ].join('\n');
}

/// The words of sharing the app itself: a line about it and the stores. Null
/// when no store has it yet.
String? appShareText(AppLocalizations l10n, List<StoreLink> links) {
  final footer = appShareFooter(l10n, links);
  if (footer == null) return null;
  return '${l10n.shareAppMessage(l10n.appTitle)}\n\n$footer';
}
