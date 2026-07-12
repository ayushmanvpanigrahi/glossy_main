import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app_colors.dart';
import '../../../data/models/settings_models.dart';
import '../../providers/settings_notifier.dart';
import '../../widgets/settings_rows.dart';
import '../../widgets/settings_scaffold.dart';

class ApiKeysScreen extends ConsumerWidget {
  const ApiKeysScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final ctrl = ref.watch(settingsControllersProvider);

    return SettingsDetailScaffold(
      title: 'API keys',
      actions: [
        TextButton(
          onPressed: state.isSaving ? null : notifier.save,
          child: state.isSaving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary,
                  ),
                )
              : const Text(
                  'Save',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppColors.primary,
                  ),
                ),
        ),
      ],
      body: ListView(
        padding: const EdgeInsets.only(top: 8, bottom: 40),
        children: [
          const SettingsSectionLabel('Provider keys'),
          SettingsGroup(
            children: [
              _KeyRow(
                controller: ctrl.orKeyCtrl,
                obscure: state.obscureOr,
                onToggleObscure: notifier.toggleObscureOr,
                label: 'OpenRouter',
                hint: 'sk-or-v1-...',
                badgeLabel: 'OR',
                badgeColor: AppColors.primary,
                status: state.orStatus,
                onValidate: () =>
                    notifier.validateOrKey(ctrl.orKeyCtrl.text.trim()),
              ),
              _KeyRow(
                controller: ctrl.groqKeyCtrl,
                obscure: state.obscureGroq,
                onToggleObscure: notifier.toggleObscureGroq,
                label: 'Groq',
                hint: 'gsk_...',
                badgeLabel: 'GQ',
                badgeColor: const Color(0xFFF55036),
                status: state.groqStatus,
                onValidate: () =>
                    notifier.validateGroqKey(ctrl.groqKeyCtrl.text.trim()),
              ),
              _KeyRow(
                controller: ctrl.geminiKeyCtrl,
                obscure: state.obscureGemini,
                onToggleObscure: notifier.toggleObscureGemini,
                label: 'Gemini',
                hint: 'AIza...',
                badgeLabel: 'GM',
                badgeColor: const Color(0xFF4285F4),
                status: state.geminiStatus,
                onValidate: () =>
                    notifier.validateGeminiKey(ctrl.geminiKeyCtrl.text.trim()),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22),
            child: Text(
              'Keys are stored securely in your device\'s encrypted storage and never sent to Glossy servers.',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                color: AppColors.muted.withValues(alpha: 0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _KeyRow extends StatelessWidget {
  const _KeyRow({
    required this.controller,
    required this.obscure,
    required this.onToggleObscure,
    required this.label,
    required this.hint,
    required this.badgeLabel,
    required this.badgeColor,
    required this.status,
    required this.onValidate,
  });

  final TextEditingController controller;
  final bool obscure;
  final VoidCallback onToggleObscure;
  final String label;
  final String hint;
  final String badgeLabel;
  final Color badgeColor;
  final KeyStatus status;
  final VoidCallback onValidate;

  Color get _statusColor => switch (status) {
    KeyStatus.idle => AppColors.muted,
    KeyStatus.checking => AppColors.warning,
    KeyStatus.valid => AppColors.success,
    KeyStatus.invalid => AppColors.danger,
    KeyStatus.networkError => AppColors.warning,
  };

  String get _statusLabel => switch (status) {
    KeyStatus.idle => 'Not set',
    KeyStatus.checking => 'Checking...',
    KeyStatus.valid => 'Active',
    KeyStatus.invalid => 'Invalid',
    KeyStatus.networkError => 'Unreachable',
  };

  @override
  Widget build(BuildContext context) {
    final isChecking = status == KeyStatus.checking;
    final isValid = status == KeyStatus.valid;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(
                  badgeLabel,
                  style: TextStyle(
                    fontFamily: 'JetBrainsMono',
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: badgeColor,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.ink,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _statusColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _statusColor.withValues(alpha: 0.30),
                    width: 0.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: _statusColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      _statusLabel,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: _statusColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  obscureText: obscure,
                  style: const TextStyle(
                    fontFamily: 'JetBrainsMono',
                    fontSize: 13,
                    color: AppColors.ink,
                  ),
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: const TextStyle(
                      fontFamily: 'JetBrainsMono',
                      fontSize: 12,
                      color: AppColors.muted,
                    ),
                    filled: true,
                    fillColor: AppColors.paper,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 11,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: isValid
                            ? AppColors.success.withValues(alpha: 0.5)
                            : AppColors.border,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: badgeColor, width: 1.5),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscure ? Icons.visibility_off : Icons.visibility,
                        size: 16,
                        color: AppColors.muted,
                      ),
                      onPressed: onToggleObscure,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 40,
                child: OutlinedButton(
                  onPressed: isChecking ? null : onValidate,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    side: BorderSide(
                      color: isChecking
                          ? AppColors.border
                          : badgeColor.withValues(alpha: 0.5),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: isChecking
                      ? SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: badgeColor,
                          ),
                        )
                      : Text(
                          'Test',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: badgeColor,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
