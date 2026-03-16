// ============================================================
//  lib/config/app_theme.dart
//  "Developer Dark Industries" — complete design token system
//
//  ARCHITECTURE (read this before touching any colour in the app):
//
//  ┌─────────────────────────────────────────────────────────┐
//  │ AppRawColors   raw hex constants — NEVER use in widgets │
//  │ AppTokens      semantic tokens — use THESE everywhere   │
//  │ AppTextStyles  ready-made TextStyle getters             │
//  │ AppDimens      spacing / radius / size constants        │
//  │ helper fns     getBoxDecoration() etc. — still callable │
//  │ _build()       full FlutterThemeData factory            │
//  └─────────────────────────────────────────────────────────┘
//
//  HOW LIVE THEME DETECTION WORKS:
//  ThemeController calls setThemeResolver(() => isDark.value)
//  on onInit().  AppTokens.isDark reads that resolver, so
//  every getter automatically returns the right colour for
//  whatever theme is currently active — no param passing needed.
// ============================================================

import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────
//  STEP 1 — RAW COLOUR CONSTANTS
//  These are brand truths. Every other colour is derived here.
// ─────────────────────────────────────────────────────────────

abstract class AppRawColors {
  // Accent / brand
  static const Color cyan      = Color(0xFF00E5FF);
  static const Color cyanDark  = Color(0xFF00B8CC);
  // Readable teal for light-mode — cyan is too bright on white backgrounds
  static const Color cyanLight = Color(0xFF007A8C);
  static const Color neonGreen = Color(0xFF69FF47);
  static const Color violet    = Color(0xFF7C4DFF);
  static const Color amber     = Color(0xFFFFCB6B);
  static const Color red       = Color(0xFFFF5370);
  static const Color orange    = Color(0xFFFF6D00);
  static const Color teal      = Color(0xFF00897B);

  // Dark surfaces
  static const Color darkBg            = Color(0xFF0B0D12);
  static const Color darkSurface       = Color(0xFF13161E);
  static const Color darkSurfaceRaised = Color(0xFF1B1F2B);
  // Dedicated dark form-field fill — slightly lighter than card, never grey
  static const Color darkFormField     = Color(0xFF1E2332);
  // Quill editor bg in dark mode — near-black, readable
  static const Color darkEditorBg      = Color(0xFF161A24);
  static const Color darkBorder        = Color(0xFF252C3D);
  static const Color darkBorderFocus   = Color(0xFF2E3850);

  // Dark text
  static const Color darkTextPrimary   = Color(0xFFE2E8F0);
  static const Color darkTextSecondary = Color(0xFF7A8BAA);
  static const Color darkTextDisabled  = Color(0xFF3D4A62);
  static const Color darkOnAccent      = Color(0xFF000000);

  // Light surfaces
  static const Color lightBg            = Color(0xFFF0F4F8);
  static const Color lightSurface       = Color(0xFFFFFFFF);
  static const Color lightSurfaceRaised = Color(0xFFE8EEF5);
  static const Color lightBorder        = Color(0xFFD0DAE8);
  static const Color lightBorderFocus   = Color(0xFFB0C0D4);

  // Light text
  static const Color lightTextPrimary   = Color(0xFF0D1117);
  static const Color lightTextSecondary = Color(0xFF4A5568);
  static const Color lightTextDisabled  = Color(0xFFA0AEC0);
  static const Color lightOnAccent      = Color(0xFF000000);
}

// ─────────────────────────────────────────────────────────────
//  STEP 2 — SEMANTIC TOKENS  (use these in every widget)
//  All getters are live: they read _isDarkNow() at call time.
// ─────────────────────────────────────────────────────────────

abstract class AppTokens {
  // Theme mode
  static bool get isDark => _isDarkNow();

  // Surfaces
  static Color get pageBg       => isDark ? AppRawColors.darkBg            : AppRawColors.lightBg;
  static Color get cardBg       => isDark ? AppRawColors.darkSurface       : AppRawColors.lightSurface;
  static Color get raisedBg     => isDark ? AppRawColors.darkSurfaceRaised : AppRawColors.lightSurfaceRaised;
  static Color get border       => isDark ? AppRawColors.darkBorder        : AppRawColors.lightBorder;
  static Color get borderFocus  => isDark ? AppRawColors.darkBorderFocus   : AppRawColors.lightBorderFocus;

