package ai.openclaw.android.presentation.viewmodel

import ai.openclaw.android.data.repository.SessionRepository
import ai.openclaw.android.domain.model.Session
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject

/**
 * 会话列表 UI 状态
 */
data class SessionListUiState(
    val sessions: List<Session> = emptyList(),
    val isLoading: Boolean = false,
    val error: String? = null,
    val isRefreshing: Boolean = false
)

@HiltViewModel
class SessionListViewModel @Inject constructor(
    private val sessionRepository: SessionRepository
) : ViewModel() {
    
    private val _uiState = MutableStateFlow(SessionListUiState())
    val uiState: StateFlow<SessionListUiState> = _uiState.asStateFlow()
    
    init {
        loadSessions()
    }
    
    private fun loadSessions() {
        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(isLoading = true)
            
            // 监听本地数据
            sessionRepository.getAllSessions().collect { sessions ->
                _uiState.value = _uiState.value.copy(
                    sessions = sessions,
                    isLoading = false
                )
            }
        }
        
        // 同步服务器数据
        syncSessions()
    }
    
    fun syncSessions() {
        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(isRefreshing = true)
            
            sessionRepository.syncSessions()
                .onFailure { error ->
                    _uiState.value = _uiState.value.copy(
                        error = error.message,
                        isRefreshing = false
                    )
                }
            
            _uiState.value = _uiState.value.copy(isRefreshing = false)
        }
    }
    
    fun createSession(label: String? = null, onCreated: (String) -> Unit) {
        viewModelScope.launch {
            sessionRepository.createSession(label)
                .onSuccess { session ->
                    onCreated(session.key)
                }
                .onFailure { error ->
                    _uiState.value = _uiState.value.copy(error = error.message)
                }
        }
    }
    
    fun deleteSession(key: String) {
        viewModelScope.launch {
            sessionRepository.deleteSession(key)
                .onFailure { error ->
                    _uiState.value = _uiState.value.copy(error = error.message)
                }
        }
    }
    
    fun resetSession(key: String) {
        viewModelScope.launch {
            sessionRepository.resetSession(key)
                .onFailure { error ->
                    _uiState.value = _uiState.value.copy(error = error.message)
                }
        }
    }
    
    fun clearError() {
        _uiState.value = _uiState.value.copy(error = null)
    }
}