package ai.openclaw.android.data.repository

import ai.openclaw.android.data.local.dao.GatewayConfigDao
import ai.openclaw.android.data.local.entity.GatewayConfigEntity
import ai.openclaw.android.domain.model.GatewayConfig
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map
import javax.inject.Inject
import javax.inject.Singleton

/**
 * Gateway 配置仓库
 */
@Singleton
class GatewayConfigRepository @Inject constructor(
    private val configDao: GatewayConfigDao
) {
    /**
     * 获取所有配置
     */
    fun getAllConfigs(): Flow<List<GatewayConfig>> {
        return configDao.getAllConfigs().map { entities ->
            entities.map { it.toDomain() }
        }
    }
    
    /**
     * 获取默认配置
     */
    suspend fun getDefaultConfig(): GatewayConfig? {
        return configDao.getDefaultConfig()?.toDomain()
    }
    
    /**
     * 获取默认配置流
     */
    fun getDefaultConfigFlow(): Flow<GatewayConfig?> {
        return configDao.getDefaultConfigFlow().map { it?.toDomain() }
    }
    
    /**
     * 保存配置
     */
    suspend fun saveConfig(config: GatewayConfig): Long {
        return configDao.insertConfig(config.toEntity())
    }
    
    /**
     * 设置默认配置
     */
    suspend fun setDefault(id: Long) {
        configDao.clearDefault()
        configDao.setDefault(id)
    }
    
    /**
     * 删除配置
     */
    suspend fun deleteConfig(id: Long) {
        configDao.deleteConfigById(id)
    }
    
    /**
     * 更新最后连接时间
     */
    suspend fun updateLastConnected(id: Long) {
        val config = configDao.getConfigById(id) ?: return
        configDao.updateConfig(config.copy(lastConnected = System.currentTimeMillis()))
    }
}

private fun GatewayConfigEntity.toDomain() = GatewayConfig(
    id = id,
    name = name,
    url = url,
    token = token,
    isDefault = isDefault,
    lastConnected = lastConnected,
    createdAt = createdAt
)

private fun GatewayConfig.toEntity() = GatewayConfigEntity(
    id = id,
    name = name,
    url = url,
    token = token,
    isDefault = isDefault,
    lastConnected = lastConnected,
    createdAt = createdAt
)