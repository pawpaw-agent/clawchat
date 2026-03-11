package ai.openclaw.android.domain.model

/**
 * Gateway 配置模型
 */
data class GatewayConfig(
    val id: Long = 0,
    val name: String,
    val url: String,
    val token: String? = null,
    val isDefault: Boolean = false,
    val lastConnected: Long? = null,
    val createdAt: Long = System.currentTimeMillis()
)