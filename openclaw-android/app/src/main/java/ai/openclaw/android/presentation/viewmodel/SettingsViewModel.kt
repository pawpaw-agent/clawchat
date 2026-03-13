package ai.openclaw.android.presentation.viewmodel

import ai.openclaw.android.data.repository.AgentsRepository
import ai.openclaw.android.data.repository.GatewayConfigRepository
import ai.openclaw.android.data.repository.SessionRepository
import ai.openclaw.android.domain.model.AgentInfo
import ai.openclaw.android.domain.model.GatewayConfig
import ai.openclaw.android.presentation.theme.ThemeMode
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject

data class SettingsUiState(
    val gatewayConfigs: List<GatewayConfig> = emptyList(),
    val defaultConfigId: Long? = null,
    val themeMode: ThemeMode = ThemeMode.SYSTEM,
    val notificationsEnabled: Boolean = true,
    val autoReconnect: Boolean = true,
    val agents: List<AgentInfo> = emptyList(),
    val currentAgent: String? = null,
    val isLoading: Boolean = false,
    val isLoadingAgents: Boolean = false,
    val error: String? = null
)

@HiltViewModel
class SettingsViewModel @Inject constructor(
    private val gatewayConfigRepository: GatewayConfigRepository,
    private val agentsRepository: AgentsRepository,
    private val sessionRepository: SessionRepository
) : ViewModel() {
    
    private val _uiState = MutableStateFlow(SettingsUiState())
    val uiState: StateFlow<SettingsUiState> = _uiState.asStateFlow()
    
    init {
        loadSettings()
        loadAgents()
    }
    
    private fun loadSettings() {
        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(isLoading = true)
            
            gatewayConfigRepository.getAllConfigs().collect { configs ->
                _uiState.value = _uiState.value.copy(
                    gatewayConfigs = configs,
                    defaultConfigId = configs.find { it.isDefault }?.id,
                    isLoading = false
                )
            }
        }
        
        // 加载当前 agent
        viewModelScope.launch {
            sessionRepository.getSessionByKey("main")?.let { session ->
                _uiState.value = _uiState.value.copy(
                    currentAgent = session.provider // provider 存储 agentId
                )
            }
        }
    }
    
    private fun loadAgents() {
        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(isLoadingAgents = true)
            
            agentsRepository.getAgents()
                .onSuccess { agents ->
                    _uiState.value = _uiState.value.copy(
                        agents = agents,
                        isLoadingAgents = false
                    )
                }
                .onFailure {
                    _uiState.value = _uiState.value.copy(
                        isLoadingAgents = false,
                        error = "Failed to load agents: ${it.message}"
                    )
                }
        }
    }
    
    fun setThemeMode(mode: ThemeMode) {
        _uiState.value = _uiState.value.copy(themeMode = mode)
    }
    
    fun setNotificationsEnabled(enabled: Boolean) {
        _uiState.value = _uiState.value.copy(notificationsEnabled = enabled)
    }
    
    fun setAutoReconnect(enabled: Boolean) {
        _uiState.value = _uiState.value.copy(autoReconnect = enabled)
    }
    
    fun setAgent(agentId: String) {
        viewModelScope.launch {
            // 使用 sessions.resolve 获取特定 agent 的 session
            sessionRepository.resolveSession(agentId = agentId)
                .onSuccess { sessionKey ->
                    _uiState.value = _uiState.value.copy(currentAgent = agentId)
                }
                .onFailure {
                    _uiState.value = _uiState.value.copy(
                        error = "Failed to set agent: ${it.message}"
                    )
                }
        }
    }
    
    fun addGatewayConfig(name: String, url: String, token: String?) {
        viewModelScope.launch {
            val config = GatewayConfig(
                name = name,
                url = url,
                token = token,
                isDefault = _uiState.value.gatewayConfigs.isEmpty()
            )
            gatewayConfigRepository.saveConfig(config)
        }
    }
    
    fun setDefaultGateway(id: Long) {
        viewModelScope.launch {
            gatewayConfigRepository.setDefault(id)
        }
    }
    
    fun deleteGatewayConfig(id: Long) {
        viewModelScope.launch {
            gatewayConfigRepository.deleteConfig(id)
        }
    }
    
    fun clearError() {
        _uiState.value = _uiState.value.copy(error = null)
    }
}