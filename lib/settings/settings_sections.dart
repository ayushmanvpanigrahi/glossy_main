import 'package:flutter/material.dart';
import '../app_colors.dart';
import 'common_widgets.dart';
import 'model_widgets.dart';
import 'settings_models.dart';

// ---------------------------------------------------------------------------
// Settings sections — each section is a stateless widget.
// ---------------------------------------------------------------------------

// ── API Keys Section ─────────────────────────────────────────────────────────

class ApiKeysSection extends StatelessWidget {
  const ApiKeysSection({
    super.key,
    required this.orKeyCtrl,
    required this.obscureOr,
    required this.onToggleObscureOr,
    required this.orStatus,
    required this.onValidateOr,
    required this.groqKeyCtrl,
    required this.obscureGroq,
    required this.onToggleObscureGroq,
    required this.groqStatus,
    required this.onValidateGroq,
    required this.geminiKeyCtrl,
    required this.obscureGemini,
    required this.onToggleObscureGemini,
    required this.geminiStatus,
    required this.onValidateGemini,
  });

  final TextEditingController orKeyCtrl;
  final bool obscureOr;
  final VoidCallback onToggleObscureOr;
  final KeyStatus orStatus;
  final VoidCallback onValidateOr;

  final TextEditingController groqKeyCtrl;
  final bool obscureGroq;
  final VoidCallback onToggleObscureGroq;
  final KeyStatus groqStatus;
  final VoidCallback onValidateGroq;

  final TextEditingController geminiKeyCtrl;
  final bool obscureGemini;
  final VoidCallback onToggleObscureGemini;
  final KeyStatus geminiStatus;
  final VoidCallback onValidateGemini;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionLabel('API KEYS'),
        const SizedBox(height: 14),

