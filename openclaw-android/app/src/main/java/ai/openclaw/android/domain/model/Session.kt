package ai.openclaw.android.domain.model

/**
 * 会话模型
 */
data class Session(
    val key: String,
    val label: String?,
    val channel: String?,
    val provider: String?,
    val model: String?,
    val createdAt: Long,
    val updatedAt: Long,
    val messageCount: Int
) {
    val displayName: String
        get() = label ?: "Session ${key.take(8)}"
}