package ai.openclaw.android.domain.model

/**
 * 配置项模型
 */
data class ConfigItem(
    val key: String,
    val value: String,
    val type: ConfigType,
    val description: String?,
    val readOnly: Boolean
)

/**
 * 配置类型
 */
enum class ConfigType {
    STRING,
    NUMBER,
    BOOLEAN,
    JSON
}