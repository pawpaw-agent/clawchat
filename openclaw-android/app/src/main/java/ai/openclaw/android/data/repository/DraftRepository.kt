package ai.openclaw.android.data.repository

import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import javax.inject.Inject
import javax.inject.Singleton

/**
 * 输入草稿管理器
 * 保存每个会话的输入框内容
 */
@Singleton
class DraftRepository @Inject constructor() {
    private val drafts = mutableMapOf<String, String>()
    private val _currentDraft = MutableStateFlow("")
    val currentDraft: StateFlow<String> = _currentDraft.asStateFlow()
    
    /**
     * 保存草稿
     */
    fun saveDraft(sessionKey: String, text: String) {
        if (text.isBlank()) {
            drafts.remove(sessionKey)
        } else {
            drafts[sessionKey] = text
        }
        _currentDraft.value = text
    }
    
    /**
     * 获取草稿
     */
    fun getDraft(sessionKey: String): String {
        return drafts[sessionKey] ?: ""
    }
    
    /**
     * 清除草稿
     */
    fun clearDraft(sessionKey: String) {
        drafts.remove(sessionKey)
        _currentDraft.value = ""
    }
}