/// Error Dialog Widget
/// A reusable dialog for displaying errors with optional retry
library;

import 'package:flutter/material.dart';

import '../../core/errors/app_exception.dart';
import '../../core/errors/error_handler.dart';

/// Error dialog configuration
class ErrorDialogConfig {
  final String? title;
  final bool showErrorCode;
  final bool showTechnicalDetails;
  final String? retryLabel;
  final String? dismissLabel;
  final IconData? customIcon;
  final Color? customColor;

  const ErrorDialogConfig({
    this.title,
    this.showErrorCode = true,
    this.showTechnicalDetails = false,
    this.retryLabel,
    this.dismissLabel,
    this.customIcon,
    this.customColor,
  });
}

/// Shows an error dialog
Future<void> showErrorDialog({
  required BuildContext context,
  required ErrorResult result,
  ErrorDialogConfig config = const ErrorDialogConfig(),
  VoidCallback? onRetry,
}) {
  return showDialog(
    context: context,
    builder: (context) => _ErrorDialogContent(
      result: result,
      config: config,
      onRetry: onRetry,
    ),
  );
}

/// Shows an error dialog from an exception
Future<void> showErrorDialogFromException({
  required BuildContext context,
  required Object error,
  ErrorDialogConfig config = const ErrorDialogConfig(),
  VoidCallback? onRetry,
}) {
  final result = errorHandler.handle(error);
  return showErrorDialog(
    context: context,
    result: result,
    config: config,
    onRetry: onRetry,
  );
}

class _ErrorDialogContent extends StatelessWidget {
  final ErrorResult result;
  final ErrorDialogConfig config;
  final VoidCallback? onRetry;

  const _ErrorDialogContent({
    required this.result,
    required this.config,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = config.customColor ?? _getErrorColor(theme);
    final icon = config.customIcon ?? _getErrorIcon();

    return AlertDialog(
      icon: Icon(
        icon,
        color: color,
        size: 48,
      ),
      title: Text(config.title ?? result.userMessage),
      content: _buildContent(context),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(config.dismissLabel ?? '关闭'),
        ),
        if (onRetry != null && result.isRecoverable)
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              onRetry?.call();
            },
            child: Text(config.retryLabel ?? '重试'),
          ),
      ],
    );
  }

  Widget _buildContent(BuildContext context) {
    final items = <Widget>[];

    // Show error code if available
    if (config.showErrorCode && result.errorCode != null) {
      items.add(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            '错误码: ${result.errorCode}',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 12,
              fontFamily: 'monospace',
            ),
          ),
        ),
      );
    }

    // Show suggested action
    if (result.suggestedAction != null) {
      if (items.isNotEmpty) items.add(const SizedBox(height: 12));
      items.add(
        Text(
          result.suggestedAction!,
          style: const TextStyle(fontSize: 14),
        ),
      );
    }

    // Show technical details if enabled
    if (config.showTechnicalDetails) {
      if (items.isNotEmpty) items.add(const SizedBox(height: 12));
      items.add(
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            result.exception.technicalMessage,
            style: TextStyle(
              fontSize: 11,
              fontFamily: 'monospace',
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items,
    );
  }

  Color _getErrorColor(ThemeData theme) {
    return switch (result.exception) {
      AuthException() => Colors.orange,
      NetworkException() => Colors.blue,
      WebSocketException() => Colors.purple,
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
      StorageException() => Icons.storage,
      ServerException() => Icons.dns,
      ValidationException() => Icons.warning_amber,
      GenericAppException() => Icons.error_outline,
    };
  }
}

/// Auth error dialog - specialized for authentication errors
class AuthErrorDialog extends StatelessWidget {
  final AuthException exception;
  final VoidCallback? onPair;
  final VoidCallback? onRetry;

  const AuthErrorDialog({
    super.key,
    required this.exception,
    this.onPair,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      icon: Icon(
        Icons.lock_outline,
        color: Colors.orange,
        size: 48,
      ),
      title: Text(exception.userMessage),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(exception.suggestedAction ?? '请重新配对设备'),
          const SizedBox(height: 16),
          Text(
            '认证失败可能导致的原因：',
            style: TextStyle(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          _buildReasonList(context),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        if (exception.isRecoverable && onRetry != null)
          FilledButton.tonal(
            onPressed: () {
              Navigator.of(context).pop();
              onRetry?.call();
            },
            child: const Text('重试连接'),
          ),
        if (onPair != null)
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              onPair?.call();
            },
            child: const Text('配对设备'),
          ),
      ],
    );
  }

  Widget _buildReasonList(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: exception.type == AuthErrorType.notPaired ||
              exception.type == AuthErrorType.pairingExpired
          ? [
              _buildReasonItem(context, '设备尚未完成配对'),
              _buildReasonItem(context, '配对信息已过期'),
            ]
          : [
              _buildReasonItem(context, '设备在其他位置被注销'),
              _buildReasonItem(context, '认证令牌已失效'),
              _buildReasonItem(context, '服务器认证策略更新'),
            ],
    );
  }

  Widget _buildReasonItem(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.circle,
            size: 4,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// Shows an auth error dialog
Future<void> showAuthErrorDialog({
  required BuildContext context,
  required AuthException exception,
  VoidCallback? onPair,
  VoidCallback? onRetry,
}) {
  return showDialog(
    context: context,
    builder: (context) => AuthErrorDialog(
      exception: exception,
      onPair: onPair,
      onRetry: onRetry,
    ),
  );
}