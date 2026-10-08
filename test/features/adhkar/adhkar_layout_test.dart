import 'package:flutter_test/flutter_test.dart';
import 'package:mre_quran/features/adhkar/domain/adhkar_layout.dart';

void main() {
  const istiadha = 'أَعُوذُ بِاللَّهِ مِنَ الشَّيطَانِ الرَّجِيمِ';
  const basmala = 'بِسْمِ اللَّهِ الرَّحْمَنِ الرَّحِيمِ';

  test('the isti\'adha and the ayah go on separate lines', () {
    expect(
      layoutAdhkarText('$istiadha ﴿اللَّهُ لاَ إِلَهَ إِلاَّ هُوَ﴾.'),
      '$istiadha\n﴿اللَّهُ لاَ إِلَهَ إِلاَّ هُوَ﴾.',
    );
  });

  test('each basmala has its own line, with the surah below it', () {
    expect(
      layoutAdhkarText(
        '$basmala ﴿قُلْ هُوَ اللَّهُ أَحَدٌ﴾ $basmala ﴿قُلْ أَعُوذُ﴾',
      ),
      '$basmala\n﴿قُلْ هُوَ اللَّهُ أَحَدٌ﴾\n$basmala\n﴿قُلْ أَعُوذُ﴾',
    );
  });

  test('works without tashkeel and with another spelling of alef', () {
    expect(
      layoutAdhkarText('اعوذ بالله من الشيطان الرجيم ﴿الله﴾'),
      'اعوذ بالله من الشيطان الرجيم\n﴿الله﴾',
    );
    expect(
      layoutAdhkarText('بسم الله الرحمن الرحيم ﴿قل﴾'),
      'بسم الله الرحمن الرحيم\n﴿قل﴾',
    );
  });

  test('an ordinary dua is left as it was', () {
    const dua = 'اللَّهُمَّ إِنِّي أَعُوذُ بِكَ مِنَ الْهَمِّ وَالْحَزَنِ';
    expect(layoutAdhkarText(dua), dua);
    const withName = 'بِسْمِ اللَّهِ الَّذِي لاَ يَضُرُّ مَعَ اسْمِهِ شَىْءٌ';
    expect(layoutAdhkarText(withName), withName);
  });

  test('no letter is added or lost', () {
    const text = '$istiadha ﴿آية﴾ $basmala ﴿سورة﴾';
    String letters(String value) => value.replaceAll(RegExp(r'\s'), '');
    expect(letters(layoutAdhkarText(text)), letters(text));
  });
}
