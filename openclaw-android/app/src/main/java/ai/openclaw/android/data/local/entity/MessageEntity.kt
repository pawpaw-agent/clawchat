package ai.openclaw.android.data.local.entity

import androidx.room.Entity
import androidx.room.ForeignKey
import androidx.room.Index
import androidx.room.PrimaryKey

/**
 * 消息实体
 */
@Entity(
    tableName = "messages",
    foreignKeys = [
        ForeignKey(
            entity = SessionEntity::class,
            parentColumns = ["key"],
            childColumns = ["sessionKey"],
            onDelete = ForeignKey.CASCADE
        )
    ],
    indices = [Index("sessionKey"), Index("timestamp")]
)
data class MessageEntity(
    @PrimaryKey
    val id: String,
    val sessionKey: String,
    val role: String, // "user", "assistant", "system"
    val content: String,
    val timestamp: Long,
    val thinking: String? = null,
    val toolCalls: String? = null, // JSON string
    val toolOutputs: String? = null, // JSON string
    val isStreaming: Boolean = false,
    val runId: String? = null,
    val error: String? = null // 错误信息
)