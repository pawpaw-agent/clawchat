package ai.openclaw.android.data.repository

import ai.openclaw.android.core.network.GatewayClient
import ai.openclaw.android.data.local.dao.MessageDao
import ai.openclaw.android.data.local.dao.SessionDao
import ai.openclaw.android.data.local.entity.MessageEntity
import ai.openclaw.android.domain.model.Message
import ai.openclaw.android.domain.model.MessageAttachment
import ai.openclaw.android.domain.model.MessageRole
import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.net.Uri
import android.util.Base64
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.withContext
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.*
import java.io.ByteArrayOutputStream
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
    private val json: Json,
    @android.annotation.SuppressLint("StaticFieldLeak")
    private val context: Context
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
        val idempotencyKey = UUID.randomUUID().toString()
        val params = buildJsonObject {
            put("sessionKey", actualSessionKey)
            put("message", content)
            put("idempotencyKey", idempotencyKey)
        }
        
        android.util.Log.d("ChatRepository", "=== chat.send params ===")
        android.util.Log.d("ChatRepository", "sessionKey: $actualSessionKey")
        android.util.Log.d("ChatRepository", "message: ${content.take(50)}...")
        android.util.Log.d("ChatRepository", "idempotencyKey: $idempotencyKey")
        
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
     * 发送带图片的消息
     */
    suspend fun sendMessageWithImage(
        sessionKey: String,
        content: String,
        imageUri: Uri
    ): Result<String> = withContext(Dispatchers.IO) {
        // 1. 压缩图片
        val compressedImage = compressImage(imageUri)
        if (compressedImage == null) {
            return@withContext Result.failure(Exception("Failed to compress image"))
        }
        
        // 2. 转换为 base64
        val base64Image = Base64.encodeToString(compressedImage, Base64.NO_WRAP)
        
        // 3. 构建附件 (Gateway expects 'content' field for base64 data)
        val attachment = buildJsonObject {
            put("type", "image")
            put("mimeType", "image/jpeg")
            put("content", base64Image)  // Use 'content' not 'data'
        }
        
        // 4. 保存用户消息到本地
        val userMessageId = UUID.randomUUID().toString()
        val userMessage = MessageEntity(
            id = userMessageId,
            sessionKey = sessionKey,
            role = "user",
            content = content,
            timestamp = System.currentTimeMillis(),
            attachments = json.encodeToString(listOf(
                mapOf("type" to "image", "mimeType" to "image/jpeg")
            ))
        )
        messageDao.insertMessage(userMessage)
        
        // 5. 创建占位的助手消息
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
        
        // 6. 发送到服务器
        val actualSessionKey = if (sessionKey.isBlank()) "main" else sessionKey
        val idempotencyKey = UUID.randomUUID().toString()
        val params = buildJsonObject {
            put("sessionKey", actualSessionKey)
            put("message", content)
            put("idempotencyKey", idempotencyKey)
            put("attachments", buildJsonArray { add(attachment) })
        }
        
        val result = gatewayClient.request("chat.send", params)
        
        result.map { response ->
            val runId = response["runId"]?.jsonPrimitive?.content ?: ""
            messageDao.updateMessage(assistantMessage.copy(runId = runId))
            runId
        }
    }
    
    /**
     * 压缩图片
     */
    private fun compressImage(uri: Uri, maxSizeKB: Int = 500): ByteArray? {
        return try {
            val inputStream = context.contentResolver.openInputStream(uri) ?: return null
            val bitmap = BitmapFactory.decodeStream(inputStream)
            inputStream.close()
            
            // 计算压缩质量
            var quality = 90
            var compressedBytes: ByteArray
            val outputStream = ByteArrayOutputStream()
            
            do {
                outputStream.reset()
                bitmap.compress(Bitmap.CompressFormat.JPEG, quality, outputStream)
                compressedBytes = outputStream.toByteArray()
                quality -= 10
            } while (compressedBytes.size > maxSizeKB * 1024 && quality > 10)
            
            outputStream.close()
            bitmap.recycle()
            
            compressedBytes
        } catch (e: Exception) {
            android.util.Log.e("ChatRepository", "Failed to compress image", e)
            null
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
     * 
     * Chat Event 格式 (Protocol v3):
     * {
     *   "event": "chat",
     *   "payload": {
     *     "runId": "...",
     *     "sessionKey": "...",
     *     "seq": 0,
     *     "state": "delta" | "final" | "aborted" | "error",
     *     "message": { ... },
     *     "errorMessage": "..." // only when state=error
     *   }
     * }
     */
    suspend fun handleStreamEvent(event: JsonObject) {
        val eventType = event["event"]?.jsonPrimitive?.content ?: return
        val payload = event["payload"] as? JsonObject ?: return
        
        when (eventType) {
            "chat" -> {
                val runId = payload["runId"]?.jsonPrimitive?.content ?: return
                val state = payload["state"]?.jsonPrimitive?.content ?: "delta"
                val message = payload["message"] as? JsonObject
                val errorMessage = payload["errorMessage"]?.jsonPrimitive?.content
                
                android.util.Log.d("ChatRepository", "Chat event: runId=$runId, state=$state")
                
                when (state) {
                    "delta" -> {
                        // 增量更新：从 message 中提取内容
                        val content = message?.let { extractMessageContent(it) } ?: ""
                        // 查找并更新正在流式的消息，如果不存在则创建
                        val existingMessage = messageDao.getMessageByRunId(runId)
                        if (existingMessage == null) {
                            // 创建新的流式消息
                            val newMessage = MessageEntity(
                                id = UUID.randomUUID().toString(),
                                sessionKey = payload["sessionKey"]?.jsonPrimitive?.content ?: "main",
                                role = "assistant",
                                content = content,
                                timestamp = System.currentTimeMillis(),
                                isStreaming = true,
                                runId = runId
                            )
                            messageDao.insertMessage(newMessage)
                        } else {
                            messageDao.updateStreamingMessageContent(runId, content, true)
                        }
                    }
                    "final" -> {
                        // 完成：更新最终内容并标记消息为非流式
                        val content = message?.let { extractMessageContent(it) } ?: ""
                        if (content.isNotBlank()) {
                            messageDao.updateStreamingMessageContent(runId, content, false)
                        } else {
                            messageDao.finishStreamingByRunId(runId)
                        }
                    }
                    "aborted" -> {
                        // 中止：标记消息为非流式
                        messageDao.finishStreamingByRunId(runId)
                        android.util.Log.d("ChatRepository", "Chat aborted: runId=$runId")
                    }
                    "error" -> {
                        // 错误：标记消息为非流式并记录错误
                        val errorMsg = errorMessage ?: "Unknown error"
                        messageDao.setErrorByRunId(runId, errorMsg)
                        android.util.Log.e("ChatRepository", "Chat error: runId=$runId, error=$errorMsg")
                    }
                }
            }
            "chat.done" -> {
                // 兼容旧版事件格式
                val sessionKey = payload["key"]?.jsonPrimitive?.content ?: return
                messageDao.finishAllStreaming(sessionKey)
            }
        }
    }
    
    /**
     * 删除消息（本地）
     */
    suspend fun deleteMessage(messageId: String) {
        messageDao.deleteMessageById(messageId)
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
    runId = runId,
    error = error,
    attachments = MessageAttachment.parseList(attachments)
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
    runId = runId,
    error = error,
    attachments = MessageAttachment.serializeList(attachments)
)