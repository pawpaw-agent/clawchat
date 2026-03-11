package ai.openclaw.android.domain.model

/**
 * 节点状态模型
 */
data class NodeStatus(
    val nodeId: String,
    val label: String?,
    val online: Boolean,
    val capabilities: List<String>,
    val lastSeen: Long?,
    val provider: String?,
    val model: String?
)