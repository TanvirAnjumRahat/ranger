import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/notifications_provider.dart';
import '../providers/routine_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/locale_provider.dart';
import '../services/notification_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings'), elevation: 0),
      body: ListView(
        children: [
          // User Profile Section
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primaryContainer,
                  theme.colorScheme.surface,
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: theme.colorScheme.primary,
                  child: Icon(
                    Icons.person,
                    size: 50,
                    color: theme.colorScheme.onPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  user?.email ?? 'Guest',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Routine Ranger User',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Notifications Section
          _buildSectionHeader(context, 'Notifications'),
          _buildSettingsTile(
            context: context,
            icon: Icons.notifications_outlined,
            title: 'Push Notifications',
            subtitle: 'Motivation topic subscription',
            trailing: Consumer<NotificationsProvider>(
              builder: (context, np, _) {
                return Switch(
                  value: np.motivationSubscribed,
                  onChanged: (value) {
                    np.setMotivationSubscribed(value);
                  },
                );
              },
            ),
          ),
          _buildSettingsTile(
            context: context,
            icon: Icons.notifications_active_outlined,
            title: 'Test Notification',
            subtitle: 'Send a test notification now',
            onTap: () async {
              final notifService = NotificationService();
              await notifService.sendTestNotification();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Test notification sent! Check your notification tray.',
                    ),
                    duration: Duration(seconds: 3),
                  ),
                );
              }
            },
          ),
          _buildSettingsTile(
            context: context,
            icon: Icons.refresh_outlined,
            title: 'Reschedule Notifications',
            subtitle: 'Reset all routine notifications',
            onTap: () async {
              final routinesProv = context.read<RoutinesProvider>();
              await routinesProv.rescheduleAllNotifications();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'All notifications rescheduled successfully!',
                    ),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
          ),
          _buildSettingsTile(
            context: context,
            icon: Icons.access_time_outlined,
            title: 'Reminder Settings',
            subtitle: 'Manage notification times',
            onTap: () {
              // Future: Open reminder settings
            },
          ),

          const SizedBox(height: 8),

          // App Preferences
          _buildSectionHeader(context, 'Preferences'),
          _buildSettingsTile(
            context: context,
            icon: Icons.palette_outlined,
            title: 'Theme',
            subtitle: 'Light / Dark mode',
            trailing: Consumer<ThemeProvider>(
              builder: (context, themeProv, _) {
                return Switch(
                  value: themeProv.isDarkMode,
                  onChanged: (value) {
                    themeProv.toggleTheme();
                  },
                );
              },
            ),
          ),
          _buildSettingsTile(
            context: context,
            icon: Icons.language_outlined,
            title: 'Language',
            subtitle: context.watch<LocaleProvider>().languageCode == 'en'
                ? 'English'
                : 'বাংলা (Bengali)',
            onTap: () async {
              final localeProvider = context.read<LocaleProvider>();
              final currentLocale = localeProvider.locale;
              final newLocale = currentLocale.languageCode == 'en'
                  ? const Locale('bn')
                  : const Locale('en');
              await localeProvider.setLocale(newLocale);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Language changed to ${newLocale.languageCode == 'en' ? 'English' : 'বাংলা'}',
                    ),
                  ),
                );
              }
            },
          ),

          const SizedBox(height: 8),

          // Data & Privacy
          _buildSectionHeader(context, 'Data & Privacy'),
          _buildSettingsTile(
            context: context,
            icon: Icons.cloud_upload_outlined,
            title: 'Backup & Sync',
            subtitle: 'Cloud sync enabled',
            onTap: () {
              // Future: Backup settings
            },
          ),
          _buildSettingsTile(
            context: context,
            icon: Icons.delete_outline,
            title: 'Clear Cache',
            subtitle: 'Free up storage space',
            onTap: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Clear Cache'),
                  content: const Text(
                    'This will clear temporary data. Your routines will not be affected.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Clear'),
                    ),
                  ],
                ),
              );
              if (confirmed == true && context.mounted) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Cache cleared')));
              }
            },
          ),

          const SizedBox(height: 8),

          // About & Help
          _buildSectionHeader(context, 'About'),
          _buildSettingsTile(
            context: context,
            icon: Icons.info_outline,
            title: 'About Routine Ranger',
            subtitle: 'Version 1.0.0',
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'Routine Ranger',
                applicationVersion: '1.0.0',
                applicationIcon: const Icon(Icons.check_circle, size: 48),
                children: [
                  const Text(
                    'A powerful routine management app with Firebase integration.',
                  ),
                ],
              );
            },
          ),
          _buildSettingsTile(
            context: context,
            icon: Icons.help_outline,
            title: 'Help & Support',
            subtitle: 'Get help with the app',
            onTap: () {
              // Future: Help screen
            },
          ),
          _buildSettingsTile(
            context: context,
            icon: Icons.privacy_tip_outlined,
            title: 'Privacy Policy',
            onTap: () {
              // Future: Privacy policy
            },
          ),

          const SizedBox(height: 8),

          // Sign Out
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: FilledButton.tonalIcon(
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Sign Out'),
                    content: const Text('Are you sure you want to sign out?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Sign Out'),
                      ),
                    ],
                  ),
                );
                if (confirmed == true && context.mounted) {
                  context.read<AuthProvider>().signOut();
                }
              },
              icon: const Icon(Icons.logout),
              label: const Text('Sign Out'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    String? subtitle,
    VoidCallback? onTap,
    Widget? trailing,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing:
          trailing ?? (onTap != null ? const Icon(Icons.chevron_right) : null),
      onTap: onTap,
    );
  }
}
