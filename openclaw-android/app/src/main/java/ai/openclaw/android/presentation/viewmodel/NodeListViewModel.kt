package ai.openclaw.android.presentation.viewmodel

import ai.openclaw.android.data.repository.NodeRepository
import ai.openclaw.android.domain.model.NodeStatus
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject

data class NodeListUiState(
    val nodes: List<NodeStatus> = emptyList(),
    val isLoading: Boolean = false,
    val isRefreshing: Boolean = false,
    val error: String? = null
)

@HiltViewModel
class NodeListViewModel @Inject constructor(
    private val nodeRepository: NodeRepository
) : ViewModel() {
    
    private val _uiState = MutableStateFlow(NodeListUiState())
    val uiState: StateFlow<NodeListUiState> = _uiState.asStateFlow()
    
    init {
        loadNodes()
    }
    
    private fun loadNodes() {
        viewModelScope.launch {
            nodeRepository.nodes.collect { nodes ->
                _uiState.value = _uiState.value.copy(nodes = nodes)
            }
        }
        syncNodes()
    }
    
    fun syncNodes() {
        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(isRefreshing = true)
            nodeRepository.syncNodes()
                .onFailure { error ->
                    _uiState.value = _uiState.value.copy(error = error.message)
                }
            _uiState.value = _uiState.value.copy(isRefreshing = false)
        }
    }
    
    fun clearError() {
        _uiState.value = _uiState.value.copy(error = null)
    }
}