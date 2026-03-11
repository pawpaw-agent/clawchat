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
    private val gatewayClient: GatewayClient,
    private val json: Json
) {
    private val _pendingApprovals = MutableStateFlow<List<ApprovalRequest>>(emptyList())
    val pendingApprovals: Flow<List<ApprovalRequest>> = _pendingApprovals.asStateFlow()
    
    /**
     * 同步待审批列表
     */
    suspend fun syncPendingApprovals(): Result<List<ApprovalRequest>> {
        val result = gatewayClient.request("exec.approval.list")
        
        return result.map { response ->
            val approvalsArray = response["approvals"]?.jsonArray
            val approvals = approvalsArray?.mapNotNull { element ->
                val obj = element as? JsonObject ?: return@mapNotNull null
                ApprovalRequest(
                    approvalId = obj["approvalId"]?.jsonPrimitive?.content ?: return@mapNotNull null,
                    command = obj["command"]?.jsonPrimitive?.content ?: "",
                    risk = obj["risk"]?.jsonPrimitive?.contentOrNull,
                    context = obj["context"]?.jsonPrimitive?.contentOrNull,
                    requestedAt = obj["requestedAt"]?.jsonPrimitive?.longOrNull ?: System.currentTimeMillis(),
                    expiresIn = obj["expiresIn"]?.jsonPrimitive?.longOrNull,
                    requestedBy = obj["requestedBy"]?.jsonPrimitive?.contentOrNull
                )
            } ?: emptyList()
            
            _pendingApprovals.value = approvals
            approvals
        }
    }
    
    /**
     * 解析审批请求
     */
    suspend fun resolveApproval(
        approvalId: String,
        action: ApprovalAction
    ): Result<Unit> {
        val params = buildJsonObject {
            put("approvalId", approvalId)
            put("action", when (action) {
                ApprovalAction.ALLOW_ONCE -> "allow-once"
                ApprovalAction.ALLOW_ALWAYS -> "allow-always"
                ApprovalAction.DENY -> "deny"
            })
        }
        
        return gatewayClient.request("exec.approval.resolve", params).map {
            // 从列表中移除
            val current = _pendingApprovals.value.toMutableList()
            current.removeAll { it.approvalId == approvalId }
            _pendingApprovals.value = current
        }
    }
    
    /**
     * 添加审批请求（用于实时事件）
     */
    fun addApprovalRequest(request: ApprovalRequest) {
        val current = _pendingApprovals.value.toMutableList()
        current.add(0, request)
        _pendingApprovals.value = current
    }
    
    /**
     * 移除审批请求（用于实时事件）
     */
    fun removeApprovalRequest(approvalId: String) {
        val current = _pendingApprovals.value.toMutableList()
        current.removeAll { it.approvalId == approvalId }
        _pendingApprovals.value = current
    }
}