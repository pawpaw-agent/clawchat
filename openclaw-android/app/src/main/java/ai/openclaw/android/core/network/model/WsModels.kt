package ai.openclaw.android.core.network.model

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

/**
 * WebSocket 帧类型密封类
 */
sealed class WsFrame {
    @Serializable
    data class Request(
        val id: String,
        val method: String,
        val params: kotlinx.serialization.json.JsonObject? = null,
        @SerialName("idempotencyKey")
        val idempotencyKey: String? = null
    ) : WsFrame()

    @Serializable
    data class Response(
        val id: String,
        val ok: Boolean,
        val payload: kotlinx.serialization.json.JsonObject? = null,
        val error: ErrorBody? = null
    ) : WsFrame()

    @Serializable
    data class Event(
        val event: String,
        val payload: kotlinx.serialization.json.JsonObject,
        val seq: Long? = null,
        @SerialName("stateVersion")
        val stateVersion: Long? = null
    ) : WsFrame()
}

@Serializable
data class ErrorBody(
    val code: String,
    val message: String,
    val details: kotlinx.serialization.json.JsonObject? = null
)

/**
 * 连接参数
 */
@Serializable
data class ConnectParams(
    @SerialName("minProtocol")
    val minProtocol: Int = 3,
    @SerialName("maxProtocol")
    val maxProtocol: Int = 3,
    val client: ClientInfo,
    val role: String,
    val scopes: List<String>,
    val caps: List<String> = emptyList(),
    val commands: List<String> = emptyList(),
    val permissions: Map<String, Boolean> = emptyMap(),
    val auth: AuthParams,
    val locale: String = "zh-CN",
    @SerialName("userAgent")
    val userAgent: String,
    val device: DeviceIdentity
)

@Serializable
data class ClientInfo(
    val id: String,
    val version: String,
    val platform: String,
    val mode: String
)

@Serializable
data class AuthParams(
    val token: String? = null
)

@Serializable
data class DeviceIdentity(
    val id: String,
    @SerialName("publicKey")
    val publicKey: String,
    val signature: String,
    @SerialName("signedAt")
    val signedAt: Long,
    val nonce: String
)

@Serializable
data class HelloOk(
    val type: String = "hello-ok",
    val protocol: Int,
    val policy: PolicyInfo? = null,
    val auth: AuthResult? = null
)

@Serializable
data class PolicyInfo(
    @SerialName("tickIntervalMs")
    val tickIntervalMs: Long = 15000
)

@Serializable
data class AuthResult(
    @SerialName("deviceToken")
    val deviceToken: String? = null,
    val role: String? = null,
    val scopes: List<String>? = null
)

/**
 * 连接质询
 */
@Serializable
data class ConnectChallenge(
    val nonce: String,
    val ts: Long
)

/**
 * 已签名的质询
 */
@Serializable
data class SignedChallenge(
    val signature: String,
    @SerialName("signedAt")
    val signedAt: Long,
    val nonce: String
)