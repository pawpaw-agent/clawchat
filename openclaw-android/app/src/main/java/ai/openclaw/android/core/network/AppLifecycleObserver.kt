package ai.openclaw.android.core.network

import androidx.lifecycle.DefaultLifecycleObserver
import androidx.lifecycle.LifecycleOwner
import androidx.lifecycle.ProcessLifecycleOwner
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject
import javax.inject.Singleton

/**
 * App 前后台状态管理
 */
@Singleton
class AppLifecycleObserver @Inject constructor(
    private val gatewayClient: GatewayClient
) : DefaultLifecycleObserver {
    
    private val _isForeground = MutableStateFlow(true)
    val isForeground: StateFlow<Boolean> = _isForeground.asStateFlow()
    
    private val scope = CoroutineScope(Dispatchers.IO)
    
    fun register() {
        ProcessLifecycleOwner.get().lifecycle.addObserver(this)
    }
    
    override fun onStart(owner: LifecycleOwner) {
        // App 进入前台
        _isForeground.value = true
        android.util.Log.d("AppLifecycleObserver", "App entered foreground")
        
        // 检查连接状态，如果断开则尝试重连
        scope.launch {
            val state = gatewayClient.connectionState.value
            if (state is ConnectionState.Disconnected || state is ConnectionState.Error) {
                android.util.Log.d("AppLifecycleObserver", "Connection lost, attempting reconnect...")
                gatewayClient.reconnect()
            }
        }
    }
    
    override fun onStop(owner: LifecycleOwner) {
        // App 进入后台
        _isForeground.value = false
        android.util.Log.d("AppLifecycleObserver", "App entered background")
    }
}