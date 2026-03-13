package ai.openclaw.android.domain.model

import kotlinx.serialization.Serializable
import kotlinx.serialization.builtins.ListSerializer
import kotlinx.serialization.json.Json

/**
 * 消息附件类型
 */
enum class AttachmentType {
    IMAGE,
    FILE,
    VIDEO,
    AUDIO
}

/**
 * 消息附件
 */
@Serializable
data class MessageAttachment(
    val id: String,
    val type: String, // "image", "file", "video", "audio"
    val name: String,
    val mimeType: String,
    val size: Long = 0,
    val url: String? = null,
    val localPath: String? = null,
    val thumbnailUrl: String? = null,
    val width: Int? = null,
    val height: Int? = null
) {
    /**
     * 是否是图片
     */
    val isImage: Boolean get() = type == "image"
    
    /**
     * 获取附件类型枚举
     */
    val attachmentType: AttachmentType
        get() = when (type) {
            "image" -> AttachmentType.IMAGE
            "file" -> AttachmentType.FILE
            "video" -> AttachmentType.VIDEO
            "audio" -> AttachmentType.AUDIO
            else -> AttachmentType.FILE
        }
    
    /**
     * 格式化文件大小
     */
    val formattedSize: String
        get() = when {
            size < 1024 -> "$size B"
            size < 1024 * 1024 -> "${size / 1024} KB"
            size < 1024 * 1024 * 1024 -> "${size / (1024 * 1024)} MB"
            else -> "${size / (1024 * 1024 * 1024)} GB"
        }
    
    companion object {
        private val json = Json { ignoreUnknownKeys = true }
        
        /**
         * 从 JSON 字符串解析附件列表
         */
        fun parseList(jsonString: String?): List<MessageAttachment>? {
            if (jsonString.isNullOrBlank()) return null
            return try {
                json.decodeFromString<List<MessageAttachment>>(jsonString)
            } catch (e: Exception) {
                null
            }
        }
        
        /**
         * 序列化附件列表为 JSON 字符串
         */
        fun serializeList(attachments: List<MessageAttachment>?): String? {
            if (attachments.isNullOrEmpty()) return null
            return json.encodeToString(ListSerializer(serializer()), attachments)
        }
    }
}