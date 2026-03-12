package ai.openclaw.android.data.local.dao

import androidx.room.*
import ai.openclaw.android.data.local.entity.MessageEntity
import kotlinx.coroutines.flow.Flow

@Dao
interface MessageDao {
    @Query("SELECT * FROM messages WHERE sessionKey = :sessionKey ORDER BY timestamp ASC")
    fun getMessagesBySession(sessionKey: String): Flow<List<MessageEntity>>
    
    @Query("SELECT * FROM messages WHERE sessionKey = :sessionKey ORDER BY timestamp DESC LIMIT :limit OFFSET :offset")
    suspend fun getMessagesPaged(sessionKey: String, limit: Int, offset: Int): List<MessageEntity>
    
    @Query("SELECT * FROM messages WHERE id = :id")
    suspend fun getMessageById(id: String): MessageEntity?
    
    @Query("SELECT COUNT(*) FROM messages WHERE sessionKey = :sessionKey")
    suspend fun getMessageCount(sessionKey: String): Int
    
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertMessage(message: MessageEntity)
    
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertMessages(messages: List<MessageEntity>)
    
    @Update
    suspend fun updateMessage(message: MessageEntity)
    
    @Query("UPDATE messages SET content = :content, isStreaming = :isStreaming WHERE id = :id")
    suspend fun updateMessageContent(id: String, content: String, isStreaming: Boolean)
    
    @Query("UPDATE messages SET isStreaming = 0 WHERE sessionKey = :sessionKey")
    suspend fun finishAllStreaming(sessionKey: String)
    
    @Query("UPDATE messages SET content = :content, isStreaming = :isStreaming WHERE runId = :runId AND isStreaming = 1")
    suspend fun updateStreamingMessageContent(runId: String, content: String, isStreaming: Boolean)
    
    @Query("UPDATE messages SET isStreaming = 0 WHERE runId = :runId")
    suspend fun finishStreamingByRunId(runId: String)
    
    @Delete
    suspend fun deleteMessage(message: MessageEntity)
    
    @Query("DELETE FROM messages WHERE sessionKey = :sessionKey")
    suspend fun deleteMessagesBySession(sessionKey: String)
    
    @Query("DELETE FROM messages WHERE sessionKey = :sessionKey AND id = :id")
    suspend fun deleteMessageById(sessionKey: String, id: String)
}