import 'package:flutter/material.dart';

import 'tokens.dart';

/// MerchantHub mobile theme. Figma Mobile (`rk4RnruVFTpKdIsgGJIt9w`) leads color;
/// this maps those tokens onto Material 3 without the stock indigo seed.
abstract final class MhTheme {
  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final scheme = ColorScheme(
      brightness: brightness,
      primary: isDark ? MhTokens.brand400 : MhTokens.brand600,
      onPrimary: isDark ? MhTokens.ink : Colors.white,
      secondary: MhTokens.coral,
      onSecondary: Colors.white,
      tertiary: MhTokens.violet,
      onTertiary: Colors.white,
      error: const Color(0xFFDC2626),
      onError: Colors.white,
      surface: isDark ? MhTokens.surfaceDark : const Color(0xFFF7FBFF),
      onSurface: isDark ? MhTokens.inkDark : MhTokens.ink,
      onSurfaceVariant: isDark ? MhTokens.mutedDark : MhTokens.muted,
      outline: isDark ? MhTokens.borderDark : MhTokens.border,
      outlineVariant: isDark ? MhTokens.borderDark : MhTokens.border,
      surfaceContainerHighest: isDark ? MhTokens.surfaceRaisedDark : MhTokens.surfaceRaised,
      primaryContainer: isDark ? MhTokens.brand900 : MhTokens.brand100,
      onPrimaryContainer: isDark ? MhTokens.brand100 : MhTokens.brand900,
      secondaryContainer: isDark ? const Color(0xFF4C1D24) : MhTokens.coralWash,
      tertiaryContainer: isDark ? const Color(0xFF2E1065) : MhTokens.violetWash,
    );

    final textTheme = Typography.englishLike2021.apply(
      fontFamily: 'Roboto',
      bodyColor: scheme.onSurface,
      displayColor: scheme.onSurface,
    ).copyWith(
      headlineLarge: TextStyle(fontWeight: FontWeight.w700, letterSpacing: -0.6, color: scheme.onSurface, fontSize: 32),
      headlineMedium: TextStyle(fontWeight: FontWeight.w700, letterSpacing: -0.4, color: scheme.onSurface, fontSize: 26),
          titleLarge: TextStyle(fontWeight: FontWeight.w600, letterSpacing: -0.2, color: scheme.onSurface, fontSize: 20),
      titleMedium: TextStyle(fontWeight: FontWeight.w600, color: scheme.onSurface, fontSize: 16),
      bodyMedium: TextStyle(height: 1.45, color: scheme.onSurface, fontSize: 15),
      bodySmall: TextStyle(height: 1.4, color: scheme.onSurfaceVariant, fontSize: 13),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
      ),
      cardTheme: CardThemeData(
        color: scheme.surfaceContainerHighest,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(MhTokens.radiusLg),
          side: BorderSide(color: scheme.outline.withValues(alpha: 0.7)),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surfaceContainerHighest,
        indicatorColor: scheme.secondaryContainer,
        elevation: 0,
        height: 68,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            color: selected ? scheme.primary : scheme.onSurfaceVariant,
          );
        }),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(MhTokens.radiusMd)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 44),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(MhTokens.radiusMd)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHighest,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(MhTokens.radiusMd)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(MhTokens.radiusMd),
          borderSide: BorderSide(color: scheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(MhTokens.radiusMd),
          borderSide: BorderSide(color: scheme.primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        side: BorderSide(color: scheme.outline),
      ),
      dividerColor: scheme.outline,
    );
  }
}
