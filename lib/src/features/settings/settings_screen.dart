/// Settings screen
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _gatewayUrlController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _gatewayUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          // Gateway settings
          ListTile(
            leading: const Icon(Icons.dns),
            title: const Text('Gateway URL'),
            subtitle: const Text('ws://localhost:18789'),
            onTap: () => _showGatewayUrlDialog(),
          ),
          
          const Divider(),
          
          // Device info
          ListTile(
            leading: const Icon(Icons.devices),
            title: const Text('Device ID'),
            subtitle: const Text('Not configured'),
          ),
          
          const Divider(),
          
          // Auth
          ListTile(
            leading: const Icon(Icons.key),
            title: const Text('Authentication'),
            subtitle: const Text('Not authenticated'),
          ),
          
          const Divider(),
          
          // Clear data
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: const Text('Clear All Data', 
              style: TextStyle(color: Colors.red)),
            onTap: () => _showClearDataDialog(),
          ),
          
          const Divider(),
          
          // About
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('About'),
            subtitle: const Text('ClawChat v0.1.0'),
          ),
        ],
      ),
    );
  }

  void _showGatewayUrlDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Gateway URL'),
        content: TextField(
          controller: _gatewayUrlController,
          decoration: const InputDecoration(
            hintText: 'ws://localhost:18789',
            labelText: 'WebSocket URL',
          ),
          keyboardType: TextInputType.url,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              // TODO: Save gateway URL
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showClearDataDialog() {
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
            onPressed: () {
              // TODO: Clear all data
              Navigator.pop(context);
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
}