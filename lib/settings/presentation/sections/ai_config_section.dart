import 'package:flutter/material.dart';
import '../../../../app_colors.dart';
import '../../data/models/settings_models.dart';
import '../widgets/settings_rows.dart';

class AiConfigSection extends StatelessWidget {
  const AiConfigSection({
    super.key,
    required this.selectedModelId,
    required this.orStatus,
    required this.groqStatus,
    required this.onProviderTap,
    required this.onModelTap,
    required this.onApiKeysTap,
    required this.onPromptTap,
    required this.onRagTap,
    required this.onHealthTap,
  });

  final String? selectedModelId;
  final KeyStatus orStatus;
  final KeyStatus groqStatus;
  final VoidCallback onProviderTap;
  final VoidCallback onModelTap;
  final VoidCallback onApiKeysTap;
  final VoidCallback onPromptTap;
  final VoidCallback onRagTap;
  final VoidCallback onHealthTap;

  bool get _anyActive =>
      orStatus == KeyStatus.valid || groqStatus == KeyStatus.valid;

  String get _modelShort {
    final id = selectedModelId ?? '';
    if (id.isEmpty) return 'Not set';
    final name = id.split('/').last.replaceAll(':free', '');
    return name.length > 14 ? '${name.substring(0, 13)}…' : name;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SettingsSectionLabel('AI configuration'),
        SettingsGroup(
          children: [
            SettingsNavRow(
              onTap: onProviderTap,
              iconWidget: SettingsIconCircle(
                label: '✦',
                icon: Icons.bolt_rounded,
                bgColor: AppColors.primary.withValues(alpha: 0.12),
                color: AppColors.primary,
              ),
              title: 'AI provider',
              trailingText: 'OpenRouter',
              trailingColor: AppColors.primary,
            ),
            SettingsNavRow(
              onTap: onModelTap,
              iconWidget: const SettingsIconCircle(
                label: '⌘',
                icon: Icons.auto_awesome_outlined,
              ),
              title: 'Preferred model',
              trailingText: _modelShort,
            ),
            SettingsNavRow(
              onTap: onApiKeysTap,
              iconWidget: const SettingsIconCircle(
                label: '▦',
                icon: Icons.key_outlined,
              ),
              title: 'API keys',
              subtitle: 'OpenRouter · Groq · Gemini',
              trailingWidget: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  StatusDotIndicator(
                    color: _anyActive ? AppColors.success : AppColors.muted,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _anyActive ? '•••• set' : 'Not set',
                    style: const TextStyle(
                      fontFamily: 'JetBrainsMono',
                      fontSize: 12,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
            ),
            SettingsNavRow(
              onTap: onPromptTap,
              iconWidget: const SettingsIconCircle(
                label: '✎',
                icon: Icons.edit_note_outlined,
                iconSize: 18,
              ),
              title: 'Custom prompt template',
              subtitle: 'System prompt for all chats',
            ),
            SettingsNavRow(
              onTap: onRagTap,
              iconWidget: const SettingsIconCircle(
                label: '◈',
                icon: Icons.auto_stories_outlined,
              ),
              title: 'RAG / book Q&A',
              subtitle: 'Embedding · indexing',
            ),
            SettingsNavRow(
              onTap: onHealthTap,
              iconWidget: SettingsIconCircle(
                label: '●',
                icon: Icons.monitor_heart_outlined,
                color: _anyActive ? AppColors.success : AppColors.muted,
                bgColor: _anyActive
                    ? AppColors.success.withValues(alpha: 0.12)
                    : AppColors.secondary,
              ),
              title: 'Service health',
              subtitle: _anyActive
                  ? 'All systems operational'
                  : 'Configure API keys first',
              trailingWidget: StatusDotIndicator(
                color: _anyActive ? AppColors.success : AppColors.muted,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
