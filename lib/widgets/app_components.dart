// ============================================================
//  lib/widgets/app_components.dart
//
//  SINGLE SOURCE OF TRUTH for all generic UI building blocks.
//  Import this file (and only this file) in widgets / screens.
//  Every component reads its colours from AppTokens so dark ↔
//  light switching works automatically everywhere.
//
//  INDEX
//  ──────────────────────────────────────────────────────────
//  PRIMITIVES
//    AppCard              themed card container
//    AppInfoRow           "Label: Value" text row
//    AppStatusBadge       active/inactive/custom badge pill
//    AppTagBadge          coloured small tag (post type etc.)
//    AppSectionHeader     "| ÖZELLİKLER" heading
//    AppDivider           themed Divider
//    AppImageThumb        90×90 rounded image / placeholder
//    AppCorrectionNote    warning note box (attendance logs)
//    AppTimeBox           check-in/out time display box
//    AppMetricChip        "Icon  Label: value" metric chip
//    AppAlertBox          system alert / warning strip
//
//  SCREEN CHROME
//    AppScreenScaffold    Scaffold + AppBar + themed bg
//    AppPageTitle         AppBar title widget
//
//  BUTTONS
//    AppPrimaryButton     cyan (+ Yeni, save, etc.)
//    AppSecondaryButton   outlined cyan (cancel, etc.)
//    AppDangerButton      red (delete)
//    AppWarningButton     orange (terminate, etc.)
//    AppSuccessButton     neon-green
//    AppCollectButton     teal (collect device data)
//    AppNewButton         full-width "+ Yeni" list header
//    AppIconAction        compact icon-only action button
//
//  NAVIGATION
//    AppNavButton         100-px grid navigation tile
//
//  FORM
//    AppFormCard          themed form container
//
//  FEEDBACK
//    AppLoader            centred cyan progress indicator
//    AppEmptyState        empty list placeholder
// ============================================================

import 'dart:ui';
import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import 'animations/digital_fade_in.dart';

// ═══════════════════════════════════════════════════════════
//  PRIMITIVES
// ═══════════════════════════════════════════════════════════

// ─────────────────────────────────────────────────────────
//  AppCard
//  Replaces every:
//    Container(decoration: BoxDecoration(
//      color:        AppTokens.cardBg, ...))
//  and:
//    Card(color: Colors.white.withOpacity(0.8), ...)
// ─────────────────────────────────────────────────────────

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  /// Optional left-accent stripe colour (for ManagementCard style)
  final Color? accentBorderColor;
  /// Override card background (e.g. transparent for glassmorphic cards)
  final Color? backgroundColor;
  final VoidCallback? onTap;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.width,
    this.accentBorderColor,
    this.backgroundColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color bg = backgroundColor ?? AppTokens.cardBg;

    // Base rounded box — always uniform border so borderRadius is legal.
    final EdgeInsetsGeometry effectiveMargin = margin ?? const EdgeInsets.symmetric(
      horizontal: AppDimens.cardMarginH,
      vertical:   AppDimens.cardMarginV,
    );
    final EdgeInsetsGeometry effectivePadding = padding ?? const EdgeInsets.all(AppDimens.cardPadding);

    Widget card = Container(
      width: width,
      margin: effectiveMargin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        color:  bg,
        // ✅ cardBorder: subtle cyan glow in dark, neutral in light
        border: Border.all(color: AppTokens.cardBorder, width: 1),
      ),
      child: accentBorderColor != null
      // ✅ Stack-based left accent stripe — avoids non-uniform border crash
          ? ClipRRect(
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        child: Stack(
          children: [
            Positioned(
              left: 0, top: 0, bottom: 0,
              child: Container(width: 3, color: accentBorderColor),
            ),
            Padding(
              padding: effectivePadding.add(const EdgeInsets.only(left: 3)),
              child: child,
            ),
          ],
        ),
      )
          : Padding(padding: effectivePadding, child: child),
    );

    if (onTap != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        child: InkWell(onTap: onTap, child: card),
      );
    }
    return card;
  }
}

