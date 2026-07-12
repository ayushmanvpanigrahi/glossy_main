import 'package:flutter/material.dart';
import '../../../../app_colors.dart';
import '../../widgets/settings_rows.dart';
import '../../widgets/settings_scaffold.dart';

class PlanScreen extends StatelessWidget {
  const PlanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SettingsDetailScaffold(
      title: 'Glossy Pro',
      body: ListView(
        padding: const EdgeInsets.only(top: 8, bottom: 40),
        children: [
          const SizedBox(height: 16),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 14),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.20),
              ),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.star_rounded,
                  size: 40,
                  color: AppColors.primary,
                ),
                const SizedBox(height: 12),
                const Text(
                  'You are on Free plan',
                  style: TextStyle(
                    fontFamily: 'PlayfairDisplay',
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Upgrade to Pro for unlimited books, advanced AI, and more.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    color: AppColors.muted,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Upgrade to Pro',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.paper,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SettingsSectionLabel('Plan features'),
          SettingsGroup(
            children: [
              _FeatureRow(icon: Icons.book_outlined, label: 'Unlimited books'),
              _FeatureRow(
                icon: Icons.auto_awesome_outlined,
                label: 'Advanced AI models',
              ),
              _FeatureRow(
                icon: Icons.sync_outlined,
                label: 'Cross-device sync',
              ),
              _FeatureRow(
                icon: Icons.cloud_upload_outlined,
                label: 'Cloud backup',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(
        children: [
          SettingsIconCircle(
            label: '',
            icon: icon,
            bgColor: AppColors.success.withValues(alpha: 0.10),
            color: AppColors.success,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 16,
                color: AppColors.ink,
              ),
            ),
          ),
          const Icon(Icons.check_rounded, size: 18, color: AppColors.success),
        ],
      ),
    );
  }
}
