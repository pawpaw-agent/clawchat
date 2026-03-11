package ai.openclaw.android.presentation.viewmodel

import ai.openclaw.android.data.repository.ConfigRepository
import ai.openclaw.android.domain.model.ConfigItem
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject

data class ConfigUiState(
    val config: Map<String, ConfigItem> = emptyMap(),
    val isLoading: Boolean = false,
    val isRefreshing: Boolean = false,
    val error: String? = null,
    val editingKey: String? = null,
    val editingValue: String = ""
)

@HiltViewModel
class ConfigViewModel @Inject constructor(
    private val configRepository: ConfigRepository
) : ViewModel() {
    
    private val _uiState = MutableStateFlow(ConfigUiState())
    val uiState: StateFlow<ConfigUiState> = _uiState.asStateFlow()
    
    init {
        loadConfig()
    }
    
    private fun loadConfig() {
        viewModelScope.launch {
            configRepository.config.collect { config ->
                _uiState.value = _uiState.value.copy(config = config)
            }
        }
        syncConfig()
    }
    
    fun syncConfig() {
        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(isRefreshing = true)
            configRepository.syncConfig()
                .onFailure { error ->
                    _uiState.value = _uiState.value.copy(error = error.message)
                }
            _uiState.value = _uiState.value.copy(isRefreshing = false)
        }
    }
    
    fun startEdit(key: String) {
        val item = _uiState.value.config[key]
        _uiState.value = _uiState.value.copy(
            editingKey = key,
            editingValue = item?.value ?: ""
        )
    }
    
    fun updateEditingValue(value: String) {
        _uiState.value = _uiState.value.copy(editingValue = value)
    }
    
    fun saveEdit() {
        val key = _uiState.value.editingKey ?: return
        val value = _uiState.value.editingValue
        
        viewModelScope.launch {
            configRepository.setConfig(key, value)
                .onFailure { error ->
                    _uiState.value = _uiState.value.copy(error = error.message)
                }
        }
        
        _uiState.value = _uiState.value.copy(
            editingKey = null,
            editingValue = ""
        )
    }
    
    fun cancelEdit() {
        _uiState.value = _uiState.value.copy(
            editingKey = null,
            editingValue = ""
        )
    }
    
    fun clearError() {
        _uiState.value = _uiState.value.copy(error = null)
    }
}