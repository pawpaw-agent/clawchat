package ai.openclaw.android.presentation.viewmodel

import ai.openclaw.android.data.repository.GatewayConfigRepository
import ai.openclaw.android.data.repository.ModelsRepository
import ai.openclaw.android.data.repository.SessionRepository
import ai.openclaw.android.domain.model.GatewayConfig
import ai.openclaw.android.domain.model.ModelInfo
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
    val models: List<ModelInfo> = emptyList(),
    val currentModel: String? = null,
    val isLoading: Boolean = false,
    val isLoadingModels: Boolean = false,
    val error: String? = null
)

@HiltViewModel
class SettingsViewModel @Inject constructor(
    private val gatewayConfigRepository: GatewayConfigRepository,
    private val modelsRepository: ModelsRepository,
    private val sessionRepository: SessionRepository
) : ViewModel() {
    
    private val _uiState = MutableStateFlow(SettingsUiState())
    val uiState: StateFlow<SettingsUiState> = _uiState.asStateFlow()
    
    init {
        loadSettings()
        loadModels()
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
        
        // 加载当前会话的模型
        viewModelScope.launch {
            sessionRepository.getSessionByKey("main")?.let { session ->
                _uiState.value = _uiState.value.copy(currentModel = session.model)
            }
        }
    }
    
    private fun loadModels() {
        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(isLoadingModels = true)
            
            modelsRepository.getModels()
                .onSuccess { models ->
                    _uiState.value = _uiState.value.copy(
                        models = models,
                        isLoadingModels = false
                    )
                }
                .onFailure {
                    _uiState.value = _uiState.value.copy(
                        isLoadingModels = false,
                        error = "Failed to load models: ${it.message}"
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
    
    fun setModel(modelId: String) {
        viewModelScope.launch {
            sessionRepository.patchSession("main", model = modelId)
                .onSuccess {
                    _uiState.value = _uiState.value.copy(currentModel = modelId)
                }
                .onFailure {
                    _uiState.value = _uiState.value.copy(
                        error = "Failed to set model: ${it.message}"
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