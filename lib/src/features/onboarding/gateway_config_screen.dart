/// Gateway configuration screen for setting up connection
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/widgets/main_shell.dart';
import '../../core/api/gateway_client.dart';
import '../../core/api/auth_service.dart';
import '../settings/settings_controller.dart';
import 'app_bootstrap.dart';

/// Convert HTTP URL to WebSocket URL
/// - http:// → ws://
/// - https:// → wss://
/// - ws:// or wss:// → unchanged
String _toWebSocketUrl(String url) {
  final trimmed = url.trim();
  
  // Already WebSocket URL
  if (trimmed.startsWith('ws://') || trimmed.startsWith('wss://')) {
    return trimmed;
  }
  
  // Convert HTTP to WebSocket
  if (trimmed.startsWith('http://')) {
    return trimmed.replaceFirst('http://', 'ws://');
  }
  
  if (trimmed.startsWith('https://')) {
    return trimmed.replaceFirst('https://', 'wss://');
  }
  
  // No protocol specified, default to wss://
  return 'wss://$trimmed';
}

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
  bool _showTokenInput = false;
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
              'Enter your OpenClaw Gateway URL to connect.',
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Examples:\n'
              '• https://gateway.example.com\n'
              '• http://192.168.1.100:18789\n'
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
                hintText: 'https://your-gateway.com',
                prefixIcon: const Icon(Icons.link),
                helperText: 'http:// → ws://, https:// → wss://',
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
            
            // Token input section
            Row(
              children: [
                Text(
                  'Already have a token?',
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _showTokenInput = !_showTokenInput;
                    });
                  },
                  child: Text(_showTokenInput ? 'Hide' : 'Enter Token'),
                ),
              ],
            ),
            
            if (_showTokenInput) ...[
              const SizedBox(height: 8),
              TextField(
                controller: _tokenController,
                decoration: InputDecoration(
                  labelText: 'Device Token',
                  hintText: 'Paste your token here',
                  prefixIcon: const Icon(Icons.vpn_key),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 8),
              Text(
                'If you already paired this device, paste the token to skip pairing.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
            
            const SizedBox(height: 32),
            
            // Continue button
            FilledButton.icon(
              onPressed: _canContinue() ? _continue : null,
              icon: const Icon(Icons.arrow_forward_rounded),
              label: const Text(_showTokenInput ? 'Connect with Token' : 'Continue to Pairing'),
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

  bool _canContinue() {
    // Can continue if:
    // 1. Test passed and no token input shown
    // 2. Or token is provided
    if (_showTokenInput && _tokenController.text.trim().isNotEmpty) {
      return _urlController.text.trim().isNotEmpty;
    }
    return _testSuccess == true;
  }

  String get _buttonLabel {
    if (_showTokenInput && _tokenController.text.trim().isNotEmpty) {
      return 'Connect with Token';
    }
    return 'Continue to Pairing';
  }

  Future<void> _testConnection() async {
    setState(() {
      _isTesting = true;
      _testResult = null;
    });

    try {
      final inputUrl = _urlController.text.trim();
      
      // Validate URL format
      if (inputUrl.isEmpty) {
        setState(() {
          _testResult = 'Please enter a Gateway URL';
          _testSuccess = false;
          _isTesting = false;
        });
        return;
      }

      // Convert to WebSocket URL
      final wsUrl = _toWebSocketUrl(inputUrl);
      
      // Try to create a Gateway client and test connection
      final authService = AuthService();
      final client = GatewayClient(
        gatewayUrl: wsUrl,
        authService: authService,
      );

      // Attempt to connect with a short timeout
      try {
        await client.connect().timeout(const Duration(seconds: 5));
        
        // If we get here, connection was successful
        client.disconnect();
        
        if (mounted) {
          setState(() {
            _testResult = 'Connection successful! Gateway is reachable.';
            _testSuccess = true;
            _isTesting = false;
          });
        }
      } catch (e) {
        // Connection failed, but let's check if it's just auth-related
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

  void _continue() async {
    final wsUrl = _toWebSocketUrl(_urlController.text.trim());
    
    // If token provided, save and go directly to main
    if (_showTokenInput && _tokenController.text.trim().isNotEmpty) {
      final token = _tokenController.text.trim();
      
      // Save configuration
      await ref.read(settingsProvider.notifier).setGatewayUrl(wsUrl);
      await ref.read(settingsProvider.notifier).setDeviceToken(token);
      
      // Refresh bootstrap state
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
            builder: (context) => _PairingScreen(
              gatewayUrl: wsUrl,
            ),
          ),
        );
      }
    }
  }
}

/// Simple pairing screen placeholder
class _PairingScreen extends ConsumerStatefulWidget {
  final String gatewayUrl;

  const _PairingScreen({required this.gatewayUrl});

  @override
  ConsumerState<_PairingScreen> createState() => _PairingScreenState();
}

class _PairingScreenState extends ConsumerState<_PairingScreen> {
  String? _pairingCode;
  bool _isPaired = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _startPairing();
  }

  Future<void> _startPairing() async {
    // Simulate pairing
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