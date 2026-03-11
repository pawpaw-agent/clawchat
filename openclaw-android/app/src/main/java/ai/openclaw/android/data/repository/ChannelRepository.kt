package ai.openclaw.android.data.repository

import ai.openclaw.android.core.network.GatewayClient
import ai.openclaw.android.domain.model.ChannelConnectionStatus
import ai.openclaw.android.domain.model.ChannelStatus
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.serialization.json.*
import javax.inject.Inject
import javax.inject.Singleton

/**
 * 渠道仓库
 */
@Singleton
class ChannelRepository @Inject constructor(
    private val gatewayClient: GatewayClient,
    private val json: Json
) {
    private val _channels = MutableStateFlow<List<ChannelStatus>>(emptyList())
    val channels: Flow<List<ChannelStatus>> = _channels.asStateFlow()
    
    /**
     * 同步渠道状态
     */
    suspend fun syncChannels(): Result<List<ChannelStatus>> {
        val result = gatewayClient.request("channel.list")
        
        return result.map { response ->
            val channelsArray = response["channels"]?.jsonArray
            val channels = channelsArray?.mapNotNull { element ->
                val obj = element as? JsonObject ?: return@mapNotNull null
                ChannelStatus(
                    channel = obj["channel"]?.jsonPrimitive?.content ?: return@mapNotNull null,
                    label = obj["label"]?.jsonPrimitive?.contentOrNull,
                    provider = obj["provider"]?.jsonPrimitive?.contentOrNull,
                    status = parseStatus(obj["status"]?.jsonPrimitive?.content),
                    connectedAt = obj["connectedAt"]?.jsonPrimitive?.longOrNull,
                    error = obj["error"]?.jsonPrimitive?.contentOrNull,
                    qrCode = obj["qrCode"]?.jsonPrimitive?.contentOrNull,
                    lastActivity = obj["lastActivity"]?.jsonPrimitive?.longOrNull
                )
            } ?: emptyList()
            
            _channels.value = channels
            channels
        }
    }
    
    /**
     * 获取 QR 码
     */
    suspend fun getQrCode(channel: String): Result<String> {
        val params = buildJsonObject {
            put("channel", channel)
        }
        
        return gatewayClient.request("channel.qr", params).map { response ->
            response["qrCode"]?.jsonPrimitive?.content ?: ""
        }
    }
    
    /**
     * 断开渠道
     */
    suspend fun disconnect(channel: String): Result<Unit> {
        val params = buildJsonObject {
            put("channel", channel)
        }
        
        return gatewayClient.request("channel.disconnect", params).map { }
    }
    
    /**
     * 重连渠道
     */
    suspend fun reconnect(channel: String): Result<Unit> {
        val params = buildJsonObject {
            put("channel", channel)
        }
        
        return gatewayClient.request("channel.reconnect", params).map { }
    }
    
    private fun parseStatus(status: String?): ChannelConnectionStatus {
        return when (status?.lowercase()) {
            "connected" -> ChannelConnectionStatus.CONNECTED
            "disconnected" -> ChannelConnectionStatus.DISCONNECTED
            "connecting" -> ChannelConnectionStatus.CONNECTING
            "error" -> ChannelConnectionStatus.ERROR
            "needs_qr" -> ChannelConnectionStatus.NEEDS_QR
            "needs_login" -> ChannelConnectionStatus.NEEDS_LOGIN
            else -> ChannelConnectionStatus.DISCONNECTED
        }
    }
}