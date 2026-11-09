import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:medify/core/design/medify_theme_extension.dart';
import 'package:medify/core/design/tokens/color_tokens.dart';
import 'package:medify/core/design/tokens/radius_tokens.dart';
import 'package:medify/core/design/tokens/space_tokens.dart';
import 'package:medify/core/design/tokens/type_tokens.dart';

/// Shared ThemeData — iOS chrome via adaptive_platform_ui (Liquid Glass);
/// Android uses Material 3 tinted surfaces from these tokens.
class AppTheme {
  AppTheme._();

  static const TextStyle _base = TextStyle(fontFamily: TypeTokens.fontFamily);

  static ThemeData get lightTheme =>
      _build(ColorTokens.light, Brightness.light);

  static ThemeData get darkTheme => _build(ColorTokens.dark, Brightness.dark);

  static CupertinoThemeData get cupertinoLight => CupertinoThemeData(
    brightness: Brightness.light,
    primaryColor: ColorTokens.light.brand,
    scaffoldBackgroundColor: ColorTokens.light.bgGrouped,
    barBackgroundColor: ColorTokens.light.chromeGlassFill,
    textTheme: CupertinoTextThemeData(
      primaryColor: ColorTokens.light.labelPrimary,
      textStyle: _base.copyWith(
        fontSize: 17,
        color: ColorTokens.light.labelPrimary,
      ),
    ),
  );

  static CupertinoThemeData get cupertinoDark => CupertinoThemeData(
    brightness: Brightness.dark,
    primaryColor: ColorTokens.dark.brand,
    scaffoldBackgroundColor: ColorTokens.dark.bgGrouped,
    barBackgroundColor: ColorTokens.dark.chromeGlassFill,
    textTheme: CupertinoTextThemeData(
      primaryColor: ColorTokens.dark.labelPrimary,
      textStyle: _base.copyWith(
        fontSize: 17,
        color: ColorTokens.dark.labelPrimary,
      ),
    ),
  );

  static ThemeData _build(ColorTokens c, Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final scheme = ColorScheme(
      brightness: brightness,
      primary: c.brand,
      onPrimary: c.onBrand,
      primaryContainer: c.brandSoft,
      onPrimaryContainer: c.labelPrimary,
      secondary: c.statusTaken,
      onSecondary: Colors.white,
      secondaryContainer: c.chromeTintSurface,
      onSecondaryContainer: c.labelPrimary,
      surface: c.bgSurface,
      onSurface: c.labelPrimary,
      surfaceContainerHighest: c.chromeTintSurface,
      error: c.danger,
      onError: Colors.white,
      outline: c.separator,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      fontFamily: TypeTokens.fontFamily,
      colorScheme: scheme,
      scaffoldBackgroundColor: c.bgGrouped,
      extensions: <ThemeExtension<dynamic>>[
        isDark ? MedifyTokens.dark : MedifyTokens.light,
      ],
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        backgroundColor: c.chromeTintSurface,
        foregroundColor: c.labelPrimary,
        titleTextStyle: TypeTokens.title3(c.labelPrimary),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: c.chromeTintSurface,
        indicatorColor: c.brand.withValues(alpha: 0.18),
        elevation: 0,
        height: SpaceTokens.bottomNavHeight,
        labelTextStyle: WidgetStatePropertyAll(
          TypeTokens.caption(c.labelSecondary),
        ),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? c.brand : c.labelSecondary,
            size: 24,
          );
        }),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: c.bgSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(RadiusTokens.card),
          side: BorderSide(color: c.separator.withValues(alpha: 0.45)),
        ),
        margin: const EdgeInsets.symmetric(
          horizontal: SpaceTokens.md,
          vertical: SpaceTokens.xs,
        ),
      ),
      dividerTheme: DividerThemeData(
        color: c.separator,
        thickness: 0.5,
        space: 0.5,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: c.brand,
        textColor: c.labelPrimary,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: SpaceTokens.md,
          vertical: SpaceTokens.xs,
        ),
      ),
      textTheme: TextTheme(
        displayLarge: TypeTokens.largeTitle(c.labelPrimary),
        displayMedium: TypeTokens.title1(c.labelPrimary),
        displaySmall: TypeTokens.title2(c.labelPrimary),
        headlineMedium: TypeTokens.title3(c.labelPrimary),
        titleLarge: TypeTokens.title3(c.labelPrimary),
        titleMedium: TypeTokens.callout(c.labelPrimary),
        bodyLarge: TypeTokens.body(c.labelPrimary),
        bodyMedium: TypeTokens.body(c.labelPrimary),
        bodySmall: TypeTokens.footnote(c.labelSecondary),
        labelLarge: TypeTokens.callout(c.onBrand),
        labelSmall: TypeTokens.caption(c.labelSecondary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: c.brand,
          foregroundColor: c.onBrand,
          minimumSize: const Size(120, SpaceTokens.buttonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(RadiusTokens.button),
          ),
          textStyle: TypeTokens.callout(c.onBrand),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: c.brand,
          minimumSize: const Size(120, SpaceTokens.buttonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(RadiusTokens.button),
          ),
          side: BorderSide(color: c.brand, width: 1.5),
          textStyle: TypeTokens.callout(c.brand),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: c.brand,
          minimumSize: const Size(120, SpaceTokens.buttonHeightSm),
          textStyle: TypeTokens.callout(c.brand),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.bgSurface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: SpaceTokens.md,
          vertical: SpaceTokens.md,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(RadiusTokens.input),
          borderSide: BorderSide(color: c.separator),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(RadiusTokens.input),
          borderSide: BorderSide(color: c.separator),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(RadiusTokens.input),
          borderSide: BorderSide(color: c.brand, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(RadiusTokens.input),
          borderSide: BorderSide(color: c.danger),
        ),
        labelStyle: TypeTokens.body(c.labelSecondary),
        hintStyle: TypeTokens.body(c.labelTertiary),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: c.brand,
        foregroundColor: c.onBrand,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(RadiusTokens.card),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: c.bgSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(RadiusTokens.sheet),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: c.labelPrimary,
        contentTextStyle: TypeTokens.body(c.bgSurface),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(RadiusTokens.button),
        ),
      ),
      iconTheme: IconThemeData(color: c.labelPrimary, size: 24),
      chipTheme: ChipThemeData(
        backgroundColor: c.chromeTintSurface,
        selectedColor: c.brand.withValues(alpha: 0.2),
        labelStyle: TypeTokens.footnote(c.labelPrimary),
        padding: const EdgeInsets.symmetric(
          horizontal: SpaceTokens.sm,
          vertical: SpaceTokens.xxs,
        ),
        shape: StadiumBorder(side: BorderSide(color: c.separator)),
      ),
    );
  }
}
