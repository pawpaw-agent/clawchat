package ai.openclaw.android.core.crypto

import ai.openclaw.android.core.network.model.DeviceIdentity
import ai.openclaw.android.core.network.model.SignedChallenge
import android.content.Context
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import com.google.crypto.tink.*
import com.google.crypto.tink.signature.PublicKeySignWrapper
import com.google.crypto.tink.signature.SignatureKeyTemplates
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.security.KeyPair
import java.security.KeyStore
import java.security.Signature
import java.util.Base64
import javax.inject.Inject
import javax.inject.Singleton

/**
 * 设备身份管理器
 * 负责生成、存储设备密钥对，并对 challenge 进行签名
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
                signature = "", // 将在签名时填充
                signedAt = 0,
                nonce = ""
            )
        } else {
            // 生成新的密钥对
            val keyPair = generateKeyPair()
            val publicKeyBytes = keyPair.public.encoded
            val publicKeyBase64 = Base64.getEncoder().encodeToString(publicKeyBytes)
            
            // 从公钥派生设备 ID (SHA-256 前 16 字节)
            val deviceId = deriveDeviceId(publicKeyBytes)
            
            // 持久化
            prefs.edit()
                .putString(KEY_DEVICE_ID, deviceId)
                .putString(KEY_PUBLIC_KEY, publicKeyBase64)
                .apply()
            
            DeviceIdentity(
                id = deviceId,
                publicKey = publicKeyBase64,
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
        val signature = Signature.getInstance("SHA256withECDSA").apply {
            initSign(privateKeyEntry.privateKey)
            update(dataToSign.toByteArray(Charsets.UTF_8))
        }
        
        val signatureBytes = signature.sign()
        val signatureBase64 = Base64.getEncoder().encodeToString(signatureBytes)
        
        SignedChallenge(
            signature = signatureBase64,
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
     * 生成密钥对
     */
    private fun generateKeyPair(): KeyPair {
        val keyPairGenerator = java.security.KeyPairGenerator.getInstance(
            KeyProperties.KEY_ALGORITHM_EC,
            KEYSTORE_PROVIDER
        )
        
        val spec = KeyGenParameterSpec.Builder(
            KEY_ALIAS,
            KeyProperties.PURPOSE_SIGN or KeyProperties.PURPOSE_VERIFY
        )
            .setDigests(KeyProperties.DIGEST_SHA256)
            .setAlgorithmParameterSpec(java.security.spec.ECGenParameterSpec("secp256r1"))
            .setUserAuthenticationRequired(false)
            .build()
        
        keyPairGenerator.initialize(spec)
        return keyPairGenerator.generateKeyPair()
    }

    /**
     * 从公钥派生设备 ID
     * 使用 SHA-256 哈希公钥的 SPKI DER 编码，返回完整的十六进制字符串
     */
    private fun deriveDeviceId(publicKeyBytes: ByteArray): String {
        val digest = java.security.MessageDigest.getInstance("SHA-256")
        val hash = digest.digest(publicKeyBytes)
        // 返回完整的 32 字节（64 个十六进制字符），与服务器 fingerprintPublicKey 一致
        return hash.joinToString("") { "%02x".format(it) }
    }
}