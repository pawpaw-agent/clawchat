package ai.openclaw.android.core.crypto

import ai.openclaw.android.core.network.model.DeviceIdentity
import ai.openclaw.android.core.network.model.SignedChallenge
import android.content.Context
import android.util.Base64
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.security.KeyFactory
import java.security.KeyPair
import java.security.KeyPairGenerator
import java.security.PrivateKey
import java.security.PublicKey
import java.security.Signature
import java.security.spec.PKCS8EncodedKeySpec
import java.security.spec.X509EncodedKeySpec
import javax.inject.Inject
import javax.inject.Singleton

/**
 * 设备身份管理器
 * 负责生成、存储设备密钥对（Ed25519），并对 challenge 进行签名
 * 
 * 使用纯 Java Ed25519 实现
 */
@Singleton
class DeviceIdentityManager @Inject constructor(
    @ApplicationContext private val context: Context,
    private val secureTokenStorage: SecureTokenStorage
) {
    companion object {
        private const val PREFS_NAME = "openclaw_device_prefs"
        private const val KEY_DEVICE_ID = "device_id"
        private const val KEY_PUBLIC_KEY_RAW = "public_key_raw"  // 原始 32 字节公钥
        private const val KEY_PUBLIC_KEY_DER = "public_key_der"  // X509 DER 编码公钥
        private const val KEY_PRIVATE_KEY_DER = "private_key_der"  // PKCS8 DER 编码私钥
    }

    // 缓存的密钥对
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
            // 已有身份，加载密钥对到缓存
            loadKeyPairFromStorage(existingPublicKeyDer, existingPrivateKeyDer)
            
            DeviceIdentity(
                id = existingDeviceId,
                publicKey = existingPublicKeyRaw,
                signature = "",
                signedAt = 0,
                nonce = ""
            )
        } else {
            // 生成新的 Ed25519 密钥对
            val keyPair = generateEd25519KeyPair()
            cachedKeyPair = keyPair
            
            // 提取原始公钥（32 字节）
            val publicKeyRaw = extractEd25519RawPublicKey(keyPair.public)
            val publicKeyRawBase64Url = Base64.encodeToString(
                publicKeyRaw,
                Base64.URL_SAFE or Base64.NO_PADDING or Base64.NO_WRAP
            )
            
            // 存储 DER 编码的公钥和私钥
            val publicKeyDer = keyPair.public.encoded
            val privateKeyDer = keyPair.private.encoded
            
            // 从原始公钥派生设备 ID
            val deviceId = deriveDeviceId(publicKeyRaw)
            
            // 持久化
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
     * 签名质询
     */
    suspend fun signChallenge(nonce: String, ts: Long): SignedChallenge = withContext(Dispatchers.IO) {
        // 使用缓存的密钥对，或从存储加载
        val keyPair = cachedKeyPair ?: loadKeyPairFromStorage()
        
        if (keyPair == null) {
            throw IllegalStateException("Device key not found. Call getOrCreateDeviceIdentity() first.")
        }
        
        // 构建签名数据
        val dataToSign = "$nonce:$ts"
        
        // 使用 Ed25519 签名
        val signature = Signature.getInstance("Ed25519").apply {
            initSign(keyPair.private)
            update(dataToSign.toByteArray(Charsets.UTF_8))
        }
        
        val signatureBytes = signature.sign()
        val signatureBase64Url = Base64.encodeToString(
            signatureBytes,
            Base64.URL_SAFE or Base64.NO_PADDING or Base64.NO_WRAP
        )
        
        SignedChallenge(
            signature = signatureBase64Url,
            signedAt = ts,
            nonce = nonce
        )
    }

    /**
     * 构建完整的设备身份（带签名）
     */
    suspend fun buildSignedDeviceIdentity(nonce: String, ts: Long): DeviceIdentity {
        val baseIdentity = getOrCreateDeviceIdentity()
        val signedChallenge = signChallenge(nonce, ts)
        
        return baseIdentity.copy(
            signature = signedChallenge.signature,
            signedAt = signedChallenge.signedAt,
            nonce = nonce
        )
    }

    /**
     * 获取设备 Token
     */
    suspend fun getDeviceToken(): String? = secureTokenStorage.getDeviceToken()

    /**
     * 保存设备 Token
     */
    suspend fun saveDeviceToken(token: String) = secureTokenStorage.saveDeviceToken(token)

    /**
     * 清除所有认证数据
     */
    suspend fun clearAuth() {
        secureTokenStorage.clearTokens()
        cachedKeyPair = null
        context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            .edit()
            .clear()
            .apply()
    }

    /**
     * 生成 Ed25519 密钥对
     */
    private fun generateEd25519KeyPair(): KeyPair {
        val keyPairGenerator = KeyPairGenerator.getInstance("Ed25519")
        return keyPairGenerator.generateKeyPair()
    }

    /**
     * 从 Ed25519 公钥提取原始字节（32 字节）
     * Ed25519 SPKI DER 格式：30 2a 30 05 06 03 2b 65 70 03 21 00 [32 bytes raw public key]
     * 总共 44 字节，原始公钥在最后 32 字节
     */
    private fun extractEd25519RawPublicKey(publicKey: PublicKey): ByteArray {
        val encoded = publicKey.encoded
        
        // Ed25519 SPKI DER 应该是 44 字节
        if (encoded.size != 44) {
            throw IllegalArgumentException("Invalid Ed25519 public key encoding: expected 44 bytes, got ${encoded.size}")
        }
        
        // 提取最后 32 字节（原始公钥）
        return encoded.copyOfRange(12, 44)
    }

    /**
     * 从存储加载密钥对
     */
    private fun loadKeyPairFromStorage(
        publicKeyDerBase64: String? = null,
        privateKeyDerBase64: String? = null
    ): KeyPair? {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        
        val pubDer = publicKeyDerBase64 ?: prefs.getString(KEY_PUBLIC_KEY_DER, null) ?: return null
        val privDer = privateKeyDerBase64 ?: prefs.getString(KEY_PRIVATE_KEY_DER, null) ?: return null
        
        val publicKeyBytes = Base64.decode(pubDer, Base64.DEFAULT)
        val privateKeyBytes = Base64.decode(privDer, Base64.DEFAULT)
        
        val keyFactory = KeyFactory.getInstance("Ed25519")
        
        val publicKey = keyFactory.generatePublic(X509EncodedKeySpec(publicKeyBytes))
        val privateKey = keyFactory.generatePrivate(PKCS8EncodedKeySpec(privateKeyBytes))
        
        val keyPair = KeyPair(publicKey, privateKey)
        cachedKeyPair = keyPair
        
        return keyPair
    }

    /**
     * 从公钥派生设备 ID
     * 使用 SHA-256 哈希公钥字节，返回完整的十六进制字符串
     */
    private fun deriveDeviceId(publicKeyRaw: ByteArray): String {
        val digest = java.security.MessageDigest.getInstance("SHA-256")
        val hash = digest.digest(publicKeyRaw)
        return hash.joinToString("") { "%02x".format(it) }
    }
}