package ai.openclaw.android.data.repository

import ai.openclaw.android.core.crypto.DeviceIdentityManager
import ai.openclaw.android.core.crypto.SecureTokenStorage
import ai.openclaw.android.core.network.ConnectionState
import ai.openclaw.android.core.network.GatewayClient
import ai.openclaw.android.core.network.model.ConnectChallenge
import ai.openclaw.android.core.network.model.HelloOk
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject
import javax.inject.Singleton

/**
 * 认证状态
 */
sealed class AuthState {
    object Idle : AuthState()
    object Connecting : AuthState()
    object WaitingForChallenge : AuthState()
    object Authenticating : AuthState()
    data class PairingRequired(val requestId: String) : AuthState()
    data class Connected(val helloOk: HelloOk) : AuthState()
    data class Error(val message: String) : AuthState()
}

/**
 * 配对状态
 */
sealed class PairingState {
    object Waiting : PairingState()
    object Approved : PairingState()
    data class Rejected(val reason: String) : PairingState()
    data class Error(val message: String) : PairingState()
}

/**
 * 认证仓库
 */
@Singleton
class AuthRepository @Inject constructor(
    private val gatewayClient: GatewayClient,
    private val deviceIdentityManager: DeviceIdentityManager,
    private val tokenStorage: SecureTokenStorage
) {
    private val scope = CoroutineScope(Dispatchers.IO + SupervisorJob())
    
    private val _authState = MutableStateFlow<AuthState>(AuthState.Idle)
    val authState: StateFlow<AuthState> = _authState.asStateFlow()

    private val _pairingState = MutableStateFlow<PairingState>(PairingState.Waiting)
    val pairingState: StateFlow<PairingState> = _pairingState.asStateFlow()

    private val _lastError = MutableStateFlow<String?>(null)
    val lastError: StateFlow<String?> = _lastError.asStateFlow()
    
    init {
        // 监听连接状态变化，自动更新 AuthState
        scope.launch {
            gatewayClient.connectionState.collect { state ->
                when (state) {
                    is ConnectionState.Connected -> {
                        _authState.value = AuthState.Connected(state.helloOk)
                        _lastError.value = null
                    }
                    is ConnectionState.Connecting -> {
                        _authState.value = AuthState.Connecting
                    }
                    is ConnectionState.ChallengeReceived -> {
                        _authState.value = AuthState.WaitingForChallenge
                    }
                    is ConnectionState.Authenticating -> {
                        _authState.value = AuthState.Authenticating
                    }
                    is ConnectionState.Disconnected -> {
                        // 只有在用户手动断开时才更新为 Idle
                        // 自动断开由 GatewayClient 自动重连处理
                    }
                    is ConnectionState.Error -> {
                        // 错误状态由 GatewayClient 自动重连处理
                        // 如果重连失败会显示错误
                    }
                }
            }
        }
    }

    /**
     * 连接并认证
     */
    suspend fun authenticate(url: String, token: String? = null): Result<HelloOk> {
        _authState.value = AuthState.Connecting
        _lastError.value = null

        return try {
            // 直接传递 DeviceIdentityManager，让 GatewayClient 在收到 challenge 后签名
            val result = gatewayClient.connect(url, deviceIdentityManager, token)

            result.fold(
                onSuccess = { helloOk ->
                    // 保存设备 Token（如果有）
                    helloOk.auth?.deviceToken?.let { deviceToken ->
                        deviceIdentityManager.saveDeviceToken(deviceToken)
                    }
                    
                    // 保存 Gateway URL
                    tokenStorage.saveGatewayUrl(url)
                    
                    _authState.value = AuthState.Connected(helloOk)
                    Result.success(helloOk)
                },
                onFailure = { error ->
                    val errorMsg = error.message ?: "Connection failed"
                    _lastError.value = errorMsg
                    _authState.value = AuthState.Error(errorMsg)
                    Result.failure(error)
                }
            )
        } catch (e: Exception) {
            val errorMsg = e.message ?: "Authentication failed"
            _lastError.value = errorMsg
            _authState.value = AuthState.Error(errorMsg)
            Result.failure(e)
        }
    }

    /**
     * 使用保存的 Token 自动连接
     */
    suspend fun autoConnect(): Result<HelloOk> {
        val url = tokenStorage.getGatewayUrl() ?: return Result.failure(Exception("No saved Gateway URL"))
        val token = deviceIdentityManager.getDeviceToken()
        
        return authenticate(url, token)
    }

    /**
     * 断开连接
     */
    fun disconnect() {
        gatewayClient.disconnect()
        _authState.value = AuthState.Idle
        _pairingState.value = PairingState.Waiting
    }

    /**
     * 清除认证数据
     */
    suspend fun clearAuth() {
        disconnect()
        deviceIdentityManager.clearAuth()
    }

    /**
     * 重置状态
     */
    fun resetState() {
        _authState.value = AuthState.Idle
        _pairingState.value = PairingState.Waiting
        _lastError.value = null
    }
}