// ─────────────────────────────────────────────────────────
//  AppInfoRow
//  Replaces every _buildInfoRow() method in every card.
// ─────────────────────────────────────────────────────────

class AppInfoRow extends StatelessWidget {
  final String label;
  final String? value;
  /// Override value text colour (e.g. for status colours)
  final Color? valueColor;

  const AppInfoRow({
    super.key,
    required this.label,
    this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final String display = (value != null && value!.isNotEmpty) ? value! : '—';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(text: '$label: ', style: AppTextStyles.labelKey),
            TextSpan(
              text: display,
              style: AppTextStyles.labelValue.copyWith(
                color: valueColor ?? AppTokens.textPrimary,
              ),
            ),
          ],
        ),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
//  AppStatusBadge
//  Active/inactive pill. Used in device cards, employee cards.
// ─────────────────────────────────────────────────────────

class AppStatusBadge extends StatelessWidget {
  final String label;
  final bool isPositive;

  const AppStatusBadge({
    super.key,
    required this.label,
    required this.isPositive,
  });

  factory AppStatusBadge.active()   => const AppStatusBadge(label: 'Bağlı / Aktif', isPositive: true);
  factory AppStatusBadge.inactive() => const AppStatusBadge(label: 'Pasif', isPositive: false);
  factory AppStatusBadge.online()   => const AppStatusBadge(label: 'Online', isPositive: true);
  factory AppStatusBadge.offline()  => const AppStatusBadge(label: 'Offline', isPositive: false);

  @override
  Widget build(BuildContext context) {
    final Color bg  = isPositive ? AppTokens.statusActiveBg  : AppTokens.statusInactiveBg;
    final Color fg  = isPositive ? AppTokens.statusActiveFg  : AppTokens.statusInactiveFg;
    final Color brd = isPositive ? AppTokens.statusActiveBrd : AppRawColors.red;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color:        bg,
        border:       Border.all(color: brd, width: 1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label, style: TextStyle(
        fontFamily: 'Inter', fontSize: AppDimens.fontSm,
        fontWeight: FontWeight.w700, color: fg, letterSpacing: 0.2,
      )),
    );
  }
}

// ─────────────────────────────────────────────────────────
//  AppTagBadge
//  Small coloured tag pill (published/draft, category, date …)
//  Replaces every _buildBadge() in post_card, siteconfig_card etc.
// ─────────────────────────────────────────────────────────

class AppTagBadge extends StatelessWidget {
  final String text;
  final Color color;

