package ai.openclaw.android.core.crypto

import ai.openclaw.android.core.network.model.DeviceIdentity
import ai.openclaw.android.core.network.model.SignedChallenge
import android.content.Context
import android.util.Base64
import android.util.Log
import com.google.crypto.tink.InsecureSecretKeyAccess
import com.google.crypto.tink.TinkProtoKeysetFormat
import com.google.crypto.tink.PublicKeySign
import com.google.crypto.tink.KeysetHandle
import com.google.crypto.tink.signature.SignatureConfig
import com.google.crypto.tink.signature.SignatureKeyTemplates
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import javax.inject.Inject
import javax.inject.Singleton

/**
 * 设备身份管理器
 * 使用 Google Tink 实现 Ed25519 签名（替代 BouncyCastle）
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
        private const val KEY_KEYSET_HANDLE = "keyset_handle"
    }

    @Volatile
    private var cachedKeysetHandle: KeysetHandle? = null
    private var cachedPublicKeyRaw: ByteArray? = null

    /**
     * 获取或创建设备身份
     */
    suspend fun getOrCreateDeviceIdentity(): DeviceIdentity = withContext(Dispatchers.IO) {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

        val existingDeviceId = prefs.getString(KEY_DEVICE_ID, null)
        val existingPublicKeyRaw = prefs.getString(KEY_PUBLIC_KEY_RAW, null)
        val existingKeysetHandle = prefs.getString(KEY_KEYSET_HANDLE, null)

        if (existingDeviceId != null && existingPublicKeyRaw != null && existingKeysetHandle != null) {
            // 加载已存在的密钥
            try {
                val keysetBytes = Base64.decode(existingKeysetHandle, Base64.DEFAULT)
                cachedKeysetHandle = TinkProtoKeysetFormat.parseKeyset(keysetBytes, InsecureSecretKeyAccess.get())
                cachedPublicKeyRaw = Base64.decode(existingPublicKeyRaw, Base64.URL_SAFE or Base64.NO_PADDING or Base64.NO_WRAP)

                Log.d(TAG, "Loaded existing device identity: $existingDeviceId")

                DeviceIdentity(
                    id = existingDeviceId,
                    publicKey = existingPublicKeyRaw,
                    signature = "",
                    signedAt = 0,
                    nonce = ""
                )
            } catch (e: Exception) {
                Log.e(TAG, "Failed to load existing keyset, regenerating", e)
                generateNewIdentity(prefs)
            }
        } else {
            generateNewIdentity(prefs)
        }
    }

    /**
     * 生成新的设备身份
     */
    private fun generateNewIdentity(prefs: android.content.SharedPreferences): DeviceIdentity {
        Log.d(TAG, "Generating new Ed25519 key pair with Tink")

        // 注册 Tink Signature 配置
        try {
            SignatureConfig.register()
        } catch (e: Exception) {
            Log.w(TAG, "Signature config already registered or registration failed", e)
        }

        // 生成 Ed25519 密钥对
        val keysetHandle = KeysetHandle.generateNew(SignatureKeyTemplates.ED25519)

        // 获取公钥原始字节（Ed25519公钥是32字节）
        val publicKeyHandle = keysetHandle.publicKeysetHandle
        val publicKeyBytes = TinkProtoKeysetFormat.serializeKeyset(publicKeyHandle, InsecureSecretKeyAccess.get())
        
        // 从序列化的公钥keyset中提取原始公钥字节
        // Ed25519公钥在Tink中的格式是: 32字节的原始公钥
        val publicKeyRaw = extractPublicKeyBytes(publicKeyHandle)

        // 缓存
        cachedKeysetHandle = keysetHandle
        cachedPublicKeyRaw = publicKeyRaw

        // 派生设备 ID
        val deviceId = deriveDeviceId(publicKeyRaw)

        // 编码
        val publicKeyRawBase64Url = Base64.encodeToString(
            publicKeyRaw,
            Base64.URL_SAFE or Base64.NO_PADDING or Base64.NO_WRAP
        )

        val keysetHandleBase64 = Base64.encodeToString(
            TinkProtoKeysetFormat.serializeKeyset(keysetHandle, InsecureSecretKeyAccess.get()),
            Base64.DEFAULT
        )

        // 保存
        prefs.edit()
            .putString(KEY_DEVICE_ID, deviceId)
            .putString(KEY_PUBLIC_KEY_RAW, publicKeyRawBase64Url)
            .putString(KEY_KEYSET_HANDLE, keysetHandleBase64)
            .apply()

        Log.d(TAG, "Generated new device identity: $deviceId")

        return DeviceIdentity(
            id = deviceId,
            publicKey = publicKeyRawBase64Url,
            signature = "",
            signedAt = 0,
            nonce = ""
        )
    }
    
    /**
     * 从 publicKeysetHandle 提取原始公钥字节
     */
    private fun extractPublicKeyBytes(publicKeysetHandle: KeysetHandle): ByteArray {
        // Ed25519 公钥是 32 字节
        // 使用 TinkProtoKeysetFormat 序列化后解析
        val serialized = TinkProtoKeysetFormat.serializeKeyset(publicKeysetHandle, InsecureSecretKeyAccess.get())
        // 解析 proto 找到公钥数据
        val keyset = com.google.crypto.tink.proto.Keyset.parseFrom(serialized)
        val key = keyset.keyList.firstOrNull { key -> key.status == com.google.crypto.tink.proto.KeyStatusType.ENABLED }
            ?: throw IllegalStateException("No enabled key found")
        // Ed25519 公钥在 keyData 中
        val keyData = key.keyData
        // Ed25519 公钥格式: type_url = "type.googleapis.com/google.crypto.tink.Ed25519PublicKey"
        // value = Ed25519PublicKey proto
        val ed25519PublicKey = com.google.crypto.tink.proto.Ed25519PublicKey.parseFrom(keyData.value)
        return ed25519PublicKey.keyValue.toByteArray()
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
        Log.d(TAG, "scopes: $scopes")

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
     * 使用 Tink 签名 payload
     */
    private suspend fun signPayload(payload: String): String = withContext(Dispatchers.IO) {
        val keysetHandle = cachedKeysetHandle ?: loadKeysetFromStorage()
            ?: throw IllegalStateException("Device key not found. Call getOrCreateDeviceIdentity() first.")

        Log.d(TAG, "Signing payload with Tink")
        Log.d(TAG, "Payload: $payload")

        try {
            val signer = keysetHandle.getPrimitive(PublicKeySign::class.java)
            val signatureBytes = signer.sign(payload.toByteArray(Charsets.UTF_8))

            Log.d(TAG, "Signature length: ${signatureBytes.size} bytes")

            Base64.encodeToString(
                signatureBytes,
                Base64.URL_SAFE or Base64.NO_PADDING or Base64.NO_WRAP
            )
        } catch (e: Exception) {
            Log.e(TAG, "Failed to sign payload", e)
            throw e
        }
    }

    /**
     * 从存储加载密钥集
     */
    private fun loadKeysetFromStorage(): KeysetHandle? {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val keysetHandleBase64 = prefs.getString(KEY_KEYSET_HANDLE, null) ?: return null

        return try {
            val keysetBytes = Base64.decode(keysetHandleBase64, Base64.DEFAULT)
            cachedKeysetHandle = TinkProtoKeysetFormat.parseKeyset(keysetBytes, InsecureSecretKeyAccess.get())
            cachedKeysetHandle
        } catch (e: Exception) {
            Log.e(TAG, "Failed to load keyset from storage", e)
            null
        }
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
        cachedKeysetHandle = null
        cachedPublicKeyRaw = null
        context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            .edit()
            .clear()
            .apply()
    }

    /**
     * 从公钥派生设备 ID
     */
    private fun deriveDeviceId(publicKeyRaw: ByteArray): String {
        val digest = java.security.MessageDigest.getInstance("SHA-256")
        val hash = digest.digest(publicKeyRaw)
        return hash.joinToString("") { "%02x".format(it) }
    }
}