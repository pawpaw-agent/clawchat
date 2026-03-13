package ai.openclaw.android.presentation.viewmodel

import ai.openclaw.android.core.network.ConnectionState
import ai.openclaw.android.core.network.GatewayClient
import ai.openclaw.android.core.network.model.HelloOk
import ai.openclaw.android.data.local.CredentialsStorage
import ai.openclaw.android.data.repository.AuthRepository
import ai.openclaw.android.data.repository.AuthState
import ai.openclaw.android.data.repository.PairingState
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.collectLatest
import kotlinx.coroutines.launch
import javax.inject.Inject

/**
 * 连接状态 UI 状态
 */
data class ConnectUiState(
    val gatewayUrl: String = "",
    val token: String = "",
    val isConnecting: Boolean = false,
    val isConnected: Boolean = false,
    val connectionState: ConnectionState? = null,
    val helloOk: HelloOk? = null,
    val errorMessage: String? = null,
    val pairingRequestId: String? = null
)

@HiltViewModel
class ConnectViewModel @Inject constructor(
    private val authRepository: AuthRepository,
    private val gatewayClient: GatewayClient,
    private val credentialsStorage: CredentialsStorage
) : ViewModel() {

    private val _uiState = MutableStateFlow(ConnectUiState())
    val uiState: StateFlow<ConnectUiState> = _uiState.asStateFlow()

    init {
        observeConnectionState()
        observeAuthState()
        loadSavedCredentials()
    }

    private fun observeConnectionState() {
        viewModelScope.launch {
            gatewayClient.connectionState.collectLatest { state ->
                _uiState.value = _uiState.value.copy(
                    connectionState = state,
                    isConnecting = state is ConnectionState.Connecting || 
                                   state is ConnectionState.Authenticating ||
                                   state is ConnectionState.ChallengeReceived
                )
            }
        }
    }

    private fun observeAuthState() {
        viewModelScope.launch {
            authRepository.authState.collectLatest { state ->
                when (state) {
                    is AuthState.Idle -> {
                        _uiState.value = _uiState.value.copy(
                            isConnected = false,
                            isConnecting = false,
                            errorMessage = null
                        )
                    }
                    is AuthState.Connecting -> {
                        _uiState.value = _uiState.value.copy(
                            isConnecting = true,
                            errorMessage = null
                        )
                    }
                    is AuthState.Authenticating -> {
                        _uiState.value = _uiState.value.copy(
                            isConnecting = true
                        )
                    }
                    is AuthState.PairingRequired -> {
                        _uiState.value = _uiState.value.copy(
                            isConnecting = false,
                            pairingRequestId = state.requestId
                        )
                    }
                    is AuthState.Connected -> {
                        _uiState.value = _uiState.value.copy(
                            isConnected = true,
                            isConnecting = false,
                            helloOk = state.helloOk,
                            errorMessage = null
                        )
                        // 保存凭证
                        saveCredentials()
                    }
                    is AuthState.Error -> {
                        _uiState.value = _uiState.value.copy(
                            isConnecting = false,
                            errorMessage = state.message
                        )
                    }
                    else -> {}
                }
            }
        }
    }

    private fun loadSavedCredentials() {
        viewModelScope.launch {
            val savedUrl = credentialsStorage.getGatewayUrl()
            val savedToken = credentialsStorage.getToken()
            
            if (!savedUrl.isNullOrBlank()) {
                _uiState.value = _uiState.value.copy(
                    gatewayUrl = savedUrl,
                    token = savedToken ?: ""
                )
            }
        }
    }
    
    private fun saveCredentials() {
        val url = _uiState.value.gatewayUrl.trim()
        val token = _uiState.value.token.trim()
        
        if (url.isNotBlank()) {
            credentialsStorage.saveCredentials(url, token.ifBlank { null })
        }
    }

    fun updateGatewayUrl(url: String) {
        _uiState.value = _uiState.value.copy(gatewayUrl = url)
    }

    fun updateToken(token: String) {
        _uiState.value = _uiState.value.copy(token = token)
    }

    fun connect() {
        val url = _uiState.value.gatewayUrl.trim()
        if (url.isEmpty()) {
            _uiState.value = _uiState.value.copy(errorMessage = "Gateway URL is required")
            return
        }

        viewModelScope.launch {
            val token = _uiState.value.token.trim().ifEmpty { null }
            authRepository.authenticate(url, token)
        }
    }

    fun disconnect() {
        authRepository.disconnect()
    }
    
    fun forgetCredentials() {
        credentialsStorage.clearCredentials()
        _uiState.value = _uiState.value.copy(
            gatewayUrl = "",
            token = ""
        )
    }

    fun clearError() {
        _uiState.value = _uiState.value.copy(errorMessage = null)
    }

    fun resetState() {
        authRepository.resetState()
    }
}