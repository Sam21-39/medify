import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Helpers for adaptive_platform_ui chrome.
///
/// iOS 26+ → native Liquid Glass bars (SF Symbols as [String]).
/// iOS <26 → Cupertino chrome ([IconData]).
/// Android → Material tinted NavigationBar / AppBar ([IconData]).
abstract final class MedifyAdaptive {
  MedifyAdaptive._();

  /// Icon for tab destinations — SF Symbol string on iOS 26+, else IconData.
  static dynamic tabIcon({
    required String sf,
    required IconData cupertino,
    required IconData material,
  }) {
    if (PlatformInfo.isIOS26OrHigher()) return sf;
    if (PlatformInfo.isIOS) return cupertino;
    return material;
  }

  static AdaptiveNavigationDestination destination({
    required String sf,
    required String? sfSelected,
    required IconData cupertino,
    required IconData material,
    required IconData materialSelected,
    required String label,
  }) {
    return AdaptiveNavigationDestination(
      icon: tabIcon(sf: sf, cupertino: cupertino, material: material),
      selectedIcon: PlatformInfo.isIOS26OrHigher()
          ? (sfSelected ?? sf)
          : PlatformInfo.isIOS
          ? cupertino
          : materialSelected,
      label: label,
    );
  }

  static AdaptiveAppBarAction action({
    required String iosSymbol,
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return AdaptiveAppBarAction(
      iosSymbol: iosSymbol,
      icon: icon,
      label: label,
      onPressed: onPressed,
    );
  }
}
