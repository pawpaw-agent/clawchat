package ai.openclaw.android.core.network

import ai.openclaw.android.data.repository.ApprovalRepository
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.flow.filter
import kotlinx.coroutines.flow.launchIn
import kotlinx.coroutines.flow.onEach
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.jsonPrimitive
import javax.inject.Inject
import javax.inject.Singleton

/**
 * 审批事件管理器
 * 监听 Gateway 事件并处理审批相关事件
 */
@Singleton
class ApprovalEventManager @Inject constructor(
    private val gatewayClient: GatewayClient,
    private val approvalRepository: ApprovalRepository
) {
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Default)
    
    /**
     * 开始监听审批事件
     */
    fun startListening() {
        gatewayClient.events
            .filter { event ->
                event.event == "exec.approval.requested" || event.event == "exec.approval.resolved"
            }
            .onEach { event ->
                // 构建完整的事件 JSON
                val eventJson = JsonObject(
                    mapOf(
                        "event" to JsonPrimitive(event.event),
                        "payload" to event.payload
                    )
                )
                approvalRepository.handleApprovalEvent(eventJson)
            }
            .launchIn(scope)
    }
}