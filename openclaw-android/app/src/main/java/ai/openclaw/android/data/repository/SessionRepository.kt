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
    private val gatewayClient: GatewayClient,
    private val json: Json
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
        val result = gatewayClient.request("session.list")
        
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
                    messageCount = obj["messageCount"]?.jsonPrimitive?.longOrNull?.toInt() ?: 0
                )
            } ?: emptyList()
            
            // 保存到本地数据库
            sessionDao.insertSessions(sessions.map { it.toEntity() })
            
            sessions
        }
    }
    
    /**
     * 创建新会话
     */
    suspend fun createSession(label: String? = null): Result<Session> {
        val params = buildJsonObject {
            label?.let { put("label", it) }
        }
        
        val result = gatewayClient.request("session.create", params)
        
        return result.map { response ->
            val session = Session(
                key = response["key"]?.jsonPrimitive?.content ?: "",
                label = response["label"]?.jsonPrimitive?.contentOrNull,
                channel = response["channel"]?.jsonPrimitive?.contentOrNull,
                provider = response["provider"]?.jsonPrimitive?.contentOrNull,
                model = response["model"]?.jsonPrimitive?.contentOrNull,
                createdAt = response["createdAt"]?.jsonPrimitive?.longOrNull ?: System.currentTimeMillis(),
                updatedAt = response["updatedAt"]?.jsonPrimitive?.longOrNull ?: System.currentTimeMillis(),
                messageCount = 0
            )
            
            // 保存到本地数据库
            sessionDao.insertSession(session.toEntity())
            
            session
        }
    }
    
    /**
     * 删除会话
     */
    suspend fun deleteSession(key: String): Result<Unit> {
        val params = buildJsonObject {
            put("key", key)
        }
        
        return gatewayClient.request("session.delete", params).map {
            sessionDao.deleteSessionByKey(key)
        }
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