/// Device pairing screen for authentication with Gateway
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../settings/settings_controller.dart';
import '../../chat/chat_screen.dart';

/// Pairing screen for device authentication
class PairingScreen extends ConsumerStatefulWidget {
  final String gatewayUrl;

  const PairingScreen({
    super.key,
    required this.gatewayUrl,
  });

  @override
  ConsumerState<PairingScreen> createState() => _PairingScreenState();
}

class _PairingScreenState extends ConsumerState<PairingScreen> {
  String? _pairingCode;
  bool _isPairing = false;
  bool _isPaired = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _startPairing();
  }

  Future<void> _startPairing() async {
    setState(() {
      _isPairing = true;
      _error = null;
    });

    try {
      // TODO: Implement actual pairing flow
      // For now, simulate pairing with mock data
      
      // Simulate getting a pairing code from Gateway
      await Future.delayed(const Duration(seconds: 1));
      
      if (mounted) {
        setState(() {
          _pairingCode = 'CLAW-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';
        });
      }

      // Simulate waiting for pairing confirmation
      await Future.delayed(const Duration(seconds: 2));
      
      if (mounted) {
        // Save configuration
        await ref.read(settingsProvider.notifier).setGatewayUrl(widget.gatewayUrl);
        await ref.read(settingsProvider.notifier).setDeviceToken('mock-device-token-${DateTime.now().millisecondsSinceEpoch}');
        
        setState(() {
          _isPairing = false;
          _isPaired = true;
        });

        // Navigate to chat after a short delay
        await Future.delayed(const Duration(seconds: 1));
        
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => const ChatScreen(),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isPairing = false;
          _error = 'Pairing failed: ${e.toString()}';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Device Pairing'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status icon
            _buildStatusIcon(theme),
            const SizedBox(height: 32),
            
            // Status text
            _buildStatusText(theme),
            const SizedBox(height: 16),
            
            // Pairing code or instructions
            if (_pairingCode != null && !_isPaired) ...[
              _buildPairingCodeCard(theme),
              const SizedBox(height: 16),
              Text(
                'Enter this code on your Gateway admin panel to complete pairing.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
                textAlign: TextAlign.center,
              ),
            ],
            
            // Success message
            if (_isPaired) ...[
              const SizedBox(height: 16),
              Text(
                'Device paired successfully! Redirecting to chat...',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.primary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            
            // Error message
            if (_error != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _error!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _startPairing,
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIcon(ThemeData theme) {
    if (_isPaired) {
      return Icon(
        Icons.check_circle_outline,
        size: 80,
        color: theme.colorScheme.primary,
      );
    }
    
    if (_error != null) {
      return Icon(
        Icons.error_outline,
        size: 80,
        color: theme.colorScheme.error,
      );
    }
    
    return SizedBox(
      width: 80,
      height: 80,
      child: CircularProgressIndicator(
        strokeWidth: 4,
        color: theme.colorScheme.primary,
      ),
    );
  }

  Widget _buildStatusText(ThemeData theme) {
    if (_isPaired) {
      return Text(
        'Paired!',
        style: theme.textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.primary,
        ),
        textAlign: TextAlign.center,
      );
    }
    
    if (_error != null) {
      return Text(
        'Pairing Failed',
        style: theme.textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.error,
        ),
        textAlign: TextAlign.center,
      );
    }
    
    return Text(
      'Pairing Device...',
      style: theme.textTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.bold,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildPairingCodeCard(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(
              'Your Pairing Code',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _pairingCode!,
              style: theme.textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: 4,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            IconButton(
              onPressed: () {
                // Copy to clipboard would go here
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Code copied to clipboard'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              icon: const Icon(Icons.copy_rounded),
              tooltip: 'Copy code',
            ),
          ],
        ),
      ),
    );
  }
}