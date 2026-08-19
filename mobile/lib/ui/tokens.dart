import 'package:flutter/material.dart';

/// Brand primitives — same ramp as Figma Mobile + web `tailwind.config.ts`.
abstract final class MhTokens {
  static const brand50 = Color(0xFFF0F9FF);
  static const brand100 = Color(0xFFE0F2FE);
  static const brand400 = Color(0xFF38BDF8);
  static const brand500 = Color(0xFF0EA5E9);
  static const brand600 = Color(0xFF0284C7);
  static const brand700 = Color(0xFF0369A1);
  static const brand900 = Color(0xFF0C4A6E);

  static const ink = Color(0xFF0F172A);
  static const muted = Color(0xFF475569);
  static const surface = Color(0xFFF8FAFC);
  static const surfaceRaised = Color(0xFFFFFFFF);
  static const border = Color(0xFFE2E8F0);

  static const inkDark = Color(0xFFE2E8F0);
  static const mutedDark = Color(0xFF94A3B8);
  static const surfaceDark = Color(0xFF0B1220);
  static const surfaceRaisedDark = Color(0xFF121A2A);
  static const borderDark = Color(0xFF1E293B);

  static const radiusSm = 8.0;
  static const radiusMd = 12.0;
  static const radiusLg = 20.0;
  static const space = 16.0;

  static const mint = Color(0xFF10B981);
  static const mintWash = Color(0xFFD1FAE5);
  static const amber = Color(0xFFF59E0B);
  static const amberWash = Color(0xFFFEF3C7);
  static const coral = Color(0xFFF43F5E);
  static const coralWash = Color(0xFFFFE4E6);
  static const violet = Color(0xFF8B5CF6);
  static const violetWash = Color(0xFFEDE9FE);
  static const peachWash = Color(0xFFFFF7ED);
}

enum MhAccent { sky, mint, amber, coral, violet }

extension MhAccentColors on MhAccent {
  Color washFor(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    return switch (this) {
      MhAccent.sky => dark ? const Color(0xFF082F49) : MhTokens.brand100,
      MhAccent.mint => dark ? const Color(0xFF064E3B) : MhTokens.mintWash,
      MhAccent.amber => dark ? const Color(0xFF78350F) : MhTokens.amberWash,
      MhAccent.coral => dark ? const Color(0xFF4C0519) : MhTokens.coralWash,
      MhAccent.violet => dark ? const Color(0xFF2E1065) : MhTokens.violetWash,
    };
  }

  Color inkFor(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    return switch (this) {
      MhAccent.sky => dark ? MhTokens.brand100 : MhTokens.brand700,
      MhAccent.mint => dark ? MhTokens.mintWash : const Color(0xFF047857),
      MhAccent.amber => dark ? MhTokens.amberWash : const Color(0xFFB45309),
      MhAccent.coral => dark ? MhTokens.coralWash : const Color(0xFFBE123C),
      MhAccent.violet => dark ? MhTokens.violetWash : const Color(0xFF6D28D9),
    };
  }

  /// Light-mode wash. Prefer [washFor] when the theme can be dark.
  Color get wash => washFor(Brightness.light);

  /// Light-mode ink. Prefer [inkFor] when the theme can be dark.
  Color get ink => inkFor(Brightness.light);

  Color get bold => switch (this) {
        MhAccent.sky => MhTokens.brand500,
        MhAccent.mint => MhTokens.mint,
        MhAccent.amber => MhTokens.amber,
        MhAccent.coral => MhTokens.coral,
        MhAccent.violet => MhTokens.violet,
      };
}
