package ai.openclaw.android.core.crypto

import ai.openclaw.android.core.network.model.DeviceIdentity
import ai.openclaw.android.core.network.model.SignedChallenge
import android.content.Context
import android.util.Base64
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.security.KeyPair
import java.security.KeyPairGenerator
import java.security.Signature
import javax.inject.Inject
import javax.inject.Singleton

/**
 * 设备身份管理器
 * 负责生成、存储设备密钥对（Ed25519），并对 challenge 进行签名
 * 
 * 使用纯 Java Ed25519 实现（Android API 29+ 或通过 Conscrypt/BouncyCastle）
 */
@Singleton
class DeviceIdentityManager @Inject constructor(
    @ApplicationContext private val context: Context,
    private val secureTokenStorage: SecureTokenStorage
) {
    companion object {
        private const val PREFS_NAME = "openclaw_device_prefs"
        private const val KEY_DEVICE_ID = "device_id"
        private const val KEY_PUBLIC_KEY = "public_key"
        private const val KEY_PRIVATE_KEY = "private_key"  // Base64 编码的私钥
    }

    /**
     * 获取或创建设备身份
     */
    suspend fun getOrCreateDeviceIdentity(): DeviceIdentity = withContext(Dispatchers.IO) {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        
        val existingDeviceId = prefs.getString(KEY_DEVICE_ID, null)
        val existingPublicKey = prefs.getString(KEY_PUBLIC_KEY, null)
        val existingPrivateKey = prefs.getString(KEY_PRIVATE_KEY, null)
        
        if (existingDeviceId != null && existingPublicKey != null && existingPrivateKey != null) {
            // 已有身份，返回
            DeviceIdentity(
                id = existingDeviceId,
                publicKey = existingPublicKey,
                signature = "",
                signedAt = 0,
                nonce = ""
            )
        } else {
            // 生成新的 Ed25519 密钥对（纯 Java 实现）
            val keyPair = generateEd25519KeyPair()
            
            // 提取原始公钥（32 字节）
            // Ed25519 SPKI DER 格式：12 字节前缀 + 32 字节原始公钥
            val publicKeyRaw = extractEd25519RawPublicKey(keyPair.public.encoded)
            val publicKeyBase64Url = Base64.encodeToString(
                publicKeyRaw,
                Base64.URL_SAFE or Base64.NO_PADDING or Base64.NO_WRAP
            )
            
            // 私钥（存储以便后续签名）
            val privateKeyRaw = keyPair.private.encoded
            val privateKeyBase64 = Base64.encodeToString(
                privateKeyRaw,
                Base64.DEFAULT
            )
            
            // 从公钥派生设备 ID (SHA-256 完整哈希)
            val deviceId = deriveDeviceId(publicKeyRaw)
            
            // 持久化
            prefs.edit()
                .putString(KEY_DEVICE_ID, deviceId)
                .putString(KEY_PUBLIC_KEY, publicKeyBase64Url)
                .putString(KEY_PRIVATE_KEY, privateKeyBase64)
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
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val privateKeyBase64 = prefs.getString(KEY_PRIVATE_KEY, null)
            ?: throw IllegalStateException("Device key not found. Call getOrCreateDeviceIdentity() first.")
        
        // 解码私钥
        val privateKeyRaw = Base64.decode(privateKeyBase64, Base64.DEFAULT)
        val keyPair = recreateKeyPair(privateKeyRaw)
        
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
        context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            .edit()
            .clear()
            .apply()
    }

    /**
     * 生成 Ed25519 密钥对（纯 Java 实现）
     */
    private fun generateEd25519KeyPair(): KeyPair {
        val keyPairGenerator = KeyPairGenerator.getInstance("Ed25519")
        return keyPairGenerator.generateKeyPair()
    }

    /**
     * 从 Ed25519 SPKI DER 编码中提取原始公钥（32 字节）
     * Ed25519 SPKI DER 格式：30 2a 30 05 06 03 2b 65 70 03 21 00 [32 bytes raw public key]
     * 总共 44 字节，原始公钥在最后 32 字节
     */
    private fun extractEd25519RawPublicKey(spkDerEncoded: ByteArray): ByteArray {
        // Ed25519 SPKI DER 应该是 44 字节
        if (spkDerEncoded.size != 44) {
            throw IllegalArgumentException("Invalid Ed25519 public key encoding: expected 44 bytes, got ${spkDerEncoded.size}")
        }
        
        // 检查 SPKI 前缀（可选，用于验证）
        val expectedPrefix = byteArrayOf(
            0x30, 0x2a, 0x30, 0x05, 0x06, 0x03, 0x2b, 0x65, 0x70, 0x03, 0x21, 0x00
        )
        
        // 提取最后 32 字节（原始公钥）
        return spkDerEncoded.copyOfRange(12, 44)
    }

    /**
     * 从私钥重新创建 KeyPair
     * 注意：Ed25519 私钥编码包含公钥信息，所以可以重建完整 KeyPair
     */
    private fun recreateKeyPair(privateKeyRaw: ByteArray): KeyPair {
        // 使用 KeyFactory 从编码重建私钥
        val keyFactory = java.security.KeyFactory.getInstance("Ed25519")
        val privateKeySpec = java.security.spec.PKCS8EncodedKeySpec(privateKeyRaw)
        val privateKey = keyFactory.generatePrivate(privateKeySpec)
        
        // Ed25519 私钥编码中包含公钥，需要提取
        // PKCS#8 格式私钥中包含公钥部分
        // 简化处理：重新生成或使用存储的公钥
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val publicKeyBase64 = prefs.getString(KEY_PUBLIC_KEY, null)
        
        if (publicKeyBase64 != null) {
            val publicKeyRaw = Base64.decode(publicKeyBase64, Base64.URL_SAFE or Base64.NO_PADDING)
            val publicKeySpec = java.security.spec.X509EncodedKeySpec(publicKeyRaw)
            val publicKey = keyFactory.generatePublic(publicKeySpec)
            return KeyPair(publicKey, privateKey)
        }
        
        throw IllegalStateException("Public key not found in storage")
    }

    /**
     * 从公钥派生设备 ID
     * 使用 SHA-256 哈希公钥字节，返回完整的十六进制字符串
     */
    private fun deriveDeviceId(publicKeyRaw: ByteArray): String {
        val digest = java.security.MessageDigest.getInstance("SHA-256")
        val hash = digest.digest(publicKeyRaw)
        // 返回完整的 32 字节（64 个十六进制字符）
        return hash.joinToString("") { "%02x".format(it) }
    }
}