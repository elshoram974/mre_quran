import 'package:material_ui/material_ui.dart';

import '../../l10n/generated/app_localizations.dart';

extension AppLocalizationsContext on BuildContext {
  /// Returns the generated strings for the active locale.
  AppLocalizations get l10n => AppLocalizations.of(this);
}

/// The app's strings plus the Material, Cupertino, and widgets translations.
///
/// Use this, not [AppLocalizations.localizationsDelegates]: the generated list
/// names the `flutter_localizations` delegates, whose `MaterialLocalizations`
/// type is not the one `material_ui` widgets look up.
const List<LocalizationsDelegate<dynamic>> appLocalizationsDelegates =
    <LocalizationsDelegate<dynamic>>[
      AppLocalizations.delegate,
      ...GlobalMaterialLocalizations.delegates,
    ];