  const AppTagBadge({super.key, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color:        color.withOpacity(0.12),
        border:       Border.all(color: color.withOpacity(0.45)),
        borderRadius: BorderRadius.circular(AppDimens.radiusXs),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: 'Inter', fontSize: AppDimens.fontSm,
          fontWeight: FontWeight.w600, color: color,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
//  AppSectionHeader
//  "| ÖZELLİKLER" heading from the website screenshot.
// ─────────────────────────────────────────────────────────

class AppSectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;

  const AppSectionHeader({super.key, required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return DigitalFadeIn(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: AppDimens.spacingMd,
          horizontal: AppDimens.spacingMd,
        ),
        child: Row(
          children: [
            Container(
              width: 3, height: 22,
              decoration: BoxDecoration(
                color: AppRawColors.cyan,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title.toUpperCase(), style: AppTextStyles.sectionHeading),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle!, style: AppTextStyles.bodySm),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
//  AppDivider
// ─────────────────────────────────────────────────────────

class AppDivider extends StatelessWidget {
  final double height;
  const AppDivider({super.key, this.height = 20});

  @override
  Widget build(BuildContext context) =>
      Divider(height: height, color: AppTokens.border, thickness: 1);
}

// ─────────────────────────────────────────────────────────
//  AppImageThumb
//  90×90 rounded image tile with placeholder & error state.
//  Replaces the ClipRRect + Container(color: Colors.grey[200])
//  pattern used in post_card, siteconfig_card, siteparameter_card,
//  sitecategory_card.
// ─────────────────────────────────────────────────────────

// lib/widgets/app_components.dart (veya ilgili dosya)

class AppImageThumb extends StatelessWidget {
  final String? imageUrl;
  final double size;
  final Widget Function(BuildContext, String)? placeholder;

  const AppImageThumb({
    super.key,
    this.imageUrl,
    this.size = 90,
    this.placeholder,
  });

  @override
  Widget build(BuildContext context) {
    final Color imgBg = AppTokens.isDark
        ? AppRawColors.darkSurfaceRaised
        : const Color(0xFFE5EAF0);
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppDimens.radiusMd),
      child: Container(
        width: size,
        height: size,
        color: imgBg,
        child:  Icon(
            Icons.image_outlined,
            color: AppTokens.textDisabled,
            size: 28
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
//  AppCorrectionNote
//  Attendance log correction note box.
// ─────────────────────────────────────────────────────────

class AppCorrectionNote extends StatelessWidget {
  final String note;
  const AppCorrectionNote({super.key, required this.note});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color:        AppRawColors.amber.withOpacity(0.10),
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        border:       Border.all(color: AppRawColors.amber.withOpacity(0.40)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Düzeltme Notu:',
              style: AppTextStyles.bodySm.copyWith(
                  fontWeight: FontWeight.w700, color: AppRawColors.amber)),
          const SizedBox(height: 2),
          Text(note,
              style: AppTextStyles.bodySm.copyWith(fontStyle: FontStyle.italic)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
//  AppTimeBox
//  Check-in / check-out time display box (attendance summary).
// ─────────────────────────────────────────────────────────

class AppTimeBox extends StatelessWidget {
  final String label;
  final String time;
  final IconData icon;
  final Color color;

  const AppTimeBox({
    super.key,
    required this.label,
    required this.time,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color:        color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        border:       Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(
        children: [
          Text(label, style: TextStyle(
            fontFamily: 'Inter', fontSize: AppDimens.fontSm,
            color: color, fontWeight: FontWeight.w700,
          )),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: AppDimens.iconSm, color: color),
              const SizedBox(width: 6),
              Text(time, style: AppTextStyles.cardTitle.copyWith(fontSize: AppDimens.fontMd)),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
//  AppMetricChip
//  "Icon  Label: value" inline metric.
// ─────────────────────────────────────────────────────────

class AppMetricChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? color;

  const AppMetricChip({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final Color fg = color ?? AppTokens.textSecondary;
    return SizedBox(
      width: 140,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: AppDimens.iconXs, color: fg),
          const SizedBox(width: 5),
          Expanded(
            child: Text.rich(
              TextSpan(children: [
                TextSpan(text: '$label: ', style: AppTextStyles.caption.copyWith(color: AppTokens.textSecondary)),
                TextSpan(text: value, style: AppTextStyles.caption.copyWith(
                  fontWeight: FontWeight.w700, color: fg,
                )),
              ]),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
//  AppAlertBox
//  System warning strip (attendance incomplete punches etc.)
// ─────────────────────────────────────────────────────────

class AppAlertBox extends StatelessWidget {
  final String message;
  final Color? color;

  const AppAlertBox({super.key, required this.message, this.color});

  @override
  Widget build(BuildContext context) {
    final Color c = color ?? AppRawColors.orange;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color:        c.withOpacity(AppTokens.isDark ? 0.10 : 0.06),
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        border:       Border.all(color: c.withOpacity(0.35)),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: c, size: AppDimens.iconMd),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message, style: AppTextStyles.bodySm.copyWith(
              color: AppTokens.isDark ? c : c.withOpacity(0.85),
              fontStyle: FontStyle.italic,
            )),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  SCREEN CHROME
// ═══════════════════════════════════════════════════════════

// ─────────────────────────────────────────────────────────
//  AppPageTitle  (goes inside AppBar title: slot)
// ─────────────────────────────────────────────────────────

class AppPageTitle extends StatelessWidget {
  final String title;

  const AppPageTitle({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: getAppBarDecoration(),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.spacingMd,
        vertical:   AppDimens.spacingMd,
      ),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          color: AppTokens.textPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
//  AppScreenScaffold
//  Replaces the repetitive Scaffold + AppBar boilerplate in
//  every screen (corporation_screen, user_screen, etc.)
// ─────────────────────────────────────────────────────────

class AppScreenScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final List<Widget>? actions;

  const AppScreenScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final double w = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: AppTokens.pageBg,
      appBar: AppBar(
        actions: actions,
        leading: w < 800
            ? IconButton(
          icon: Icon(Icons.menu, color: AppTokens.textPrimary),
          onPressed: () => Scaffold.of(context).openDrawer(),
        )
            : null,
        automaticallyImplyLeading: false,
        backgroundColor:        Colors.transparent,
        surfaceTintColor:       Colors.transparent,
        scrolledUnderElevation: 0,
        elevation:              0,
        toolbarHeight:          70,
        title: AppPageTitle(title: title),
      ),
      body: Container(
        decoration: getBackgroundDecoration(),
        child: body,
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  BUTTONS
// ═══════════════════════════════════════════════════════════

/// Cyan primary action button.
class AppPrimaryButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool fullWidth;

  const AppPrimaryButton({
    super.key, required this.label,
    this.icon, this.onPressed, this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    final style = buttonStyle().copyWith(
      minimumSize: fullWidth ? const WidgetStatePropertyAll(Size(double.infinity, AppDimens.btnHeight)) : null,
    );
    return icon != null
        ? ElevatedButton.icon(style: style, onPressed: onPressed,
        icon: Icon(icon, size: AppDimens.iconSm), label: Text(label))
        : ElevatedButton(style: style, onPressed: onPressed, child: Text(label));
  }
}

/// Outlined cyan secondary button.
class AppSecondaryButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;

  const AppSecondaryButton({super.key, required this.label, this.icon, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return icon != null
        ? OutlinedButton.icon(onPressed: onPressed,
        icon: Icon(icon, size: AppDimens.iconSm), label: Text(label))
        : OutlinedButton(onPressed: onPressed, child: Text(label));
  }
}

/// Red destructive button.
class AppDangerButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;

  const AppDangerButton({super.key, required this.label, this.icon, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return icon != null
        ? ElevatedButton.icon(style: negativeButtonStyle(), onPressed: onPressed,
        icon: Icon(icon, size: AppDimens.iconSm), label: Text(label))
        : ElevatedButton(style: negativeButtonStyle(), onPressed: onPressed, child: Text(label));
  }
}

/// Orange warning button (terminate, etc.).
class AppWarningButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;

  const AppWarningButton({super.key, required this.label, this.icon, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return icon != null
        ? ElevatedButton.icon(style: warningButtonStyle(), onPressed: onPressed,
        icon: Icon(icon, size: AppDimens.iconSm), label: Text(label))
        : ElevatedButton(style: warningButtonStyle(), onPressed: onPressed, child: Text(label));
  }
}

/// Green success button.
class AppSuccessButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;

  const AppSuccessButton({super.key, required this.label, this.icon, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return icon != null
        ? ElevatedButton.icon(style: positiveButtonStyle(), onPressed: onPressed,
        icon: Icon(icon, size: AppDimens.iconSm), label: Text(label))
        : ElevatedButton(style: positiveButtonStyle(), onPressed: onPressed, child: Text(label));
  }
}

/// Teal collect button (PDKS device data pull).
class AppCollectButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;

  const AppCollectButton({super.key, required this.label, this.icon, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return icon != null
        ? ElevatedButton.icon(style: collectButtonStyle(), onPressed: onPressed,
        icon: Icon(icon, size: AppDimens.iconSm), label: Text(label))
        : ElevatedButton(style: collectButtonStyle(), onPressed: onPressed, child: Text(label));
  }
}

/// Full-width "+ Yeni" list header button.
class AppNewButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String label;

  const AppNewButton({super.key, required this.onPressed, this.label = 'Yeni'});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppDimens.spacingSm),
      child: ElevatedButton.icon(
        style: buttonStyle().copyWith(
          minimumSize: const WidgetStatePropertyAll(Size(double.infinity, AppDimens.btnHeight)),
        ),
        onPressed: onPressed,
        icon: const Icon(Icons.add, size: AppDimens.iconMd),
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: AppDimens.fontLg)),
      ),
    );
  }
}

/// Compact icon-only action button (used in card action columns).
class AppIconAction extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback? onPressed;
  final String? tooltip;

  const AppIconAction({
    super.key,
    required this.icon,
    required this.color,
    this.onPressed,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, color: color, size: AppDimens.iconLg),
      onPressed: onPressed,
      tooltip: tooltip,
      constraints: const BoxConstraints(),
      padding: const EdgeInsets.all(AppDimens.spacingXs),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  NAVIGATION
// ═══════════════════════════════════════════════════════════

/// 100-px navigation grid tile — replaces NavButton.
class AppNavButton extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color? accentColor;
  final VoidCallback onPressed;

  const AppNavButton({
    super.key,
    required this.title,
    required this.icon,
    required this.onPressed,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final Color accent = accentColor ?? AppRawColors.cyan;
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(AppDimens.radiusMd),
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppDimens.radiusMd),
          color:  AppTokens.cardBg,
          border: Border.all(color: accent.withOpacity(0.55), width: 1.5),
        ),
        padding: const EdgeInsets.all(AppDimens.spacingSm),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: AppDimens.iconXl, color: accent),
            const SizedBox(height: 6),
            Text(title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleSmall!.copyWith(
                color:       AppTokens.textPrimary,
                fontWeight:  FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  FORM
// ═══════════════════════════════════════════════════════════

/// Themed form container — replaces the
/// Colors.white.withOpacity(0.7) form container in every screen.
class AppFormCard extends StatelessWidget {
  final Widget child;
  final double? width;

  const AppFormCard({super.key, required this.child, this.width});

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = MediaQuery.of(context).size.width >= 800;

    final container = Container(
      width: width,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppDimens.radiusXxl),
        color: AppTokens.cardBg,
        border: Border.all(color: AppTokens.formBorder, width: 1.5),
      ),
      child: child,
    );

    // MOBİLDE BLUR EFKETİNİ TAMAMEN KALDIRIYORUZ
    // Sadece desktop (isDesktop) ise blur uygulansın diyebiliriz
    // ama mobil performansı için burayı sadeleştirmek en iyisidir.
    if (!isDesktop) {
      return container; // Sadece container dön, blur hesaplama
    }

    // Masaüstünde görsel şölen devam edebilir
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppDimens.radiusXxl),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: container,
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  FEEDBACK
// ═══════════════════════════════════════════════════════════

class AppLoader extends StatelessWidget {
  const AppLoader({super.key});

  @override
  Widget build(BuildContext context) =>
      const Center(child: CircularProgressIndicator(color: AppRawColors.cyan, strokeWidth: 2.5));
}

class AppEmptyState extends StatelessWidget {
  final String message;
  final IconData icon;

  const AppEmptyState({
    super.key,
    this.message = 'Kayıt bulunamadı.',
    this.icon = Icons.inbox_outlined,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 56, color: AppTokens.textDisabled),
          const SizedBox(height: 16),
          Text(message, style: AppTextStyles.bodyMd.copyWith(color: AppTokens.textSecondary)),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  FILTER BAR
//  Replaces every hardcoded white filter container across screens.
// ═══════════════════════════════════════════════════════════

/// Themed container for filter/search bars above list views.
/// Drop your filter Row/Column as [child].
class AppFilterBar extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? margin;

  const AppFilterBar({super.key, required this.child, this.margin});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ?? const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color:        AppTokens.filterBarBg,
        borderRadius: BorderRadius.circular(AppDimens.radiusLg),
        border:       Border.all(color: AppTokens.cardBorder),
      ),
      child: child,
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  QUILL EDITOR WRAPPER
//  Replaces every hardcoded white/grey Quill container.
//  Wrap your QuillSimpleToolbar + QuillEditor here.
// ═══════════════════════════════════════════════════════════

/// Toolbar strip for the Quill editor.
class AppEditorToolbar extends StatelessWidget {
  final Widget child;
  const AppEditorToolbar({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color:  AppTokens.editorToolbarBg,
        border: Border.all(color: AppTokens.editorBorder),
        borderRadius: const BorderRadius.only(
          topLeft:  Radius.circular(AppDimens.radiusMd),
          topRight: Radius.circular(AppDimens.radiusMd),
        ),
      ),
      child: child,
    );
  }
}

/// Editor body for the Quill editor.
/// [height] defaults to 50% of screen height.
class AppEditorBody extends StatelessWidget {
  final Widget child;
  final double? height;

  const AppEditorBody({super.key, required this.child, this.height});

  @override
  Widget build(BuildContext context) {
    final double h = height ?? MediaQuery.of(context).size.height * 0.5;
    return Container(
      height: h,
      decoration: BoxDecoration(
        color:  AppTokens.editorBg,
        border: Border(
          left:   BorderSide(color: AppTokens.editorBorder),
          right:  BorderSide(color: AppTokens.editorBorder),
          bottom: BorderSide(color: AppTokens.editorBorder),
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft:  Radius.circular(AppDimens.radiusMd),
          bottomRight: Radius.circular(AppDimens.radiusMd),
        ),
      ),
      child: child,
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  METRIC CARD  (used in attendance report dashboard)
//  Replaces hardcoded white metric cards.
// ═══════════════════════════════════════════════════════════

class AppMetricCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  final IconData icon;
  final double width;

  const AppMetricCard({
    super.key,
    required this.title,
    required this.value,
    required this.color,
    required this.icon,
    this.width = 160,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(AppDimens.spacingMd),
      decoration: BoxDecoration(
        color:        AppTokens.cardBg,
        borderRadius: BorderRadius.circular(AppDimens.radiusXl),
        border:       Border.all(color: color.withOpacity(0.45), width: 1.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: AppDimens.iconLg),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(
            fontFamily: 'Inter', fontSize: 22,
            fontWeight: FontWeight.w700, color: color,
          )),
          const SizedBox(height: 2),
          Text(title, textAlign: TextAlign.center,
              style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

/// Image picker tap-target used in post / parameter forms.
/// Replaces hardcoded grey.shade100 container.
class AppImagePickerBox extends StatelessWidget {
  final String? imageUrl;
  final VoidCallback? onTap;
  final double height;

  const AppImagePickerBox({
    super.key,
    this.imageUrl,
    this.onTap,
    this.height = 150,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimens.radiusMd),
      child: Container(
        height: height,
        width: double.infinity,
        decoration: BoxDecoration(
          border:       Border.all(color: AppTokens.border),
          borderRadius: BorderRadius.circular(AppDimens.radiusMd),
          color:        AppTokens.raisedBg,
        ),
        child: imageUrl != null && imageUrl!.isNotEmpty
            ? ClipRRect(
          borderRadius: BorderRadius.circular(AppDimens.radiusMd),
          child: Image.network(imageUrl!, fit: BoxFit.contain),
        )
            : Icon(Icons.add_photo_alternate,
            size: 40, color: AppTokens.textDisabled),
      ),
    );
  }
}