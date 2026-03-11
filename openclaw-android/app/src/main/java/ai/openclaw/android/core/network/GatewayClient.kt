package ai.openclaw.android.core.network

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
    
    val connectionState: StateFlow<ConnectionState> = _connectionState.asStateFlow()
    val events: SharedFlow<WsFrame.Event> = _events.asSharedFlow()
    val challenge: StateFlow<ConnectChallenge?> = _challenge.asStateFlow()

    /**
     * 连接到 Gateway
     */
    suspend fun connect(
        url: String,
        deviceIdentity: DeviceIdentity,
        token: String? = null
    ): Result<HelloOk> = withContext(Dispatchers.IO) {
        if (_connectionState.value is ConnectionState.Connected) {
            disconnect()
        }
        
        currentUrl = url
        currentToken = token
        
        try {
            val challengeResult = waitForChallenge(url)
            if (challengeResult.isFailure) {
                return@withContext Result.failure(challengeResult.exceptionOrNull() ?: Exception("Connection failed"))
            }
            
            val challenge = _challenge.value ?: return@withContext Result.failure(Exception("No challenge received"))
            sendConnect(deviceIdentity, token)
        } catch (e: Exception) {
            Result.failure<HelloOk>(e)
        }
    }

    private suspend fun waitForChallenge(url: String): Result<Unit> = suspendCancellableCoroutine { continuation ->
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
                                    continuation.resumeWith(Result.success(Unit))
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
                    continuation.resumeWith(Result.failure(t))
                }
            }
        }
        
        val request = Request.Builder()
            .url(url)
            .build()
        
        this@GatewayClient.webSocket = okHttpClient.newWebSocket(request, listener)
    }

    /**
     * 发送 connect 方法
     */
    private suspend fun sendConnect(
        deviceIdentity: DeviceIdentity,
        token: String?
    ): Result<HelloOk> {
        val clientInfo = ClientInfo(
            id = "android-app",
            version = "0.1.0",
            platform = "android",
            mode = "operator"
        )
        
        val connectParams = ConnectParams(
            client = clientInfo,
            role = "operator",
            scopes = listOf("operator.read", "operator.write"),
            auth = AuthParams(token = token),
            userAgent = "openclaw-android/0.1.0",
            device = deviceIdentity
        )
        
        return request<HelloOk>("connect", json.encodeToJsonElement(connectParams).jsonObject)
    }

    /**
     * 发送请求并等待响应
     */
    suspend fun <T> requestRaw(
        method: String,
        params: JsonObject?,
        idempotencyKey: String?,
        deserializer: (JsonObject) -> T
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
                idempotencyKey?.let { put("idempotencyKey", it) }
            }
        )
        
        webSocket?.send(jsonStr) ?: return@withContext Result.failure(Exception("WebSocket not connected"))
        
        return@withContext try {
            val response = withTimeout(30000) { deferred.await() }
            if (response.ok && response.payload != null) {
                Result.success(deserializer(response.payload))
            } else {
                Result.failure(Exception(response.error?.message ?: "Request failed"))
            }
        } catch (e: TimeoutCancellationException) {
            Result.failure(Exception("Request timeout"))
        } finally {
            pendingRequests.remove(id)
        }
    }

    /**
     * 发送请求并等待响应（泛型版本）
     */
    suspend inline fun <reified T> request(
        method: String,
        params: JsonObject? = null,
        idempotencyKey: String? = null
    ): Result<T> = requestRaw(method, params, idempotencyKey) { payload ->
        json.decodeFromJsonElement<T>(payload)
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