import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app_colors.dart';
import '../../widgets/settings_rows.dart';
import '../../widgets/settings_scaffold.dart';

class CustomPromptTemplateScreen extends StatefulWidget {
  const CustomPromptTemplateScreen({super.key});

  @override
  State<CustomPromptTemplateScreen> createState() =>
      _CustomPromptTemplateScreenState();
}

class _CustomPromptTemplateScreenState
    extends State<CustomPromptTemplateScreen> {
  final _ctrl = TextEditingController(
    text:
        'You are a helpful reading assistant for the Glossy app. Help users understand and discuss books.',
  );

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SettingsDetailScaffold(
      title: 'Prompt template',
      actions: [
        TextButton(
          onPressed: () => context.pop(),
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
          const SettingsSectionLabel('System prompt'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.stage,
                borderRadius: BorderRadius.circular(16),
              ),
              child: TextField(
                controller: _ctrl,
                maxLines: 10,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  color: AppColors.ink,
                ),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.all(16),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22),
            child: Text(
              'This prompt is sent at the start of every AI conversation. Keep it concise and focused.',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                color: AppColors.muted.withValues(alpha: 0.8),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const SettingsSectionLabel('Templates'),
          SettingsGroup(
            children: [
              SettingsNavRow(
                iconWidget: const SettingsIconCircle(
                  label: '📚',
                  icon: Icons.auto_stories_outlined,
                ),
                title: 'Book assistant',
                subtitle: 'Default reading companion',
                onTap: () {},
              ),
              SettingsNavRow(
                iconWidget: const SettingsIconCircle(
                  label: '🎓',
                  icon: Icons.school_outlined,
                ),
                title: 'Study mode',
                subtitle: 'Focus on key takeaways and summaries',
                onTap: () {},
              ),
              SettingsNavRow(
                iconWidget: const SettingsIconCircle(
                  label: '✨',
                  icon: Icons.auto_awesome_outlined,
                ),
                title: 'Creative mode',
                subtitle: 'Imaginative and exploratory discussions',
                onTap: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }
}
