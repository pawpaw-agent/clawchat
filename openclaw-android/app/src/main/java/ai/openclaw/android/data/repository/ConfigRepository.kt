package ai.openclaw.android.data.repository

import ai.openclaw.android.core.network.GatewayClient
import ai.openclaw.android.domain.model.ConfigItem
import ai.openclaw.android.domain.model.ConfigType
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.serialization.json.*
import javax.inject.Inject
import javax.inject.Singleton

/**
 * 配置仓库
 */
@Singleton
class ConfigRepository @Inject constructor(
    private val gatewayClient: GatewayClient,
    private val json: Json
) {
    private val _config = MutableStateFlow<Map<String, ConfigItem>>(emptyMap())
    val config: Flow<Map<String, ConfigItem>> = _config.asStateFlow()
    
    /**
     * 同步配置
     */
    suspend fun syncConfig(): Result<Map<String, ConfigItem>> {
        val result = gatewayClient.request("config.get")
        
        return result.map { response ->
            val configMap = mutableMapOf<String, ConfigItem>()
            
            response.forEach { (key, value) ->
                val configItem = ConfigItem(
                    key = key,
                    value = value.toString(),
                    type = when (value) {
                        is JsonPrimitive -> {
                            when {
                                value.booleanOrNull != null -> ConfigType.BOOLEAN
                                value.longOrNull != null -> ConfigType.NUMBER
                                value.doubleOrNull != null -> ConfigType.NUMBER
                                else -> ConfigType.STRING
                            }
                        }
                        is JsonObject, is JsonArray -> ConfigType.JSON
                        else -> ConfigType.STRING
                    },
                    description = null,
                    readOnly = false
                )
                configMap[key] = configItem
            }
            
            _config.value = configMap
            configMap
        }
    }
    
    /**
     * 设置配置项
     */
    suspend fun setConfig(key: String, value: String): Result<Unit> {
        val params = buildJsonObject {
            put("key", key)
            put("value", value)
        }
        
        return gatewayClient.request("config.set", params).map {
            // 更新本地缓存
            val current = _config.value.toMutableMap()
            current[key]?.let { existing ->
                current[key] = existing.copy(value = value)
            }
            _config.value = current
        }
    }
    
    /**
     * 获取单个配置项
     */
    suspend fun getConfigItem(key: String): Result<ConfigItem?> {
        val params = buildJsonObject {
            put("key", key)
        }
        
        return gatewayClient.request("config.get", params).map { response ->
            val value = response[key]
            value?.let {
                ConfigItem(
                    key = key,
                    value = it.toString(),
                    type = ConfigType.STRING,
                    description = null,
                    readOnly = false
                )
            }
        }
    }
}