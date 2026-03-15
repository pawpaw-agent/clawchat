/// Welcome/Onboarding screen for first-time users
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'gateway_config_screen.dart';

/// Onboarding screen shown to first-time users
class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Logo and title
              const Spacer(),
              _buildHeader(context),
              const Spacer(),
              
              // Features list
              _buildFeatures(context),
              const Spacer(),
              
              // Get started button
              _buildGetStartedButton(context),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      children: [
        // App icon
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Icon(
            Icons.chat_bubble_outline_rounded,
            size: 64,
            color: theme.colorScheme.onPrimaryContainer,
          ),
        ),
        const SizedBox(height: 24),
        
        // App name
        Text(
          'ClawChat',
          style: theme.textTheme.headlineLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 8),
        
        // Tagline
        Text(
          'Direct & Secure AI Chat',
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildFeatures(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      children: [
        _buildFeatureItem(
          context,
          icon: Icons.security_outlined,
          title: 'Direct Connection',
          description: 'Connect directly to your Gateway without intermediaries',
        ),
        const SizedBox(height: 16),
        _buildFeatureItem(
          context,
          icon: Icons.lock_outline,
          title: 'End-to-End Encrypted',
          description: 'Your messages stay private and secure',
        ),
        const SizedBox(height: 16),
        _buildFeatureItem(
          context,
          icon: Icons.devices_outlined,
          title: 'Multi-Device',
          description: 'Seamlessly chat from any paired device',
        ),
      ],
    );
  }

  Widget _buildFeatureItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
  }) {
    final theme = Theme.of(context);
    
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer.withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGetStartedButton(BuildContext context) {
    return FilledButton.icon(
      onPressed: () {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const GatewayConfigScreen(),
          ),
        );
      },
      icon: const Icon(Icons.arrow_forward_rounded),
      label: const Text('Get Started'),
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(
          horizontal: 32,
          vertical: 16,
        ),
      ),
    );
  }
}