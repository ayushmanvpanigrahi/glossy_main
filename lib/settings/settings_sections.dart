import 'package:flutter/material.dart';
import '../app_colors.dart';
import 'common_widgets.dart';
import 'model_widgets.dart';
import 'provider_widgets.dart';
import 'settings_models.dart';

// ---------------------------------------------------------------------------
// Named sections pulled out of SettingsScreen.build() so the screen itself
// stays a thin orchestrator. Each section is a StatelessWidget that takes
// exactly the state/callbacks it needs — no shared mutable state, no
// reaching back into the screen's private members.
// ---------------------------------------------------------------------------

// ── AI Provider section: provider picker + API key fields ──────────────────

class AiProviderSection extends StatelessWidget {
  const AiProviderSection({
    super.key,
    required this.isProviderOpen,
    required this.onProviderTap,
    required this.apiKeyController,
    required this.obscureApiKey,
    required this.onToggleObscureApiKey,
    required this.groqApiKeyController,
    required this.obscureGroqApiKey,
    required this.onToggleObscureGroqApiKey,
    required this.onGroqKeyChanged,
  });

  final bool isProviderOpen;
  final VoidCallback onProviderTap;

  final TextEditingController apiKeyController;
  final bool obscureApiKey;
  final VoidCallback onToggleObscureApiKey;

  final TextEditingController groqApiKeyController;
  final bool obscureGroqApiKey;
  final VoidCallback onToggleObscureGroqApiKey;
  final ValueChanged<String> onGroqKeyChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionLabel('AI PROVIDER'),
        const SizedBox(height: 16),

        ProviderDropdown(isOpen: isProviderOpen, onTap: onProviderTap),
        const SizedBox(height: 16),

        TextField(
          controller: apiKeyController,
          obscureText: obscureApiKey,
          style: const TextStyle(fontFamily: 'JetBrainsMono', fontSize: 14),
          decoration: InputDecoration(
            labelText: 'OpenRouter API Key',
            border: const OutlineInputBorder(),
            suffixIcon: IconButton(
              icon: Icon(
                obscureApiKey ? Icons.visibility_off : Icons.visibility,
              ),
              onPressed: onToggleObscureApiKey,
            ),
          ),
        ),
        const SizedBox(height: 16),

        TextField(
          controller: groqApiKeyController,
          obscureText: obscureGroqApiKey,
          style: const TextStyle(fontFamily: 'JetBrainsMono', fontSize: 14),
          decoration: InputDecoration(
            labelText: 'Groq API Key (optional)',
            border: const OutlineInputBorder(),
            suffixIcon: IconButton(
              icon: Icon(
                obscureGroqApiKey ? Icons.visibility_off : Icons.visibility,
              ),
              onPressed: onToggleObscureGroqApiKey,
            ),
          ),
          onChanged: onGroqKeyChanged,
        ),
      ],
    );
  }
}

// ── Model section: search, filter, list, fetch warnings ────────────────────

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

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
                    icon: const Icon(Icons.refresh),
                    tooltip: 'Refresh model list',
                    onPressed: onRefresh,
                  ),
          ],
        ),
        const SizedBox(height: 8),

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
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
              isDense: true,
            ),
            onChanged: onSearchChanged,
          ),
          const SizedBox(height: 8),

          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Free models only'),
            value: freeOnly,
            onChanged: onFreeOnlyChanged,
          ),
          const SizedBox(height: 8),

          if (allModels.isEmpty)
            const InfoBanner(
              message: 'No models available right now',
              color: AppColors.warning,
              icon: Icons.info_outline,
            )
          else ...[
            Text(
              '${filteredModels.length} model(s) available',
              style: const TextStyle(color: AppColors.muted, fontSize: 12),
            ),
            for (final warning in fetchWarnings) ...[
              const SizedBox(height: 6),
              InfoBanner(
                message: warning,
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
      ],
    );
  }
}

// ── RAG section: embedding mode, embedding key, indexing trigger ───────────

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
        const SectionLabel('RAG (BOOK Q&A)'),
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

        if (embeddingMode == 'api') ...[
          TextField(
            controller: embeddingApiKeyController,
            obscureText: obscureEmbeddingKey,
            style: const TextStyle(fontFamily: 'JetBrainsMono', fontSize: 14),
            decoration: InputDecoration(
              labelText: 'Gemini Embedding API Key',
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: Icon(
                  obscureEmbeddingKey
                      ? Icons.visibility_off
                      : Icons.visibility,
                ),
                onPressed: onToggleObscureEmbeddingKey,
              ),
            ),
            onChanged: onEmbeddingApiKeyChanged,
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
