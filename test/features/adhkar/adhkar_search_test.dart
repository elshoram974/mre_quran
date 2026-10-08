import 'package:flutter_test/flutter_test.dart';
import 'package:mre_quran/features/adhkar/domain/adhkar_collection.dart';
import 'package:mre_quran/features/adhkar/domain/adhkar_search.dart';
import 'package:mre_quran/features/adhkar/domain/dhikr.dart';

import '../../helpers/adhkar_fixtures.dart';

Dhikr _dhikr(int order, String text) => Dhikr(
  order: order,
  text: text,
  repeat: 1,
  repeatLabel: '',
  source: 'مصدر',
  variant: 0,
);

AdhkarCollection _list(String id, String title, List<Dhikr> entries) =>
    AdhkarCollection(
      id: id,
      titles: {'ar': title, 'en': id},
      icon: AdhkarIcon.generic,
      group: kDaily,
      entries: entries,
    );

void main() {
  final catalog = AdhkarCatalog(
    [
      _list('sleep', 'أذكار النوم', [
        _dhikr(1, 'بِاسْمِكَ اللَّهُمَّ أَمُوتُ وَأَحْيَا'),
        _dhikr(2, 'اللَّهُمَّ قِنِي عَذَابَكَ يَوْمَ تَبْعَثُ عِبَادَكَ'),
      ]),
      _list('wake', 'أذكار الاستيقاظ من النوم', [
        _dhikr(1, 'الْحَمْدُ لِلَّهِ الَّذِي أَحْيَانَا بَعْدَ مَا أَمَاتَنَا'),
      ]),
      _list('food', 'الدعاء قبل الطعام', [
        _dhikr(
          1,
          'اللَّهُمَّ بَارِكْ لَنَا فِيهِ وَأَطْعِمْنَا خَيْرًا مِنْهُ',
        ),
      ]),
    ],
    groups: [kDaily],
  );
  final index = AdhkarSearchIndex(catalog);

  test(
    'folding ignores tashkeel and the forms of alef, ya, and ta marbuta',
    () {
      expect(
        foldForSearch('أَذْكَارُ النَّوْمِ'),
        foldForSearch('اذكار النوم'),
      );
      expect(foldForSearch('الصَّلاةِ'), foldForSearch('الصلاه'));
      expect(foldForSearch('على'), foldForSearch('علي'));
      expect(foldForSearch('  a،b  '), 'a b');
    },
  );

  test('names come first, earlier matches before later ones', () {
    final hits = index.search('النوم');
    expect(hits.first, isA<CollectionHit>());
    final lists = hits.whereType<CollectionHit>().map((h) => h.collection.id);
    // "sleep" starts with the name; "wake" only holds it.
    expect(lists.toList(), ['sleep', 'wake']);
    final firstWord = hits.indexWhere((hit) => hit is DhikrHit);
    expect(
      firstWord == -1 ||
          hits.sublist(0, firstWord).every((h) => h is CollectionHit),
      isTrue,
    );
  });

  test('finds a dhikr by its words, typed without tashkeel', () {
    final hits = index.search('اموت واحيا');
    final dhikr = hits.whereType<DhikrHit>().single;
    expect(dhikr.collection.id, 'sleep');
    expect(dhikr.dhikr.order, 1);
    expect(dhikr.snippet, contains('أَمُوتُ'));
  });

  test('every word typed must be there, in any order', () {
    expect(index.search('عذابك تبعث').whereType<DhikrHit>(), hasLength(1));
    expect(index.search('عذابك طعام').whereType<DhikrHit>(), isEmpty);
    expect(index.search('   '), isEmpty);
  });

  test('a list found by name is not repeated through its own words', () {
    final hits = index.search('الطعام');
    expect(hits.whereType<CollectionHit>().single.collection.id, 'food');
    expect(hits.whereType<DhikrHit>(), isEmpty);
  });

  test('English titles are found too, ignoring case', () {
    expect(
      index.search('SLEEP').whereType<CollectionHit>().first.collection.id,
      'sleep',
    );
  });

  test('a long dua is shown around the match', () {
    final words = List.generate(40, (i) => 'كلمة$i').join(' ');
    final long = AdhkarSearchIndex(
      AdhkarCatalog(
        [
          _list('long', 'طويل', [
            _dhikr(1, '$words وَحْدَهُ لاَ شَرِيكَ لَهُ'),
          ]),
        ],
        groups: [kDaily],
      ),
    );
    final hit = long.search('شريك').whereType<DhikrHit>().single;
    expect(hit.snippet, startsWith('…'));
    expect(hit.snippet, contains('شَرِيكَ'));
    expect(hit.snippet.length, lessThan(160));
  });

  test('Quran dhikr are searched through the words given for them', () {
    final withQuran = AdhkarSearchIndex(
      fixtureCatalogWithQuran(),
      quranWords: (dhikr) =>
          dhikr.quran == null ? null : 'الله لا اله الا هو الحي القيوم',
    );
    final hit = withQuran.search('الحي القيوم').whereType<DhikrHit>().single;
    expect(hit.dhikr.quran, isNotNull);
    // Without the Quran text the passage is simply not searched.
    expect(
      AdhkarSearchIndex(fixtureCatalogWithQuran()).search('القيوم'),
      isEmpty,
    );
  });
}
