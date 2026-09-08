import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Modern floating button component with soft card-based design
/// Supports: Primary, Secondary, Outline, Danger, and Icon variants
class AppButton extends StatelessWidget {
  final String? label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final IconData? suffixIcon;
  final bool isLoading;
  final bool isDisabled;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final double? borderRadius;
  final String? semanticsLabel;

  const AppButton({
    super.key,
    this.label,
    this.onPressed,
    this.icon,
    this.suffixIcon,
    this.isLoading = false,
    this.isDisabled = false,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.large,
    this.width,
    this.height,
    this.padding,
    this.borderRadius,
    this.semanticsLabel,
  });

  /// Primary button - for main actions (Login, Sign Up, Continue, Start)
  const AppButton.primary({
    super.key,
    required String this.label,
    required this.onPressed,
    this.icon,
    this.suffixIcon,
    this.isLoading = false,
    this.width,
    this.height,
    this.size = AppButtonSize.large,
    this.semanticsLabel,
  })  : isDisabled = false,
        variant = AppButtonVariant.primary,
        padding = null,
        borderRadius = null;

  /// Secondary button - for alternative actions (Cancel, Skip, View Details)
  const AppButton.secondary({
    super.key,
    required String this.label,
    required this.onPressed,
    this.icon,
    this.suffixIcon,
    this.isLoading = false,
    this.width,
    this.height,
    this.size = AppButtonSize.large,
    this.semanticsLabel,
  })  : isDisabled = false,
        variant = AppButtonVariant.secondary,
        padding = null,
        borderRadius = null;

  /// Outline button - for less important actions (Learn More, Preview)
  const AppButton.outline({
    super.key,
    required String this.label,
    required this.onPressed,
    this.icon,
    this.suffixIcon,
    this.isLoading = false,
    this.width,
    this.height,
    this.size = AppButtonSize.large,
    this.semanticsLabel,
  })  : isDisabled = false,
        variant = AppButtonVariant.outline,
        padding = null,
        borderRadius = null;

  /// Danger button - for destructive actions (Logout, Delete, Exit)
  const AppButton.danger({
    super.key,
    required String this.label,
    required this.onPressed,
    this.icon,
    this.suffixIcon,
    this.isLoading = false,
    this.width,
    this.height,
    this.size = AppButtonSize.large,
    this.semanticsLabel,
  })  : isDisabled = false,
        variant = AppButtonVariant.danger,
        padding = null,
        borderRadius = null;

  /// Icon button - for small actions (Settings, Notifications, Back)
  const AppButton.icon({
    super.key,
    required IconData this.icon,
    required this.onPressed,
    this.width,
    this.height,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.small,
    this.semanticsLabel,
  })  : label = null,
        suffixIcon = null,
        isLoading = false,
        isDisabled = false,
        padding = null,
        borderRadius = null;

  /// Text button - for inline links (Forgot Password?, Log In)
  const AppButton.text({
    super.key,
    required String this.label,
    required this.onPressed,
    this.icon,
    this.suffixIcon,
    this.size = AppButtonSize.small,
    this.semanticsLabel,
  })  : isLoading = false,
        isDisabled = false,
        variant = AppButtonVariant.text,
        width = null,
        height = null,
        padding = null,
        borderRadius = null;

