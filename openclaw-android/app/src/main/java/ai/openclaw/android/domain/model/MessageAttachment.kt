package ai.openclaw.android.domain.model

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
data class MessageAttachment(
    val id: String,
    val type: AttachmentType,
    val name: String,
    val mimeType: String,
    val size: Long,
    val url: String? = null,
    val localPath: String? = null,
    val thumbnailUrl: String? = null,
    val width: Int? = null,
    val height: Int? = null
) {
    /**
     * 是否是图片
     */
    val isImage: Boolean get() = type == AttachmentType.IMAGE
    
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
}