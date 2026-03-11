package ai.openclaw.android

import android.app.Application
import dagger.hilt.android.HiltAndroidApp
import org.conscrypt.Conscrypt
import java.security.Security

@HiltAndroidApp
class OpenClawApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        
        // 注册 Conscrypt provider 以支持 Ed25519
        Security.insertProviderAt(Conscrypt.newProvider(), 1)
    }
}