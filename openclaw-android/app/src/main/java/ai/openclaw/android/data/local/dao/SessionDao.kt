package ai.openclaw.android.data.local.dao

import androidx.room.*
import ai.openclaw.android.data.local.entity.SessionEntity
import kotlinx.coroutines.flow.Flow

@Dao
interface SessionDao {
    @Query("SELECT * FROM sessions ORDER BY updatedAt DESC")
    fun getAllSessions(): Flow<List<SessionEntity>>
    
    @Query("SELECT * FROM sessions WHERE `key` = :key")
    suspend fun getSessionByKey(key: String): SessionEntity?
    
    @Query("SELECT * FROM sessions WHERE `key` = :key")
    fun getSessionByKeyFlow(key: String): Flow<SessionEntity?>
    
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertSession(session: SessionEntity)
    
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertSessions(sessions: List<SessionEntity>)
    
    @Update
    suspend fun updateSession(session: SessionEntity)
    
    @Query("UPDATE sessions SET messageCount = :count, lastMessage = :lastMessage, lastMessageTime = :lastTime, updatedAt = :updatedAt WHERE `key` = :key")
    suspend fun updateSessionStats(key: String, count: Int, lastMessage: String?, lastTime: Long?, updatedAt: Long)
    
    @Delete
    suspend fun deleteSession(session: SessionEntity)
    
    @Query("DELETE FROM sessions WHERE `key` = :key")
    suspend fun deleteSessionByKey(key: String)
    
    @Query("DELETE FROM sessions")
    suspend fun deleteAllSessions()
}