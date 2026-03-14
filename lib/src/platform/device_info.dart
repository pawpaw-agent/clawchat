/// Platform channel - Device info (placeholder)
library;

import 'package:flutter/services.dart';

/// Device info via platform channel
class DeviceInfo {
  static const _channel = MethodChannel('com.openclaw.clawchat/device_info');

  /// Get device fingerprint
  static Future<String> getDeviceFingerprint() async {
    try {
      final result = await _channel.invokeMethod<String>('getDeviceFingerprint');
      return result ?? '';
    } on PlatformException {
      return '';
    }
  }

  /// Get device model
  static Future<String> getDeviceModel() async {
    try {
      final result = await _channel.invokeMethod<String>('getDeviceModel');
      return result ?? '';
    } on PlatformException {
      return '';
    }
  }

  /// Get OS version
  static Future<String> getOsVersion() async {
    try {
      final result = await _channel.invokeMethod<String>('getOsVersion');
      return result ?? '';
    } on PlatformException {
      return '';
    }
  }
}