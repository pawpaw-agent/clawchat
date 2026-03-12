package ai.openclaw.android.domain.model

/**
 * 模型信息
 */
data class ModelInfo(
    val id: String,
    val name: String,
    val reasoning: Boolean = false,
    val contextWindow: Int = 0,
    val maxTokens: Int = 0,
    val input: List<String> = emptyList()
)