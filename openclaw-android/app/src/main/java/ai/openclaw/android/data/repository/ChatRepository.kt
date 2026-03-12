package ai.openclaw.android.data.repository

import ai.openclaw.android.core.network.GatewayClient
import ai.openclaw.android.data.local.dao.MessageDao
import ai.openclaw.android.data.local.dao.SessionDao
import ai.openclaw.android.data.local.entity.MessageEntity
import ai.openclaw.android.domain.model.Message
import ai.openclaw.android.domain.model.MessageRole
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map
import kotlinx.serialization.json.*
import java.util.UUID
import javax.inject.Inject
import javax.inject.Singleton

/**
 * 聊天仓库
 */
@Singleton
class ChatRepository @Inject constructor(
    private val messageDao: MessageDao,
    private val sessionDao: SessionDao,
    private val gatewayClient: GatewayClient,
    private val json: Json
) {
    /**
     * 获取会话消息流
     */
    fun getMessages(sessionKey: String): Flow<List<Message>> {
        return messageDao.getMessagesBySession(sessionKey).map { entities ->
            entities.map { it.toDomain() }
        }
    }
    
    /**
     * 获取历史消息（分页）
     */
    suspend fun getHistoryMessages(sessionKey: String, limit: Int = 50, offset: Int = 0): List<Message> {
        return messageDao.getMessagesPaged(sessionKey, limit, offset).map { it.toDomain() }
    }
    
    /**
     * 发送消息
     */
    suspend fun sendMessage(
        sessionKey: String,
        content: String
    ): Result<String> {
        // 1. 保存用户消息到本地
        val userMessageId = UUID.randomUUID().toString()
        val userMessage = MessageEntity(
            id = userMessageId,
            sessionKey = sessionKey,
            role = "user",
            content = content,
            timestamp = System.currentTimeMillis()
        )
        messageDao.insertMessage(userMessage)
        
        // 2. 创建占位的助手消息
        val assistantMessageId = UUID.randomUUID().toString()
        val assistantMessage = MessageEntity(
            id = assistantMessageId,
            sessionKey = sessionKey,
            role = "assistant",
            content = "",
            timestamp = System.currentTimeMillis(),
            isStreaming = true
        )
        messageDao.insertMessage(assistantMessage)
        
        // 3. 发送到服务器
        val actualSessionKey = if (sessionKey.isBlank()) "main" else sessionKey
        val params = buildJsonObject {
            put("sessionKey", actualSessionKey)
            put("messages", buildJsonArray {
                add(buildJsonObject {
                    put("role", "user")
                    put("content", content)
                })
            })
        }
        
        val result = gatewayClient.request("chat.send", params)
        
        return result.map { response ->
            val runId = response["runId"]?.jsonPrimitive?.content ?: ""
            
            // 更新消息的 runId
            messageDao.updateMessage(assistantMessage.copy(runId = runId))
            
            // 更新会话统计
            val count = messageDao.getMessageCount(sessionKey)
            sessionDao.updateSessionStats(
                key = sessionKey,
                count = count,
                lastMessage = content.take(100),
                lastTime = System.currentTimeMillis(),
                updatedAt = System.currentTimeMillis()
            )
            
            runId
        }
    }
    
    /**
     * 停止生成
     */
    suspend fun abort(sessionKey: String, runId: String): Result<Unit> {
        val actualSessionKey = if (sessionKey.isBlank()) "main" else sessionKey
        val params = buildJsonObject {
            put("sessionKey", actualSessionKey)
            put("runId", runId)
        }
        
        return gatewayClient.request("chat.abort", params).map {
            // 结束所有流式消息
            messageDao.finishAllStreaming(sessionKey)
        }
    }
    
    /**
     * 同步历史消息
     */
    suspend fun syncHistory(sessionKey: String, limit: Int = 50): Result<List<Message>> {
        // 使用固定的 main session
        val actualSessionKey = if (sessionKey.isBlank()) "main" else sessionKey
        
        val params = buildJsonObject {
            put("sessionKey", actualSessionKey)
            put("limit", limit)
        }
        
        val result = gatewayClient.request("chat.history", params)
        
        return result.map { response ->
            android.util.Log.d("ChatRepository", "=== syncHistory Response ===")
            android.util.Log.d("ChatRepository", "Response keys: ${response.keys}")
            android.util.Log.d("ChatRepository", "sessionKey: $actualSessionKey")
            
            val messagesArray = response["messages"]?.jsonArray
            android.util.Log.d("ChatRepository", "Messages array size: ${messagesArray?.size}")
            
            val messages = messagesArray?.mapNotNull { element ->
                val obj = element as? JsonObject ?: return@mapNotNull null
                
                // 提取内容：支持 text 字段和 content 字段
                val contentStr = extractMessageContent(obj)
                
                Message(
                    id = obj["id"]?.jsonPrimitive?.content ?: UUID.randomUUID().toString(),
                    sessionKey = actualSessionKey,
                    role = when (obj["role"]?.jsonPrimitive?.content) {
                        "user" -> MessageRole.USER
                        "assistant" -> MessageRole.ASSISTANT
                        "system" -> MessageRole.SYSTEM
                        else -> MessageRole.USER
                    },
                    content = contentStr,
                    timestamp = obj["timestamp"]?.jsonPrimitive?.longOrNull ?: System.currentTimeMillis()
                )
            } ?: emptyList()
            
            // 保存到本地
            android.util.Log.d("ChatRepository", "Saving ${messages.size} messages to database with sessionKey=$actualSessionKey")
            messages.forEach { 
                android.util.Log.d("ChatRepository", "  - id=${it.id}, role=${it.role}, content=${it.content.take(50)}...") 
            }
            messageDao.insertMessages(messages.map { it.toEntity() })
            
            messages
        }
    }
    
    /**
     * 从消息对象中提取文本内容
     * 支持格式：
     * 1. text 字段：直接使用
     * 2. content 字符串：直接使用
     * 3. content 数组：提取 type="text" 的 text 字段
     */
    private fun extractMessageContent(obj: JsonObject): String {
        // 优先检查 text 字段
        val textField = obj["text"]?.jsonPrimitive?.content
        if (!textField.isNullOrBlank()) {
            return textField
        }
        
        val content = obj["content"] ?: return ""
        
        return when (content) {
            is JsonPrimitive -> content.content
            is JsonArray -> {
                // 从 content blocks 数组中提取文本
                val textParts = content.mapNotNull { block ->
                    val blockObj = block as? JsonObject ?: return@mapNotNull null
                    when (blockObj["type"]?.jsonPrimitive?.content) {
                        "text" -> blockObj["text"]?.jsonPrimitive?.content
                        "thinking" -> null // 暂时跳过 thinking blocks
                        else -> null
                    }
                }.filter { !it.isNullOrBlank() }
                
                // 如果没有找到 text blocks，尝试其他方式
                if (textParts.isEmpty()) {
                    // 尝试提取 thinking 内容作为备用
                    content.mapNotNull { block ->
                        val blockObj = block as? JsonObject ?: return@mapNotNull null
                        if (blockObj["type"]?.jsonPrimitive?.content == "thinking") {
                            blockObj["thinking"]?.jsonPrimitive?.content
                        } else null
                    }.firstOrNull() ?: ""
                } else {
                    textParts.joinToString("\n\n")
                }
            }
            is JsonObject -> content.toString()
            else -> ""
        }
    }
    
    /**
     * 处理流式事件
     */
    suspend fun handleStreamEvent(event: JsonObject) {
        val eventType = event["event"]?.jsonPrimitive?.content ?: return
        val payload = event["payload"] as? JsonObject ?: return
        
        when (eventType) {
            "chat" -> {
                val messageId = payload["messageId"]?.jsonPrimitive?.content ?: return
                val content = payload["content"]?.jsonPrimitive?.content ?: ""
                val isDone = payload["done"]?.jsonPrimitive?.booleanOrNull ?: false
                
                messageDao.updateMessageContent(messageId, content, !isDone)
            }
            "chat.done" -> {
                val sessionKey = payload["key"]?.jsonPrimitive?.content ?: return
                messageDao.finishAllStreaming(sessionKey)
            }
        }
    }
}

// 扩展函数
private fun MessageEntity.toDomain() = Message(
    id = id,
    sessionKey = sessionKey,
    role = when (role) {
        "user" -> MessageRole.USER
        "assistant" -> MessageRole.ASSISTANT
        "system" -> MessageRole.SYSTEM
        else -> MessageRole.USER
    },
    content = content,
    timestamp = timestamp,
    thinking = thinking,
    isStreaming = isStreaming,
    runId = runId
)

private fun Message.toEntity() = MessageEntity(
    id = id,
    sessionKey = sessionKey,
    role = when (role) {
        MessageRole.USER -> "user"
        MessageRole.ASSISTANT -> "assistant"
        MessageRole.SYSTEM -> "system"
    },
    content = content,
    timestamp = timestamp,
    thinking = thinking,
    isStreaming = isStreaming,
    runId = runId
)