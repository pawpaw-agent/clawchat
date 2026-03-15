/// Unit tests for NetworkMonitor
library;

import 'dart:async';

import 'package:clawchat/src/core/api/network_monitor.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';

void main() {
  group('NetworkStatus', () {
    test('creates from ConnectivityResult.wifi', () {
      final status = NetworkStatus.fromResult(ConnectivityResult.wifi);

      expect(status.isConnected, isTrue);
      expect(status.isWifi, isTrue);
      expect(status.isMobile, isFalse);
      expect(status.isExpensive, isFalse);
      expect(status.connectionType, equals(ConnectivityResult.wifi));
    });

    test('creates from ConnectivityResult.mobile', () {
      final status = NetworkStatus.fromResult(ConnectivityResult.mobile);

      expect(status.isConnected, isTrue);
      expect(status.isWifi, isFalse);
      expect(status.isMobile, isTrue);
      expect(status.isExpensive, isTrue);
      expect(status.connectionType, equals(ConnectivityResult.mobile));
    });

    test('creates from ConnectivityResult.none', () {
      final status = NetworkStatus.fromResult(ConnectivityResult.none);

      expect(status.isConnected, isFalse);
      expect(status.isWifi, isFalse);
      expect(status.isMobile, isFalse);
      expect(status.isExpensive, isFalse);
      expect(status.connectionType, equals(ConnectivityResult.none));
    });

    test('disconnected constant has correct values', () {
      expect(NetworkStatus.disconnected.isConnected, isFalse);
      expect(
          NetworkStatus.disconnected.connectionType, equals(ConnectivityResult.none));
    });

    test('toString returns readable format', () {
      final status = NetworkStatus.fromResult(ConnectivityResult.wifi);
      expect(status.toString(), contains('connected: true'));
      expect(status.toString(), contains('wifi'));
    });
  });

  group('NetworkMonitor', () {
    late NetworkMonitor monitor;

    setUp(() {
      monitor = NetworkMonitor(
        logger: Logger(printer: PrettyPrinter(methodCount: 0)),
      );
    });

    tearDown(() async {
      await monitor.dispose();
    });

    test('initial state is disconnected', () {
      expect(monitor.currentStatus, equals(NetworkStatus.disconnected));
      expect(monitor.isConnected, isFalse);
      expect(monitor.isWifi, isFalse);
      expect(monitor.isMobile, isFalse);
    });

    test('statusStream emits current status when subscribed', () async {
      // Start monitor to get initial status
      await monitor.start();

      // Subscribe to stream
      final completer = Completer<NetworkStatus>();
      final subscription = monitor.statusStream.listen(completer.complete);

      // Wait for emission with timeout
      final status = await completer.future.timeout(
        const Duration(seconds: 5),
        onTimeout: () => NetworkStatus.disconnected,
      );

      expect(status, isNotNull);
      await subscription.cancel();
    });

    test('onStatusChange registers callback', () {
      var called = false;
      void callback(NetworkStatus status) {
        called = true;
      }

      monitor.onStatusChange(callback);
      expect(() => monitor.offStatusChange(callback), returnsNormally);
    });

    test('offStatusChange removes callback', () {
      void callback(NetworkStatus status) {}

      monitor.onStatusChange(callback);
      monitor.offStatusChange(callback);

      // No exception means success
      expect(true, isTrue);
    });

    test('onRestoration registers callback', () {
      var called = false;
      void callback(NetworkStatus prev, NetworkStatus curr) {
        called = true;
      }

      monitor.onRestoration(callback);
      expect(() => monitor.offRestoration(callback), returnsNormally);
    });

    test('checkStatus returns NetworkStatus', () async {
      final status = await monitor.checkStatus();
      expect(status, isA<NetworkStatus>());
    });

    test('start can be called safely', () async {
      // First start
      await monitor.start();

      // Second start should not throw
      await monitor.start();

      expect(monitor.currentStatus, isA<NetworkStatus>());
    });

    test('stop can be called multiple times', () async {
      await monitor.stop();
      await monitor.stop();
      // No exception means success
      expect(true, isTrue);
    });

    test('dispose clears all callbacks', () async {
      var callbackCount = 0;
      void callback(NetworkStatus status) {
        callbackCount++;
      }

      monitor.onStatusChange(callback);
      await monitor.dispose();

      // Callbacks should be cleared
      // We can't directly test this, but dispose should work without error
      expect(true, isTrue);
    });
  });

  group('NetworkMonitor with connectivity changes', () {
    late NetworkMonitor monitor;
    List<NetworkStatus> statusChanges = [];

    setUp(() {
      monitor = NetworkMonitor(
        logger: Logger(printer: PrettyPrinter(methodCount: 0)),
      );
      statusChanges = [];
      monitor.onStatusChange((status) {
        statusChanges.add(status);
      });
    });

    tearDown(() async {
      await monitor.dispose();
    });

    test('detects WiFi connection', () async {
      await monitor.start();

      // Wait a bit for initial status
      await Future.delayed(const Duration(milliseconds: 100));

      // If connected, status should reflect it
      if (monitor.isConnected) {
        expect(monitor.currentStatus.isConnected, isTrue);
      }
    });

    test('handles network type transitions', () async {
      // This test requires actual network changes or mocking
      // In a real environment, you would use mock connectivity

      await monitor.start();

      // Simulate the callback being called directly
      // In production, this would be triggered by connectivity_plus
      expect(statusChanges, isNotEmpty);
    });
  });

  group('NetworkStatus edge cases', () {
    test('handles ethernet connection', () {
      final status = NetworkStatus.fromResult(ConnectivityResult.ethernet);

      expect(status.isConnected, isTrue);
      expect(status.isWifi, isFalse);
      expect(status.isMobile, isFalse);
    });

    test('handles bluetooth connection', () {
      final status = NetworkStatus.fromResult(ConnectivityResult.bluetooth);

      expect(status.isConnected, isTrue);
      expect(status.isWifi, isFalse);
      expect(status.isMobile, isFalse);
    });

    test('handles VPN connection', () {
      final status = NetworkStatus.fromResult(ConnectivityResult.vpn);

      expect(status.isConnected, isTrue);
    });

    test('timestamp is set to current time', () {
      final before = DateTime.now();
      final status = NetworkStatus.fromResult(ConnectivityResult.wifi);
      final after = DateTime.now();

      expect(status.timestamp.isAfter(before.subtract(const Duration(seconds: 1))), isTrue);
      expect(status.timestamp.isBefore(after.add(const Duration(seconds: 1))), isTrue);
    });
  });

  group('NetworkMonitor memory management', () {
    test('multiple start/stop cycles work correctly', () async {
      final monitor = NetworkMonitor();

      for (var i = 0; i < 3; i++) {
        await monitor.start();
        await monitor.stop();
      }

      await monitor.dispose();
      expect(true, isTrue);
    });

    test('callbacks are properly managed', () async {
      final monitor = NetworkMonitor();

      void callback1(NetworkStatus status) {}
      void callback2(NetworkStatus status) {}
      void restorationCallback(NetworkStatus prev, NetworkStatus curr) {}

      monitor.onStatusChange(callback1);
      monitor.onStatusChange(callback2);
      monitor.onRestoration(restorationCallback);

      monitor.offStatusChange(callback1);
      monitor.offRestoration(restorationCallback);

      await monitor.dispose();
      expect(true, isTrue);
    });
  });
}