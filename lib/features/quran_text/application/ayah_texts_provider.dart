import 'dart:convert';
import 'dart:isolate';

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_tokens.dart';
import '../../mushaf/domain/mushaf_edition.dart';
import '../../quran_index/application/quran_metadata_provider.dart';
import '../data/riwaya_text_parser.dart';
import '../domain/ayah_texts.dart';
import '../domain/quran_text.dart';
import 'quran_text_providers.dart';

/// The font that draws the app's own Quran text: the Mushaf's script when the
/// text holds it, else the app's Quran font. Whatever shows Hafs ayahs uses
/// it, so every ayah in the app is in one hand.
String appQuranFont(QuranText text) => text.hasMushafScript
    ? AppTokens.mushafFontFamily
    : AppTokens.quranFontFamily;

/// The text of [MushafEdition]'s ayahs, to copy and share from its pages;
/// null for an edition without a text. A reading's bundled text is checked
/// against its SHA-256 before it is used.
final editionTextsProvider = FutureProvider.family<AyahTexts?, MushafEdition>((
  ref,
  edition,
) async {
  if (edition.matchesAppText) {
    final text = await ref.watch(quranTextProvider.future);
    return HafsAyahTexts(text, fontFamily: appQuranFont(text));
  }
  final info = edition.text;
  if (info == null) return null;
  final metadata = await ref.watch(quranMetadataProvider.future);
  final data = await rootBundle.load(info.asset);
  final bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
  final ayahs = await Isolate.run(() {
    if (sha256.convert(bytes).toString() != info.sha256) {
      throw StateError('${info.asset} does not match its checksum');
    }
    return RiwayaTextParser.parse(utf8.decode(bytes));
  });
  return RiwayaAyahTexts(
    metadata: metadata,
    ayahs: ayahs,
    fontFamily: info.fontFamily,
    unmatchedSurahs: info.unmatchedSurahs,
  );
});
