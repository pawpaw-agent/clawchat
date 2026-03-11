package ai.openclaw.android.presentation.viewmodel

import ai.openclaw.android.core.network.GatewayClient
import ai.openclaw.android.data.repository.PairingState
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.isActive
import kotlinx.coroutines.launch
import javax.inject.Inject

/**
 * 配对 UI 状态
 */
data class PairingUiState(
    val requestId: String = "",
    val pairingCode: String = "",
    val pairingState: PairingState = PairingState.Waiting,
    val isApproved: Boolean = false
)

@HiltViewModel
class PairingViewModel @Inject constructor(
    private val gatewayClient: GatewayClient
) : ViewModel() {

    private val _uiState = MutableStateFlow(PairingUiState())
    val uiState: StateFlow<PairingUiState> = _uiState.asStateFlow()

    private var pollingJob: Job? = null

    fun initialize(requestId: String) {
        _uiState.value = _uiState.value.copy(requestId = requestId)
        
        // 生成配对码（实际应从服务器获取）
        val pairingCode = generatePairingCode()
        _uiState.value = _uiState.value.copy(pairingCode = pairingCode)
        
        // 开始轮询配对状态
        startPolling()
    }

    private fun generatePairingCode(): String {
        // 生成 6 位数字配对码
        return (100000..999999).random().toString()
    }

    private fun startPolling() {
        pollingJob?.cancel()
        pollingJob = viewModelScope.launch {
            // 模拟轮询配对状态
            // 实际实现中，应该监听 Gateway 事件
            gatewayClient.events.collect { event ->
                when (event.event) {
                    "device.approved" -> {
                        val payload = event.payload
                        val approvedRequestId = payload["requestId"]?.jsonPrimitive?.content
                        if (approvedRequestId == _uiState.value.requestId) {
                            _uiState.value = _uiState.value.copy(
                                pairingState = PairingState.Approved,
                                isApproved = true
                            )
                            pollingJob?.cancel()
                        }
                    }
                    "device.rejected" -> {
                        val payload = event.payload
                        val rejectedRequestId = payload["requestId"]?.jsonPrimitive?.content
                        if (rejectedRequestId == _uiState.value.requestId) {
                            _uiState.value = _uiState.value.copy(
                                pairingState = PairingState.Rejected("Device pairing was rejected")
                            )
                            pollingJob?.cancel()
                        }
                    }
                }
            }
        }
    }

    fun retry() {
        _uiState.value = _uiState.value.copy(
            pairingState = PairingState.Waiting,
            isApproved = false
        )
        startPolling()
    }

    override fun onCleared() {
        super.onCleared()
        pollingJob?.cancel()
    }
}