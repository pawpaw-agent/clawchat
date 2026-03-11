package ai.openclaw.android.data.local.dao

import androidx.room.*
import ai.openclaw.android.data.local.entity.GatewayConfigEntity
import kotlinx.coroutines.flow.Flow

@Dao
interface GatewayConfigDao {
    @Query("SELECT * FROM gateway_configs ORDER BY isDefault DESC, lastConnected DESC")
    fun getAllConfigs(): Flow<List<GatewayConfigEntity>>
    
    @Query("SELECT * FROM gateway_configs WHERE id = :id")
    suspend fun getConfigById(id: Long): GatewayConfigEntity?
    
    @Query("SELECT * FROM gateway_configs WHERE isDefault = 1 LIMIT 1")
    suspend fun getDefaultConfig(): GatewayConfigEntity?
    
    @Query("SELECT * FROM gateway_configs WHERE isDefault = 1 LIMIT 1")
    fun getDefaultConfigFlow(): Flow<GatewayConfigEntity?>
    
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertConfig(config: GatewayConfigEntity): Long
    
    @Update
    suspend fun updateConfig(config: GatewayConfigEntity)
    
    @Query("UPDATE gateway_configs SET isDefault = 0")
    suspend fun clearDefault()
    
    @Query("UPDATE gateway_configs SET isDefault = 1 WHERE id = :id")
    suspend fun setDefault(id: Long)
    
    @Delete
    suspend fun deleteConfig(config: GatewayConfigEntity)
    
    @Query("DELETE FROM gateway_configs WHERE id = :id")
    suspend fun deleteConfigById(id: Long)
}