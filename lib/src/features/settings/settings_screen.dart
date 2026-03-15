/// Settings screen
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'settings_controller.dart';
import '../../core/storage/app_settings.dart';
import '../../core/constants.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(settingsProvider.notifier).refresh(),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: settings.isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(context, ref, settings),
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref, SettingsState settings) {
    if (settings.error != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(settings.error!),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Dismiss',
              textColor: Colors.white,
              onPressed: () => ref.read(settingsProvider.notifier).clearError(),
            ),
          ),
        );
      });
    }

    return ListView(
      children: [
        // Gateway Settings Section
        _buildSectionHeader('Gateway'),
        _buildGatewayTile(context, ref, settings),
        const Divider(),

        // Authentication Section
        _buildSectionHeader('Authentication'),
        _buildAuthTile(context, ref, settings),
        _buildClearAuthTile(context, ref, settings),
        const Divider(),

        // Appearance Section
        _buildSectionHeader('Appearance'),
        _buildThemeTile(context, ref, settings),
        _buildLanguageTile(context, ref, settings),
        const Divider(),

        // Data Section
        _buildSectionHeader('Data'),
        _buildClearDataTile(context, ref, settings),
        const Divider(),

        // About Section
        _buildSectionHeader('About'),
        _buildAboutTile(),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  // ==================== Gateway Section ====================

  Widget _buildGatewayTile(BuildContext context, WidgetRef ref, SettingsState settings) {
    return ListTile(
      leading: const Icon(Icons.dns),
      title: const Text('Gateway URL'),
      subtitle: Text(
        settings.gatewayUrl ?? AppConstants.defaultGatewayUrl,
        style: TextStyle(
          color: settings.gatewayUrl == null ? Colors.grey : null,
        ),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _showGatewayUrlDialog(context, ref, settings),
    );
  }

  void _showGatewayUrlDialog(BuildContext context, WidgetRef ref, SettingsState settings) {
    final controller = TextEditingController(
      text: settings.gatewayUrl ?? AppConstants.defaultGatewayUrl,
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Gateway URL'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'ws://localhost:18789',
                labelText: 'WebSocket URL',
                helperText: 'Enter the Gateway WebSocket URL',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.url,
              autofocus: true,
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                controller.text = AppConstants.defaultGatewayUrl;
              },
              child: Text('Reset to default (${AppConstants.defaultGatewayUrl})'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final url = controller.text.trim();
              if (url.isNotEmpty) {
                await ref.read(settingsProvider.notifier).setGatewayUrl(url);
                if (context.mounted) Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  // ==================== Authentication Section ====================

  Widget _buildAuthTile(BuildContext context, WidgetRef ref, SettingsState settings) {
    return ListTile(
      leading: Icon(
        settings.isAuthenticated ? Icons.verified_user : Icons.warning_amber,
        color: settings.isAuthenticated ? Colors.green : Colors.orange,
      ),
      title: const Text('Authentication Status'),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            settings.isAuthenticated ? 'Device Paired' : 'Not Paired',
          ),
          if (settings.maskedDeviceToken != null)
            Text(
              'Token: ${settings.maskedDeviceToken}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          if (settings.maskedPublicKey != null)
            Text(
              'Key: ${settings.maskedPublicKey}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
        ],
      ),
      isThreeLine: settings.isAuthenticated,
    );
  }

  Widget _buildClearAuthTile(BuildContext context, WidgetRef ref, SettingsState settings) {
    return ListTile(
      leading: const Icon(Icons.key_off),
      title: const Text('Clear Authentication'),
      subtitle: const Text('Remove device token and public key'),
      enabled: settings.isAuthenticated,
      onTap: settings.isAuthenticated
          ? () => _showClearAuthDialog(context, ref)
          : null,
    );
  }

  void _showClearAuthDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Authentication?'),
        content: const Text(
          'This will remove your device token and public key. '
          'You will need to pair with the Gateway again to continue.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              await ref.read(settingsProvider.notifier).clearAuthInfo();
              if (context.mounted) Navigator.pop(context);
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.orange,
            ),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  // ==================== Appearance Section ====================

  Widget _buildThemeTile(BuildContext context, WidgetRef ref, SettingsState settings) {
    return ListTile(
      leading: Icon(settings.themeMode.icon),
      title: const Text('Theme'),
      subtitle: Text(settings.themeMode.displayName),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _showThemeDialog(context, ref, settings),
    );
  }

  void _showThemeDialog(BuildContext context, WidgetRef ref, SettingsState settings) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose Theme'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: AppThemeMode.values.map((mode) {
            return RadioListTile<AppThemeMode>(
              title: Row(
                children: [
                  Icon(mode.icon, size: 20),
                  const SizedBox(width: 12),
                  Text(mode.displayName),
                ],
              ),
              value: mode,
              groupValue: settings.themeMode,
              onChanged: (value) {
                if (value != null) {
                  ref.read(settingsProvider.notifier).setThemeMode(value);
                  Navigator.pop(context);
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildLanguageTile(BuildContext context, WidgetRef ref, SettingsState settings) {
    return ListTile(
      leading: const Icon(Icons.language),
      title: const Text('Language'),
      subtitle: Text(AppLanguage.getDisplayName(settings.language)),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _showLanguageDialog(context, ref, settings),
    );
  }

  void _showLanguageDialog(BuildContext context, WidgetRef ref, SettingsState settings) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose Language'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: AppLanguage.supportedLanguages.map((lang) {
            return RadioListTile<String>(
              title: Text(AppLanguage.getDisplayName(lang)),
              value: lang,
              groupValue: settings.language,
              onChanged: (value) {
                if (value != null) {
                  ref.read(settingsProvider.notifier).setLanguage(value);
                  Navigator.pop(context);
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  // ==================== Data Section ====================

  Widget _buildClearDataTile(BuildContext context, WidgetRef ref, SettingsState settings) {
    return ListTile(
      leading: const Icon(Icons.delete_forever, color: Colors.red),
      title: const Text('Clear All Data'),
      subtitle: const Text('Remove all cached data, credentials, and settings'),
      onTap: () => _showClearDataDialog(context, ref),
    );
  }

  void _showClearDataDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Data?'),
        content: const Text(
          'This will delete all cached data, credentials, and settings. '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              await ref.read(settingsProvider.notifier).clearAllSettings();
              if (context.mounted) Navigator.pop(context);
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  // ==================== About Section ====================

  Widget _buildAboutTile() {
    return ListTile(
      leading: const Icon(Icons.info),
      title: const Text('About'),
      subtitle: Text('${AppConstants.appName} v${AppConstants.appVersion}'),
    );
  }
}