import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app_colors.dart';
import '../../providers/settings_notifier.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/settings_rows.dart';
import '../../widgets/settings_scaffold.dart';

class RagBookQnaScreen extends ConsumerWidget {
  const RagBookQnaScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    return SettingsDetailScaffold(
      title: 'RAG / book Q&A',
      actions: [
        TextButton(
          onPressed: state.isSaving ? null : notifier.save,
          child: const Text(
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
          const SettingsSectionLabel('Embedding mode'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.stage,
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SegmentedToggle<String>(
                    options: const [('api', 'API'), ('local', 'On-device')],
                    selected: state.embeddingMode,
                    onChanged: notifier.setEmbeddingMode,
                  ),
                  if (state.embeddingMode == 'api') ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.paper,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 14,
                            color: AppColors.muted,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Uses the Gemini key from API Keys.',
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
                  ],
                ],
              ),
            ),
          ),
          const SettingsSectionLabel('Index books'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.stage,
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.all(16),
              child: SegmentedToggle<String>(
                options: const [
                  ('onAdd', 'On add'),
                  ('lazy', 'On first use'),
                  ('background', 'Background'),
                ],
                selected: state.indexingTrigger,
                onChanged: notifier.setIndexingTrigger,
              ),
            ),
          ),
          const SettingsSectionLabel('How it works'),
          SettingsGroup(
            children: const [
              _InfoRow(
                icon: Icons.upload_file_outlined,
                title: 'Books are indexed',
                subtitle: 'Text is split into chunks and embedded',
              ),
              _InfoRow(
                icon: Icons.search_outlined,
                title: 'Semantic search',
                subtitle: 'Relevant passages are found per question',
              ),
              _InfoRow(
                icon: Icons.chat_outlined,
                title: 'Context-aware answers',
                subtitle: 'AI responds using your book\'s content',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(
        children: [
          SettingsIconCircle(
            label: '',
            icon: icon,
            bgColor: AppColors.primary.withValues(alpha: 0.08),
            color: AppColors.primary,
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 15,
                  color: AppColors.ink,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: AppColors.muted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