  /// Card border: subtle cyan glow in dark mode, neutral in light mode.
  static Color get cardBorder   => isDark
      ? AppRawColors.cyan.withOpacity(0.18)
      : AppRawColors.lightBorder;

  /// Form container border: slightly stronger cyan tint in dark mode.
  static Color get formBorder   => isDark
      ? AppRawColors.cyan.withOpacity(0.28)
      : AppRawColors.lightBorder;

  // Text
  static Color get textPrimary   => isDark ? AppRawColors.darkTextPrimary   : AppRawColors.lightTextPrimary;
  static Color get textSecondary => isDark ? AppRawColors.darkTextSecondary : AppRawColors.lightTextSecondary;
  static Color get textDisabled  => isDark ? AppRawColors.darkTextDisabled  : AppRawColors.lightTextDisabled;
  static Color get onAccent      => isDark ? AppRawColors.darkOnAccent      : AppRawColors.lightOnAccent;

  // Fixed accents — same in both themes
  static const Color accent       = AppRawColors.cyan;
  static const Color accentDark   = AppRawColors.cyanDark;

  /// Accent that is actually readable in the current theme.
  /// Dark → bright cyan. Light → deep teal (cyanLight) so it shows on white.
  static Color get accentReadable => isDark ? AppRawColors.cyan : AppRawColors.cyanLight;

  static const Color success      = AppRawColors.neonGreen;
  static const Color error        = AppRawColors.red;
  static const Color warning      = AppRawColors.amber;
  static const Color orange       = AppRawColors.orange;
  static const Color teal         = AppRawColors.teal;
  static const Color violet       = AppRawColors.violet;

  /// Background fill for TextFormField / DropdownButtonFormField.
  /// Distinct from cardBg so fields are clearly readable in dark mode.
  static Color get formFieldBg => isDark ? AppRawColors.darkFormField : AppRawColors.lightSurface;

  /// Background for the Quill editor body (markdown editor).
  static Color get editorBg => isDark ? AppRawColors.darkEditorBg : AppRawColors.lightSurface;

  /// Background for the Quill toolbar strip.
  static Color get editorToolbarBg => isDark ? AppRawColors.darkSurface : AppRawColors.lightSurfaceRaised;

  /// Border colour for the editor / toolbar chrome.
  static Color get editorBorder => isDark ? AppRawColors.darkBorder : AppRawColors.lightBorder;

  /// Background for inline filter bars above list views.
  static Color get filterBarBg => isDark ? AppRawColors.darkSurface : AppRawColors.lightSurface;

  // Status badge helpers
  static Color get statusActiveBg   => AppRawColors.neonGreen.withOpacity(0.12);
  static Color get statusActiveFg   => isDark ? AppRawColors.neonGreen : const Color(0xFF1B6B1B);
  static Color get statusActiveBrd  => AppRawColors.neonGreen;
  static Color get statusInactiveBg => AppRawColors.red.withOpacity(0.12);
  static Color get statusInactiveFg => AppRawColors.red;

  // Attendance log type colours — semantic names, not raw
  static const Color logIn         = Color(0xFF2E7D32); // dark green
  static const Color logOut        = Color(0xFFC62828); // dark red
  static const Color logBreakStart = Color(0xFFE65100); // deep orange
  static const Color logBreakEnd   = Color(0xFF1565C0); // dark blue

  // Attendance compliance badge colours
  static const Color complianceOk     = Color(0xFF2E7D32);
  static const Color complianceLate   = Color(0xFFE65100);
  static const Color complianceEarly  = Color(0xFFEF5350);
  static const Color complianceAbsent = Color(0xFFB71C1C);
  static const Color complianceMissed = Color(0xFF6A1B9A);
  static const Color complianceOff    = Color(0xFF546E7A);
}

// ─────────────────────────────────────────────────────────────
//  STEP 3 — DIMENSION TOKENS
// ─────────────────────────────────────────────────────────────

