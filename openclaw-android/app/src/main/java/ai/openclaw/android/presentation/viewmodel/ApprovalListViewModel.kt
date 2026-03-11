package ai.openclaw.android.presentation.viewmodel

import ai.openclaw.android.data.repository.ApprovalRepository
import ai.openclaw.android.domain.model.ApprovalAction
import ai.openclaw.android.domain.model.ApprovalRequest
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject

data class ApprovalListUiState(
    val approvals: List<ApprovalRequest> = emptyList(),
    val isLoading: Boolean = false,
    val isRefreshing: Boolean = false,
    val error: String? = null,
    val resolvingId: String? = null
)

@HiltViewModel
class ApprovalListViewModel @Inject constructor(
    private val approvalRepository: ApprovalRepository
) : ViewModel() {
    
    private val _uiState = MutableStateFlow(ApprovalListUiState())
    val uiState: StateFlow<ApprovalListUiState> = _uiState.asStateFlow()
    
    init {
        loadApprovals()
    }
    
    private fun loadApprovals() {
        viewModelScope.launch {
            approvalRepository.pendingApprovals.collect { approvals ->
                _uiState.value = _uiState.value.copy(approvals = approvals)
            }
        }
        syncApprovals()
    }
    
    fun syncApprovals() {
        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(isRefreshing = true)
            approvalRepository.syncPendingApprovals()
                .onFailure { error ->
                    _uiState.value = _uiState.value.copy(error = error.message)
                }
            _uiState.value = _uiState.value.copy(isRefreshing = false)
        }
    }
    
    fun resolveApproval(approvalId: String, action: ApprovalAction) {
        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(resolvingId = approvalId)
            approvalRepository.resolveApproval(approvalId, action)
                .onFailure { error ->
                    _uiState.value = _uiState.value.copy(error = error.message)
                }
            _uiState.value = _uiState.value.copy(resolvingId = null)
        }
    }
    
    fun clearError() {
        _uiState.value = _uiState.value.copy(error = null)
    }
}