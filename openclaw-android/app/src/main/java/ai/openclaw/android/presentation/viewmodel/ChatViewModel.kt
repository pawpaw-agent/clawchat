package ai.openclaw.android.presentation.viewmodel

import ai.openclaw.android.core.network.GatewayClient
import ai.openclaw.android.data.repository.AgentsRepository
import ai.openclaw.android.data.repository.ChatRepository
import ai.openclaw.android.domain.model.Message
import ai.openclaw.android.domain.model.MessageRole
import androidx.lifecycle.SavedStateHandle
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject

/**
 * 聊天 UI 状态
 */
data class ChatUiState(
    val sessionKey: String = "",
    val messages: List<Message> = emptyList(),
    val inputText: String = "",
    val isLoading: Boolean = false,
    val isSending: Boolean = false,
    val isStreaming: Boolean = false,
    val currentRunId: String? = null,
    val error: String? = null,
    val hasMoreHistory: Boolean = true,
    val isLoadingHistory: Boolean = false,
    val agentEmoji: String? = null,
    val agentName: String? = null
)

@HiltViewModel
class ChatViewModel @Inject constructor(
    private val chatRepository: ChatRepository,
    private val gatewayClient: GatewayClient,
    private val agentsRepository: AgentsRepository,
    savedStateHandle: SavedStateHandle
) : ViewModel() {
    
    private val sessionKey: String = savedStateHandle["sessionKey"] ?: ""
    
    private val _uiState = MutableStateFlow(ChatUiState(sessionKey = sessionKey))
    val uiState: StateFlow<ChatUiState> = _uiState.asStateFlow()
    
    init {
        loadMessages()
        loadAgentInfo()
        observeStreamEvents()
    }
    
    private fun loadMessages() {
        viewModelScope.launch {
            chatRepository.getMessages(sessionKey).collect { messages ->
                _uiState.value = _uiState.value.copy(
                    messages = messages,
                    isStreaming = messages.any { it.isStreaming }
                )
            }
        }
        
        // 同步历史
        viewModelScope.launch {
            chatRepository.syncHistory(sessionKey)
        }
    }
    
    private fun loadAgentInfo() {
        viewModelScope.launch {
            agentsRepository.getAgents()
                .onSuccess { agents ->
                    // 获取第一个 agent（通常是 main）
                    val agent = agents.firstOrNull()
                    _uiState.value = _uiState.value.copy(
                        agentEmoji = agent?.identity?.emoji,
                        agentName = agent?.identity?.name ?: agent?.name ?: agent?.id
                    )
                }
        }
    }
    
    private fun observeStreamEvents() {
        viewModelScope.launch {
            gatewayClient.events.collect { event ->
                when (event.event) {
                    "chat", "chat.done" -> {
                        // 解析事件 payload 并调用 chatRepository.handleStreamEvent
                        try {
                            val eventJson = kotlinx.serialization.json.JsonObject(
                                mapOf(
                                    "event" to kotlinx.serialization.json.JsonPrimitive(event.event),
                                    "payload" to event.payload
                                )
                            )
                            chatRepository.handleStreamEvent(eventJson)
                        } catch (e: Exception) {
                            // 忽略解析错误
                        }
                    }
                }
            }
        }
    }
    
    fun updateInputText(text: String) {
        _uiState.value = _uiState.value.copy(inputText = text)
    }
    
    fun sendMessage() {
        val text = _uiState.value.inputText.trim()
        if (text.isEmpty()) return
        
        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(
                isSending = true,
                inputText = ""
            )
            
            chatRepository.sendMessage(sessionKey, text)
                .onSuccess { runId ->
                    _uiState.value = _uiState.value.copy(
                        isSending = false,
                        currentRunId = runId
                    )
                }
                .onFailure { error ->
                    _uiState.value = _uiState.value.copy(
                        isSending = false,
                        error = error.message
                    )
                }
        }
    }
    
    fun abort() {
        val runId = _uiState.value.currentRunId ?: return
        
        viewModelScope.launch {
            chatRepository.abort(sessionKey, runId)
                .onSuccess {
                    _uiState.value = _uiState.value.copy(
                        currentRunId = null,
                        isStreaming = false
                    )
                }
        }
    }
    
    fun loadMoreHistory() {
        if (_uiState.value.isLoadingHistory || !_uiState.value.hasMoreHistory) return
        
        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(isLoadingHistory = true)
            
            val offset = _uiState.value.messages.size
            chatRepository.syncHistory(sessionKey, limit = 50)
                .onSuccess { messages ->
                    _uiState.value = _uiState.value.copy(
                        hasMoreHistory = messages.size >= 50,
                        isLoadingHistory = false
                    )
                }
                .onFailure {
                    _uiState.value = _uiState.value.copy(isLoadingHistory = false)
                }
        }
    }
    
    fun clearError() {
        _uiState.value = _uiState.value.copy(error = null)
    }
}