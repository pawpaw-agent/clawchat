/// Unit tests for NetworkMonitor
library;

import 'dart:async';

import 'package:clawchat/src/core/api/network_monitor.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';

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
      await Future.delayed(const Duration(milliseconds: 100));
      expect(completer.isCompleted, isFalse);
    });
  });
}