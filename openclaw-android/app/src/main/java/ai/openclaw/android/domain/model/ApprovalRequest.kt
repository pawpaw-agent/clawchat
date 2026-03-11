package ai.openclaw.android.domain.model

/**
 * 审批请求模型
 */
data class ApprovalRequest(
    val approvalId: String,
    val command: String,
    val risk: String?,
    val context: String?,
    val requestedAt: Long,
    val expiresIn: Long?,
    val requestedBy: String?
)

/**
 * 审批操作类型
 */
enum class ApprovalAction {
    ALLOW_ONCE,
    ALLOW_ALWAYS,
    DENY
}