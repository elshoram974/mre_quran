import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mre_quran/features/mushaf/application/mushaf_packs.dart';
import 'package:mre_quran/features/mushaf/application/page_image_providers.dart';
import 'package:mre_quran/features/mushaf/data/page_asset_store.dart';
import 'package:mre_quran/features/mushaf/domain/mushaf_edition.dart';
import 'package:mre_quran/features/mushaf/presentation/offline_packs_section.dart';
import 'package:mre_quran/l10n/generated/app_localizations.dart';

import '../../helpers/fake_pack_downloader.dart';

void main() {
  late Directory root;
  late FakePackDownloader downloader;

  setUp(() {
    root = Directory.systemTemp.createTempSync('offline_section');
    downloader = FakePackDownloader();
  });
  tearDown(() => root.deleteSync(recursive: true));

  /// File work runs in real time and one step at a time; pump until [done].
  Future<void> until(WidgetTester tester, bool Function() done) async {
    for (var i = 0; i < 1500 && !done(); i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump(const Duration(milliseconds: 50));
    }
    await tester.pumpAndSettle();
  }

  /// Waits until the editions have loaded.
  Future<void> settle(WidgetTester tester) => until(
    tester,
    () =>
        find.byType(FilledButton).evaluate().isNotEmpty ||
        find.byType(TextButton).evaluate().isNotEmpty,
  );

  Future<void> pump(
    WidgetTester tester, {
    Locale locale = const Locale('ar'),
    Brightness brightness = Brightness.light,
    double textScale = 1,
    Size size = const Size(390, 900),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          packDownloaderProvider.overrideWithValue(downloader),
          pageAssetStoreProvider.overrideWithValue(
            PageAssetStore(
              root: () async => root,
              fetch: (_) async => Uint8List(0),
            ),
          ),
        ],
        child: MaterialApp(
          locale: locale,
          theme: ThemeData(brightness: brightness),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(textScale)),
            child: child!,
          ),
          home: const Scaffold(
            body: SingleChildScrollView(child: OfflinePacksSection()),
          ),
        ),
      ),
    );
    await settle(tester);
  }

  testWidgets('lists every edition with its size, in Arabic', (tester) async {
    await pump(tester);
    expect(find.text('المصحف دون اتصال'), findsOneWidget);
    expect(find.text('مصحف المدينة'), findsOneWidget);
    expect(find.text('مصحف التجويد'), findsOneWidget);
    expect(find.text('غير محمّل · نحو ٨٠ ميجابايت'), findsOneWidget);
    expect(find.text('تحميل'), findsNWidgets(3));
  });

  testWidgets('download asks first, then starts one notified download', (
    tester,
  ) async {
    await pump(tester);
    await tester.tap(find.text('تحميل').at(1));
    await tester.pumpAndSettle();
    expect(find.text('تحميل مصحف التجويد؟'), findsOneWidget);
    expect(downloader.enqueued, isEmpty, reason: 'nothing before the answer');
    await tester.tap(find.widgetWithText(FilledButton, 'تحميل').last);
    await until(tester, () => downloader.enqueued.isNotEmpty);
    expect(downloader.enqueued['mushaf-tajweed'], hasLength(1208));
    expect(
      downloader.texts['mushaf-tajweed']!.runningTitle,
      'جارٍ تحميل مصحف التجويد',
    );
    expect(find.text('جارٍ التحميل · ٠٪'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    await tester.tap(find.text('إلغاء'));
    await until(tester, () => downloader.cancelled.isNotEmpty);
    expect(downloader.cancelled, ['mushaf-tajweed']);
  });

  Uint8List pngBytes() => Uint8List.fromList([
    0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0, 0, 0, 0, //
  ]);

  void putFiles(MushafEdition edition, {int? count}) {
    final files = edition.packFiles;
    for (final f in count == null ? files : files.take(count)) {
      File('${root.path}/mushaf/${f.path}')
        ..createSync(recursive: true)
        ..writeAsBytesSync(pngBytes());
    }
  }

  testWidgets('a finished edition shows ready and its size on the device', (
    tester,
  ) async {
    putFiles(MushafEdition.madinah);
    await pump(tester);
    expect(find.textContaining('جاهز دون اتصال'), findsOneWidget);
    expect(find.textContaining('على الجهاز'), findsOneWidget);
    expect(find.textContaining('وليست في الذاكرة المؤقتة'), findsOneWidget);
  });

  testWidgets('deleting is strict: warning, ticked box, then it goes', (
    tester,
  ) async {
    putFiles(MushafEdition.madinah);
    await pump(tester);
    await tester.tap(find.text('حذف'));
    await tester.pumpAndSettle();
    expect(find.text('حذف مصحف المدينة من هذا الجهاز؟'), findsOneWidget);
    expect(find.textContaining('٦٠٤ ملف صورة'), findsOneWidget);
    expect(find.textContaining('نهائيًا'), findsOneWidget);
    final delete = find.widgetWithText(FilledButton, 'حذف نهائي');
    // Not before the box is ticked.
    expect(tester.widget<FilledButton>(delete).onPressed, isNull);
    await tester.tap(delete, warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.text('حذف نهائي'), findsOneWidget, reason: 'still asking');
    await tester.tap(find.byType(CheckboxListTile));
    await tester.pumpAndSettle();
    expect(tester.widget<FilledButton>(delete).onPressed, isNotNull);
    await tester.tap(delete);
    await until(
      tester,
      () => find.textContaining('جاهز دون اتصال').evaluate().isEmpty,
    );
    expect(find.text('تحميل'), findsNWidgets(3));
    expect(
      Directory('${root.path}/mushaf/images/madinah').existsSync(),
      isFalse,
    );
  });

  testWidgets('cancelling the warning deletes nothing', (tester) async {
    putFiles(MushafEdition.madinah);
    await pump(tester);
    await tester.tap(find.text('حذف'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('إلغاء'));
    await tester.pumpAndSettle();
    expect(find.textContaining('جاهز دون اتصال'), findsOneWidget);
    expect(
      Directory('${root.path}/mushaf/images/madinah').existsSync(),
      isTrue,
    );
  });

  testWidgets('a partial download can be deleted to free space too', (
    tester,
  ) async {
    putFiles(MushafEdition.madinah, count: 100);
    await pump(tester);
    expect(find.byTooltip('حذف'), findsOneWidget);
    expect(find.text('متابعة'), findsOneWidget);
  });

  testWidgets('coming back to the app collects what finished meanwhile', (
    tester,
  ) async {
    await pump(tester);
    final before = downloader.resumes;
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    putFiles(MushafEdition.madinah);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await until(
      tester,
      () => find.textContaining('جاهز دون اتصال').evaluate().isNotEmpty,
    );
    expect(downloader.resumes, greaterThan(before));
    expect(find.textContaining('جاهز دون اتصال'), findsOneWidget);
  });

  for (final (name, locale, brightness, scale, size) in [
    (
      'English',
      const Locale('en'),
      Brightness.light,
      1.0,
      const Size(390, 900),
    ),
    (
      'dark, large text',
      const Locale('ar'),
      Brightness.dark,
      2.0,
      const Size(320, 900),
    ),
    (
      'expanded',
      const Locale('ar'),
      Brightness.light,
      1.0,
      const Size(1000, 900),
    ),
  ]) {
    testWidgets('lays out without overflow: $name', (tester) async {
      await pump(
        tester,
        locale: locale,
        brightness: brightness,
        textScale: scale,
        size: size,
      );
      expect(tester.takeException(), isNull);
      expect(find.byType(OfflinePacksSection), findsOneWidget);
    });
  }
}