abstract class AppDimens {
  // Border radius
  static const double radiusXs = 4.0;
  static const double radiusSm = 6.0;
  static const double radiusMd = 8.0;
  static const double radiusLg = 12.0;
  static const double radiusXl = 16.0;
  static const double radiusXxl = 20.0;

  // Spacing
  static const double spacingXs = 4.0;
  static const double spacingSm = 8.0;
  static const double spacingMd = 16.0;
  static const double spacingLg = 24.0;
  static const double spacingXl = 32.0;

  // Card
  static const double cardPadding  = 16.0;
  static const double cardMarginH  = 8.0;
  static const double cardMarginV  = 4.0;

  // Icon sizes
  static const double iconXs = 12.0;
  static const double iconSm = 14.0;
  static const double iconMd = 18.0;
  static const double iconLg = 22.0;
  static const double iconXl = 36.0;
  static const double iconXxl = 64.0;

  // Font sizes
  static const double fontXs  = 10.0;
  static const double fontSm  = 11.0;
  static const double fontMd  = 13.0;
  static const double fontLg  = 15.0;
  static const double fontXl  = 16.0;
  static const double fontXxl = 18.0;

  // Button
  static const double btnHeight = 40.0;
  static const double btnPaddingH = 14.0;
  static const double btnPaddingV = 10.0;

  // Sidebar
  static const double sidebarWidth = 250.0;
}

// ─────────────────────────────────────────────────────────────
//  STEP 4 — TEXT STYLE TOKENS
//  Always use 'Inter'. All colours live-read from AppTokens.
// ─────────────────────────────────────────────────────────────
bool get _isPerformanceMode => !kIsWeb && (Platform.isAndroid || Platform.isIOS);
abstract class AppTextStyles {
  // Card header (bold title row inside a card)
  static TextStyle get cardTitle => TextStyle(
    fontFamily: 'Inter',
    fontSize: AppDimens.fontXl,
    fontWeight: FontWeight.w700,
    color: AppTokens.textPrimary,
  );

  // Section heading (e.g. "| ÖZELLİKLER")
  static TextStyle get sectionHeading => TextStyle(
    fontFamily: 'Inter',
    fontSize: AppDimens.fontXl,
    fontWeight: FontWeight.w700,
    color: AppTokens.textPrimary,
    letterSpacing: 1.5,
  );

  // Info row — label part
  static TextStyle get labelKey => TextStyle(
    fontFamily: 'Inter',
    fontSize: AppDimens.fontMd,
    color: AppTokens.textSecondary,
    height: 1.5,
  );

  // Info row — value part
  static TextStyle get labelValue => TextStyle(
    fontFamily: 'Inter',
    fontSize: AppDimens.fontMd,
    fontWeight: FontWeight.w600,
    color: AppTokens.textPrimary,
    height: 1.5,
  );

  // Body text (normal)
  static TextStyle get bodyMd => TextStyle(
    fontFamily: 'Inter',
    fontSize: AppDimens.fontMd,
    color: AppTokens.textPrimary,
    height: 1.5,
  );

  // Small secondary text
  static TextStyle get bodySm => TextStyle(
    fontFamily: 'Inter',
    fontSize: AppDimens.fontSm,
    color: AppTokens.textSecondary,
    height: 1.4,
  );

  // Tiny label (badge text, captions)
  static TextStyle get caption => TextStyle(
    fontFamily: 'Inter',
    fontSize: AppDimens.fontXs,
    color: AppTokens.textSecondary,
  );

  // Accent-coloured label
  static const TextStyle accentLabel = TextStyle(
    fontFamily: 'Inter',
    fontSize: AppDimens.fontMd,
    fontWeight: FontWeight.w600,
    color: AppRawColors.cyan,
  );

  // Error / destructive label
  static const TextStyle errorLabel = TextStyle(
    fontFamily: 'Inter',
    fontSize: AppDimens.fontMd,
    fontWeight: FontWeight.w600,
    color: AppRawColors.red,
  );

