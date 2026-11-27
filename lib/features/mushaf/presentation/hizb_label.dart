import '../../../l10n/generated/app_localizations.dart';
import '../../quran_index/domain/quran_metadata.dart';

/// Names [quarter] as the Mushaf marks it in its margin: the hizb where it
/// begins, then a quarter, half and three quarters of it. The number is
/// written by [digits].
String hizbQuarterLabel(
  AppLocalizations l10n,
  HizbQuarter quarter,
  String Function(int) digits,
) {
  final hizb = digits(quarter.hizb);
  return switch (quarter.quarter) {
    1 => l10n.hizbQuarter(hizb),
    2 => l10n.hizbHalf(hizb),
    3 => l10n.hizbThreeQuarters(hizb),
    _ => l10n.hizbTitle(hizb),
  };
}
