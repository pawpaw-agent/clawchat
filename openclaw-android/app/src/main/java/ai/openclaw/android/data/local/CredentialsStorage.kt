package ai.openclaw.android.data.local

import android.content.Context
import androidx.security.crypto.EncryptedSharedPreferences
import androidx.security.crypto.MasterKey
import dagger.hilt.android.qualifiers.ApplicationContext
import javax.inject.Inject
import javax.inject.Singleton

/**
 * 凭证存储管理器
 * 使用 EncryptedSharedPreferences 安全存储 Gateway URL 和 Token
 */
@Singleton
class CredentialsStorage @Inject constructor(
    @ApplicationContext private val context: Context
) {
    private val masterKey = MasterKey.Builder(context)
        .setKeyScheme(MasterKey.KeyScheme.AES256_GCM)
        .build()

    private val sharedPreferences = EncryptedSharedPreferences.create(
        context,
        "clawchat_credentials",
        masterKey,
        EncryptedSharedPreferences.PrefKeyEncryptionScheme.AES256_SIV,
        EncryptedSharedPreferences.PrefValueEncryptionScheme.AES256_GCM
    )

    /**
     * 保存 Gateway 凭证
     */
    fun saveCredentials(url: String, token: String?) {
        sharedPreferences.edit()
            .putString(KEY_GATEWAY_URL, url)
            .putString(KEY_TOKEN, token ?: "")
            .apply()
    }

    /**
     * 获取保存的 Gateway URL
     */
    fun getGatewayUrl(): String? {
        return try {
            sharedPreferences.getString(KEY_GATEWAY_URL, null)
        } catch (e: Exception) {
            android.util.Log.e("CredentialsStorage", "Failed to get gateway URL: ${e.message}")
            // 可能是签名变更导致无法解密，清除旧数据
            clearCredentials()
            null
        }
    }

    /**
     * 获取保存的 Token
     */
    fun getToken(): String? {
        return try {
            val token = sharedPreferences.getString(KEY_TOKEN, null)
            if (token.isNullOrBlank()) null else token
        } catch (e: Exception) {
            android.util.Log.e("CredentialsStorage", "Failed to get token: ${e.message}")
            // 可能是签名变更导致无法解密，清除旧数据
            clearCredentials()
            null
        }
    }

    /**
     * 清除保存的凭证
     */
    fun clearCredentials() {
        sharedPreferences.edit()
            .remove(KEY_GATEWAY_URL)
            .remove(KEY_TOKEN)
            .apply()
    }

    /**
     * 检查是否有保存的凭证
     */
    fun hasCredentials(): Boolean {
        val url = getGatewayUrl()
        return !url.isNullOrBlank()
    }

    companion object {
        private const val KEY_GATEWAY_URL = "gateway_url"
        private const val KEY_TOKEN = "token"
    }
}