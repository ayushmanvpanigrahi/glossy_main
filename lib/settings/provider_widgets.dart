import 'package:flutter/material.dart';
import '../app_colors.dart';

// ---------------------------------------------------------------------------
// Provider dropdown + its bottom-sheet picker.
// ---------------------------------------------------------------------------

class ProviderDropdown extends StatelessWidget {
  const ProviderDropdown({
    super.key,
    required this.isOpen,
    required this.onTap,
  });

  final bool isOpen;
  final VoidCallback onTap;

  static final _radius = BorderRadius.circular(8);
  static const _borderEnabled = BorderSide(color: AppColors.ink, width: 1.0);
  static const _borderFocused = BorderSide(
    color: AppColors.primary,
    width: 1.5,
  );
  static const _labelStyle = TextStyle(
    fontFamily: 'Inter',
    fontSize: 16,
    color: AppColors.ink,
  );

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: InputDecorator(
        isFocused: isOpen,
        decoration: InputDecoration(
          labelText: 'Provider',
          labelStyle: _labelStyle,
          floatingLabelStyle: TextStyle(
            fontFamily: 'Inter',
            fontSize: 16,
            color: isOpen ? AppColors.primary : AppColors.ink,
          ),
          filled: true,
          fillColor: AppColors.stage,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          border: OutlineInputBorder(
            borderRadius: _radius,
            borderSide: const BorderSide(color: AppColors.ink),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: _radius,
            borderSide: _borderEnabled,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: _radius,
            borderSide: _borderFocused,
          ),
        ),
        child: const Row(
          children: [
            Expanded(
              child: Text(
                'OpenRouter',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 16,
                  color: AppColors.ink,
                ),
              ),
            ),
            Icon(Icons.keyboard_arrow_down, color: AppColors.muted),
          ],
        ),
      ),
    );
  }
}

class ProviderSheet extends StatelessWidget {
  const ProviderSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Select Provider',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.ink,
              ),
            ),
          ),
          ListTile(
            title: const Text(
              'OpenRouter',
              style: TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w600,
              ),
            ),
            trailing: const Icon(Icons.check_circle, color: AppColors.primary),
            onTap: () => Navigator.pop(context),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
