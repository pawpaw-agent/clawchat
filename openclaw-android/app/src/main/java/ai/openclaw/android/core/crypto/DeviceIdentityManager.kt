package ai.openclaw.android.core.crypto

import ai.openclaw.android.core.network.model.DeviceIdentity
import ai.openclaw.android.core.network.model.SignedChallenge
import android.content.Context
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.security.KeyPair
import java.security.KeyPairGenerator
import java.security.KeyStore
import java.security.Signature
import java.security.spec.ECGenParameterSpec
import java.util.Base64
import javax.inject.Inject
import javax.inject.Singleton

/**
 * 设备身份管理器
 * 负责生成、存储设备密钥对（Ed25519），并对 challenge 进行签名
 * 
 * 注意：Ed25519 需要 Android API 27+ (Android 8.1+)
 * 在不支持 Ed25519 的设备上，会回退到 EC (secp256r1)
 */
@Singleton
class DeviceIdentityManager @Inject constructor(
    @ApplicationContext private val context: Context,
    private val secureTokenStorage: SecureTokenStorage
) {
    companion object {
        private const val KEY_ALIAS = "openclaw_device_key"
        private const val KEYSTORE_PROVIDER = "AndroidKeyStore"
        private const val PREFS_NAME = "openclaw_device_prefs"
        private const val KEY_DEVICE_ID = "device_id"
        private const val KEY_PUBLIC_KEY = "public_key"
        
        // Ed25519 SPKI DER 前缀：302a300506032b6570032100（12 字节）
        // 后面跟 32 字节的原始公钥
        private val ED25519_SPKI_PREFIX = byteArrayOf(
            0x30, 0x2a, 0x30, 0x05, 0x06, 0x03, 0x2b, 0x65, 0x70, 0x03, 0x21, 0x00
        )
        
        // Ed25519 签名算法
        private const val SIGNATURE_ALGORITHM_ED25519 = "Ed25519"
        // EdDSA 签名算法（Java 标准名称）
        private const val SIGNATURE_ALGORITHM_EDDSA = "EdDSA"
    }

    private val keyStore: KeyStore by lazy {
        KeyStore.getInstance(KEYSTORE_PROVIDER).apply { load(null) }
    }

    /**
     * 获取或创建设备身份
     */
    suspend fun getOrCreateDeviceIdentity(): DeviceIdentity = withContext(Dispatchers.IO) {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        
        val existingDeviceId = prefs.getString(KEY_DEVICE_ID, null)
        val existingPublicKey = prefs.getString(KEY_PUBLIC_KEY, null)
        
        if (existingDeviceId != null && existingPublicKey != null && keyStore.containsAlias(KEY_ALIAS)) {
            // 已有身份，返回
            DeviceIdentity(
                id = existingDeviceId,
                publicKey = existingPublicKey,
                signature = "",
                signedAt = 0,
                nonce = ""
            )
        } else {
            // 生成新的 Ed25519 密钥对
            val keyPair = generateEd25519KeyPair()
            
            // 提取原始公钥（32 字节）
            val publicKeyRaw = extractEd25519RawPublicKey(keyPair)
            val publicKeyBase64Url = Base64.getUrlEncoder().withoutPadding().encodeToString(publicKeyRaw)
            
            // 从原始公钥派生设备 ID (SHA-256 完整哈希)
            val deviceId = deriveDeviceId(publicKeyRaw)
            
            // 持久化
            prefs.edit()
                .putString(KEY_DEVICE_ID, deviceId)
                .putString(KEY_PUBLIC_KEY, publicKeyBase64Url)
                .apply()
            
            DeviceIdentity(
                id = deviceId,
                publicKey = publicKeyBase64Url,
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
        if (!keyStore.containsAlias(KEY_ALIAS)) {
            throw IllegalStateException("Device key not found. Call getOrCreateDeviceIdentity() first.")
        }
        
        // 构建签名数据
        val dataToSign = "$nonce:$ts"
        
        // 使用 Android Keystore 私钥签名
        val privateKeyEntry = keyStore.getEntry(KEY_ALIAS, null) as KeyStore.PrivateKeyEntry
        
        // 尝试使用 Ed25519/EdDSA 签名
        val signature = try {
            Signature.getInstance(SIGNATURE_ALGORITHM_EDDSA).apply {
                initSign(privateKeyEntry.privateKey)
                update(dataToSign.toByteArray(Charsets.UTF_8))
            }
        } catch (e: Exception) {
            // 回退到 Ed25519
            Signature.getInstance(SIGNATURE_ALGORITHM_ED25519).apply {
                initSign(privateKeyEntry.privateKey)
                update(dataToSign.toByteArray(Charsets.UTF_8))
            }
        }
        
        val signatureBytes = signature.sign()
        val signatureBase64Url = Base64.getUrlEncoder().withoutPadding().encodeToString(signatureBytes)
        
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
        keyStore.deleteEntry(KEY_ALIAS)
        context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            .edit()
            .clear()
            .apply()
    }

    /**
     * 生成 Ed25519 密钥对
     * Ed25519 需要 Android API 27+ (Android 8.1+)
     */
    private fun generateEd25519KeyPair(): KeyPair {
        return try {
            // 尝试使用 Android Keystore 生成 Ed25519 密钥
            val keyPairGenerator = KeyPairGenerator.getInstance(
                KeyProperties.KEY_ALGORITHM_EC,
                KEYSTORE_PROVIDER
            )
            
            val spec = KeyGenParameterSpec.Builder(
                KEY_ALIAS,
                KeyProperties.PURPOSE_SIGN or KeyProperties.PURPOSE_VERIFY
            )
                .setAlgorithmParameterSpec(ECGenParameterSpec("ed25519"))
                .setDigests(KeyProperties.DIGEST_NONE)  // Ed25519 不需要预哈希
                .setUserAuthenticationRequired(false)
                .build()
            
            keyPairGenerator.initialize(spec)
            keyPairGenerator.generateKeyPair()
        } catch (e: Exception) {
            // 如果 Ed25519 不支持，回退到纯 Java 实现
            // 注意：这不是 Android Keystore 密钥，安全性较低
            generateEd25519KeyPairFallback()
        }
    }

    /**
     * 回退方案：使用纯 Java 生成 Ed25519 密钥对
     * 注意：这不是 HSM 支持的密钥，安全性较低
     */
    private fun generateEd25519KeyPairFallback(): KeyPair {
        val keyPairGenerator = KeyPairGenerator.getInstance("Ed25519")
        return keyPairGenerator.generateKeyPair()
    }

    /**
     * 从 Ed25519 公钥提取原始字节（32 字节）
     * Ed25519 SPKI DER 格式：前缀（12 字节）+ 原始公钥（32 字节）
     */
    private fun extractEd25519RawPublicKey(keyPair: KeyPair): ByteArray {
        val encoded = keyPair.public.encoded
        
        // 检查是否是 Ed25519 SPKI 格式
        if (encoded.size == 44 && encoded.sliceArray(0..11).contentEquals(ED25519_SPKI_PREFIX)) {
            // 提取 32 字节原始公钥
            return encoded.sliceArray(12..43)
        }
        
        // 如果不是标准 SPKI 格式，返回完整编码（可能需要进一步处理）
        throw IllegalStateException("Unexpected Ed25519 public key format: ${encoded.size} bytes")
    }

    /**
     * 从原始公钥派生设备 ID
     * 使用 SHA-256 哈希原始公钥字节，返回完整的十六进制字符串
     */
    private fun deriveDeviceId(publicKeyRaw: ByteArray): String {
        val digest = java.security.MessageDigest.getInstance("SHA-256")
        val hash = digest.digest(publicKeyRaw)
        // 返回完整的 32 字节（64 个十六进制字符）
        return hash.joinToString("") { "%02x".format(it) }
    }
}