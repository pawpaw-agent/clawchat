/// Gateway configuration screen for setting up connection
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'pairing_screen.dart';

/// Gateway configuration screen
class GatewayConfigScreen extends ConsumerStatefulWidget {
  const GatewayConfigScreen({super.key});

  @override
  ConsumerState<GatewayConfigScreen> createState() => _GatewayConfigScreenState();
}

class _GatewayConfigScreenState extends ConsumerState<GatewayConfigScreen> {
  final _urlController = TextEditingController();
  bool _isTesting = false;
  String? _testResult;
  bool? _testSuccess;

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configure Gateway'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Instructions
            Text(
              'Enter your OpenClaw Gateway URL to connect.',
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Example: https://gateway.example.com or http://192.168.1.100:8080',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 24),
            
            // URL input
            TextField(
              controller: _urlController,
              decoration: InputDecoration(
                labelText: 'Gateway URL',
                hintText: 'https://your-gateway.com',
                prefixIcon: const Icon(Icons.link),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                suffixIcon: _urlController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _urlController.clear();
                          setState(() {
                            _testResult = null;
                            _testSuccess = null;
                          });
                        },
                      )
                    : null,
              ),
              keyboardType: TextInputType.url,
              onChanged: (value) {
                setState(() {
                  _testResult = null;
                  _testSuccess = null;
                });
              },
            ),
            const SizedBox(height: 16),
            
            // Test connection button
            OutlinedButton.icon(
              onPressed: _isTesting || _urlController.text.isEmpty
                  ? null
                  : _testConnection,
              icon: _isTesting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.wifi_find_rounded),
              label: Text(_isTesting ? 'Testing...' : 'Test Connection'),
            ),
            
            // Test result
            if (_testResult != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _testSuccess!
                      ? theme.colorScheme.primaryContainer.withOpacity(0.3)
                      : theme.colorScheme.errorContainer.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      _testSuccess! ? Icons.check_circle : Icons.error,
                      color: _testSuccess!
                          ? theme.colorScheme.primary
                          : theme.colorScheme.error,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _testResult!,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            const Spacer(),
            
            // Continue button
            FilledButton.icon(
              onPressed: _testSuccess == true ? _continue : null,
              icon: const Icon(Icons.arrow_forward_rounded),
              label: const Text('Continue'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Future<void> _testConnection() async {
    setState(() {
      _isTesting = true;
      _testResult = null;
    });

    try {
      final url = _urlController.text.trim();
      
      // Validate URL format
      if (!url.startsWith('http://') && !url.startsWith('https://')) {
        setState(() {
          _testResult = 'URL must start with http:// or https://';
          _testSuccess = false;
          _isTesting = false;
        });
        return;
      }

      // TODO: Implement actual connection test
      // For now, simulate a successful test
      await Future.delayed(const Duration(seconds: 1));
      
      // Simulate success (in real implementation, would actually test connection)
      if (mounted) {
        setState(() {
          _testResult = 'Connection successful! Gateway is reachable.';
          _testSuccess = true;
          _isTesting = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _testResult = 'Connection failed: ${e.toString()}';
          _testSuccess = false;
          _isTesting = false;
        });
      }
    }
  }

  void _continue() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => PairingScreen(
          gatewayUrl: _urlController.text.trim(),
        ),
      ),
    );
  }
}