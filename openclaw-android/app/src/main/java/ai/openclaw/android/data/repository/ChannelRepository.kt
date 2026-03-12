package ai.openclaw.android.data.repository

import ai.openclaw.android.domain.model.ChannelConnectionStatus
import ai.openclaw.android.domain.model.ChannelStatus
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asStateFlow
import javax.inject.Inject
import javax.inject.Singleton

/**
 * 渠道仓库
 * 注意：channel.list API 暂不支持，返回空列表
 */
@Singleton
class ChannelRepository @Inject constructor(
) {
    private val _channels = MutableStateFlow<List<ChannelStatus>>(emptyList())
    val channels: Flow<List<ChannelStatus>> = _channels.asStateFlow()
    
    /**
     * 同步渠道状态
     * 注意：channel.list API 暂不支持
     */
    suspend fun syncChannels(): Result<List<ChannelStatus>> {
        // Gateway 不支持 channel.list，返回空列表
        return Result.success(emptyList())
    }
    
    /**
     * 获取 QR 码
     */
    suspend fun getQrCode(channel: String): Result<String> {
        return Result.failure(UnsupportedOperationException("Not implemented"))
    }
    
    /**
     * 断开渠道
     */
    suspend fun disconnect(channel: String): Result<Unit> {
        return Result.failure(UnsupportedOperationException("Not implemented"))
    }
    
    /**
     * 重连渠道
     */
    suspend fun reconnect(channel: String): Result<Unit> {
        return Result.failure(UnsupportedOperationException("Not implemented"))
    }
}