package com.openclaw.clawchat.platform

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log
import androidx.core.app.NotificationCompat
import com.google.firebase.messaging.FirebaseMessagingService
import com.google.firebase.messaging.RemoteMessage
import com.openclaw.clawchat.MainActivity
import com.openclaw.clawchat.R
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.plugin.common.MethodChannel

/**
 * Firebase Cloud Messaging service for ClawChat.
 * 
 * Features:
 * - Receives FCM messages in foreground and background
 * - Shows notifications for background/terminated messages
 * - Handles notification tap to navigate to conversation
 * - Forwards messages to Flutter when app is in foreground
 */
class FirebaseService : FirebaseMessagingService() {

    companion object {
        private const val TAG = "FirebaseService"
        const val CHANNEL_ID = "clawchat_messages"
        const val CHANNEL_NAME = "Messages"
        const val CHANNEL_DESC = "Chat message notifications"
        
        const val METHOD_CHANNEL = "com.openclaw.clawchat/push_notification"
        const val EVENT_CHANNEL = "com.openclaw.clawchat/push_notification_event"
        
        const val ACTION_OPEN_CONVERSATION = "com.openclaw.clawchat.OPEN_CONVERSATION"
        const val EXTRA_CONVERSATION_ID = "conversation_id"
        const val EXTRA_MESSAGE_ID = "message_id"
        const val EXTRA_SENDER_ID = "sender_id"
        const val EXTRA_SENDER_NAME = "sender_name"
        
        private var eventSink: io.flutter.plugin.common.EventChannel.EventSink? = null
        private var tokenCallback: ((String) -> Unit)? = null
        private var messageCallback: ((Map<String, Any?>) -> Unit)? = null
        
        // Track if app is in foreground
        @Volatile
        var isForeground: Boolean = false
            private set
        
        fun setForeground(foreground: Boolean) {
            isForeground = foreground
        }
        
        fun setEventSink(sink: io.flutter.plugin.common.EventChannel.EventSink?) {
            eventSink = sink
        }
        
        fun setTokenCallback(callback: ((String) -> Unit)?) {
            tokenCallback = callback
        }
        
        fun setMessageCallback(callback: ((Map<String, Any?>) -> Unit)?) {
            messageCallback = callback
        }
    }

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
        Log.d(TAG, "FirebaseService created")
    }

    override fun onNewToken(token: String) {
        super.onNewToken(token)
        Log.d(TAG, "New FCM token received: ${token.take(20)}...")
        
        // Notify Flutter via callback
        tokenCallback?.invoke(token)
        
        // Also try to send via event channel
        eventSink?.success(mapOf(
            "type" to "token",
            "token" to token
        ))
    }

    override fun onMessageReceived(remoteMessage: RemoteMessage) {
        super.onMessageReceived(remoteMessage)
        Log.d(TAG, "Message received from: ${remoteMessage.from}")
        
        // Extract data payload
        val data = remoteMessage.data
        val notification = remoteMessage.notification
        
        Log.d(TAG, "Data payload: $data")
        Log.d(TAG, "Notification: ${notification?.title} - ${notification?.body}")
        
        // Build message map
        val messageData = mutableMapOf<String, Any?>(
            "messageId" to remoteMessage.messageId,
            "sentTime" to remoteMessage.sentTime,
            "from" to remoteMessage.from
        )
        
        // Extract notification content
        notification?.let {
            messageData["title"] = it.title
            messageData["body"] = it.body
            messageData["imageUrl"] = it.imageUrl?.toString()
        }
        
        // Extract data payload (conversation info)
        data["conversationId"]?.let { messageData["conversationId"] = it }
        data["messageId"]?.let { messageData["dataMessageId"] = it }
        data["senderId"]?.let { messageData["senderId"] = it }
        data["senderName"]?.let { messageData["senderName"] = it }
        data["type"]?.let { messageData["dataType"] = it }
        
        // Handle based on app state
        if (isForeground) {
            // App in foreground - don't show notification, just forward to Flutter
            Log.d(TAG, "App in foreground, forwarding message to Flutter")
            messageCallback?.invoke(messageData)
            eventSink?.success(mapOf(
                "type" to "message",
                "data" to messageData
            ))
        } else {
            // App in background or terminated - show notification
            Log.d(TAG, "App in background, showing notification")
            showNotification(messageData)
            
            // Still notify Flutter so it can handle when app opens
            messageCallback?.invoke(messageData)
        }
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                CHANNEL_NAME,
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = CHANNEL_DESC
                enableLights(true)
                enableVibration(true)
                setShowBadge(true)
            }
            
            val notificationManager = getSystemService(NotificationManager::class.java)
            notificationManager.createNotificationChannel(channel)
            Log.d(TAG, "Notification channel created")
        }
    }

    private fun showNotification(messageData: Map<String, Any?>) {
        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        
        val conversationId = messageData["conversationId"] as? String ?: return
        val title = (messageData["senderName"] as? String) 
            ?: (messageData["title"] as? String) 
            ?: "ClawChat"
        val body = (messageData["body"] as? String) ?: "New message"
        val messageId = messageData["messageId"] as? String ?: ""
        val senderId = messageData["senderId"] as? String ?: ""
        
        // Create intent to open conversation
        val intent = Intent(this, MainActivity::class.java).apply {
            action = ACTION_OPEN_CONVERSATION
            flags = Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP
            putExtra(EXTRA_CONVERSATION_ID, conversationId)
            putExtra(EXTRA_MESSAGE_ID, messageId)
            putExtra(EXTRA_SENDER_ID, senderId)
            putExtra(EXTRA_SENDER_NAME, title)
        }
        
        val pendingIntentFlags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        } else {
            PendingIntent.FLAG_UPDATE_CURRENT
        }
        
        val pendingIntent = PendingIntent.getActivity(
            this,
            conversationId.hashCode(), // Unique ID per conversation for grouping
            intent,
            pendingIntentFlags
        )
        
        // Build notification
        val notification = NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_launcher_foreground)
            .setContentTitle(title)
            .setContentText(body)
            .setAutoCancel(true)
            .setContentIntent(pendingIntent)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setCategory(NotificationCompat.CATEGORY_MESSAGE)
            .setDefaults(NotificationCompat.DEFAULT_ALL)
            .build()
        
        // Use conversation ID as notification ID for grouping
        val notificationId = conversationId.hashCode()
        notificationManager.notify(notificationId, notification)
        Log.d(TAG, "Notification shown for conversation: $conversationId")
    }

    override fun onDestroy() {
        super.onDestroy()
        eventSink = null
        tokenCallback = null
        messageCallback = null
        Log.d(TAG, "FirebaseService destroyed")
    }
}