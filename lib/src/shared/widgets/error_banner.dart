/// Error Banner Widget
/// A dismissible banner for displaying errors inline
library;

import 'package:flutter/material.dart';

import '../../core/errors/app_exception.dart';
import '../../core/errors/error_handler.dart';

/// Error banner widget for inline error display
class ErrorBanner extends StatelessWidget {
  final ErrorResult result;
  final VoidCallback? onRetry;
  final VoidCallback? onDismiss;
  final bool showIcon;
  final bool showAction;
  final bool isCompact;

  const ErrorBanner({
    super.key,
    required this.result,
    this.onRetry,
    this.onDismiss,
    this.showIcon = true,
    this.showAction = true,
    this.isCompact = false,
  });

  /// Create from exception
  factory ErrorBanner.fromException({
    Key? key,
    required Object error,
    VoidCallback? onRetry,
    VoidCallback? onDismiss,
    bool showIcon = true,
    bool showAction = true,
    bool isCompact = false,
  }) {
    return ErrorBanner(
      key: key,
      result: errorHandler.handle(error),
      onRetry: onRetry,
      onDismiss: onDismiss,
      showIcon: showIcon,
      showAction: showAction,
      isCompact: isCompact,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _getErrorColor(theme);

    return Material(
      color: color.withOpacity(0.1),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: 16,
          vertical: isCompact ? 8 : 12,
        ),
        child: Row(
          children: [
            if (showIcon) ...[
              Icon(
                _getErrorIcon(),
                color: color,
                size: isCompact ? 18 : 20,
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    result.userMessage,
                    style: TextStyle(
                      fontSize: isCompact ? 13 : 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (!isCompact && result.suggestedAction != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      result.suggestedAction!,
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (showAction && onRetry != null && result.isRecoverable)
              TextButton(
                onPressed: onRetry,
                style: TextButton.styleFrom(
                  foregroundColor: color,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  minimumSize: const Size(0, 32),
                ),
                child: const Text('重试'),
              ),
            if (onDismiss != null) ...[
              const SizedBox(width: 4),
              IconButton(
                onPressed: onDismiss,
                icon: const Icon(Icons.close),
                iconSize: 18,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 32,
                  minHeight: 32,
                ),
                color: theme.colorScheme.onSurfaceVariant,
                tooltip: '关闭',
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getErrorColor(ThemeData theme) {
    return switch (result.exception) {
      AuthException() => Colors.orange,
      NetworkException() => Colors.blue,
      WebSocketException() => Colors.purple,
      GatewayException() => Colors.indigo,
      StorageException() => Colors.red,
      ServerException() => Colors.amber,
      ValidationException() => Colors.teal,
      GenericAppException() => theme.colorScheme.error,
    };
  }

  IconData _getErrorIcon() {
    return switch (result.exception) {
      AuthException() => Icons.lock_outline,
      NetworkException() => Icons.wifi_off,
      WebSocketException() => Icons.link_off,
      GatewayException() => Icons.router,
      StorageException() => Icons.storage,
      ServerException() => Icons.dns,
      ValidationException() => Icons.warning_amber,
      GenericAppException() => Icons.error_outline,
    };
  }
}

/// Animated error banner with slide-in animation
class AnimatedErrorBanner extends StatefulWidget {
  final ErrorResult result;
  final VoidCallback? onRetry;
  final VoidCallback? onDismiss;
  final bool showIcon;
  final bool showAction;
  final bool isCompact;
  final Duration animationDuration;

  const AnimatedErrorBanner({
    super.key,
    required this.result,
    this.onRetry,
    this.onDismiss,
    this.showIcon = true,
    this.showAction = true,
    this.isCompact = false,
    this.animationDuration = const Duration(milliseconds: 300),
  });

  @override
  State<AnimatedErrorBanner> createState() => _AnimatedErrorBannerState();
}

class _AnimatedErrorBannerState extends State<AnimatedErrorBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> dismiss() async {
    await _controller.reverse();
    widget.onDismiss?.call();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: ErrorBanner(
        result: widget.result,
        onRetry: widget.onRetry,
        onDismiss: widget.onDismiss != null ? dismiss : null,
        showIcon: widget.showIcon,
        showAction: widget.showAction,
        isCompact: widget.isCompact,
      ),
    );
  }
}

/// Network status banner for connection errors
class NetworkStatusBanner extends StatelessWidget {
  final bool isConnected;
  final bool isConnecting;
  final VoidCallback? onRetry;

  const NetworkStatusBanner({
    super.key,
    required this.isConnected,
    this.isConnecting = false,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    if (isConnected && !isConnecting) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);

    if (isConnecting) {
      return Material(
        color: theme.colorScheme.primaryContainer,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '正在连接...',
                style: TextStyle(
                  color: theme.colorScheme.onPrimaryContainer,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ErrorBanner(
      result: ErrorResult(
        exception: NetworkException(type: NetworkErrorType.noConnection),
        wasLogged: false,
        timestamp: DateTime.now(),
      ),
      onRetry: onRetry,
      isCompact: true,
    );
  }
}

/// Connection status provider for use with providers
class ConnectionStatus {
  final bool isConnected;
  final bool isReconnecting;
  final int reconnectAttempts;
  final AppException? lastError;

  const ConnectionStatus({
    this.isConnected = false,
    this.isReconnecting = false,
    this.reconnectAttempts = 0,
    this.lastError,
  });

  ConnectionStatus copyWith({
    bool? isConnected,
    bool? isReconnecting,
    int? reconnectAttempts,
    AppException? lastError,
    bool clearError = false,
  }) {
    return ConnectionStatus(
      isConnected: isConnected ?? this.isConnected,
      isReconnecting: isReconnecting ?? this.isReconnecting,
      reconnectAttempts: reconnectAttempts ?? this.reconnectAttempts,
      lastError: clearError ? null : (lastError ?? this.lastError),
    );
  }
}