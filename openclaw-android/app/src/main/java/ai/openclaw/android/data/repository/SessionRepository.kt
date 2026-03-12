package ai.openclaw.android.data.repository

import ai.openclaw.android.core.network.GatewayClient
import ai.openclaw.android.data.local.dao.SessionDao
import ai.openclaw.android.data.local.entity.SessionEntity
import ai.openclaw.android.domain.model.Session
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map
import kotlinx.serialization.json.*
import javax.inject.Inject
import javax.inject.Singleton

/**
 * 会话仓库
 */
@Singleton
class SessionRepository @Inject constructor(
    private val sessionDao: SessionDao,
    private val gatewayClient: GatewayClient
) {
    /**
     * 获取所有会话
     */
    fun getAllSessions(): Flow<List<Session>> {
        return sessionDao.getAllSessions().map { entities ->
            entities.map { it.toDomain() }
        }
    }
    
    /**
     * 获取单个会话
     */
    suspend fun getSessionByKey(key: String): Session? {
        return sessionDao.getSessionByKey(key)?.toDomain()
    }
    
    /**
     * 从服务器同步会话列表
     */
    suspend fun syncSessions(): Result<List<Session>> {
        // 调用 Gateway sessions.list API
        val result = gatewayClient.request("sessions.list", buildJsonObject {
            put("limit", 50)
            put("includeGlobal", true)
        })
        
        return result.map { response ->
            val sessionsArray = response["sessions"]?.jsonArray
            val sessions = sessionsArray?.mapNotNull { element ->
                val obj = element as? JsonObject ?: return@mapNotNull null
                Session(
                    key = obj["key"]?.jsonPrimitive?.content ?: return@mapNotNull null,
                    label = obj["label"]?.jsonPrimitive?.contentOrNull,
                    channel = obj["channel"]?.jsonPrimitive?.contentOrNull,
                    provider = obj["provider"]?.jsonPrimitive?.contentOrNull,
                    model = obj["model"]?.jsonPrimitive?.contentOrNull,
                    createdAt = obj["createdAt"]?.jsonPrimitive?.longOrNull ?: System.currentTimeMillis(),
                    updatedAt = obj["updatedAt"]?.jsonPrimitive?.longOrNull ?: System.currentTimeMillis(),
                    messageCount = obj["messageCount"]?.jsonPrimitive?.intOrNull ?: 0
                )
            } ?: emptyList()
            
            // 保存到本地数据库
            sessions.forEach { session ->
                sessionDao.insertSession(session.toEntity())
            }
            
            sessions
        }
    }
    
    /**
     * 创建新会话
     */
    suspend fun createSession(label: String? = null): Result<Session> {
        // 返回固定的 main session
        val session = Session(
            key = "main",
            label = label ?: "Main",
            channel = null,
            provider = null,
            model = null,
            createdAt = System.currentTimeMillis(),
            updatedAt = System.currentTimeMillis(),
            messageCount = 0
        )
        return Result.success(session)
    }
    
    /**
     * 更新会话属性
     * 
     * @param key 会话 key
     * @param model 模型 ID（可选）
     * @param label 标签（可选）
     */
    suspend fun patchSession(
        key: String,
        model: String? = null,
        label: String? = null
    ): Result<Unit> {
        val params = buildJsonObject {
            put("key", key)
            model?.let { put("model", it) }
            label?.let { put("label", it) }
        }
        
        return gatewayClient.request("sessions.patch", params).map {
            // 更新本地数据库
            val existing = sessionDao.getSessionByKey(key)
            existing?.let {
                sessionDao.updateSession(
                    it.copy(
                        model = model ?: it.model,
                        label = label ?: it.label,
                        updatedAt = System.currentTimeMillis()
                    )
                )
            }
        }
    }
    
    /**
     * 删除会话
     */
    suspend fun deleteSession(key: String): Result<Unit> {
        val params = buildJsonObject {
            put("key", key)
        }
        
        return gatewayClient.request("sessions.delete", params).map {
            sessionDao.deleteSessionByKey(key)
        }
    }
    
    /**
     * 重置会话
     */
    suspend fun resetSession(key: String): Result<Unit> {
        val params = buildJsonObject {
            put("key", key)
            put("reason", "reset")
        }
        
        return gatewayClient.request("sessions.reset", params)
    }
}

// 扩展函数：Entity -> Domain
private fun SessionEntity.toDomain() = Session(
    key = key,
    label = label,
    channel = channel,
    provider = provider,
    model = model,
    createdAt = createdAt,
    updatedAt = updatedAt,
    messageCount = messageCount
)

// 扩展函数：Domain -> Entity
private fun Session.toEntity() = SessionEntity(
    key = key,
    label = label,
    channel = channel,
    provider = provider,
    model = model,
    createdAt = createdAt,
    updatedAt = updatedAt,
    messageCount = messageCount
)