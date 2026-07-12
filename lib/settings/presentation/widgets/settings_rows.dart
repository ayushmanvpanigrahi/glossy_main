import 'package:flutter/material.dart';
import '../../../../app_colors.dart';

// ---------------------------------------------------------------------------
// Shared widgets for Settings screens.
// ---------------------------------------------------------------------------

class SettingsSectionLabel extends StatelessWidget {
  const SettingsSectionLabel(this.label, {super.key});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 0, 22, 10),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.2,
          color: AppColors.muted,
        ),
      ),
    );
  }
}

class SettingsGroup extends StatelessWidget {
  const SettingsGroup({super.key, required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(children: children),
    );
  }
}

class SettingsNavRow extends StatelessWidget {
  const SettingsNavRow({
    super.key,
    this.onTap,
    this.iconWidget,
    required this.title,
    this.subtitle,
    this.trailingText,
    this.trailingColor,
    this.trailingWidget,
    this.showChevron = true,
  });

  final VoidCallback? onTap;
  final Widget? iconWidget;
  final String title;
  final String? subtitle;
  final String? trailingText;
  final Color? trailingColor;
  final Widget? trailingWidget;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              ?iconWidget,
              if (iconWidget != null) const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: AppColors.ink,
                      ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          color: AppColors.muted,
                        ),
                      ),
                  ],
                ),
              ),
              if (trailingText != null)
                Text(
                  trailingText!,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    color: trailingColor ?? AppColors.muted,
                  ),
                ),
              ?trailingWidget,
              if (onTap != null &&
                  trailingWidget == null &&
                  trailingText == null &&
                  showChevron)
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: AppColors.muted,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class SettingsToggleRow extends StatelessWidget {
  const SettingsToggleRow({
    super.key,
    this.iconWidget,
    required this.title,
    required this.value,
    required this.onChanged,
  });

  final Widget? iconWidget;
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          ?iconWidget,
          if (iconWidget != null) const SizedBox(width: 14),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: AppColors.ink,
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.primary,
            activeTrackColor: AppColors.primary.withValues(alpha: 0.35),
            inactiveThumbColor: AppColors.paper,
            inactiveTrackColor: AppColors.muted.withValues(alpha: 0.3),
            trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
          ),
        ],
      ),
    );
  }
}

class SettingsIconCircle extends StatelessWidget {
  const SettingsIconCircle({
    super.key,
    required this.label,
    this.icon,
    this.iconSize,
    this.bgColor,
    this.color,
  });

  final String label;
  final IconData? icon;
  final double? iconSize;
  final Color? bgColor;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: bgColor ?? AppColors.secondary,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: icon != null
          ? Icon(icon, size: iconSize ?? 14, color: color ?? AppColors.ink)
          : Text(
              label,
              style: TextStyle(
                fontFamily: 'JetBrainsMono',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color ?? AppColors.ink,
              ),
            ),
    );
  }
}

class SettingsBadge extends StatelessWidget {
  const SettingsBadge({super.key, required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.primary,
        ),
      ),
    );
  }
}

class StatusDotIndicator extends StatelessWidget {
  const StatusDotIndicator({super.key, required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.4),
            blurRadius: 4,
            spreadRadius: 1,
          ),
        ],
      ),
    );
  }
}

class SignOutButton extends StatelessWidget {
  const SignOutButton({super.key, required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.danger.withValues(alpha: 0.15),
          width: 0.5,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: Text(
                'Sign out',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: AppColors.danger,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
