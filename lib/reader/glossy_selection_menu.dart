import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../app_colors.dart';

// ---------------------------------------------------------------------------
// GlossySelectionMenu
// ---------------------------------------------------------------------------
// Replaces the OS-native text selection toolbar entirely. We stopped relying
// on AdaptiveTextSelectionToolbar because on real devices Android injects
// every "Process Text" capable app (ChatGPT, Grok, Perplexity, etc. — see
// your screenshot) into that native menu, burying our own "Glossy" button
// under an overflow "..." — sometimes 8+ items deep.
//
// This widget is a small, fully custom, always-on-top pill: just
// Copy | Highlight | Glossy — styled to match the reference design.
// ---------------------------------------------------------------------------

class GlossySelectionMenu extends StatelessWidget {
  const GlossySelectionMenu({
    super.key,
    required this.anchor,
    required this.selectedText,
    required this.onGlossy,
    this.onHighlight,
  });

  /// Global position (top-center of the selected text region) to anchor
  /// the pill above.
  final Offset anchor;
  final String selectedText;
  final VoidCallback onGlossy;
  final VoidCallback? onHighlight;

  static const _menuWidth = 220.0;
  static const _menuHeight = 44.0;

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final left = (anchor.dx - _menuWidth / 2).clamp(
      8.0,
      screenSize.width - _menuWidth - 8.0,
    );
    // Prefer floating above the selection; if too close to the top of the
    // screen, flip below instead so it never gets clipped off-screen.
    final preferredTop = anchor.dy - _menuHeight - 12;
    final top = preferredTop < 8 ? anchor.dy + 24 : preferredTop;

    return Positioned(
      left: left,
      top: top,
      child: Material(
        color: Colors.transparent,
        child: Container(
          height: _menuHeight,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: AppColors.ink,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _MenuButton(
                label: 'Copy',
                onTap: () {
                  Clipboard.setData(ClipboardData(text: selectedText));
                },
              ),
              _divider(),
              _MenuButton(label: 'Highlight', onTap: onHighlight ?? () {}),
              _divider(),
              _MenuButton(
                label: 'Glossy',
                color: AppColors.primary,
                onTap: onGlossy,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _divider() => Container(
    width: 1,
    height: 20,
    color: Colors.white.withValues(alpha: 0.15),
  );
}

class _MenuButton extends StatelessWidget {
  const _MenuButton({required this.label, required this.onTap, this.color});

  final String label;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: color ?? Colors.white,
          ),
        ),
      ),
    );
  }
}
