import 'package:flutter/material.dart';

/// Available NasBeat visual themes.
enum NasBeatTheme {
  defaultDark('default'),
  amoledBlack('amoled_black'),
  blueDark('blue_dark'),
  niceGrey('nice_grey'),
  glassmorphism('glassmorphism');

  const NasBeatTheme(this.key);
  final String key;

  static NasBeatTheme fromKey(String? key) => NasBeatTheme.values.firstWhere(
        (t) => t.key == key,
        orElse: () => NasBeatTheme.defaultDark,
      );

  String get displayName => switch (this) {
        NasBeatTheme.defaultDark => 'NasBeat Dark',
        NasBeatTheme.amoledBlack => 'Super AMOLED Black',
        NasBeatTheme.blueDark => 'Blue Dark',
        NasBeatTheme.niceGrey => 'Nice Grey',
        NasBeatTheme.glassmorphism => 'Glassmorphism (iOS)',
      };

  Color get background => switch (this) {
        NasBeatTheme.defaultDark => const Color(0xFF0A040C),
        NasBeatTheme.amoledBlack => Colors.black,
        NasBeatTheme.blueDark => const Color(0xFF050C1A),
        NasBeatTheme.niceGrey => const Color(0xFF151515),
        NasBeatTheme.glassmorphism => const Color(0xFF060A10),
      };

  Color get surface => switch (this) {
        NasBeatTheme.defaultDark => const Color(0xFF1A111B),
        NasBeatTheme.amoledBlack => const Color(0xFF0D0D0D),
        NasBeatTheme.blueDark => const Color(0xFF0D1B2A),
        NasBeatTheme.niceGrey => const Color(0xFF252525),
        NasBeatTheme.glassmorphism => const Color(0x18FFFFFF),
      };

  Color get accent => switch (this) {
        NasBeatTheme.defaultDark => const Color(0xFFFE385E),
        NasBeatTheme.amoledBlack => const Color(0xFFFF5252),
        NasBeatTheme.blueDark => const Color(0xFF00B4D8),
        NasBeatTheme.niceGrey => const Color(0xFF64FFDA),
        NasBeatTheme.glassmorphism => const Color(0xFF60C0F0),
      };

  Color get accentSecondary => switch (this) {
        NasBeatTheme.defaultDark => const Color(0xFF0EA5E0),
        NasBeatTheme.amoledBlack => const Color(0xFFFF1744),
        NasBeatTheme.blueDark => const Color(0xFF0077B6),
        NasBeatTheme.niceGrey => const Color(0xFF26C6DA),
        NasBeatTheme.glassmorphism => const Color(0xFF93D5F5),
      };

  Color get primaryText => switch (this) {
        NasBeatTheme.defaultDark => const Color(0xFFDAEAF7),
        NasBeatTheme.amoledBlack => const Color(0xFFFFFFFF),
        NasBeatTheme.blueDark => const Color(0xFFE0F4FF),
        NasBeatTheme.niceGrey => const Color(0xFFEEEEEE),
        NasBeatTheme.glassmorphism => const Color(0xFFF0F9FF),
      };

  Color get secondaryText => switch (this) {
        NasBeatTheme.defaultDark => const Color(0xFFF2E7F0),
        NasBeatTheme.amoledBlack => const Color(0xFFE0E0E0),
        NasBeatTheme.blueDark => const Color(0xFFB2D9FF),
        NasBeatTheme.niceGrey => const Color(0xFFBDBDBD),
        NasBeatTheme.glassmorphism => const Color(0xFFBAE6FD),
      };

  bool get isAmoled => this == NasBeatTheme.amoledBlack;

  bool get isGlass => this == NasBeatTheme.glassmorphism;

