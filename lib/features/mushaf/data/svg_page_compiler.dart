import 'dart:typed_data';

import 'package:vector_graphics_compiler/vector_graphics_compiler.dart' as vg;

import '../domain/svg_page.dart';

/// Compiles a page's artwork into the binaries the renderer paints.
///
/// This is the slow part of showing a page, so it runs with the rest of the
/// page's preparation, off the main isolate, and never when the page is
/// already on screen.
abstract final class SvgPageCompiler {
  /// [page] drawn [stretch] times as tall as printed, when its lines can be
  /// spread; at its printed height otherwise.
  static SvgPagePicture compile(SvgPage page, {double stretch = 1}) {
    final spread = page.canSpread && stretch > 1;
    return SvgPagePicture(
      page: page.page,
      ink: _encode(spread ? page.inkLines!.at(stretch) : page.ink),
      marks: _encode(spread ? page.marksLines!.at(stretch) : page.marks),
      layout: page.layout,
      stretch: spread ? stretch : 1,
      titles: page.titles,
    );
  }

  // The optimisers need a native library and gain nothing here: a page has
  // no clips, masks or overlapping fills.
  static Uint8List _encode(String svg) => vg.encodeSvg(
    xml: svg,
    debugName: 'mushaf-page',
    enableClippingOptimizer: false,
    enableMaskingOptimizer: false,
    enableOverdrawOptimizer: false,
  );
}
