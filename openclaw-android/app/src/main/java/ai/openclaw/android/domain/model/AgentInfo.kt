package ai.openclaw.android.domain.model

/**
 * Agent 信息
 */
data class AgentInfo(
    val id: String,
    val name: String? = null,
    val model: String? = null,
    val workspace: String? = null,
    val identity: AgentIdentity? = null
)

data class AgentIdentity(
    val emoji: String? = null,
    val name: String? = null
)