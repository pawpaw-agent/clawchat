/// Device Authentication Service
/// Handles device key generation, signing, and secure storage
library;

import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:crypto/crypto.dart';
import 'package:uuid/uuid.dart';

import 'gateway_protocol.dart';

/// Service for device authentication with OpenClaw Gateway
class AuthService {
  static const _deviceIdKey = 'clawchat_device_id';
  static const _privateKeyKey = 'clawchat_private_key';
  static const _publicKeyKey = 'clawchat_public_key';
  static const _deviceTokenKey = 'clawchat_device_token';

  final FlutterSecureStorage _secureStorage;
  final Uuid _uuid;

  String? _deviceId;
  String? _privateKey;
  String? _publicKey;
  String? _deviceToken;

  AuthService({
    FlutterSecureStorage? secureStorage,
    Uuid? uuid,
  })  : _secureStorage = secureStorage ?? const FlutterSecureStorage(),
        _uuid = uuid ?? const Uuid();

  /// Get or create device ID
  Future<String> get deviceId async {
    if (_deviceId != null) return _deviceId!;
    
    final stored = await _secureStorage.read(key: _deviceIdKey);
    if (stored != null) {
      _deviceId = stored;
      return _deviceId!;
    }

    // Generate new device ID
    _deviceId = _uuid.v4();
    await _secureStorage.write(key: _deviceIdKey, value: _deviceId);
    return _deviceId!;
  }

  /// Get device token (from previous successful auth)
  Future<String?> get deviceToken async {
    if (_deviceToken != null) return _deviceToken;
    _deviceToken = await _secureStorage.read(key: _deviceTokenKey);
    return _deviceToken;
  }

  /// Store device token after successful authentication
  Future<void> storeDeviceToken(String token) async {
    _deviceToken = token;
    await _secureStorage.write(key: _deviceTokenKey, value: token);
  }

  /// Check if device keys exist
  Future<bool> hasDeviceKeys() async {
    final privateKey = await _secureStorage.read(key: _privateKeyKey);
    final publicKey = await _secureStorage.read(key: _publicKeyKey);
    return privateKey != null && publicKey != null;
  }

  /// Generate new device key pair (simplified for demo)
  /// In production, use proper Ed25519 or ECDSA
  Future<KeyPair> generateDeviceKeys() async {
    // Generate random bytes for key material
    final random = Random.secure();
    final privateKeyBytes = Uint8List(32);
    final publicKeyBytes = Uint8List(32);
    
    for (var i = 0; i < 32; i++) {
      privateKeyBytes[i] = random.nextInt(256);
      publicKeyBytes[i] = random.nextInt(256);
    }

    _privateKey = base64Encode(privateKeyBytes);
    _publicKey = base64Encode(publicKeyBytes);

    await _secureStorage.write(key: _privateKeyKey, value: _privateKey);
    await _secureStorage.write(key: _publicKeyKey, value: _publicKey);

    return KeyPair(
      privateKey: _privateKey!,
      publicKey: _publicKey!,
    );
  }

  /// Get existing device keys
  Future<KeyPair?> getDeviceKeys() async {
    if (_privateKey != null && _publicKey != null) {
      return KeyPair(privateKey: _privateKey!, publicKey: _publicKey!);
    }

    final privateKey = await _secureStorage.read(key: _privateKeyKey);
    final publicKey = await _secureStorage.read(key: _publicKeyKey);

    if (privateKey == null || publicKey == null) return null;

    _privateKey = privateKey;
    _publicKey = publicKey;

    return KeyPair(privateKey: privateKey, publicKey: publicKey);
  }

  /// Sign challenge nonce with device key
  /// Returns signature and signed timestamp
  Future<SignatureResult> signChallenge(String nonce) async {
    final keys = await getDeviceKeys();
    if (keys == null) {
      throw AuthException('No device keys found. Generate keys first.');
    }

    final signedAt = DateTime.now().millisecondsSinceEpoch;
    final message = '$nonce:$signedAt';
    
    // Simplified signing for demo (use proper crypto in production)
    final signature = _signMessage(message, keys.privateKey);

    return SignatureResult(
      signature: signature,
      signedAt: signedAt,
    );
  }

  /// Create device auth payload for connect handshake
  Future<DeviceAuth> createDeviceAuth(String nonce) async {
    final id = await deviceId;
    final keys = await getDeviceKeys();
    
    if (keys == null) {
      throw AuthException('No device keys found');
    }

    final signatureResult = await signChallenge(nonce);

    return DeviceAuth(
      id: id,
      publicKey: keys.publicKey,
      signature: signatureResult.signature,
      signedAt: signatureResult.signedAt,
      nonce: nonce,
    );
  }

  /// Clear all stored credentials
  Future<void> clearCredentials() async {
    await _secureStorage.deleteAll();
    _deviceId = null;
    _privateKey = null;
    _publicKey = null;
    _deviceToken = null;
  }

  /// Simple HMAC-based signing (for demo purposes)
  /// In production, use Ed25519 or ECDSA with pointycastle or similar
  String _signMessage(String message, String privateKey) {
    final keyBytes = base64Decode(privateKey);
    final messageBytes = utf8.encode(message);
    
    final hmac = Hmac(sha256, keyBytes);
    final digest = hmac.convert(messageBytes);
    
    return base64Encode(digest.bytes);
  }
}

/// Key pair container
class KeyPair {
  final String privateKey;
  final String publicKey;

  const KeyPair({
    required this.privateKey,
    required this.publicKey,
  });
}

/// Signature result container
class SignatureResult {
  final String signature;
  final int signedAt;

  const SignatureResult({
    required this.signature,
    required this.signedAt,
  });
}

/// Authentication exception
class AuthException implements Exception {
  final String message;
  const AuthException(this.message);

  @override
  String toString() => 'AuthException: $message';
}