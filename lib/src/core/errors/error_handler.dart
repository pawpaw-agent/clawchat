/// Unified error handler
/// Provides centralized error handling, logging, and user notification
library;

import 'package:flutter/material.dart';
import 'package:logger/logger.dart';

import 'app_exception.dart';
import '../../shared/utils/logger.dart';

/// Error handling result
class ErrorResult {
  final AppException exception;
  final bool wasLogged;
  final DateTime timestamp;

  const ErrorResult({
    required this.exception,
    required this.wasLogged,
    required this.timestamp,
  });

  /// User-friendly message
  String get userMessage => exception.userMessage;

  /// Suggested action for the user
  String? get suggestedAction => exception.suggestedAction;

  /// Whether this error is recoverable
  bool get isRecoverable => exception.isRecoverable;

  /// Error code if available
  String? get errorCode => exception.errorCode;
}

/// Callback type for retry actions
typedef RetryCallback = Future<void> Function();

/// Centralized error handler
class ErrorHandler {
  final Logger _logger;

  ErrorHandler({Logger? logger}) : _logger = logger ?? createLogger('ErrorHandler');

  /// Handle an error and return a structured result
  ErrorResult handle(
    Object error, {
    StackTrace? stackTrace,
    String? context,
    bool shouldLog = true,
  }) {
    // Classify the exception
    final appException = ExceptionClassifier.classify(error);

    // Log the error
    if (shouldLog) {
      _logError(appException, stackTrace, context);
    }

    return ErrorResult(
      exception: appException,
      wasLogged: shouldLog,
      timestamp: DateTime.now(),
    );
  }

  /// Handle error with automatic UI feedback
  Future<ErrorResult> handleErrorWithContext(
    Object error, {
    required BuildContext context,
    StackTrace? stackTrace,
    String? contextName,
    RetryCallback? onRetry,
    bool showDialog = false,
    bool showSnackBar = true,
  }) async {
    final result = handle(
      error,
      stackTrace: stackTrace,
      context: contextName,
    );

    // Show UI feedback
    if (showSnackBar && context.mounted) {
      _showErrorFeedback(context, result, onRetry: onRetry);
    } else if (showDialog && context.mounted) {
      _showErrorDialog(context, result, onRetry: onRetry);
    }

    return result;
  }

  /// Log error details
  void _logError(
    AppException exception,
    StackTrace? stackTrace,
    String? context,
  ) {
    final contextPrefix = context != null ? '[$context] ' : '';

    if (exception is GenericAppException) {
      _logger.e(
        '${contextPrefix}${exception.technicalMessage}',
        error: exception.originalError,
        stackTrace: exception.stackTrace ?? stackTrace,
      );
    } else {
      _logger.e(
        '${contextPrefix}${exception.technicalMessage}',
        error: exception,
        stackTrace: stackTrace,
      );
    }
  }

  /// Show error as snackbar with optional retry
  void _showErrorFeedback(
    BuildContext context,
    ErrorResult result, {
    RetryCallback? onRetry,
  }) {
    final color = _getErrorColor(result.exception);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: color),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    result.userMessage,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  if (result.suggestedAction != null)
                    Text(
                      result.suggestedAction!,
                      style: TextStyle(
                        fontSize: 12,
                        color: color.withOpacity(0.8),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: Colors.grey[900],
        duration: const Duration(seconds: 4),
        action: onRetry != null && result.isRecoverable
            ? SnackBarAction(
                label: '重试',
                textColor: color,
                onPressed: () async {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  await onRetry();
                },
              )
            : null,
      ),
    );
  }

  /// Show error as dialog
  void _showErrorDialog(
    BuildContext context,
    ErrorResult result, {
    RetryCallback? onRetry,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(
          _getErrorIcon(result.exception),
          color: _getErrorColor(result.exception),
          size: 48,
        ),
        title: Text(result.userMessage),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (result.errorCode != null)
              Text(
                '错误码: ${result.errorCode}',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            if (result.suggestedAction != null) ...[
              const SizedBox(height: 8),
              Text(
                result.suggestedAction!,
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('关闭'),
          ),
          if (onRetry != null && result.isRecoverable)
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop();
                onRetry();
              },
              child: const Text('重试'),
            ),
        ],
      ),
    );
  }

  /// Get color based on error type
  Color _getErrorColor(AppException exception) {
    return switch (exception) {
      AuthException() => Colors.orange,
      NetworkException() => Colors.blue,
      WebSocketException() => Colors.purple,
      GatewayException() => Colors.indigo,
      StorageException() => Colors.red,
      ServerException() => Colors.amber,
      ValidationException() => Colors.teal,
      GenericAppException() => Colors.grey,
      _ => Colors.grey,
    };
  }

  /// Get icon based on error type
  IconData _getErrorIcon(AppException exception) {
    return switch (exception) {
      AuthException() => Icons.lock_outline,
      NetworkException() => Icons.wifi_off,
      WebSocketException() => Icons.link_off,
      GatewayException() => Icons.router,
      StorageException() => Icons.storage,
      ServerException() => Icons.dns,
      ValidationException() => Icons.warning_amber,
      GenericAppException() => Icons.error_outline,
      _ => Icons.error_outline,
    };
  }
}

/// Global error handler instance
final errorHandler = ErrorHandler();

/// Extension for easy error handling in widgets
extension ErrorHandlingExtension on Object {
  /// Convert to AppException
  AppException toAppException() {
    if (this is AppException) return this as AppException;
    return ExceptionClassifier.classify(this);
  }
}

/// Mixin for controllers to handle errors consistently
mixin ErrorHandlingMixin {
  final ErrorHandler _errorHandler = errorHandler;

  /// Handle error and return result
  ErrorResult handleError(
    Object error, {
    StackTrace? stackTrace,
    String? context,
  }) {
    return _errorHandler.handle(error, stackTrace: stackTrace, context: context);
  }

  /// Handle error with UI feedback
  Future<ErrorResult> handleErrorWithContext(
    Object error, {
    required BuildContext context,
    StackTrace? stackTrace,
    String? contextName,
    RetryCallback? onRetry,
    bool showDialog = false,
  }) async {
    return _errorHandler.handleErrorWithContext(
      error,
      context: context,
      stackTrace: stackTrace,
      contextName: contextName,
      onRetry: onRetry,
      showDialog: showDialog,
    );
  }
}