package ai.openclaw.android.data.repository

import ai.openclaw.android.core.network.GatewayClient
import ai.openclaw.android.domain.model.ApprovalAction
import ai.openclaw.android.domain.model.ApprovalRequest
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.serialization.json.*
import javax.inject.Inject
import javax.inject.Singleton

/**
 * 审批仓库
 */
@Singleton
class ApprovalRepository @Inject constructor(
    private val gatewayClient: GatewayClient
) {
    private val _pendingApprovals = MutableStateFlow<List<ApprovalRequest>>(emptyList())
    val pendingApprovals: Flow<List<ApprovalRequest>> = _pendingApprovals.asStateFlow()
    
    /**
     * 同步待审批列表
     * 注意：审批通过事件推送，不通过 API 查询
     */
    suspend fun syncPendingApprovals(): Result<List<ApprovalRequest>> {
        // Gateway 不支持主动查询审批队列
        // 审批请求通过 exec.approval.requested 事件推送
        return Result.success(_pendingApprovals.value)
    }
    
    /**
     * 解析审批请求
     */
    suspend fun resolveApproval(
        approvalId: String,
        action: ApprovalAction
    ): Result<Unit> {
        val decision = when (action) {
            ApprovalAction.ALLOW_ONCE -> "allow-once"
            ApprovalAction.ALLOW_ALWAYS -> "allow-always"
            ApprovalAction.DENY -> "deny"
        }
        
        val params = buildJsonObject {
            put("id", approvalId)
            put("decision", decision)
        }
        
        return gatewayClient.request("exec.approval.resolve", params).map {
            // 移除已解决的审批
            removeApprovalRequest(approvalId)
        }
    }
    
    /**
     * 添加审批请求（用于实时事件）
     */
    fun addApprovalRequest(request: ApprovalRequest) {
        val current = _pendingApprovals.value.toMutableList()
        // 避免重复添加
        if (current.none { it.approvalId == request.approvalId }) {
            current.add(0, request)
            _pendingApprovals.value = current
        }
    }
    
    /**
     * 移除审批请求（用于实时事件）
     */
    fun removeApprovalRequest(approvalId: String) {
        val current = _pendingApprovals.value.toMutableList()
        current.removeAll { it.approvalId == approvalId }
        _pendingApprovals.value = current
    }
    
    /**
     * 处理审批事件
     */
    fun handleApprovalEvent(event: JsonObject) {
        val eventType = event["event"]?.jsonPrimitive?.content ?: return
        val payload = event["payload"] as? JsonObject ?: return
        
        when (eventType) {
            "exec.approval.requested" -> {
                // 新审批请求
                val approvalId = payload["id"]?.jsonPrimitive?.content ?: return
                val command = payload["command"]?.jsonPrimitive?.contentOrNull ?: ""
                val risk = payload["security"]?.jsonPrimitive?.contentOrNull
                val context = payload["cwd"]?.jsonPrimitive?.contentOrNull
                
                val request = ApprovalRequest(
                    approvalId = approvalId,
                    command = command,
                    risk = risk,
                    context = context,
                    requestedAt = System.currentTimeMillis(),
                    expiresIn = payload["timeoutMs"]?.jsonPrimitive?.longOrNull,
                    requestedBy = payload["agentId"]?.jsonPrimitive?.contentOrNull
                )
                
                addApprovalRequest(request)
                android.util.Log.d("ApprovalRepository", "Approval requested: $approvalId")
            }
            "exec.approval.resolved" -> {
                // 审批已解决
                val approvalId = payload["id"]?.jsonPrimitive?.content ?: return
                removeApprovalRequest(approvalId)
                android.util.Log.d("ApprovalRepository", "Approval resolved: $approvalId")
            }
        }
    }
}