  // Link style
  static const TextStyle link = TextStyle(
    fontFamily: 'Inter',
    fontSize: AppDimens.fontSm,
    color: AppRawColors.cyan,
    decoration: TextDecoration.underline,
    decorationColor: AppRawColors.cyan,
  );
}

// ─────────────────────────────────────────────────────────────
//  LIVE THEME RESOLVER — set by ThemeController.onInit()
// ─────────────────────────────────────────────────────────────

bool Function() _themeResolver = () => true; // default → dark

/// Called once from ThemeController.onInit().
void setThemeResolver(bool Function() resolver) => _themeResolver = resolver;

bool _isDarkNow() => _themeResolver();

// ─────────────────────────────────────────────────────────────
//  PLATFORM HELPER
// ─────────────────────────────────────────────────────────────

bool _isDesktop() {
  if (kIsWeb) return false;
  try { return Platform.isWindows || Platform.isLinux || Platform.isMacOS; }
  catch (_) { return false; }
}

// ─────────────────────────────────────────────────────────────
//  BOX DECORATION HELPERS  (backwards-compatible, no args needed)
// ─────────────────────────────────────────────────────────────

/// Standard card / panel surface.
BoxDecoration getBoxDecoration() {
  final bool dark = _isDarkNow();

  // MOBİLDE GÖLGELERİ KAPATALIM
  if (_isPerformanceMode) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(AppDimens.radiusMd),
      color: dark ? AppRawColors.darkSurface : AppRawColors.lightSurface,
      border: Border.all(
          color: dark ? AppRawColors.darkBorder : AppRawColors.lightBorder,
          width: 1
      ),
    );
  }

  // DESKTOP İÇİN GÖLGELİ HALİ
  final shadow = dark
      ? BoxShadow(color: Colors.black.withOpacity(0.45), blurRadius: 8, offset: const Offset(0, 2))
      : BoxShadow(color: Colors.black.withOpacity(0.07), blurRadius: 6, offset: const Offset(0, 1));

  return BoxDecoration(
    borderRadius: BorderRadius.circular(AppDimens.radiusMd),
    color: dark ? AppRawColors.darkSurface : AppRawColors.lightSurface,
    border: Border.all(color: dark ? AppRawColors.darkBorder : AppRawColors.lightBorder, width: 1),
    boxShadow: [shadow],
  );
}

/// Page background gradient.
BoxDecoration getBackgroundDecoration() {
  if (_isDarkNow()) {
    return const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft, end: Alignment.bottomRight,
        colors: [AppRawColors.darkBg, Color(0xFF0E1118), Color(0xFF0B0F18)],
      ),
    );
  }
  return const BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft, end: Alignment.bottomRight,
      colors: [AppRawColors.lightBg, AppRawColors.lightSurfaceRaised],
    ),
  );
}

/// AppBar / sidebar decoration.
BoxDecoration getAppBarDecoration() {
  final bool dark = _isDarkNow();
  return BoxDecoration(
    color: dark ? AppRawColors.darkBg : AppRawColors.lightSurface,
    border: Border(bottom: BorderSide(color: dark ? AppRawColors.darkBorder : AppRawColors.lightBorder, width: 1)),
  );
}

// ─────────────────────────────────────────────────────────────
//  BUTTON STYLE HELPERS
// ─────────────────────────────────────────────────────────────

const _btnShape8 = RoundedRectangleBorder(
  borderRadius: BorderRadius.all(Radius.circular(AppDimens.radiusMd)),
);
const _btnPad = EdgeInsets.symmetric(horizontal: AppDimens.btnPaddingH, vertical: AppDimens.btnPaddingV);
const _btnText = TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: AppDimens.fontMd);

ButtonStyle buttonStyle() => ElevatedButton.styleFrom(
  backgroundColor: AppTokens.accentReadable, foregroundColor: Colors.black,
  elevation: 0, shape: _btnShape8, padding: _btnPad, textStyle: _btnText,
);

ButtonStyle negativeButtonStyle() => ElevatedButton.styleFrom(
  backgroundColor: AppRawColors.red, foregroundColor: Colors.white,
  elevation: 0, shape: _btnShape8, padding: _btnPad, textStyle: _btnText,
);

