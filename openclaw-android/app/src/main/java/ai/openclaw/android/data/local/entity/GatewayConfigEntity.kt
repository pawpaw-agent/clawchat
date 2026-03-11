package ai.openclaw.android.data.local.entity

import androidx.room.Entity
import androidx.room.PrimaryKey

/**
 * Gateway 配置实体
 */
@Entity(tableName = "gateway_configs")
data class GatewayConfigEntity(
    @PrimaryKey(autoGenerate = true)
    val id: Long = 0,
    val name: String,
    val url: String,
    val token: String? = null,
    val isDefault: Boolean = false,
    val lastConnected: Long? = null,
    val createdAt: Long = System.currentTimeMillis()
)