import 'package:aura_farming/utils/theme_data.dart';
import 'package:flutter/material.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('More'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSettingsSection(context),
          const SizedBox(height: 24),
          _buildAboutSection(context),
        ],
      ),
    );
  }

  Widget _buildSettingsSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.magicalCardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Settings',
            style: Theme.of(context).textTheme.displayMedium,
          ),
          const SizedBox(height: 16),
          _buildSettingsItem(
            context,
            Icons.notifications,
            'Notifications',
            'Manage your notification preferences',
          ),
          _buildSettingsItem(
            context,
            Icons.palette,
            'Appearance',
            'Customize the app theme',
          ),
          _buildSettingsItem(
            context,
            Icons.security,
            'Privacy',
            'Privacy and data settings',
          ),
          _buildSettingsItem(
            context,
            Icons.backup,
            'Backup & Sync',
            'Manage your data backup',
          ),
        ],
      ),
    );
  }

  Widget _buildAboutSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.magicalCardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'About',
            style: Theme.of(context).textTheme.displayMedium,
          ),
          const SizedBox(height: 16),
          _buildAboutItem(
            context,
            Icons.info,
            'About Aura Farming',
            'Learn more about the app',
          ),
          _buildAboutItem(
            context,
            Icons.star,
            'Rate the App',
            'Share your experience',
          ),
          _buildAboutItem(
            context,
            Icons.share,
            'Share with Friends',
            'Spread the magic',
          ),
          _buildAboutItem(
            context,
            Icons.help,
            'Help & Support',
            'Get assistance',
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsItem(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
  ) {
    return ListTile(
      leading: Icon(icon, color: Colors.purple[300]),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      subtitle: Text(subtitle, style: const TextStyle(color: Colors.white70)),
      trailing: const Icon(Icons.chevron_right, color: Colors.white54),
      onTap: () {
        // Handle settings item tap
      },
    );
  }

  Widget _buildAboutItem(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
  ) {
    return ListTile(
      leading: Icon(icon, color: Colors.blue[300]),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      subtitle: Text(subtitle, style: const TextStyle(color: Colors.white70)),
      trailing: const Icon(Icons.chevron_right, color: Colors.white54),
      onTap: () {
        // Handle about item tap
      },
    );
  }
}