  @override
  Widget build(BuildContext context) {
    final effectivelyDisabled = isDisabled || onPressed == null;
    // Handle text button variant
    if (variant == AppButtonVariant.text) {
      return TextButton(
        onPressed: effectivelyDisabled ? null : onPressed,
        style: TextButton.styleFrom(
          minimumSize: const Size(48, 48),
          padding: padding ??
              const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius ?? 12),
          ),
        ),
        child: _buildTextButtonContent(),
      );
    }

    // Get button configuration based on variant
    final config = _getButtonConfig();
    final buttonSize = _getButtonSize();

    // Handle icon-only button
    if (label == null && icon != null) {
      final canActivate = !effectivelyDisabled && !isLoading;
      return Semantics(
        button: true,
        enabled: canActivate,
        label: semanticsLabel ?? 'Button',
        onTap: canActivate ? onPressed : null,
        excludeSemantics: true,
        child: Container(
          width: width ?? buttonSize.iconSize,
          height: height ?? buttonSize.iconSize,
          decoration: BoxDecoration(
            color: effectivelyDisabled
                ? config.disabledBackgroundColor
                : config.backgroundColor,
            borderRadius: BorderRadius.circular(
                borderRadius ?? buttonSize.iconBorderRadius),
            border: config.borderColor != null
                ? Border.all(color: config.borderColor!, width: 2)
                : null,
            boxShadow: effectivelyDisabled ? null : config.shadow,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: canActivate ? onPressed : null,
              borderRadius: BorderRadius.circular(
                  borderRadius ?? buttonSize.iconBorderRadius),
              child: Center(
                child: isLoading
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: config.textColor,
                          strokeWidth: 2,
                        ),
                      )
                    : Icon(
                        icon,
                        color: effectivelyDisabled
                            ? config.disabledTextColor
                            : config.textColor,
                        size: buttonSize.iconContentSize,
                      ),
              ),
            ),
          ),
        ),
      );
    }

    // Standard button with label
    final canActivate = !effectivelyDisabled && !isLoading;
    return Semantics(
      button: true,
      enabled: canActivate,
      label: semanticsLabel ?? label!,
      onTap: canActivate ? onPressed : null,
      excludeSemantics: true,
      child: Container(
        width: width,
        height: height ?? buttonSize.height,
        decoration: BoxDecoration(
          color: effectivelyDisabled
              ? config.disabledBackgroundColor
              : config.backgroundColor,
          borderRadius:
              BorderRadius.circular(borderRadius ?? buttonSize.borderRadius),
          border: config.borderColor != null
              ? Border.all(color: config.borderColor!, width: 2)
              : null,
          boxShadow: effectivelyDisabled ? null : config.shadow,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: canActivate ? onPressed : null,
            borderRadius:
                BorderRadius.circular(borderRadius ?? buttonSize.borderRadius),
            child: Padding(
              padding: padding ?? buttonSize.padding,
              child: _buildButtonContent(
                config,
                buttonSize,
                disabled: effectivelyDisabled,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildButtonContent(
    _ButtonConfig config,
    _ButtonSize buttonSize, {
    required bool disabled,
  }) {
    if (isLoading) {
      return Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            color: config.textColor,
            strokeWidth: 2,
          ),
        ),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(
            icon,
            color: disabled ? config.disabledTextColor : config.textColor,
            size: buttonSize.iconContentSize,
          ),
          SizedBox(width: buttonSize.iconSpacing),
        ],
        if (label != null)
          Flexible(
            child: Text(
              label!,
              style: buttonSize.textStyle.copyWith(
                color: disabled ? config.disabledTextColor : config.textColor,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        if (suffixIcon != null) ...[
          SizedBox(width: buttonSize.iconSpacing),
          Icon(
            suffixIcon,
            color: disabled ? config.disabledTextColor : config.textColor,
            size: buttonSize.iconContentSize,
          ),
        ],
      ],
    );
  }

  Widget _buildTextButtonContent() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, color: AppTheme.primaryBlue, size: 16),
          const SizedBox(width: 6),
        ],
        Text(
          label!,
          style: AppTheme.labelLarge.copyWith(
            color: AppTheme.primaryBlue,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (suffixIcon != null) ...[
          const SizedBox(width: 6),
          Icon(suffixIcon, color: AppTheme.primaryBlue, size: 16),
        ],
      ],
    );
  }

  _ButtonConfig _getButtonConfig() {
    switch (variant) {
      case AppButtonVariant.primary:
        return _ButtonConfig(
          backgroundColor: AppTheme.primaryBlue,
          textColor: Colors.white,
          disabledBackgroundColor: AppTheme.textLight.withValues(alpha: 0.2),
          disabledTextColor: AppTheme.textLight,
          shadow: AppTheme.elevatedShadow,
        );

      case AppButtonVariant.secondary:
        return _ButtonConfig(
          backgroundColor: AppTheme.cardWhite,
          textColor: AppTheme.textDark,
          disabledBackgroundColor: AppTheme.textLight.withValues(alpha: 0.1),
          disabledTextColor: AppTheme.textLight,
          shadow: AppTheme.softShadow,
        );

      case AppButtonVariant.outline:
        return _ButtonConfig(
          backgroundColor: Colors.transparent,
          textColor: AppTheme.primaryBlue,
          borderColor: AppTheme.primaryBlue,
          disabledBackgroundColor: Colors.transparent,
          disabledTextColor: AppTheme.textLight,
          shadow: [],
        );

      case AppButtonVariant.danger:
        return _ButtonConfig(
          backgroundColor: AppTheme.errorRed,
          textColor: Colors.white,
          disabledBackgroundColor: AppTheme.textLight.withValues(alpha: 0.2),
          disabledTextColor: AppTheme.textLight,
          shadow: [
            BoxShadow(
              color: AppTheme.errorRed.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        );

      case AppButtonVariant.text:
        return _ButtonConfig(
          backgroundColor: Colors.transparent,
          textColor: AppTheme.primaryBlue,
          disabledBackgroundColor: Colors.transparent,
          disabledTextColor: AppTheme.textLight,
          shadow: [],
        );
    }
  }

  _ButtonSize _getButtonSize() {
    switch (size) {
      case AppButtonSize.small:
        return _ButtonSize(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          borderRadius: 12,
          textStyle: AppTheme.labelMedium.copyWith(fontWeight: FontWeight.w600),
          iconContentSize: 18,
          iconSpacing: 6,
          iconSize: 48,
          iconBorderRadius: 12,
        );

      case AppButtonSize.medium:
        return _ButtonSize(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          borderRadius: 16,
          textStyle: AppTheme.labelLarge.copyWith(fontWeight: FontWeight.w600),
          iconContentSize: 20,
          iconSpacing: 8,
          iconSize: 48,
          iconBorderRadius: 14,
        );

      case AppButtonSize.large:
        return _ButtonSize(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          borderRadius: 18,
          textStyle: AppTheme.labelLarge.copyWith(fontWeight: FontWeight.w600),
          iconContentSize: 22,
          iconSpacing: 10,
          iconSize: 56,
          iconBorderRadius: 16,
        );

      case AppButtonSize.extraLarge:
        return _ButtonSize(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
          borderRadius: 20,
          textStyle: AppTheme.headlineSmall.copyWith(
            fontWeight: FontWeight.bold,
          ),
          iconContentSize: 24,
          iconSpacing: 12,
          iconSize: 64,
          iconBorderRadius: 18,
        );
    }
  }
}

/// Button style variants
enum AppButtonVariant {
  primary, // Blue gradient background, white text
  secondary, // White background, dark text
  outline, // Transparent with border
  danger, // Red background, white text
  text, // Text only, no background
}

/// Button size options
enum AppButtonSize {
  small, // Height: 40px
  medium, // Height: 48px
  large, // Height: 56px (default)
  extraLarge, // Height: 64px
}

/// Internal button configuration
class _ButtonConfig {
  final Color backgroundColor;
  final Color textColor;
  final Color? borderColor;
  final Color disabledBackgroundColor;
  final Color disabledTextColor;
  final List<BoxShadow> shadow;

  _ButtonConfig({
    required this.backgroundColor,
    required this.textColor,
    this.borderColor,
    required this.disabledBackgroundColor,
    required this.disabledTextColor,
    required this.shadow,
  });
}

/// Internal button size configuration
class _ButtonSize {
  final double height;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final TextStyle textStyle;
  final double iconContentSize;
  final double iconSpacing;
  final double iconSize;
  final double iconBorderRadius;

  _ButtonSize({
    required this.height,
    required this.padding,
    required this.borderRadius,
    required this.textStyle,
    required this.iconContentSize,
    required this.iconSpacing,
    required this.iconSize,
    required this.iconBorderRadius,
  });
}
