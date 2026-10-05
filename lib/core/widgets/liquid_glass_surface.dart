import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

/// Restrained glass for app chrome; never use on Quran page content.
class LiquidGlassSurface extends StatelessWidget {
  const LiquidGlassSurface({
    super.key,
    required this.child,
    this.padding,
    this.margin,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) => GlassContainer(
    useOwnLayer: true,
    quality: GlassQuality.standard,
    padding: padding,
    margin: margin,
    child: child,
  );
}

/// Keeps a Material [AppBar]'s preferred-size contract while adding glass.
class LiquidGlassAppBar extends StatelessWidget implements PreferredSizeWidget {
  const LiquidGlassAppBar({super.key, required this.appBar});

  final PreferredSizeWidget appBar;

  @override
  Size get preferredSize => appBar.preferredSize;

  @override
  Widget build(BuildContext context) => LiquidGlassSurface(child: appBar);
}