ButtonStyle positiveButtonStyle() => ElevatedButton.styleFrom(
  backgroundColor: AppRawColors.neonGreen, foregroundColor: Colors.black,
  elevation: 0, shape: _btnShape8, padding: _btnPad, textStyle: _btnText,
);

ButtonStyle warningButtonStyle() => ElevatedButton.styleFrom(
  backgroundColor: AppRawColors.orange, foregroundColor: Colors.white,
  elevation: 0, shape: _btnShape8, padding: _btnPad, textStyle: _btnText,
);

ButtonStyle collectButtonStyle() => ElevatedButton.styleFrom(
  backgroundColor: AppRawColors.teal, foregroundColor: Colors.white,
  elevation: 0, shape: _btnShape8, padding: _btnPad, textStyle: _btnText,
);

// ─────────────────────────────────────────────────────────────
//  BACKWARDS-COMPATIBLE APPCOLORS ALIAS  (legacy code still compiles)
// ─────────────────────────────────────────────────────────────

/// @deprecated  Use AppTokens / AppRawColors instead.
class AppColors {
  AppColors._();
  static const Color primary                = AppRawColors.cyan;
  static const Color primaryVariant         = AppRawColors.cyanDark;
  static const Color accentGreen            = AppRawColors.neonGreen;
  static const Color accentPurple           = AppRawColors.violet;
  static const Color warning                = AppRawColors.amber;
  static const Color error                  = AppRawColors.red;
  static const Color darkBg                 = AppRawColors.darkBg;
  static const Color darkSurface            = AppRawColors.darkSurface;
  static const Color darkSurfaceRaised      = AppRawColors.darkSurfaceRaised;
  static const Color darkBorder             = AppRawColors.darkBorder;
  static const Color darkBorderBright       = AppRawColors.darkBorderFocus;
  static const Color darkTextPrimary        = AppRawColors.darkTextPrimary;
  static const Color darkTextSecondary      = AppRawColors.darkTextSecondary;
  static const Color darkTextDisabled       = AppRawColors.darkTextDisabled;
  static const Color darkTextOnAccent       = AppRawColors.darkOnAccent;
  static const Color lightBg                = AppRawColors.lightBg;
  static const Color lightSurface           = AppRawColors.lightSurface;
  static const Color lightSurfaceRaised     = AppRawColors.lightSurfaceRaised;
  static const Color lightBorder            = AppRawColors.lightBorder;
  static const Color lightBorderBright      = AppRawColors.lightBorderFocus;
  static const Color lightTextPrimary       = AppRawColors.lightTextPrimary;
  static const Color lightTextSecondary     = AppRawColors.lightTextSecondary;
  static const Color lightTextDisabled      = AppRawColors.lightTextDisabled;
  static const Color lightTextOnAccent      = AppRawColors.lightOnAccent;
  static const Color lightPrimary           = AppRawColors.darkSurface;
  static const Color darkPrimary            = AppRawColors.cyanDark;
  static const Color textIcons              = AppRawColors.darkTextPrimary;
  static const Color textIconsReverse       = Color(0xFFFFFFFF);
  static const Color accent                 = AppRawColors.cyan;
  static const Color primaryText            = AppRawColors.darkTextPrimary;
  static const Color secondaryText          = AppRawColors.darkTextSecondary;
  static const Color divider                = AppRawColors.darkBorder;
  static const Color blackBorder            = AppRawColors.darkBorder;
  static const Color container              = AppRawColors.darkSurface;
  static const Color appBarBackground       = AppRawColors.darkSurface;
  static const Color appBarBackgroundDarker = AppRawColors.darkBg;
  static const Color appBarText             = AppRawColors.darkTextPrimary;
  static const Color backgroundGradient1    = AppRawColors.darkBg;
  static const Color backgroundGradient2    = Color(0xFF0F1219);
  static const Color backgroundGradient3    = Color(0xFF131820);
}

// ─────────────────────────────────────────────────────────────
//  THEME FACTORIES
// ─────────────────────────────────────────────────────────────

