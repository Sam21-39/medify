import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:medify/core/widgets/medify_icon.dart';
import 'package:medify/gen/assets.gen.dart';

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
    SvgGenImage? svg,
  }) {
    // iOS 26+ native bar only accepts SF Symbols, so SVG applies elsewhere.
    if (svg != null && !PlatformInfo.isIOS26OrHigher()) {
      return AdaptiveNavigationDestination(icon: MedifyIcon(svg), label: label);
    }
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

  /// Clears AdaptiveScaffold chrome. Plugin only bumps MediaQuery — body
  /// must use SafeArea. [tabShell] adds clearance under overlay tab bar.
  static Widget body({required Widget child, bool tabShell = false}) {
    return SafeArea(
      child: tabShell
          ? Padding(
              padding: const EdgeInsets.only(bottom: tabOverlayClearance),
              child: child,
            )
          : child,
    );
  }

  /// Bottom inset so scroll content clears native/Material tab overlay.
  static const double tabOverlayClearance = 160;
}

/// Time picker: Cupertino wheel on iOS, Material dial on Android.
Future<TimeOfDay?> showMedifyTimePicker({
  required BuildContext context,
  required TimeOfDay initialTime,
}) {
  return AdaptiveTimePicker.show(context: context, initialTime: initialTime);
}

/// Dialog with custom [content] and a cancel/confirm pair.
/// CupertinoAlertDialog on iOS, AlertDialog on Android. Closes before [onConfirm].
Future<void> showMedifyDialog({
  required BuildContext context,
  required String title,
  required Widget content,
  required String cancelLabel,
  required String confirmLabel,
  required VoidCallback onConfirm,
}) {
  void confirm(BuildContext dialogContext) {
    Navigator.of(dialogContext).pop();
    onConfirm();
  }

  if (PlatformInfo.isIOS) {
    return showCupertinoDialog<void>(
      context: context,
      builder: (dialogContext) => CupertinoAlertDialog(
        title: Text(title),
        content: content,
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(cancelLabel),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => confirm(dialogContext),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
  }

  return showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: content,
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: Text(cancelLabel),
        ),
        TextButton(
          onPressed: () => confirm(dialogContext),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
}
