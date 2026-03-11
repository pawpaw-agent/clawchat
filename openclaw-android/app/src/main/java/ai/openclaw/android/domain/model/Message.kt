package ai.openclaw.android.domain.model

/**
 * 消息模型
 */
data class Message(
    val id: String,
    val sessionKey: String,
    val role: MessageRole,
    val content: String,
    val timestamp: Long,
    val thinking: String? = null,
    val toolCalls: List<ToolCall>? = null,
    val isStreaming: Boolean = false,
    val runId: String? = null
)

/**
 * 消息角色
 */
enum class MessageRole {
    USER,
    ASSISTANT,
    SYSTEM
}

/**
 * 工具调用
 */
data class ToolCall(
    val id: String,
    val name: String,
    val arguments: String
)

/**
 * 工具输出
 */
data class ToolOutput(
    val toolCallId: String,
    val output: String
)