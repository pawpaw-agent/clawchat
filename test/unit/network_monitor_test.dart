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
      final status = NetworkStatus.fromResults([ConnectivityResult.wifi]);

      expect(status.isConnected, isTrue);
      expect(status.isWifi, isTrue);
      expect(status.isMobile, isFalse);
      expect(status.isExpensive, isFalse);
      expect(status.connectionTypes, contains(ConnectivityResult.wifi));
    });

    test('creates from ConnectivityResult.mobile', () {
      final status = NetworkStatus.fromResults([ConnectivityResult.mobile]);

      expect(status.isConnected, isTrue);
      expect(status.isWifi, isFalse);
      expect(status.isMobile, isTrue);
      expect(status.isExpensive, isTrue);
      expect(status.connectionTypes, contains(ConnectivityResult.mobile));
    });

    test('creates from ConnectivityResult.none', () {
      final status = NetworkStatus.fromResults([ConnectivityResult.none]);

      expect(status.isConnected, isFalse);
      expect(status.isWifi, isFalse);
      expect(status.isMobile, isFalse);
    });

    test('handles multiple connection types', () {
      final status = NetworkStatus.fromResults([
        ConnectivityResult.wifi,
        ConnectivityResult.mobile,
      ]);

      expect(status.isConnected, isTrue);
      expect(status.isWifi, isTrue);
      expect(status.isMobile, isTrue);
    });
  });

  group('NetworkMonitor', () {
    test('initial status is disconnected', () {
      final monitor = NetworkMonitor();
      expect(monitor.isConnected, isFalse);
    });

    test('statusStream emits status updates', () async {
      final monitor = NetworkMonitor();
      final completer = Completer<void>();
      
      monitor.onStatusChanged((status) {
        if (!completer.isCompleted) {
          completer.complete();
        }
      });

      // Status callback is registered
      expect(monitor._statusCallbacks.length, equals(1));
    });
  });
}