package ai.openclaw.android.data.local.entity

import androidx.room.Entity
import androidx.room.PrimaryKey

/**
 * 会话实体
 */
@Entity(tableName = "sessions")
data class SessionEntity(
    @PrimaryKey
    val key: String,
    val label: String?,
    val channel: String?,
    val provider: String?,
    val model: String?,
    val createdAt: Long,
    val updatedAt: Long,
    val messageCount: Int = 0,
    val lastMessage: String? = null,
    val lastMessageTime: Long? = null
)