package ai.openclaw.android.core.network

import android.app.Application
import android.os.Bundle
import androidx.lifecycle.DefaultLifecycleObserver
import androidx.lifecycle.LifecycleOwner
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
 * 通过注册 Application.ActivityLifecycleCallbacks 来检测前后台切换
 */
@Singleton
class AppLifecycleObserver @Inject constructor(
    private val gatewayClient: GatewayClient
) : Application.ActivityLifecycleCallbacks {
    
    private val _isForeground = MutableStateFlow(true)
    val isForeground: StateFlow<Boolean> = _isForeground.asStateFlow()
    
    private val scope = CoroutineScope(Dispatchers.IO)
    private var activityCount: Int = 0
    
    fun register(application: Application) {
        application.registerActivityLifecycleCallbacks(this)
    }
    
    override fun onActivityCreated(activity: android.app.Activity, savedInstanceState: Bundle?) {}
    
    override fun onActivityStarted(activity: android.app.Activity) {
        activityCount++
        if (activityCount == 1) {
            // 第一个 Activity 可见，App 进入前台
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
    }
    
    override fun onActivityResumed(activity: android.app.Activity) {}
    
    override fun onActivityPaused(activity: android.app.Activity) {}
    
    override fun onActivityStopped(activity: android.app.Activity) {
        activityCount--
        if (activityCount == 0) {
            // 所有 Activity 都不可见，App 进入后台
            _isForeground.value = false
            android.util.Log.d("AppLifecycleObserver", "App entered background")
        }
    }
    
    override fun onActivitySaveInstanceState(activity: android.app.Activity, outState: Bundle) {}
    
    override fun onActivityDestroyed(activity: android.app.Activity) {}
}