        // Outer card wrapping all three keys
        Container(
          decoration: BoxDecoration(
            color: AppColors.stage,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              _KeyRow(
                controller:      orKeyCtrl,
                obscure:         obscureOr,
                onToggleObscure: onToggleObscureOr,
                label:           'OpenRouter',
                hint:            'sk-or-v1-...',
                badge:           'OR',
                badgeColor:      AppColors.primary,
                status:          orStatus,
                onValidate:      onValidateOr,
                showDivider:     true,
              ),
              _KeyRow(
                controller:      groqKeyCtrl,
                obscure:         obscureGroq,
                onToggleObscure: onToggleObscureGroq,
                label:           'Groq',
                hint:            'gsk_...',
                badge:           'GQ',
                badgeColor:      const Color(0xFFF55036),
                status:          groqStatus,
                onValidate:      onValidateGroq,
                showDivider:     true,
              ),
              _KeyRow(
                controller:      geminiKeyCtrl,
                obscure:         obscureGemini,
                onToggleObscure: onToggleObscureGemini,
                label:           'Gemini',
                hint:            'AIza...',
                badge:           'GM',
                badgeColor:      const Color(0xFF4285F4),
                status:          geminiStatus,
                onValidate:      onValidateGemini,
                showDivider:     false,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Single key row inside the card ───────────────────────────────────────────

class _KeyRow extends StatelessWidget {
  const _KeyRow({
    required this.controller,
    required this.obscure,
    required this.onToggleObscure,
    required this.label,
    required this.hint,
    required this.badge,
    required this.badgeColor,
    required this.status,
    required this.onValidate,
    required this.showDivider,
  });

  final TextEditingController controller;
  final bool obscure;
  final VoidCallback onToggleObscure;
  final String label;
  final String hint;
  final String badge;
  final Color badgeColor;
  final KeyStatus status;
  final VoidCallback onValidate;
  final bool showDivider;

  Color get _dotColor => switch (status) {
    KeyStatus.idle         => AppColors.muted.withValues(alpha: 0.4),
    KeyStatus.checking     => AppColors.warning,
    KeyStatus.valid        => AppColors.success,
    KeyStatus.invalid      => AppColors.danger,
    KeyStatus.networkError => AppColors.warning,
  };

  String get _statusLabel => switch (status) {
    KeyStatus.idle         => 'Not set',
    KeyStatus.checking     => 'Checking...',
    KeyStatus.valid        => 'Active',
    KeyStatus.invalid      => 'Invalid',
    KeyStatus.networkError => 'Unreachable',
  };

  @override
  Widget build(BuildContext context) {
    final isChecking = status == KeyStatus.checking;
    final isValid    = status == KeyStatus.valid;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: badge + label + status pill
              Row(
                children: [
                  // Badge
                  Container(
                    width: 30,
                    height: 20,
                    decoration: BoxDecoration(
                      color: badgeColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Center(
                      child: Text(
                        badge,
                        style: TextStyle(
                          fontFamily: 'JetBrainsMono',
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: badgeColor,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink,
                    ),
                  ),
                  const Spacer(),
                  // Status pill
                  _StatusPill(
                    label:       _statusLabel,
                    color:       _dotColor,
                    icon:        _statusIconFor(status),
                    isAnimating: isChecking,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Input row
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller:  controller,
                      obscureText: obscure,
                      style: TextStyle(
                        fontFamily: 'JetBrainsMono',
                        fontSize: 12,
                        color: isValid ? AppColors.ink : AppColors.ink,
                      ),
                      decoration: InputDecoration(
                        hintText: hint,
                        hintStyle: const TextStyle(
                          fontFamily: 'JetBrainsMono',
                          fontSize: 11,
                          color: AppColors.muted,
                        ),
                        filled:      true,
                        fillColor:   AppColors.paper,
                        isDense:     true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 11,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: AppColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: isValid
                                ? AppColors.success.withValues(alpha: 0.5)
                                : AppColors.border,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
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
                  // Validate button
                  SizedBox(
                    height: 40,
                    child: OutlinedButton(
                      onPressed: isChecking ? null : onValidate,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        side: BorderSide(
                          color: isChecking ? AppColors.border : badgeColor.withValues(alpha: 0.6),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
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
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: badgeColor,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (showDivider)
          const Divider(height: 1, thickness: 1, color: AppColors.border),
      ],
    );
  }

  static IconData _statusIconFor(KeyStatus s) => switch (s) {
    KeyStatus.idle         => Icons.circle_outlined,
    KeyStatus.checking     => Icons.sync,
    KeyStatus.valid        => Icons.check_circle_rounded,
    KeyStatus.invalid      => Icons.cancel_rounded,
    KeyStatus.networkError => Icons.wifi_off_rounded,
  };
}

class _StatusPill extends StatefulWidget {
  const _StatusPill({
    required this.label,
    required this.color,
    required this.icon,
    required this.isAnimating,
  });

  final String label;
  final Color color;
  final IconData icon;
  final bool isAnimating;

  @override
  State<_StatusPill> createState() => _StatusPillState();
}

class _StatusPillState extends State<_StatusPill>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    if (widget.isAnimating) _ctrl.repeat();
  }

  @override
  void didUpdateWidget(_StatusPill old) {
    super.didUpdateWidget(old);
    if (widget.isAnimating && !_ctrl.isAnimating) {
      _ctrl.repeat();
    } else if (!widget.isAnimating && _ctrl.isAnimating) {
      _ctrl.stop();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: widget.color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: widget.color.withValues(alpha: 0.30)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          widget.isAnimating
              ? RotationTransition(
                  turns: _ctrl,
                  child: Icon(widget.icon, size: 12, color: widget.color),
                )
              : Icon(widget.icon, size: 12, color: widget.color),
          const SizedBox(width: 4),
          Text(
            widget.label,
            style: TextStyle(
              fontFamily: 'JetBrainsMono',
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: widget.color,
            ),
          ),
        ],
      ),
    );
  }
}

class _ValidateButton extends StatelessWidget {
  const _ValidateButton({
    required this.onPressed,
    required this.isChecking,
  });

  final VoidCallback? onPressed;
  final bool isChecking;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          side: const BorderSide(color: AppColors.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: isChecking
            ? const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Text(
                'Test',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink,
                ),
              ),
      ),
    );
  }
}

// ── Model Section ─────────────────────────────────────────────────────────────

class ModelSection extends StatelessWidget {
  const ModelSection({
    super.key,
    required this.isModelsLoading,
    required this.modelsFetchError,
    required this.onRefresh,
    required this.searchController,
    required this.onSearchChanged,
    required this.freeOnly,
    required this.onFreeOnlyChanged,
    required this.allModels,
    required this.filteredModels,
    required this.fetchWarnings,
    required this.selectedModelId,
    required this.onSelectModel,
    required this.isPinging,
    required this.pingResult,
    required this.onPing,
  });

  final bool isModelsLoading;
  final String? modelsFetchError;
  final VoidCallback onRefresh;

  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;

  final bool freeOnly;
  final ValueChanged<bool> onFreeOnlyChanged;

  final List<OpenRouterModel> allModels;
  final List<OpenRouterModel> filteredModels;
  final List<String> fetchWarnings;

  final String? selectedModelId;
  final ValueChanged<String> onSelectModel;

  final bool isPinging;
  final ModelPingResult? pingResult;
  final VoidCallback onPing;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header row
        Row(
          children: [
            const SectionLabel('PREFERRED MODEL'),
            const Spacer(),
            isModelsLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : IconButton(
                    icon: const Icon(Icons.refresh, size: 18),
                    tooltip: 'Refresh model list',
                    onPressed: onRefresh,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
          ],
        ),
        const SizedBox(height: 12),

        if (modelsFetchError != null)
          InfoBanner(
            message: modelsFetchError!,
            color: AppColors.danger,
            icon: Icons.error_outline,
          )
        else ...[
          TextField(
            controller: searchController,
            decoration: const InputDecoration(
              hintText: 'Search models...',
              prefixIcon: Icon(Icons.search, size: 18),
              border: OutlineInputBorder(),
              isDense: true,
              contentPadding: EdgeInsets.symmetric(vertical: 10),
            ),
            onChanged: onSearchChanged,
          ),
          const SizedBox(height: 8),

          Row(
            children: [
              const Text(
                'Free only',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  color: AppColors.muted,
                ),
              ),
              const Spacer(),
              Switch(
                value: freeOnly,
                onChanged: onFreeOnlyChanged,
              ),
            ],
          ),
          const SizedBox(height: 6),

          if (allModels.isEmpty)
            const InfoBanner(
              message: 'No models available right now',
              color: AppColors.warning,
              icon: Icons.info_outline,
            )
          else ...[
            Row(
              children: [
                Text(
                  '${filteredModels.length} model(s)',
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                ),
              ],
            ),
            for (final w in fetchWarnings) ...[
              const SizedBox(height: 6),
              InfoBanner(
                message: w,
                color: AppColors.warning,
                icon: Icons.warning_amber,
              ),
            ],
            const SizedBox(height: 8),
            ModelList(
              models: filteredModels,
              selectedModelId: selectedModelId,
              onSelect: onSelectModel,
            ),
          ],
        ],

        const SizedBox(height: 12),

        // Model ping row
        if (selectedModelId != null)
          _ModelPingRow(
            modelId:    selectedModelId!,
            isPinging:  isPinging,
            pingResult: pingResult,
            onPing:     onPing,
          ),
      ],
    );
  }
}

// ── Model ping row ─────────────────────────────────────────────────────────

class _ModelPingRow extends StatelessWidget {
  const _ModelPingRow({
    required this.modelId,
    required this.isPinging,
    required this.pingResult,
    required this.onPing,
  });

  final String modelId;
  final bool isPinging;
  final ModelPingResult? pingResult;
  final VoidCallback onPing;

  (Color, IconData, String) get _pingState {
    if (isPinging) {
      return (AppColors.warning, Icons.sync, 'Testing model...');
    }
    return switch (pingResult) {
      null                        => (AppColors.muted,    Icons.play_circle_outline, 'Run model test'),
      ModelPingResult.success     => (AppColors.success,  Icons.check_circle_rounded, 'Model is responding ✓'),
      ModelPingResult.emptyResponse => (AppColors.warning, Icons.warning_amber_rounded, 'Empty response'),
      ModelPingResult.failed      => (AppColors.danger,   Icons.cancel_rounded, 'Model failed'),
      ModelPingResult.unauthorized=> (AppColors.danger,   Icons.lock_outline, 'Unauthorized'),
      ModelPingResult.networkError=> (AppColors.warning,  Icons.wifi_off_rounded, 'No connection'),
      ModelPingResult.noKey       => (AppColors.muted,    Icons.key_off_outlined, 'No API key'),
    };
  }

  @override
  Widget build(BuildContext context) {
    final (color, icon, label) = _pingState;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          isPinging
              ? SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: color,
                  ),
                )
              : Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
                if (pingResult == ModelPingResult.success)
                  Text(
                    modelId,
                    style: const TextStyle(
                      fontFamily: 'JetBrainsMono',
                      fontSize: 10,
                      color: AppColors.muted,
                    ),
                  ),
              ],
            ),
          ),
          TextButton(
            onPressed: isPinging ? null : onPing,
            child: Text(
              pingResult == null ? 'Test' : 'Retest',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Save button ───────────────────────────────────────────────────────────────

class SaveButton extends StatelessWidget {
  const SaveButton({
    super.key,
    required this.isSaving,
    required this.onSave,
  });

  final bool isSaving;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isSaving ? null : onSave,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: isSaving
            ? const SizedBox(
                height: 16,
                width: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Text(
                'Save settings',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
}

// ── RAG Section (same as before, carries its own Gemini key field) ────────────

class RagSection extends StatelessWidget {
  const RagSection({
    super.key,
    required this.embeddingMode,
    required this.onEmbeddingModeChanged,
    required this.embeddingApiKeyController,
    required this.obscureEmbeddingKey,
    required this.onToggleObscureEmbeddingKey,
    required this.onEmbeddingApiKeyChanged,
    required this.indexingTrigger,
    required this.onIndexingTriggerChanged,
  });

  final String embeddingMode;
  final ValueChanged<String> onEmbeddingModeChanged;

  final TextEditingController embeddingApiKeyController;
  final bool obscureEmbeddingKey;
  final VoidCallback onToggleObscureEmbeddingKey;
  final ValueChanged<String> onEmbeddingApiKeyChanged;

  final String indexingTrigger;
  final ValueChanged<String> onIndexingTriggerChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionLabel('RAG — BOOK Q&A'),
        const SizedBox(height: 16),

        const Text(
          'Embedding mode',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            color: AppColors.muted,
          ),
        ),
        const SizedBox(height: 8),
        SegmentedToggle<String>(
          options: const [('api', 'API'), ('local', 'On-device')],
          selected: embeddingMode,
          onChanged: onEmbeddingModeChanged,
        ),
        const SizedBox(height: 16),

        // Note: Gemini key field is shown in API Keys section above.
        // Here we just note it's shared.
        if (embeddingMode == 'api') ...[
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.stage,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, size: 14, color: AppColors.muted),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Uses the Gemini key from API Keys section above.',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: AppColors.muted,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        const Text(
          'Index books',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            color: AppColors.muted,
          ),
        ),
        const SizedBox(height: 8),
        SegmentedToggle<String>(
          options: const [
            ('onAdd', 'On add'),
            ('lazy', 'On first use'),
            ('background', 'Background'),
          ],
          selected: indexingTrigger,
          onChanged: onIndexingTriggerChanged,
        ),
      ],
    );
  }
}
