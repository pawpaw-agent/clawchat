package ai.openclaw.android.core.network

import ai.openclaw.android.core.crypto.DeviceIdentityManager
import ai.openclaw.android.core.network.model.*
import kotlinx.coroutines.*
import kotlinx.coroutines.flow.*
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.*
import okhttp3.*
import java.util.UUID
import java.util.concurrent.ConcurrentHashMap
import javax.inject.Inject
import javax.inject.Singleton

/**
 * Gateway WebSocket 客户端
 */
@Singleton
class GatewayClient @Inject constructor(
    private val okHttpClient: OkHttpClient,
    private val json: Json
) {
    private var webSocket: WebSocket? = null
    private val pendingRequests = ConcurrentHashMap<String, CompletableDeferred<WsFrame.Response>>()
    private val _events = MutableSharedFlow<WsFrame.Event>(extraBufferCapacity = 64)
    private val _connectionState = MutableStateFlow<ConnectionState>(ConnectionState.Disconnected)
    private val _challenge = MutableStateFlow<ConnectChallenge?>(null)
    
    private var currentUrl: String? = null
    private var currentToken: String? = null
    private var reconnectJob: Job? = null
    private var deviceIdentityManager: DeviceIdentityManager? = null
    
    val connectionState: StateFlow<ConnectionState> = _connectionState.asStateFlow()
    val events: SharedFlow<WsFrame.Event> = _events.asSharedFlow()
    val challenge: StateFlow<ConnectChallenge?> = _challenge.asStateFlow()

    /**
     * 连接到 Gateway
     * @param url Gateway WebSocket URL
     * @param deviceIdentityManager 设备身份管理器，用于签名 challenge
     * @param token 认证 Token（可选）
     */
    suspend fun connect(
        url: String,
        deviceIdentityManager: DeviceIdentityManager,
        token: String? = null
    ): Result<HelloOk> = withContext(Dispatchers.IO) {
        if (_connectionState.value is ConnectionState.Connected) {
            disconnect()
        }
        
        currentUrl = url
        currentToken = token
        this@GatewayClient.deviceIdentityManager = deviceIdentityManager
        
        val challengeResult = waitForChallenge(url)
        if (challengeResult.isFailure) {
            return@withContext Result.failure<HelloOk>(challengeResult.exceptionOrNull() ?: Exception("Connection failed"))
        }
        
        val challenge = _challenge.value
        if (challenge == null) {
            return@withContext Result.failure<HelloOk>(Exception("No challenge received"))
        }
        
        // 如果有 Token，不发送设备身份（让 Gateway 使用 Token 认证）
        // 如果没有 Token，发送设备身份进行签名验证
        val signedIdentity = if (token.isNullOrBlank()) {
            deviceIdentityManager.buildSignedDeviceIdentity(challenge.nonce, challenge.ts)
        } else {
            // 有 Token 时，发送空的设备身份（不包含签名）
            null
        }
        
        val result = sendConnect(signedIdentity, token)
        
        // 成功后更新连接状态
        result.onSuccess { helloOk ->
            _connectionState.value = ConnectionState.Connected(helloOk)
        }
        
        return@withContext result
    }

    private suspend fun waitForChallenge(url: String): Result<Unit> {
        return suspendCancellableCoroutine { continuation ->
            _connectionState.value = ConnectionState.Connecting
            
            val listener = object : WebSocketListener() {
                override fun onOpen(webSocket: WebSocket, response: Response) {
                    // WebSocket 连接已建立，等待 challenge
                }
                
                override fun onMessage(webSocket: WebSocket, text: String) {
                    try {
                        val frame = parseFrame(text)
                        when (frame) {
                            is WsFrame.Event -> {
                                if (frame.event == "connect.challenge") {
                                    val payload = frame.payload
                                    val challenge = ConnectChallenge(
                                        nonce = payload["nonce"]?.jsonPrimitive?.content ?: "",
                                        ts = payload["ts"]?.jsonPrimitive?.longOrNull ?: System.currentTimeMillis()
                                    )
                                    _challenge.value = challenge
                                    _connectionState.value = ConnectionState.ChallengeReceived(challenge)
                                    if (continuation.isActive) {
                                        continuation.resume(Result.success(Unit), null)
                                    }
                                } else {
                                    _events.tryEmit(frame)
                                }
                            }
                            is WsFrame.Response -> {
                                pendingRequests[frame.id]?.complete(frame)
                            }
                            else -> { /* ignore */ }
                        }
                    } catch (e: Exception) {
                        // Log error
                    }
                }
                
                override fun onClosing(webSocket: WebSocket, code: Int, reason: String) {
                    webSocket.close(1000, null)
                }
                
                override fun onClosed(webSocket: WebSocket, code: Int, reason: String) {
                    _connectionState.value = ConnectionState.Disconnected
                    clearPendingRequests()
                }
                
                override fun onFailure(webSocket: WebSocket, t: Throwable, response: Response?) {
                    _connectionState.value = ConnectionState.Error(t.message ?: "Connection failed")
                    clearPendingRequests()
                    if (continuation.isActive) {
                        continuation.resume(Result.failure(t), null)
                    }
                }
            }
            
            val request = Request.Builder()
                .url(url)
                .build()
            
            this@GatewayClient.webSocket = okHttpClient.newWebSocket(request, listener)
        }
    }

    /**
     * 发送 connect 方法
     */
    private suspend fun sendConnect(
        deviceIdentity: DeviceIdentity?,
        token: String?
    ): Result<HelloOk> {
        // 调试日志 - client 参数
        android.util.Log.d("GatewayClient", "=== Connect Params Debug ===")
        android.util.Log.d("GatewayClient", "client.id: cli")
        android.util.Log.d("GatewayClient", "client.mode: ui")
        android.util.Log.d("GatewayClient", "client.version: 0.1.0")
        android.util.Log.d("GatewayClient", "client.platform: android")
        android.util.Log.d("GatewayClient", "role: operator")
        android.util.Log.d("GatewayClient", "scopes: [operator.read, operator.write]")
        android.util.Log.d("GatewayClient", "device: ${if (deviceIdentity != null) "provided" else "not provided (using token auth)"}")
        android.util.Log.d("GatewayClient", "token: ${if (token.isNullOrBlank()) "not provided" else "provided"}")
        android.util.Log.d("GatewayClient", "=== End Connect Params ===")
        
        // 手动构建 JSON，避免 null 值被序列化
        val params = buildJsonObject {
            put("minProtocol", 3)
            put("maxProtocol", 3)
            put("client", buildJsonObject {
                put("id", "cli")
                put("version", "0.1.0")
                put("platform", "android")
                put("mode", "ui")
            })
            put("role", "operator")
            put("scopes", buildJsonArray {
                add("operator.read")
                add("operator.write")
                add("operator.admin")
                add("operator.approvals")
                add("operator.pairing")
            })
            // 只有当 token 不为空时才发送 auth 对象
            if (!token.isNullOrBlank()) {
                put("auth", buildJsonObject {
                    put("token", token)
                })
            }
            put("locale", "zh-CN")
            put("userAgent", "openclaw-android/0.1.0")
            // 只有当设备身份不为空时才发送 device 对象
            if (deviceIdentity != null) {
                put("device", buildJsonObject {
                    put("id", deviceIdentity.id)
                    put("publicKey", deviceIdentity.publicKey)
                    put("signature", deviceIdentity.signature)
                    put("signedAt", deviceIdentity.signedAt)
                    put("nonce", deviceIdentity.nonce)
                })
            }
        }
        
        android.util.Log.d("GatewayClient", "Connect JSON: ${json.encodeToString(params)}")
        
        return requestInternal("connect", params) { payload ->
            json.decodeFromJsonElement<HelloOk>(payload)
        }
    }

    /**
     * 发送请求并等待响应（返回 JsonObject）
     */
    suspend fun request(
        method: String,
        params: JsonObject? = null
    ): Result<JsonObject> = requestInternal(method, params) { it }

    /**
     * 内部请求方法
     */
    private suspend fun <T> requestInternal(
        method: String,
        params: JsonObject?,
        transformer: (JsonObject) -> T
    ): Result<T> = withContext(Dispatchers.IO) {
        val id = UUID.randomUUID().toString()
        val deferred = CompletableDeferred<WsFrame.Response>()
        pendingRequests[id] = deferred
        
        val jsonStr = json.encodeToString(
            buildJsonObject {
                put("type", "req")
                put("id", id)
                put("method", method)
                params?.let { put("params", it) }
            }
        )
        
        webSocket?.send(jsonStr) ?: return@withContext Result.failure<T>(Exception("WebSocket not connected"))
        
        return@withContext try {
            val response = withTimeout(30000) { deferred.await() }
            if (response.ok && response.payload != null) {
                Result.success(transformer(response.payload))
            } else {
                Result.failure<T>(Exception(response.error?.message ?: "Request failed"))
            }
        } catch (e: TimeoutCancellationException) {
            Result.failure<T>(Exception("Request timeout"))
        } finally {
            pendingRequests.remove(id)
        }
    }

    /**
     * 断开连接
     */
    fun disconnect() {
        reconnectJob?.cancel()
        webSocket?.close(1000, "Client disconnect")
        webSocket = null
        _connectionState.value = ConnectionState.Disconnected
        _challenge.value = null
        clearPendingRequests()
    }

    /**
     * 解析帧
     */
    private fun parseFrame(text: String): WsFrame {
        val element = json.parseToJsonElement(text)
        val type = element.jsonObject["type"]?.jsonPrimitive?.content
        
        return when (type) {
            "req" -> json.decodeFromJsonElement<WsFrame.Request>(element)
            "res" -> json.decodeFromJsonElement<WsFrame.Response>(element)
            "event" -> json.decodeFromJsonElement<WsFrame.Event>(element)
            else -> throw IllegalArgumentException("Unknown frame type: $type")
        }
    }

    private fun clearPendingRequests() {
        pendingRequests.values.forEach { it.completeExceptionally(Exception("Connection closed")) }
        pendingRequests.clear()
    }
}

/**
 * 连接状态
 */
sealed class ConnectionState {
    object Disconnected : ConnectionState()
    object Connecting : ConnectionState()
    data class ChallengeReceived(val challenge: ConnectChallenge) : ConnectionState()
    object Authenticating : ConnectionState()
    data class Connected(val helloOk: HelloOk) : ConnectionState()
    data class Error(val message: String) : ConnectionState()
}