  ThemeData buildThemeData() {
    final bg = background;
    final surf = surface;
    final acc = accent;
    final accSec = accentSecondary;
    final pText = primaryText;
    final sText = secondaryText;

    final colorScheme = ColorScheme.dark(
      primary: acc,
      secondary: accSec,
      surface: bg,
      surfaceContainerHighest: surf,
      onPrimary: pText,
      onSecondary: pText,
      onSurface: pText,
    );

    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: bg,
      dialogBackgroundColor: bg,
      primaryColorDark: acc,
      fontFamily: 'Gilroy',
      primarySwatch: MaterialColor(acc.toARGB32(), {
        50: acc.withValues(alpha: 0.1),
        100: acc.withValues(alpha: 0.2),
        200: acc.withValues(alpha: 0.3),
        300: acc.withValues(alpha: 0.4),
        400: acc.withValues(alpha: 0.5),
        500: acc.withValues(alpha: 0.6),
        600: acc.withValues(alpha: 0.7),
        700: acc.withValues(alpha: 0.8),
        800: acc.withValues(alpha: 0.9),
        900: acc,
      }),
      colorScheme: colorScheme,
      iconTheme: IconThemeData(color: pText),
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStateProperty.all(acc),
        interactive: true,
        radius: const Radius.circular(10),
        thickness: WidgetStateProperty.all(5),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: isGlass ? Colors.transparent : bg,
        foregroundColor: pText,
        surfaceTintColor: Colors.transparent,
        iconTheme: IconThemeData(color: pText),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: acc),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: acc,
        selectionColor: acc,
        selectionHandleColor: acc,
      ),
      brightness: Brightness.dark,
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStatePropertyAll(pText),
        trackOutlineColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected) ? accSec : acc),
        trackColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected)
                ? accSec
                : sText.withValues(alpha: 0.0)),
      ),
      searchBarTheme: SearchBarThemeData(
        backgroundColor: WidgetStatePropertyAll(bg),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: surf,
        textStyle: TextStyle(color: pText),
      ),
      dropdownMenuTheme: DropdownMenuThemeData(
        menuStyle: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(bg),
        ),
        textStyle: TextStyle(color: pText),
      ),
      menuTheme: MenuThemeData(
        style: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(bg),
        ),
      ),
      cardTheme: CardThemeData(
        color: isGlass ? surf : bg,
        surfaceTintColor: Colors.transparent,
        elevation: isGlass ? 0 : null,
        shape: isGlass
            ? RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                    color: Colors.white.withValues(alpha: 0.12), width: 0.8),
              )
            : null,
      ),
    );
  }
}

/// Canonical app theme.
///
/// Use [AppTheme] in new code. The [Default_Theme] typedef at the bottom of
/// this file provides backward-compatible access for existing callers while
/// imports are being migrated.
class AppTheme {
  // ── Text Styles ─────────────────────────────────────────────────────────────
  static const primaryTextStyle = TextStyle(fontFamily: "Fjalla");
  static const secondoryTextStyle = TextStyle(fontFamily: "Gilroy");
  static const secondoryTextStyleMedium =
      TextStyle(fontFamily: "Gilroy", fontWeight: FontWeight.w700);
  static const tertiaryTextStyle = TextStyle(fontFamily: "CodePro");
  static const fontAwesomeRegularFont =
      TextStyle(fontFamily: "FontAwesome-Regular");
  static const fontAwesomeSolidFont =
      TextStyle(fontFamily: "FontAwesome-Solids");

  // ── Default Colors (backward compat) ────────────────────────────────────────
  static const themeColor = Color(0xFF0A040C);
  static const primaryColor1 = Color(0xFFDAEAF7);
  static const primaryColor2 = Color.fromARGB(255, 242, 231, 240);
  static const accentColor1 = Color(0xFF0EA5E0);
  static const accentColor1light = Color(0xFF18C9ED);
  static const accentColor2 = Color(0xFFFE385E);
  static const successColor = Color(0xFF5EFF43);

  // ── Theme Data ───────────────────────────────────────────────────────────────
  ThemeData get defaultThemeData => NasBeatTheme.defaultDark.buildThemeData();

  static ThemeData themeDataFor(NasBeatTheme theme) => theme.buildThemeData();
}

/// Backward-compat alias for [AppTheme].
/// Prefer importing from [core/theme/app_theme.dart] and using [AppTheme] directly.
// ignore: camel_case_types
typedef Default_Theme = AppTheme;
