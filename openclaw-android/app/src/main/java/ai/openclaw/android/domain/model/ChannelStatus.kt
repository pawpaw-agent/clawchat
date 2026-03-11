package ai.openclaw.android.domain.model

/**
 * 渠道状态模型
 */
data class ChannelStatus(
    val channel: String,
    val label: String?,
    val provider: String?,
    val status: ChannelConnectionStatus,
    val connectedAt: Long?,
    val error: String?,
    val qrCode: String? = null,
    val lastActivity: Long?
)

/**
 * 渠道连接状态
 */
enum class ChannelConnectionStatus {
    CONNECTED,
    DISCONNECTED,
    CONNECTING,
    ERROR,
    NEEDS_QR,
    NEEDS_LOGIN
}