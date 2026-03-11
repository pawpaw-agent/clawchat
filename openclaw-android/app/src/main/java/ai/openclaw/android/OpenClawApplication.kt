package ai.openclaw.android

import android.app.Application
import android.util.Log
import dagger.hilt.android.HiltAndroidApp
import org.conscrypt.Conscrypt
import java.security.Security

@HiltAndroidApp
class OpenClawApplication : Application() {
    
    companion object {
        private const val TAG = "OpenClawApp"
        
        init {
            // 在类加载时立即注册 Conscrypt Provider（早于 onCreate）
            try {
                val provider = Conscrypt.newProvider()
                Security.insertProviderAt(provider, 1)
                Log.d(TAG, "Conscrypt provider registered: ${provider.name}")
                
                // 验证 Ed25519 可用
                val kpg = java.security.KeyPairGenerator.getInstance("Ed25519")
                Log.d(TAG, "Ed25519 KeyPairGenerator available! Provider: ${kpg.provider.name}")
            } catch (e: Exception) {
                Log.e(TAG, "Failed to register Conscrypt or Ed25519 not available: ${e.message}", e)
            }
        }
    }
    
    override fun onCreate() {
        super.onCreate()
        
        // 再次确认 Provider 已注册
        val providers = Security.getProviders()
        Log.d(TAG, "Security providers: ${providers.map { it.name }}")
        
        // 验证 Ed25519 可用
        try {
            val kpg = java.security.KeyPairGenerator.getInstance("Ed25519")
            Log.d(TAG, "Ed25519 KeyPairGenerator confirmed available in onCreate()")
        } catch (e: Exception) {
            Log.e(TAG, "Ed25519 NOT available in onCreate(): ${e.message}", e)
        }
    }
}