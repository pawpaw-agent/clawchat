package ai.openclaw.android.data.repository

import ai.openclaw.android.core.network.GatewayClient
import ai.openclaw.android.domain.model.AgentInfo
import ai.openclaw.android.domain.model.AgentIdentity
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.serialization.json.*
import javax.inject.Inject
import javax.inject.Singleton

/**
 * Agent 仓库
 */
@Singleton
class AgentsRepository @Inject constructor(
    private val gatewayClient: GatewayClient
) {
    private val _agents = MutableStateFlow<List<AgentInfo>>(emptyList())
    val agents: Flow<List<AgentInfo>> = _agents.asStateFlow()
    
    /**
     * 获取 Agent 列表
     */
    suspend fun getAgents(): Result<List<AgentInfo>> {
        val result = gatewayClient.request("agents.list")
        
        return result.map { response ->
            val agentsArray = response["agents"]?.jsonArray
            val agents = agentsArray?.mapNotNull { element ->
                val obj = element as? JsonObject ?: return@mapNotNull null
                AgentInfo(
                    id = obj["id"]?.jsonPrimitive?.content ?: return@mapNotNull null,
                    name = obj["name"]?.jsonPrimitive?.contentOrNull,
                    model = obj["model"]?.jsonPrimitive?.contentOrNull,
                    workspace = obj["workspace"]?.jsonPrimitive?.contentOrNull,
                    identity = obj["identity"]?.jsonObject?.let { identityObj ->
                        AgentIdentity(
                            emoji = identityObj["emoji"]?.jsonPrimitive?.contentOrNull,
                            name = identityObj["name"]?.jsonPrimitive?.contentOrNull
                        )
                    }
                )
            } ?: emptyList()
            
            _agents.value = agents
            agents
        }
    }
    
    /**
     * 根据 ID 获取 Agent
     */
    fun getAgentById(agentId: String): AgentInfo? {
        return _agents.value.find { it.id == agentId }
    }
}