ThemeData getAppTheme()      => _build(isDark: true);
ThemeData getAppLightTheme() => _build(isDark: false);

ThemeData _build({required bool isDark}) {
  final Color bg            = isDark ? AppRawColors.darkBg            : AppRawColors.lightBg;
  final Color surface       = isDark ? AppRawColors.darkSurface       : AppRawColors.lightSurface;
  final Color surfaceRaised = isDark ? AppRawColors.darkSurfaceRaised : AppRawColors.lightSurfaceRaised;
  final Color border        = isDark ? AppRawColors.darkBorder        : AppRawColors.lightBorder;
  final Color textPrimary   = isDark ? AppRawColors.darkTextPrimary   : AppRawColors.lightTextPrimary;
  final Color textSecondary = isDark ? AppRawColors.darkTextSecondary : AppRawColors.lightTextSecondary;
  final Color textDisabled  = isDark ? AppRawColors.darkTextDisabled  : AppRawColors.lightTextDisabled;
  final Color onAccent      = isDark ? AppRawColors.darkOnAccent      : AppRawColors.lightOnAccent;

  TextStyle ts(Color c, {FontWeight fw = FontWeight.normal, double? sz}) =>
      TextStyle(fontFamily: 'Inter', color: c, fontWeight: fw, fontSize: sz);

  final tt = TextTheme(
    displayLarge:  ts(textPrimary, fw: FontWeight.w700),
    displayMedium: ts(textPrimary, fw: FontWeight.w700),
    displaySmall:  ts(textPrimary, fw: FontWeight.w600),
    headlineLarge: ts(textPrimary, fw: FontWeight.w600),
    headlineMedium:ts(textPrimary, fw: FontWeight.w600),
    headlineSmall: ts(textPrimary, fw: FontWeight.w600),
    titleLarge:    ts(textPrimary, fw: FontWeight.w600),
    titleMedium:   ts(textSecondary, fw: FontWeight.w500),
    titleSmall:    ts(textSecondary, fw: FontWeight.w500),
    labelLarge:    ts(textPrimary, fw: FontWeight.w500),
    labelMedium:   ts(textSecondary),
    labelSmall:    ts(textSecondary, sz: 11),
    bodyLarge:     ts(textPrimary),
    bodyMedium:    ts(textPrimary),
    bodySmall:     ts(textSecondary, sz: 12),
  );

  final cs = ColorScheme(
    brightness:              isDark ? Brightness.dark : Brightness.light,
    primary:                 AppRawColors.cyan,
    onPrimary:               onAccent,
    primaryContainer:        AppRawColors.cyan.withOpacity(0.15),
    onPrimaryContainer:      AppRawColors.cyan,
    secondary:               AppRawColors.violet,
    onSecondary:             Colors.white,
    secondaryContainer:      AppRawColors.violet.withOpacity(0.15),
    onSecondaryContainer:    AppRawColors.violet,
    tertiary:                AppRawColors.neonGreen,
    onTertiary:              Colors.black,
    error:                   AppRawColors.red,
    onError:                 Colors.white,
    surface:                 surface,
    onSurface:               textPrimary,
    surfaceContainerHighest: surfaceRaised,
    outline:                 border,
    outlineVariant:          border.withOpacity(0.5),
    shadow:                  Colors.black.withOpacity(isDark ? 0.5 : 0.1),
    inverseSurface:          isDark ? AppRawColors.lightSurface : AppRawColors.darkSurface,
    onInverseSurface:        isDark ? AppRawColors.lightTextPrimary : AppRawColors.darkTextPrimary,
    inversePrimary:          AppRawColors.cyanDark,
  );

  return ThemeData(
    useMaterial3:            true,
    brightness:              isDark ? Brightness.dark : Brightness.light,
    fontFamily:              'Inter',
    colorScheme:             cs,
    scaffoldBackgroundColor: bg,
    textTheme:               tt,
    primaryTextTheme:        tt,

    appBarTheme: AppBarTheme(
      backgroundColor:        isDark ? AppRawColors.darkBg : AppRawColors.lightSurface,
      surfaceTintColor:       Colors.transparent,
      elevation:              0,
      scrolledUnderElevation: 1,
      shadowColor:            Colors.black.withOpacity(0.4),
      iconTheme:              const IconThemeData(color: AppRawColors.cyan),
      titleTextStyle:         ts(textPrimary, fw: FontWeight.w600, sz: 17),
    ),

    cardTheme: CardThemeData(
      color:            surface,
      surfaceTintColor: Colors.transparent,
      elevation:        0,
      margin:           const EdgeInsets.symmetric(horizontal: AppDimens.cardMarginH, vertical: AppDimens.cardMarginV),
      shape:            RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        side: BorderSide(color: border, width: 1),
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled:           true,
      fillColor:        isDark ? AppRawColors.darkFormField : AppRawColors.lightSurface,
      hintStyle:        ts(textDisabled),
      labelStyle:       ts(textSecondary),
      floatingLabelStyle: TextStyle(
        fontFamily: 'Inter',
        color: isDark ? AppRawColors.cyan : AppRawColors.cyanLight,
      ),
      contentPadding:   const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      border:            OutlineInputBorder(borderRadius: BorderRadius.circular(AppDimens.radiusMd), borderSide: BorderSide(color: border)),
      enabledBorder:     OutlineInputBorder(borderRadius: BorderRadius.circular(AppDimens.radiusMd), borderSide: BorderSide(color: border)),
      focusedBorder:     OutlineInputBorder(borderRadius: BorderRadius.circular(AppDimens.radiusMd), borderSide: BorderSide(color: isDark ? AppRawColors.cyan : AppRawColors.cyanLight, width: 2)),
      errorBorder:       OutlineInputBorder(borderRadius: BorderRadius.circular(AppDimens.radiusMd), borderSide: const BorderSide(color: AppRawColors.red, width: 1.5)),
      focusedErrorBorder:OutlineInputBorder(borderRadius: BorderRadius.circular(AppDimens.radiusMd), borderSide: const BorderSide(color: AppRawColors.red, width: 2)),
      disabledBorder:    OutlineInputBorder(borderRadius: BorderRadius.circular(AppDimens.radiusMd), borderSide: BorderSide(color: textDisabled.withOpacity(0.3))),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: isDark ? AppRawColors.cyan : AppRawColors.cyanLight,
        foregroundColor: onAccent,
        elevation: 0, shadowColor: Colors.transparent,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(AppDimens.radiusMd))),
        textStyle: ts(onAccent, fw: FontWeight.w600),
        padding: _btnPad,
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: isDark ? AppRawColors.cyan : AppRawColors.cyanLight,
        side: BorderSide(color: isDark ? AppRawColors.cyan : AppRawColors.cyanLight, width: 1.5),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(AppDimens.radiusMd))),
        textStyle: ts(isDark ? AppRawColors.cyan : AppRawColors.cyanLight, fw: FontWeight.w500),
        padding: _btnPad,
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: isDark ? AppRawColors.cyan : AppRawColors.cyanLight,
        textStyle: ts(isDark ? AppRawColors.cyan : AppRawColors.cyanLight, fw: FontWeight.w500),
      ),
    ),

    iconTheme:   IconThemeData(color: textSecondary, size: AppDimens.iconLg),
    dividerTheme: DividerThemeData(color: border, thickness: 1, space: 1),

    listTileTheme: ListTileThemeData(
      tileColor: Colors.transparent, textColor: textPrimary,
      iconColor: isDark ? AppRawColors.cyan : AppRawColors.cyanLight,
      selectedTileColor: (isDark ? AppRawColors.cyan : AppRawColors.cyanLight).withOpacity(0.10),
      selectedColor: isDark ? AppRawColors.cyan : AppRawColors.cyanLight, dense: true,
    ),

    drawerTheme: DrawerThemeData(
      backgroundColor: isDark ? AppRawColors.darkBg : AppRawColors.lightSurface,
      surfaceTintColor: Colors.transparent,
      scrimColor: Colors.black.withOpacity(0.55),
    ),

    dialogTheme: DialogThemeData(
      backgroundColor:  surface,
      surfaceTintColor: Colors.transparent,
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimens.radiusLg),
        side: BorderSide(color: border),
      ),
      titleTextStyle:   ts(textPrimary,   fw: FontWeight.w600, sz: 17),
      contentTextStyle: ts(textSecondary, sz: 14),
    ),

    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: surfaceRaised,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(14))),
    ),

    snackBarTheme: SnackBarThemeData(
      backgroundColor:  surfaceRaised,
      contentTextStyle: ts(textPrimary),
      actionTextColor:  AppRawColors.cyan,
      behavior:         SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        side: BorderSide(color: border),
      ),
    ),

    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: surfaceRaised,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: border),
      ),
      textStyle: ts(textPrimary, sz: 12),
    ),

    tabBarTheme: TabBarThemeData(
      labelColor:           isDark ? AppRawColors.cyan : AppRawColors.cyanLight,
      unselectedLabelColor: textSecondary,
      indicatorColor:       isDark ? AppRawColors.cyan : AppRawColors.cyanLight,
      indicatorSize:        TabBarIndicatorSize.label,
      labelStyle:           ts(isDark ? AppRawColors.cyan : AppRawColors.cyanLight, fw: FontWeight.w600),
      unselectedLabelStyle: ts(textSecondary),
    ),

    chipTheme: ChipThemeData(
      backgroundColor:     surfaceRaised,
      selectedColor:       AppRawColors.cyan.withOpacity(0.20),
      labelStyle:          ts(textPrimary, sz: 12),
      secondaryLabelStyle: ts(AppRawColors.cyan, sz: 12),
      side: BorderSide(color: border),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    ),

    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((s) =>
      s.contains(WidgetState.selected)
          ? (isDark ? AppRawColors.cyan : AppRawColors.cyanLight)
          : textDisabled),
      trackColor: WidgetStateProperty.resolveWith((s) =>
      s.contains(WidgetState.selected)
          ? (isDark ? AppRawColors.cyan : AppRawColors.cyanLight).withOpacity(0.35)
          : border),
    ),

    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((s) =>
      s.contains(WidgetState.selected)
          ? (isDark ? AppRawColors.cyan : AppRawColors.cyanLight)
          : Colors.transparent),
      checkColor: WidgetStateProperty.all(Colors.black),
      side: WidgetStateBorderSide.resolveWith((s) =>
          BorderSide(color: s.contains(WidgetState.selected)
              ? (isDark ? AppRawColors.cyan : AppRawColors.cyanLight)
              : border, width: 1.5)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
    ),

    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith((s) =>
      s.contains(WidgetState.selected)
          ? (isDark ? AppRawColors.cyan : AppRawColors.cyanLight)
          : textDisabled),
    ),

    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppRawColors.cyan,
      linearTrackColor: AppRawColors.darkBorder,
    ),

    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: isDark ? AppRawColors.cyan : AppRawColors.cyanLight,
      foregroundColor: onAccent,
      elevation: 2,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(AppDimens.radiusMd))),
    ),

    dataTableTheme: DataTableThemeData(
      headingRowColor:  WidgetStateProperty.all((isDark ? AppRawColors.cyan : AppRawColors.cyanLight).withOpacity(0.08)),
      headingTextStyle: ts(isDark ? AppRawColors.cyan : AppRawColors.cyanLight, fw: FontWeight.w600, sz: 13),
      dataRowColor:     WidgetStateProperty.resolveWith((s) =>
      s.contains(WidgetState.selected)
          ? (isDark ? AppRawColors.cyan : AppRawColors.cyanLight).withOpacity(0.08)
          : Colors.transparent),
      dataTextStyle:    ts(textPrimary, sz: 13),
      dividerThickness: 1,
    ),

    expansionTileTheme: ExpansionTileThemeData(
      iconColor:                isDark ? AppRawColors.cyan : AppRawColors.cyanLight,
      collapsedIconColor:       textSecondary,
      textColor:                isDark ? AppRawColors.cyan : AppRawColors.cyanLight,
      collapsedTextColor:       textPrimary,
      backgroundColor:          Colors.transparent,
      collapsedBackgroundColor: Colors.transparent,
    ),
  );
}