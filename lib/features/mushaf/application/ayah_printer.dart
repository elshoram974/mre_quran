import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pdf;
import 'package:printing/printing.dart';

/// Prints already-rendered ayah cards using the platform's print dialog.
abstract interface class AyahPrinter {
  Future<void> printCards(List<Uint8List> images);
}

/// The platform print service used by the sharing sheet.
final ayahPrinterProvider = Provider<AyahPrinter>(
  (ref) => const _SystemAyahPrinter(),
);

class _SystemAyahPrinter implements AyahPrinter {
  const _SystemAyahPrinter();

  @override
  Future<void> printCards(List<Uint8List> images) async {
    await Printing.layoutPdf(
      onLayout: (format) => buildAyahPrintPdf(images, format),
    );
  }
}

/// Builds one printer page per card, preserving the rendered Quran text.
Future<Uint8List> buildAyahPrintPdf(
  List<Uint8List> images,
  PdfPageFormat format,
) async {
  final document = pdf.Document();
  for (final image in images) {
    final picture = pdf.MemoryImage(image);
    document.addPage(
      pdf.Page(
        pageFormat: format,
        build: (_) =>
            pdf.Center(child: pdf.Image(picture, fit: pdf.BoxFit.contain)),
      ),
    );
  }
  return document.save();
}
