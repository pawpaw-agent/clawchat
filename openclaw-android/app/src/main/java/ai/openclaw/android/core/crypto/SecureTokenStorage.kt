package ai.openclaw.android.core.crypto

import android.content.Context
import androidx.datastore.core.DataStore
import androidx.datastore.preferences.core.Preferences
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.stringPreferencesKey
import androidx.datastore.preferences.preferencesDataStore
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.withContext
import javax.inject.Inject
import javax.inject.Singleton

private val Context.dataStore: DataStore<Preferences> by preferencesDataStore(name = "openclaw_secure_tokens")

/**
 * 安全的 Token 存储
 * 使用 DataStore 存储 Token（后续可升级为 EncryptedDataStore）
 */
@Singleton
class SecureTokenStorage @Inject constructor(
    @ApplicationContext private val context: Context
) {
    companion object {
        private val KEY_DEVICE_TOKEN = stringPreferencesKey("device_token")
        private val KEY_GATEWAY_URL = stringPreferencesKey("gateway_url")
    }

    /**
     * 保存设备 Token
     */
    suspend fun saveDeviceToken(token: String) = withContext(Dispatchers.IO) {
        context.dataStore.edit { prefs ->
            prefs[KEY_DEVICE_TOKEN] = token
        }
    }

    /**
     * 获取设备 Token
     */
    suspend fun getDeviceToken(): String? = withContext(Dispatchers.IO) {
        context.dataStore.data.map { prefs ->
            prefs[KEY_DEVICE_TOKEN]
        }.first()
    }

    /**
     * 保存 Gateway URL
     */
    suspend fun saveGatewayUrl(url: String) = withContext(Dispatchers.IO) {
        context.dataStore.edit { prefs ->
            prefs[KEY_GATEWAY_URL] = url
        }
    }

    /**
     * 获取 Gateway URL
     */
    suspend fun getGatewayUrl(): String? = withContext(Dispatchers.IO) {
        context.dataStore.data.map { prefs ->
            prefs[KEY_GATEWAY_URL]
        }.first()
    }

    /**
     * 清除所有 Token
     */
    suspend fun clearTokens() = withContext(Dispatchers.IO) {
        context.dataStore.edit { prefs ->
            prefs.remove(KEY_DEVICE_TOKEN)
            prefs.remove(KEY_GATEWAY_URL)
        }
    }
}