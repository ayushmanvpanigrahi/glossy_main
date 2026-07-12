import 'package:flutter/material.dart';
import '../../../../app_colors.dart';
import '../widgets/settings_rows.dart';

class AccountSection extends StatelessWidget {
  const AccountSection({
    super.key,
    required this.userName,
    required this.userEmail,
    required this.isPro,
    required this.onAccountTap,
    required this.onProTap,
  });

  final String userName;
  final String userEmail;
  final bool isPro;
  final VoidCallback onAccountTap;
  final VoidCallback onProTap;

  @override
  Widget build(BuildContext context) {
    final initials = userName
        .trim()
        .split(' ')
        .map((w) => w.isNotEmpty ? w[0] : '')
        .take(2)
        .join()
        .toUpperCase();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SettingsSectionLabel('Account'),
        SettingsGroup(
          children: [
            SettingsNavRow(
              onTap: onAccountTap,
              iconWidget: Container(
                width: 34,
                height: 34,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  initials,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.paper,
                  ),
                ),
              ),
              title: userName,
              subtitle: userEmail,
            ),
            SettingsNavRow(
              onTap: onProTap,
              iconWidget: const SettingsIconCircle(label: '★'),
              title: 'Glossy Pro',
              trailingWidget: SettingsBadge(
                label: isPro ? 'Pro plan' : 'Free plan',
              ),
            ),
          ],
        ),
      ],
    );
  }
}
