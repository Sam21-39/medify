import 'package:flutter/material.dart';

import 'package:medify/gen/assets.gen.dart';

/// Bundled SVG icon tinted to [color], falling back to the ambient [IconTheme].
class MedifyIcon extends StatelessWidget {
  const MedifyIcon(this.asset, {super.key, this.size = 24, this.color});

  final SvgGenImage asset;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final tint =
        color ??
        IconTheme.of(context).color ??
        Theme.of(context).colorScheme.onSurface;
    return asset.svg(
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(tint, BlendMode.srcIn),
    );
  }
}
