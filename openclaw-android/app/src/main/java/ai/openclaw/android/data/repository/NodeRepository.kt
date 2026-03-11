package ai.openclaw.android.data.repository

import ai.openclaw.android.core.network.GatewayClient
import ai.openclaw.android.domain.model.NodeStatus
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.serialization.json.*
import javax.inject.Inject
import javax.inject.Singleton

/**
 * 节点仓库
 */
@Singleton
class NodeRepository @Inject constructor(
    private val gatewayClient: GatewayClient,
    private val json: Json
) {
    private val _nodes = MutableStateFlow<List<NodeStatus>>(emptyList())
    val nodes: Flow<List<NodeStatus>> = _nodes.asStateFlow()
    
    /**
     * 同步节点状态
     */
    suspend fun syncNodes(): Result<List<NodeStatus>> {
        val result = gatewayClient.request("node.list")
        
        return result.map { response ->
            val nodesArray = response["nodes"]?.jsonArray
            val nodes = nodesArray?.mapNotNull { element ->
                val obj = element as? JsonObject ?: return@mapNotNull null
                NodeStatus(
                    nodeId = obj["nodeId"]?.jsonPrimitive?.content ?: return@mapNotNull null,
                    label = obj["label"]?.jsonPrimitive?.contentOrNull,
                    online = obj["online"]?.jsonPrimitive?.booleanOrNull ?: false,
                    capabilities = obj["capabilities"]?.jsonArray?.mapNotNull { 
                        (it as? JsonPrimitive)?.content 
                    } ?: emptyList(),
                    lastSeen = obj["lastSeen"]?.jsonPrimitive?.longOrNull,
                    provider = obj["provider"]?.jsonPrimitive?.contentOrNull,
                    model = obj["model"]?.jsonPrimitive?.contentOrNull
                )
            } ?: emptyList()
            
            _nodes.value = nodes
            nodes
        }
    }
}