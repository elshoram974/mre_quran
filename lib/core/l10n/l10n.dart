import 'package:flutter/widgets.dart';

import '../../l10n/generated/app_localizations.dart';

extension AppLocalizationsContext on BuildContext {
  /// Returns the generated strings for the active locale.
  AppLocalizations get l10n => AppLocalizations.of(this);
}
