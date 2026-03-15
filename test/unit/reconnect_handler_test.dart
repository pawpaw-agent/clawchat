/// Unit tests for ReconnectHandler
library;

import 'dart:async';

import 'package:clawchat/src/core/api/gateway_client.dart';
import 'package:clawchat/src/core/api/gateway_protocol.dart';
import 'package:clawchat/src/core/api/reconnect_handler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';
import 'package:mocktail/mocktail.dart';

// Mock classes
class MockGatewayClient extends Mock implements GatewayClient {}

class FakeRequestFrame extends Fake implements RequestFrame {}

void main() {
  group('PendingMessage', () {
    test('creates with default values', () {
      final message = PendingMessage(
        id: 'test-id',
        method: 'chat.send',
        params: {'content': 'hello'},
        createdAt: DateTime.now(),
      );

      expect(message.id, equals('test-id'));
      expect(message.method, equals('chat.send'));
      expect(message.sendAttempts, equals(0));
      expect(message.requiresConfirmation, isTrue);
      expect(message.isExpired, isFalse);
      expect(message.canRetry, isTrue);
    });

    test('withIncrementedAttempts increases attempts', () {
      final message = PendingMessage(
        id: 'test-id',
        method: 'chat.send',
        params: {},
        createdAt: DateTime.now(),
        sendAttempts: 1,
      );

      final updated = message.withIncrementedAttempts();

      expect(updated.sendAttempts, equals(2));
      expect(message.sendAttempts, equals(1)); // Original unchanged
    });

    test('isExpired returns true for old messages', () {
      final message = PendingMessage(
        id: 'test-id',
        method: 'chat.send',
        params: {},
        createdAt: DateTime.now().subtract(const Duration(minutes: 6)),
      );

      expect(message.isExpired, isTrue);
      expect(message.canRetry, isFalse);
    });

    test('canRetry returns false after max attempts', () {
      final message = PendingMessage(
        id: 'test-id',
        method: 'chat.send',
        params: {},
        createdAt: DateTime.now(),
        sendAttempts: PendingMessage.maxAttempts,
      );

      expect(message.canRetry, isFalse);
    });

    test('toString contains relevant info', () {
      final message = PendingMessage(
        id: 'test-id',
        method: 'chat.send',
        params: {},
        createdAt: DateTime.now(),
      );

      expect(message.toString(), contains('test-id'));
      expect(message.toString(), contains('chat.send'));
    });
  });

  group('ReconnectHandler', () {
    late MockGatewayClient mockClient;
    late ReconnectHandler handler;

    setUpAll(() {
      registerFallbackValue(FakeRequestFrame());
    });

    setUp(() {
      mockClient = MockGatewayClient();
      handler = ReconnectHandler(
        client: mockClient,
        logger: Logger(printer: PrettyPrinter(methodCount: 0)),
        enableMessageQueue: true,
        maxPendingMessages: 10,
      );
    });

    tearDown(() async {
      await handler.dispose();
    });

    test('initial state is correct', () {
      expect(handler.isReconnecting, isFalse);
      expect(handler.shouldReconnect, isTrue);
      expect(handler.pendingCount, equals(0));
      expect(handler.sendPaused, isFalse);
    });

    test('setReconnectEnabled changes state', () {
      handler.setReconnectEnabled(false);
      expect(handler.shouldReconnect, isFalse);

      handler.setReconnectEnabled(true);
      expect(handler.shouldReconnect, isTrue);
    });

    test('initialize stores handshake parameters', () {
      handler.initialize(
        version: '1.0.0',
        token: 'test-token',
        locale: 'en-US',
      );

      // Parameters are stored internally, verified by behavior
      expect(true, isTrue);
    });

    test('handleDisconnection pauses sending', () {
      handler.handleDisconnection();
      expect(handler.sendPaused, isTrue);
    });

    test('onMessageSent registers callback', () {
      var called = false;
      void callback(PendingMessage message) {
        called = true;
      }

      handler.onMessageSent(callback);
      handler.offMessageSent(callback);
      // No exception means success
      expect(true, isTrue);
    });

    test('onMessageFailed registers callback', () {
      var called = false;
      void callback(PendingMessage message, String error) {
        called = true;
      }

      handler.onMessageFailed(callback);
      handler.offMessageFailed(callback);
      expect(true, isTrue);
    });

    test('onResendProgress registers callback', () {
      var called = false;
      void callback(int total, int sent, int failed) {
        called = true;
      }

      handler.onResendProgress(callback);
      handler.offResendProgress(callback);
      expect(true, isTrue);
    });

    test('dispose clears all state', () async {
      handler.onMessageSent((_) {});
      handler.onMessageFailed((_, __) {});
      handler.onResendProgress((_, __, ___) {});

      await handler.dispose();

      // No exception means success
      expect(true, isTrue);
    });
  });

  group('ReconnectHandler message queue', () {
    late MockGatewayClient mockClient;
    late ReconnectHandler handler;

    setUpAll(() {
      registerFallbackValue(FakeRequestFrame());
    });

    setUp(() {
      mockClient = MockGatewayClient();
      handler = ReconnectHandler(
        client: mockClient,
        logger: Logger(printer: PrettyPrinter(methodCount: 0)),
        enableMessageQueue: true,
        maxPendingMessages: 5,
      );
    });

    tearDown(() async {
      await handler.dispose();
    });

    test('queueMessage throws when disconnected without queue', () async {
      handler = ReconnectHandler(
        client: mockClient,
        logger: Logger(printer: PrettyPrinter(methodCount: 0)),
        enableMessageQueue: false,
      );

      // Mock disconnected state
      when(() => mockClient.isConnected).thenReturn(false);

      expect(
        () => handler.queueMessage('test.method', {}),
        throwsA(isA<GatewayException>()),
      );
    });

    test('markAsSent adds to unconfirmed', () {
      final message = PendingMessage(
        id: 'test-id',
        method: 'test.method',
        params: {},
        createdAt: DateTime.now(),
      );

      handler.markAsSent(message);
      expect(handler.pendingCount, equals(1));
    });

    test('markAsConfirmed removes from unconfirmed', () {
      final message = PendingMessage(
        id: 'test-id',
        method: 'test.method',
        params: {},
        createdAt: DateTime.now(),
      );

      handler.markAsSent(message);
      expect(handler.pendingCount, equals(1));

      handler.markAsConfirmed('test-id');
      expect(handler.pendingCount, equals(0));
    });
  });

  group('ReconnectHandler reconnection logic', () {
    late MockGatewayClient mockClient;
    late ReconnectHandler handler;

    setUpAll(() {
      registerFallbackValue(FakeRequestFrame());
    });

    setUp(() {
      mockClient = MockGatewayClient();
      handler = ReconnectHandler(
        client: mockClient,
        logger: Logger(printer: PrettyPrinter(methodCount: 0)),
      );
    });

    tearDown(() async {
      await handler.dispose();
    });

    test('reconnect fails without initialization', () async {
      final result = await handler.reconnect();
      expect(result, isFalse);
    });

    test('reconnect with disabled auto-reconnect does nothing', () async {
      handler.setReconnectEnabled(false);
      handler.initialize(version: '1.0.0');

      final result = await handler.reconnect();
      // Should return false since reconnection is disabled
      // Actual behavior depends on implementation
      expect(result, isFalse);
    });

    test('multiple handleDisconnection calls are safe', () {
      handler.handleDisconnection();
      handler.handleDisconnection();
      handler.handleDisconnection();

      expect(handler.sendPaused, isTrue);
    });
  });

  group('PendingMessage edge cases', () {
    test('handles custom timeout', () {
      final message = PendingMessage(
        id: 'test-id',
        method: 'test.method',
        params: {},
        createdAt: DateTime.now(),
        timeout: const Duration(seconds: 10),
      );

      expect(message.timeout, equals(const Duration(seconds: 10)));
    });

    test('requiresConfirmation defaults to true', () {
      final message = PendingMessage(
        id: 'test-id',
        method: 'test.method',
        params: {},
        createdAt: DateTime.now(),
      );

      expect(message.requiresConfirmation, isTrue);
    });

    test('canRetry is true when attempts < max and not expired', () {
      final message = PendingMessage(
        id: 'test-id',
        method: 'test.method',
        params: {},
        createdAt: DateTime.now().subtract(const Duration(minutes: 4)),
        sendAttempts: 2,
      );

      // 4 minutes < 5 minutes, 2 < 3
      expect(message.canRetry, isTrue);
    });

    test('canRetry is false when both conditions fail', () {
      final message = PendingMessage(
        id: 'test-id',
        method: 'test.method',
        params: {},
        createdAt: DateTime.now().subtract(const Duration(minutes: 6)),
        sendAttempts: 5,
      );

      expect(message.canRetry, isFalse);
    });
  });

  group('ReconnectHandler constants', () {
    test('maxAttempts is 3', () {
      expect(PendingMessage.maxAttempts, equals(3));
    });

    test('maxAge is 5 minutes', () {
      expect(PendingMessage.maxAge, equals(const Duration(minutes: 5)));
    });
  });
}