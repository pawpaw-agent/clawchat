package ai.openclaw.android.presentation.viewmodel

import ai.openclaw.android.data.repository.ChannelRepository
import ai.openclaw.android.domain.model.ChannelStatus
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject

data class ChannelListUiState(
    val channels: List<ChannelStatus> = emptyList(),
    val isLoading: Boolean = false,
    val isRefreshing: Boolean = false,
    val error: String? = null,
    val selectedQrCode: String? = null
)

@HiltViewModel
class ChannelListViewModel @Inject constructor(
    private val channelRepository: ChannelRepository
) : ViewModel() {
    
    private val _uiState = MutableStateFlow(ChannelListUiState())
    val uiState: StateFlow<ChannelListUiState> = _uiState.asStateFlow()
    
    init {
        loadChannels()
    }
    
    private fun loadChannels() {
        viewModelScope.launch {
            channelRepository.channels.collect { channels ->
                _uiState.value = _uiState.value.copy(channels = channels)
            }
        }
        syncChannels()
    }
    
    fun syncChannels() {
        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(isRefreshing = true)
            channelRepository.syncChannels()
                .onFailure { error ->
                    _uiState.value = _uiState.value.copy(error = error.message)
                }
            _uiState.value = _uiState.value.copy(isRefreshing = false)
        }
    }
    
    fun getQrCode(channel: String) {
        viewModelScope.launch {
            channelRepository.getQrCode(channel)
                .onSuccess { qrCode ->
                    _uiState.value = _uiState.value.copy(selectedQrCode = qrCode)
                }
                .onFailure { error ->
                    _uiState.value = _uiState.value.copy(error = error.message)
                }
        }
    }
    
    fun disconnect(channel: String) {
        viewModelScope.launch {
            channelRepository.disconnect(channel)
                .onFailure { error ->
                    _uiState.value = _uiState.value.copy(error = error.message)
                }
        }
    }
    
    fun reconnect(channel: String) {
        viewModelScope.launch {
            channelRepository.reconnect(channel)
                .onFailure { error ->
                    _uiState.value = _uiState.value.copy(error = error.message)
                }
        }
    }
    
    fun clearQrCode() {
        _uiState.value = _uiState.value.copy(selectedQrCode = null)
    }
    
    fun clearError() {
        _uiState.value = _uiState.value.copy(error = null)
    }
}