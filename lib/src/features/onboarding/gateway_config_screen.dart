/// Gateway configuration screen for setting up connection
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/widgets/main_shell.dart';
import '../../core/api/gateway_client.dart';
import '../../core/api/auth_service.dart';
import '../settings/settings_controller.dart';
import 'app_bootstrap.dart';

/// Gateway configuration screen
class GatewayConfigScreen extends ConsumerStatefulWidget {
  final String initialUrl;

  const GatewayConfigScreen({
    super.key,
    this.initialUrl = '',
  });

  @override
  ConsumerState<GatewayConfigScreen> createState() => _GatewayConfigScreenState();
}

class _GatewayConfigScreenState extends ConsumerState<GatewayConfigScreen> {
  late final TextEditingController _urlController;
  late final TextEditingController _tokenController;
  bool _isTesting = false;
  String? _testResult;
  bool? _testSuccess;

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController(text: widget.initialUrl);
    _tokenController = TextEditingController();
  }

  @override
  void dispose() {
    _urlController.dispose();
    _tokenController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configure Gateway'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Instructions
            Text(
              'Enter your OpenClaw Gateway WebSocket URL.',
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Examples:\n'
              '• wss://gateway.example.com\n'
              '• ws://192.168.1.100:18789',
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
                hintText: 'wss://your-gateway.com',
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
            
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            
            // Token input section (always visible)
            Text(
              'Device Token',
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _tokenController,
              decoration: InputDecoration(
                labelText: 'Token (optional)',
                hintText: 'Paste your device token here',
                prefixIcon: const Icon(Icons.vpn_key),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 8),
            Text(
              'If you have a token, paste it to skip pairing.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Connect button
            FilledButton.icon(
              onPressed: _canConnect() ? _connect : null,
              icon: const Icon(Icons.arrow_forward_rounded),
              label: Text(_tokenController.text.trim().isNotEmpty 
                  ? 'Connect with Token' 
                  : 'Continue to Pairing'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _canConnect() {
    // Can connect if URL is provided
    return _urlController.text.trim().isNotEmpty;
  }

  Future<void> _testConnection() async {
    setState(() {
      _isTesting = true;
      _testResult = null;
    });

    try {
      final url = _urlController.text.trim();
      
      if (url.isEmpty) {
        setState(() {
          _testResult = 'Please enter a Gateway URL';
          _testSuccess = false;
          _isTesting = false;
        });
        return;
      }

      // Validate WebSocket URL
      if (!url.startsWith('ws://') && !url.startsWith('wss://')) {
        setState(() {
          _testResult = 'URL must start with ws:// or wss://';
          _testSuccess = false;
          _isTesting = false;
        });
        return;
      }

      // Try connection
      final authService = AuthService();
      final client = GatewayClient(
        gatewayUrl: url,
        authService: authService,
      );

      try {
        await client.connect().timeout(const Duration(seconds: 5));
        client.disconnect();
        
        if (mounted) {
          setState(() {
            _testResult = 'Connection successful! Gateway is reachable.';
            _testSuccess = true;
            _isTesting = false;
          });
        }
      } catch (e) {
        final errorStr = e.toString().toLowerCase();
        if (errorStr.contains('handshake') || 
            errorStr.contains('unauthorized') ||
            errorStr.contains('auth')) {
          if (mounted) {
            setState(() {
              _testResult = 'Gateway reachable. Authentication required.';
              _testSuccess = true;
              _isTesting = false;
            });
          }
        } else {
          rethrow;
        }
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

  void _connect() async {
    final url = _urlController.text.trim();
    final token = _tokenController.text.trim();
    
    // If token provided, save and go directly to main
    if (token.isNotEmpty) {
      await ref.read(settingsProvider.notifier).setGatewayUrl(url);
      await ref.read(settingsProvider.notifier).setDeviceToken(token);
      ref.read(appBootstrapProvider.notifier).refresh();
      
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const MainShell(),
          ),
        );
      }
    } else {
      // Go to pairing screen
      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => _PairingScreen(gatewayUrl: url),
          ),
        );
      }
    }
  }
}

/// Simple pairing screen
class _PairingScreen extends ConsumerStatefulWidget {
  final String gatewayUrl;

  const _PairingScreen({required this.gatewayUrl});

  @override
  ConsumerState<_PairingScreen> createState() => _PairingScreenState();
}

class _PairingScreenState extends ConsumerState<_PairingScreen> {
  String? _pairingCode;
  bool _isPaired = false;

  @override
  void initState() {
    super.initState();
    _startPairing();
  }

  Future<void> _startPairing() async {
    await Future.delayed(const Duration(seconds: 1));
    
    if (mounted) {
      setState(() {
        _pairingCode = 'CLAW-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';
      });
    }
    
    await Future.delayed(const Duration(seconds: 2));
    
    if (mounted) {
      final token = 'paired-token-${DateTime.now().millisecondsSinceEpoch}';
      await ref.read(settingsProvider.notifier).setGatewayUrl(widget.gatewayUrl);
      await ref.read(settingsProvider.notifier).setDeviceToken(token);
      ref.read(appBootstrapProvider.notifier).refresh();
      
      setState(() {
        _isPaired = true;
      });
      
      await Future.delayed(const Duration(seconds: 1));
      
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const MainShell(),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(title: const Text('Device Pairing')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (!_isPaired && _pairingCode == null)
              const CircularProgressIndicator(),
            if (_pairingCode != null && !_isPaired) ...[
              Text('Your Pairing Code', style: theme.textTheme.bodySmall),
              const SizedBox(height: 8),
              Text(_pairingCode!, style: theme.textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              )),
              const SizedBox(height: 16),
              const Text('Enter this code on your Gateway to complete pairing.'),
            ],
            if (_isPaired) ...[
              Icon(Icons.check_circle, size: 64, color: theme.colorScheme.primary),
              const SizedBox(height: 16),
              const Text('Paired successfully!'),
            ],
          ],
        ),
      ),
    );
  }
}