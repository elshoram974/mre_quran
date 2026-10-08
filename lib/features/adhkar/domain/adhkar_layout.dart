/// Puts the formulas said before an ayah, and the ayahs themselves, each on its
/// own line. Only the line breaks change; no letter does.
///
/// Said before reciting: the isti'adha (once, first) and the basmala (before a
/// surah). They sit on their own line, with the ayahs between ﴿ ﴾ below.
String layoutAdhkarText(String text) {
  var out = text;
  for (final formula in [_istiadha, _basmala]) {
    out = out.replaceAllMapped(formula, (match) => '\n${match[0]}\n');
  }
  out = out
      .replaceAll(RegExp(r'\s*﴿'), '\n﴿')
      .replaceAll(RegExp(r'﴾\s+'), '﴾\n');
  return out
      .split('\n')
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty)
      .join('\n');
}

// A letter followed by any tashkeel, so spelling with or without vowels matches.
String _word(String letters) => letters
    .split('')
    .map((letter) => '$letter[\u064B-\u0652\u0670\u0640]*')
    .join();

final RegExp _istiadha = RegExp(
  [
    '[أا]${_word('عوذ')}',
    _word('بالله'),
    _word('من'),
    _word('الشيطان'),
    _word('الرجيم'),
  ].join(r'\s+'),
);

final RegExp _basmala = RegExp(
  [_word('بسم'), _word('الله'), _word('الرحمن'), _word('الرحيم')].join(r'\s+'),
);
