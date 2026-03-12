package ai.openclaw.android.data.repository

import ai.openclaw.android.data.local.dao.SessionDao
import ai.openclaw.android.data.local.entity.SessionEntity
import ai.openclaw.android.domain.model.Session
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map
import javax.inject.Inject
import javax.inject.Singleton

/**
 * 会话仓库
 * 注意：session.list/create/delete API 暂不支持
 */
@Singleton
class SessionRepository @Inject constructor(
    private val sessionDao: SessionDao
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
     * 注意：session.list API 暂不支持，使用固定的 main session
     */
    suspend fun syncSessions(): Result<List<Session>> {
        // Gateway 不支持 session.list，确保本地有 main session
        val existingMain = sessionDao.getSessionByKey("main")
        if (existingMain == null) {
            // 创建并保存 main session
            val mainEntity = SessionEntity(
                key = "main",
                label = "Main",
                channel = null,
                provider = null,
                model = null,
                createdAt = System.currentTimeMillis(),
                updatedAt = System.currentTimeMillis(),
                messageCount = 0
            )
            sessionDao.insertSession(mainEntity)
        }
        
        // 返回本地所有 sessions
        val sessions = sessionDao.getAllSessionsOnce().map { it.toDomain() }
        return Result.success(sessions)
    }
    
    /**
     * 创建新会话
     * 注意：session.create API 暂不支持
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
     * 删除会话
     * 注意：session.delete API 暂不支持
     */
    suspend fun deleteSession(key: String): Result<Unit> {
        return Result.success(Unit)
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