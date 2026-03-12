package ai.openclaw.android.data.repository

import ai.openclaw.android.domain.model.ApprovalAction
import ai.openclaw.android.domain.model.ApprovalRequest
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asStateFlow
import javax.inject.Inject
import javax.inject.Singleton

/**
 * 审批仓库
 * 注意：exec.approval.list/resolve API 暂不支持
 */
@Singleton
class ApprovalRepository @Inject constructor(
) {
    private val _pendingApprovals = MutableStateFlow<List<ApprovalRequest>>(emptyList())
    val pendingApprovals: Flow<List<ApprovalRequest>> = _pendingApprovals.asStateFlow()
    
    /**
     * 同步待审批列表
     * 注意：exec.approval.list API 暂不支持
     */
    suspend fun syncPendingApprovals(): Result<List<ApprovalRequest>> {
        // Gateway 不支持 exec.approval.list，返回空列表
        return Result.success(emptyList())
    }
    
    /**
     * 解析审批请求
     * 注意：exec.approval.resolve API 暂不支持
     */
    suspend fun resolveApproval(
        approvalId: String,
        action: ApprovalAction
    ): Result<Unit> {
        return Result.failure(UnsupportedOperationException("Not implemented"))
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