package ai.openclaw.android.core.crypto

import ai.openclaw.android.core.network.model.DeviceIdentity
import ai.openclaw.android.core.network.model.SignedChallenge
import android.content.Context
import android.util.Base64
import android.util.Log
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import org.bouncycastle.jce.provider.BouncyCastleProvider
import java.security.KeyFactory
import java.security.KeyPair
import java.security.KeyPairGenerator
import java.security.PrivateKey
import java.security.Provider
import java.security.PublicKey
import java.security.Security
import java.security.Signature
import java.security.spec.PKCS8EncodedKeySpec
import java.security.spec.X509EncodedKeySpec
import javax.inject.Inject
import javax.inject.Singleton

/**
 * 设备身份管理器
 * 负责生成、存储设备密钥对（Ed25519），并对 challenge 进行签名
 */
@Singleton
class DeviceIdentityManager @Inject constructor(
    @ApplicationContext private val context: Context,
    private val secureTokenStorage: SecureTokenStorage
) {
    companion object {
        private const val TAG = "DeviceIdentity"
        private const val PREFS_NAME = "openclaw_device_prefs"
        private const val KEY_DEVICE_ID = "device_id"
        private const val KEY_PUBLIC_KEY_RAW = "public_key_raw"
        private const val KEY_PUBLIC_KEY_DER = "public_key_der"
        private const val KEY_PRIVATE_KEY_DER = "private_key_der"
        
        private val ed25519Provider: Provider by lazy {
            val provider = BouncyCastleProvider()
            Security.addProvider(provider)
            Log.d(TAG, "BouncyCastle provider added: ${provider.name}")
            provider
        }
    }

    @Volatile
    private var cachedKeyPair: KeyPair? = null

    /**
     * 获取或创建设备身份
     */
    suspend fun getOrCreateDeviceIdentity(): DeviceIdentity = withContext(Dispatchers.IO) {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        
        val existingDeviceId = prefs.getString(KEY_DEVICE_ID, null)
        val existingPublicKeyRaw = prefs.getString(KEY_PUBLIC_KEY_RAW, null)
        val existingPublicKeyDer = prefs.getString(KEY_PUBLIC_KEY_DER, null)
        val existingPrivateKeyDer = prefs.getString(KEY_PRIVATE_KEY_DER, null)
        
        if (existingDeviceId != null && existingPublicKeyRaw != null && 
            existingPublicKeyDer != null && existingPrivateKeyDer != null) {
            loadKeyPairFromStorage(existingPublicKeyDer, existingPrivateKeyDer)
            
            DeviceIdentity(
                id = existingDeviceId,
                publicKey = existingPublicKeyRaw,
                signature = "",
                signedAt = 0,
                nonce = ""
            )
        } else {
            val keyPair = generateEd25519KeyPair()
            cachedKeyPair = keyPair
            
            val publicKeyRaw = extractEd25519RawPublicKey(keyPair.public)
            val publicKeyRawBase64Url = Base64.encodeToString(
                publicKeyRaw,
                Base64.URL_SAFE or Base64.NO_PADDING or Base64.NO_WRAP
            )
            
            val publicKeyDer = keyPair.public.encoded
            val privateKeyDer = keyPair.private.encoded
            
            val deviceId = deriveDeviceId(publicKeyRaw)
            
            prefs.edit()
                .putString(KEY_DEVICE_ID, deviceId)
                .putString(KEY_PUBLIC_KEY_RAW, publicKeyRawBase64Url)
                .putString(KEY_PUBLIC_KEY_DER, Base64.encodeToString(publicKeyDer, Base64.DEFAULT))
                .putString(KEY_PRIVATE_KEY_DER, Base64.encodeToString(privateKeyDer, Base64.DEFAULT))
                .apply()
            
            DeviceIdentity(
                id = deviceId,
                publicKey = publicKeyRawBase64Url,
                signature = "",
                signedAt = 0,
                nonce = ""
            )
        }
    }

    /**
     * 构建完整的设备身份（带签名）
     * 使用 V2 payload 格式: v2|deviceId|clientId|clientMode|role|scopes|signedAtMs|token|nonce
     */
    suspend fun buildSignedDeviceIdentity(
        nonce: String,
        ts: Long,
        token: String? = null
    ): DeviceIdentity {
        val baseIdentity = getOrCreateDeviceIdentity()
        
        // 构建 V2 payload 格式
        val deviceId = baseIdentity.id
        val clientId = "cli"
        val clientMode = "ui"
        val role = "operator"
        // IMPORTANT: scopes 必须与 GatewayClient 发送的 scopes 一致！
        val scopes = "operator.read,operator.write"
        val signedAtMs = ts.toString()
        val tokenPart = token ?: ""
        
        // 调试日志
        Log.d(TAG, "=== Device Identity Debug ===")
        Log.d(TAG, "deviceId: $deviceId")
        Log.d(TAG, "publicKey (base64url): ${baseIdentity.publicKey}")
        Log.d(TAG, "challenge.nonce: $nonce")
        Log.d(TAG, "challenge.ts: $ts")
        Log.d(TAG, "token: $tokenPart")
        Log.d(TAG, "scopes: $scopes (MUST match GatewayClient)")
        
        val payload = buildV2Payload(
            deviceId = deviceId,
            clientId = clientId,
            clientMode = clientMode,
            role = role,
            scopes = scopes,
            signedAtMs = signedAtMs,
            token = tokenPart,
            nonce = nonce
        )
        
        Log.d(TAG, "V2 Payload: $payload")
        
        val signatureBase64Url = signPayload(payload)
        
        Log.d(TAG, "signature (base64url): $signatureBase64Url")
        Log.d(TAG, "=== End Debug ===")
        
        return baseIdentity.copy(
            signature = signatureBase64Url,
            signedAt = ts,
            nonce = nonce
        )
    }

    /**
     * 构建 V2 设备认证 payload
     * 格式: v2|deviceId|clientId|clientMode|role|scopes|signedAtMs|token|nonce
     */
    private fun buildV2Payload(
        deviceId: String,
        clientId: String,
        clientMode: String,
        role: String,
        scopes: String,
        signedAtMs: String,
        token: String,
        nonce: String
    ): String {
        return listOf(
            "v2",
            deviceId,
            clientId,
            clientMode,
            role,
            scopes,
            signedAtMs,
            token,
            nonce
        ).joinToString("|")
    }

    /**
     * 签名 payload
     */
    private suspend fun signPayload(payload: String): String = withContext(Dispatchers.IO) {
        val keyPair = cachedKeyPair ?: loadKeyPairFromStorage()
        
        if (keyPair == null) {
            throw IllegalStateException("Device key not found. Call getOrCreateDeviceIdentity() first.")
        }
        
        Log.d(TAG, "Signing payload: $payload")
        Log.d(TAG, "Payload bytes: ${payload.toByteArray(Charsets.UTF_8).joinToString(" ") { "%02x".format(it) }}")
        
        val signature = Signature.getInstance("Ed25519", ed25519Provider).apply {
            initSign(keyPair.private)
            update(payload.toByteArray(Charsets.UTF_8))
        }
        
        val signatureBytes = signature.sign()
        Log.d(TAG, "Signature length: ${signatureBytes.size} bytes")
        
        Base64.encodeToString(
            signatureBytes,
            Base64.URL_SAFE or Base64.NO_PADDING or Base64.NO_WRAP
        )
    }

    /**
     * 旧方法 - 签名质询（保留兼容）
     */
    suspend fun signChallenge(nonce: String, ts: Long): SignedChallenge {
        val identity = buildSignedDeviceIdentity(nonce, ts)
        return SignedChallenge(
            signature = identity.signature,
            signedAt = identity.signedAt,
            nonce = identity.nonce
        )
    }

    suspend fun getDeviceToken(): String? = secureTokenStorage.getDeviceToken()

    suspend fun saveDeviceToken(token: String) = secureTokenStorage.saveDeviceToken(token)

    suspend fun clearAuth() {
        secureTokenStorage.clearTokens()
        cachedKeyPair = null
        context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            .edit()
            .clear()
            .apply()
    }

    private fun generateEd25519KeyPair(): KeyPair {
        Log.d(TAG, "Generating Ed25519 key pair with provider: ${ed25519Provider.name}")
        val keyPairGenerator = KeyPairGenerator.getInstance("Ed25519", ed25519Provider)
        return keyPairGenerator.generateKeyPair()
    }

    private fun extractEd25519RawPublicKey(publicKey: PublicKey): ByteArray {
        val encoded = publicKey.encoded
        
        if (encoded.size != 44) {
            throw IllegalArgumentException("Invalid Ed25519 public key encoding: expected 44 bytes, got ${encoded.size}")
        }
        
        return encoded.copyOfRange(12, 44)
    }

    private fun loadKeyPairFromStorage(
        publicKeyDerBase64: String? = null,
        privateKeyDerBase64: String? = null
    ): KeyPair? {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        
        val pubDer = publicKeyDerBase64 ?: prefs.getString(KEY_PUBLIC_KEY_DER, null) ?: return null
        val privDer = privateKeyDerBase64 ?: prefs.getString(KEY_PRIVATE_KEY_DER, null) ?: return null
        
        val publicKeyBytes = Base64.decode(pubDer, Base64.DEFAULT)
        val privateKeyBytes = Base64.decode(privDer, Base64.DEFAULT)
        
        val keyFactory = KeyFactory.getInstance("Ed25519", ed25519Provider)
        
        val publicKey = keyFactory.generatePublic(X509EncodedKeySpec(publicKeyBytes))
        val privateKey = keyFactory.generatePrivate(PKCS8EncodedKeySpec(privateKeyBytes))
        
        val keyPair = KeyPair(publicKey, privateKey)
        cachedKeyPair = keyPair
        
        return keyPair
    }

    private fun deriveDeviceId(publicKeyRaw: ByteArray): String {
        val digest = java.security.MessageDigest.getInstance("SHA-256")
        val hash = digest.digest(publicKeyRaw)
        return hash.joinToString("") { "%02x".format(it) }
    }
}