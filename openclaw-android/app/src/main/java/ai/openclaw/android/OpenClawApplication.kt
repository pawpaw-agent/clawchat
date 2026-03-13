package ai.openclaw.android

import ai.openclaw.android.core.network.ApprovalEventManager
import android.app.Application
import android.util.Log
import dagger.hilt.android.HiltAndroidApp
import org.bouncycastle.jce.provider.BouncyCastleProvider
import java.security.Security
import javax.inject.Inject

@HiltAndroidApp
class OpenClawApplication : Application() {
    
    @Inject
    lateinit var approvalEventManager: ApprovalEventManager
    
    companion object {
        private const val TAG = "OpenClawApp"
        
        init {
            // 注册 BouncyCastle Provider 以支持 Ed25519
            try {
                val provider = BouncyCastleProvider()
                Security.addProvider(provider)
                Log.d(TAG, "BouncyCastle provider registered: ${provider.name}")
            } catch (e: Exception) {
                Log.e(TAG, "Failed to register BouncyCastle: ${e.message}", e)
            }
        }
    }
    
    override fun onCreate() {
        super.onCreate()
        
        // 启动审批事件监听
        approvalEventManager.startListening()
        Log.d(TAG, "Approval event manager started")
    }
}