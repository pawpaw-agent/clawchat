/// Settings screen with Gateway configuration
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'settings_controller.dart';

/// Settings screen
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late final TextEditingController _gatewayUrlController;
  late final TextEditingController _deviceTokenController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _gatewayUrlController = TextEditingController();
    _deviceTokenController = TextEditingController();
    
    // Load current values
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final settings = ref.read(settingsProvider);
      _gatewayUrlController.text = settings.gatewayUrl ?? '';
      _deviceTokenController.text = settings.deviceToken ?? '';
    });
  }

  @override
  void dispose() {
    _gatewayUrlController.dispose();
    _deviceTokenController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Gateway Configuration Section
          _buildSectionHeader(theme, 'Gateway Configuration'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _gatewayUrlController,
                    decoration: const InputDecoration(
                      labelText: 'Gateway URL',
                      hintText: 'wss://gateway.example.com',
                      prefixIcon: Icon(Icons.link),
                      helperText: 'WebSocket URL (ws:// or wss://)',
                    ),
                    keyboardType: TextInputType.url,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _deviceTokenController,
                    decoration: const InputDecoration(
                      labelText: 'Device Token',
                      hintText: 'Paste your token here',
                      prefixIcon: Icon(Icons.vpn_key),
                      helperText: 'Optional: Skip pairing with existing token',
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _isSaving ? null : _saveSettings,
                          icon: _isSaving
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.save),
                          label: const Text('Save & Connect'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Connection Status Section
          _buildSectionHeader(theme, 'Connection Status'),
          Card(
            child: ListTile(
              leading: Icon(
                settings.gatewayUrl != null && settings.gatewayUrl!.isNotEmpty
                    ? Icons.check_circle
                    : Icons.cancel,
                color: settings.gatewayUrl != null && settings.gatewayUrl!.isNotEmpty
                    ? theme.colorScheme.primary
                    : theme.colorScheme.error,
              ),
              title: Text(
                settings.gatewayUrl != null && settings.gatewayUrl!.isNotEmpty
                    ? 'Gateway Configured'
                    : 'Not Configured',
              ),
              subtitle: Text(
                settings.gatewayUrl ?? 'Enter Gateway URL above',
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Theme Section
          _buildSectionHeader(theme, 'Appearance'),
          Card(
            child: Column(
              children: [
                RadioListTile<ThemeMode>(
                  title: const Text('System Default'),
                  value: ThemeMode.system,
                  groupValue: settings.themeMode,
                  onChanged: (value) => _setThemeMode(value!),
                ),
                RadioListTile<ThemeMode>(
                  title: const Text('Light'),
                  value: ThemeMode.light,
                  groupValue: settings.themeMode,
                  onChanged: (value) => _setThemeMode(value!),
                ),
                RadioListTile<ThemeMode>(
                  title: const Text('Dark'),
                  value: ThemeMode.dark,
                  groupValue: settings.themeMode,
                  onChanged: (value) => _setThemeMode(value!),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // About Section
          _buildSectionHeader(theme, 'About'),
          Card(
            child: Column(
              children: [
                ListTile(
                  title: const Text('ClawChat'),
                  subtitle: const Text('Direct & Secure AI Chat'),
                  trailing: const Text('v1.0.0'),
                ),
                ListTile(
                  title: const Text('OpenClaw'),
                  subtitle: const Text('https://openclaw.ai'),
                  trailing: const Icon(Icons.open_in_new),
                  onTap: () {
                    // Open URL
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(ThemeData theme, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Future<void> _saveSettings() async {
    setState(() {
      _isSaving = true;
    });

    try {
      final gatewayUrl = _gatewayUrlController.text.trim();
      final deviceToken = _deviceTokenController.text.trim();

      if (gatewayUrl.isNotEmpty) {
        await ref.read(settingsProvider.notifier).setGatewayUrl(gatewayUrl);
      }

      if (deviceToken.isNotEmpty) {
        await ref.read(settingsProvider.notifier).setDeviceToken(deviceToken);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Settings saved')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _setThemeMode(ThemeMode mode) async {
    await ref.read(settingsProvider.notifier).setThemeMode(mode);
  }
}