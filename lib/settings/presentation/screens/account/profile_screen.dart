import 'package:flutter/material.dart';
import '../../../../app_colors.dart';
import '../../providers/settings_state.dart';
import '../../widgets/settings_rows.dart';
import '../../widgets/settings_scaffold.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SettingsDetailScaffold(
      title: 'Profile',
      body: ListView(
        padding: const EdgeInsets.only(top: 8, bottom: 40),
        children: [
          const SizedBox(height: 24),
          Center(
            child: Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const Text(
                'AM',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 26,
                  fontWeight: FontWeight.w600,
                  color: AppColors.paper,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Center(
            child: Text(
              SettingsState.userName,
              style: TextStyle(
                fontFamily: 'PlayfairDisplay',
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.ink,
              ),
            ),
          ),
          const SizedBox(height: 4),
          const Center(
            child: Text(
              SettingsState.userEmail,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                color: AppColors.muted,
              ),
            ),
          ),
          const SizedBox(height: 28),
          const SettingsSectionLabel('Account details'),
          SettingsGroup(
            children: [
              SettingsNavRow(
                iconWidget: const SettingsIconCircle(
                  label: '✎',
                  icon: Icons.person_outline,
                ),
                title: 'Edit name',
                trailingText: SettingsState.userName,
                onTap: () {},
              ),
              SettingsNavRow(
                iconWidget: const SettingsIconCircle(
                  label: '@',
                  icon: Icons.alternate_email,
                ),
                title: 'Email',
                trailingText: SettingsState.userEmail,
                onTap: () {},
              ),
              SettingsNavRow(
                iconWidget: const SettingsIconCircle(
                  label: '🔑',
                  icon: Icons.lock_outline,
                ),
                title: 'Change password',
                onTap: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }
}
