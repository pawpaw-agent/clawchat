package com.openclaw.clawchat

import android.content.Intent
import android.os.Bundle
import com.openclaw.clawchat.platform.BackgroundServicePlugin
import com.openclaw.clawchat.platform.PushNotificationPlugin
import com.openclaw.clawchat.platform.FirebaseService
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity: FlutterActivity() {
    
    companion object {
        private const val TAG = "MainActivity"
        
        // Store launch intent data for Flutter to read later
        @Volatile
        var pendingConversationId: String? = null
        @Volatile
        var pendingMessageId: String? = null
        @Volatile
        var pendingSenderId: String? = null
        @Volatile
        var pendingSenderName: String? = null
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Register the background service plugin
        flutterEngine.plugins.add(BackgroundServicePlugin())
        // Register the push notification plugin
        flutterEngine.plugins.add(PushNotificationPlugin())
    }
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Handle cold start from notification tap
        handleIntent(intent)
    }
    
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        // Handle notification tap when app is in background
        handleIntent(intent)
    }
    
    private fun handleIntent(intent: Intent?) {
        intent?.let {
            if (it.action == FirebaseService.ACTION_OPEN_CONVERSATION) {
                pendingConversationId = it.getStringExtra(FirebaseService.EXTRA_CONVERSATION_ID)
                pendingMessageId = it.getStringExtra(FirebaseService.EXTRA_MESSAGE_ID)
                pendingSenderId = it.getStringExtra(FirebaseService.EXTRA_SENDER_ID)
                pendingSenderName = it.getStringExtra(FirebaseService.EXTRA_SENDER_NAME)
                
                android.util.Log.d(TAG, "Opening conversation from notification: $pendingConversationId")
            }
        }
    }
    
    override fun onResume() {
        super.onResume()
        // Mark app as in foreground
        FirebaseService.setForeground(true)
    }
    
    override fun onPause() {
        super.onPause()
        // Mark app as in background
        FirebaseService.setForeground(false)
    }
}