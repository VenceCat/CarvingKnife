import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'app_tokens.dart';
import 'app_visuals.dart';

class AppWallpaperBackground extends StatelessWidget {
  final Widget child;
  final AppVisuals visuals;
  final double overlayOpacity;

  const AppWallpaperBackground({
    super.key,
    required this.child,
    required this.visuals,
    this.overlayOpacity = 0.03,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        if (visuals.useWallpaper && visuals.wallpaperDecoration != null)
          Positioned.fill(
            child: Container(decoration: visuals.wallpaperDecoration),
          ),
        if (visuals.useWallpaper)
          Positioned.fill(
            child: Container(
              color: Colors.black.withValues(alpha: overlayOpacity),
            ),
          ),
        if (!visuals.useWallpaper && visuals.useGlassEffect)
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFEAF2FF),
                    Color(0xFFF8FBFF),
                    Color(0xFFF2FAF7),
                  ],
                ),
              ),
            ),
          ),
        child,
      ],
    );
  }
}

class AppGlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double radius;
  final Color? borderColor;
  final bool isSelected;
  final Color? selectedColor;

  const AppGlassCard({
    super.key,
    required this.child,
    this.padding,
    this.radius = AppRadii.lg,
    this.borderColor,
    this.isSelected = false,
    this.selectedColor,
  });

  @override
  Widget build(BuildContext context) {
    final visuals = AppVisuals.resolve(context);
    final decoration = AppSurfaceDecoration.card(
      context,
      radius: radius,
      borderColor: borderColor,
      isSelected: isSelected,
      selectedColor: selectedColor,
    );

    final card = AnimatedContainer(
      duration: AppMotion.quick,
      padding: padding,
      decoration: decoration,
      child: child,
    );

    if (!visuals.useGlassEffect) return card;

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: card,
      ),
    );
  }
}

class AppFloatingAddButton extends StatelessWidget {
  final VoidCallback onTap;
  final Color themeColor;
  final bool useWallpaper;
  final bool useGlassEffect;
  final double size;

  const AppFloatingAddButton({
    super.key,
    required this.onTap,
    required this.themeColor,
    required this.useWallpaper,
    required this.useGlassEffect,
    this.size = 58,
  });

  @override
  Widget build(BuildContext context) {
    final backgroundColor = useGlassEffect
        ? Colors.white.withValues(alpha: useWallpaper ? 0.34 : 0.76)
        : (useWallpaper ? Colors.white.withValues(alpha: 0.92) : themeColor);
    final borderColor = useGlassEffect
        ? themeColor.withValues(alpha: useWallpaper ? 0.22 : 0.16)
        : (useWallpaper
            ? Colors.white.withValues(alpha: 0.58)
            : themeColor.withValues(alpha: 0.2));
    final iconColor = useGlassEffect
        ? themeColor
        : useWallpaper
            ? themeColor
            : Colors.white;

    final buttonCore = Material(
      color: backgroundColor,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(
                  alpha: useGlassEffect
                      ? (useWallpaper ? 0.12 : 0.08)
                      : (useWallpaper ? 0.12 : 0.2),
                ),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Icon(Icons.add_rounded, size: 30, color: iconColor),
        ),
      ),
    );

    if (!useGlassEffect) {
      return SizedBox(
        width: size,
        height: size,
        child: ClipOval(child: buttonCore),
      );
    }

    return SizedBox(
      width: size,
      height: size,
      child: ClipOval(
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 9, sigmaY: 9),
          child: buttonCore,
        ),
      ),
    );
  }
}

