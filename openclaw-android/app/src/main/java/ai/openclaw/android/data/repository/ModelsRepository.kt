package ai.openclaw.android.data.repository

import ai.openclaw.android.core.network.GatewayClient
import ai.openclaw.android.domain.model.ModelInfo
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.serialization.json.*
import javax.inject.Inject
import javax.inject.Singleton

/**
 * 模型仓库
 */
@Singleton
class ModelsRepository @Inject constructor(
    private val gatewayClient: GatewayClient
) {
    private val _models = MutableStateFlow<List<ModelInfo>>(emptyList())
    val models: Flow<List<ModelInfo>> = _models.asStateFlow()
    
    /**
     * 获取可用模型列表
     */
    suspend fun getModels(): Result<List<ModelInfo>> {
        val result = gatewayClient.request("models.list")
        
        return result.map { response ->
            val modelsArray = response["models"]?.jsonArray
            val models = modelsArray?.mapNotNull { element ->
                val obj = element as? JsonObject ?: return@mapNotNull null
                ModelInfo(
                    id = obj["id"]?.jsonPrimitive?.content ?: return@mapNotNull null,
                    name = obj["name"]?.jsonPrimitive?.contentOrNull
                        ?: obj["id"]?.jsonPrimitive?.content ?: "Unknown",
                    reasoning = obj["reasoning"]?.jsonPrimitive?.booleanOrNull ?: false,
                    contextWindow = obj["contextWindow"]?.jsonPrimitive?.intOrNull ?: 0,
                    maxTokens = obj["maxTokens"]?.jsonPrimitive?.intOrNull ?: 0,
                    input = obj["input"]?.jsonArray?.mapNotNull { 
                        (it as? JsonPrimitive)?.content 
                    } ?: emptyList()
                )
            } ?: emptyList()
            
            _models.value = models
            models
        }
    }
    
    /**
     * 根据模型 ID 获取模型信息
     */
    fun getModelById(modelId: String): ModelInfo? {
        return _models.value.find { it.id == modelId }
    }
}