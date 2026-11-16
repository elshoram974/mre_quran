import '../../../l10n/generated/app_localizations.dart';
import '../../settings/domain/app_settings.dart';

/// The name of [edition] as readers know it: the narrator and their teacher.
String editionName(AppLocalizations l10n, MushafEdition edition) =>
    switch (edition) {
      MushafEdition.hafs => l10n.editionHafs,
      MushafEdition.shubah => l10n.editionShubah,
      MushafEdition.warsh => l10n.editionWarsh,
      MushafEdition.qalon => l10n.editionQalon,
      MushafEdition.douri => l10n.editionDouri,
    };