class AppSurfaceDecoration {
  static BoxDecoration card(
    BuildContext context, {
    double radius = AppRadii.lg,
    Color? borderColor,
    bool isSelected = false,
    Color? selectedColor,
  }) {
    final visuals = AppVisuals.resolve(context);
    return BoxDecoration(
      color: visuals.cardColor,
      borderRadius: BorderRadius.circular(radius),
      border: borderColor != null
          ? Border.all(
              color: borderColor,
              width: isSelected ? 2 : 1,
            )
          : null,
      boxShadow: [
        BoxShadow(
          color: isSelected && selectedColor != null
              ? selectedColor.withValues(alpha: 0.2)
              : Colors.black.withValues(alpha: visuals.useWallpaper ? 0.08 : 0.05),
          blurRadius: isSelected ? 8 : 10,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  static BoxDecoration bottomBar(BuildContext context) {
    final visuals = AppVisuals.resolve(context);
    return BoxDecoration(
      color: visuals.useGlassEffect
          ? Colors.white.withValues(alpha: visuals.useWallpaper ? 0.32 : 0.7)
          : visuals.useWallpaper
              ? Colors.white.withValues(alpha: 0.92)
              : Colors.white,
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(
            alpha: visuals.useGlassEffect
                ? (visuals.useWallpaper ? 0.12 : 0.06)
                : (visuals.useWallpaper ? 0.1 : 0.04),
          ),
          blurRadius: 10,
          offset: const Offset(0, -2),
        ),
      ],
    );
  }
}

class AppPageTitleBar extends StatelessWidget {
  final String title;
  final AppVisuals visuals;
  final double left;
  final double right;
  final double bottom;
  final Widget? leading;
  final Widget? trailing;

  const AppPageTitleBar({
    super.key,
    required this.title,
    required this.visuals,
    this.left = AppSpacing.xl,
    this.right = AppSpacing.xl,
    this.bottom = AppSpacing.lg,
    this.leading,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final bar = Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top,
        bottom: bottom,
        left: left,
        right: right,
      ),
      decoration: BoxDecoration(
        gradient: visuals.useWallpaper
            ? LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.28),
                  Colors.transparent,
                ],
              )
            : null,
        color: visuals.useGlassEffect
            ? Colors.white.withValues(alpha: visuals.useWallpaper ? 0.16 : 0.62)
            : visuals.useWallpaper
                ? Colors.transparent
                : visuals.pageBackgroundColor,
      ),
      child: Row(
        children: [
          if (leading != null) ...[
            leading!,
            const SizedBox(width: AppSpacing.md),
          ],
          Expanded(
            child: Text(
              title,
              style: AppTypography.pageTitle.copyWith(
                color: visuals.titleColor,
                shadows: visuals.titleShadows,
              ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );

    if (!visuals.useGlassEffect) return bar;

    return ClipRect(
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: bar,
      ),
    );
  }
}

class AppBottomSheetSurface extends StatelessWidget {
  final Widget child;
  final BorderRadius borderRadius;
  final BoxConstraints? constraints;

  const AppBottomSheetSurface({
    super.key,
    required this.child,
    this.borderRadius = const BorderRadius.vertical(top: Radius.circular(20)),
    this.constraints,
  });

  @override
  Widget build(BuildContext context) {
    final visuals = AppVisuals.resolve(context);
    final container = Container(
      constraints: constraints,
      decoration: BoxDecoration(
        color: visuals.useGlassEffect
            ? Colors.white.withValues(alpha: visuals.useWallpaper ? 0.36 : 0.86)
            : Colors.white,
        borderRadius: borderRadius,
      ),
      child: child,
    );

    if (!visuals.useGlassEffect) return container;

    return ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 9, sigmaY: 9),
        child: container,
      ),
    );
  }
}

class AppDialogSurface extends StatelessWidget {
  final Widget child;
  final double radius;
  final EdgeInsetsGeometry? padding;

  const AppDialogSurface({
    super.key,
    required this.child,
    this.radius = 20,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final visuals = AppVisuals.resolve(context);
    final content = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: visuals.useGlassEffect
            ? Colors.white.withValues(alpha: visuals.useWallpaper ? 0.38 : 0.9)
            : Colors.white,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: child,
    );

    if (!visuals.useGlassEffect) return content;

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: content,
      ),
    );
  }
}
