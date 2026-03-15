package com.openclaw.clawchat.platform

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationCompat
import com.openclaw.clawchat.R

/**
 * Foreground service for maintaining WebSocket connection in background.
 * 
 * Features:
 * - Shows persistent notification with connection status
 * - Supports status updates (connected/disconnected/reconnecting)
 * - Provides stop action button in notification
 * - Uses START_STICKY for automatic restart
 */
class ForegroundService : Service() {

    companion object {
        const val CHANNEL_ID = "clawchat_foreground_service"
        const val NOTIFICATION_ID = 1001
        const val ACTION_STOP_SERVICE = "com.openclaw.clawchat.STOP_FOREGROUND_SERVICE"
        const val ACTION_UPDATE_STATUS = "com.openclaw.clawchat.UPDATE_STATUS"
        
        // Status constants
        const val STATUS_CONNECTED = "connected"
        const val STATUS_DISCONNECTED = "disconnected"
        const val STATUS_RECONNECTING = "reconnecting"
        
        // Intent extras
        const val EXTRA_TITLE = "title"
        const val EXTRA_CONTENT = "content"
        const val EXTRA_STATUS = "status"
        
        @Volatile
        private var currentStatus: String = STATUS_DISCONNECTED
        private var statusCallback: ((String) -> Unit)? = null
        
        fun setStatusCallback(callback: ((String) -> Unit)?) {
            statusCallback = callback
        }
        
        fun getCurrentStatus(): String = currentStatus
        
        fun start(context: Context, title: String = "ClawChat", content: String = "Service running") {
            val intent = Intent(context, ForegroundService::class.java).apply {
                action = "START"
                putExtra(EXTRA_TITLE, title)
                putExtra(EXTRA_CONTENT, content)
            }
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(intent)
            } else {
                context.startService(intent)
            }
        }
        
        fun stop(context: Context) {
            val intent = Intent(context, ForegroundService::class.java).apply {
                action = "STOP"
            }
            context.startService(intent)
        }
        
        fun updateStatus(context: Context, status: String, title: String? = null, content: String? = null) {
            currentStatus = status
            val intent = Intent(context, ForegroundService::class.java).apply {
                action = ACTION_UPDATE_STATUS
                putExtra(EXTRA_STATUS, status)
                putExtra(EXTRA_TITLE, title)
                putExtra(EXTRA_CONTENT, content)
            }
            context.startService(intent)
        }
    }
    
    private lateinit var notificationManager: NotificationManager
    private var currentTitle: String = "ClawChat"
    private var currentContent: String = "Service running"
    
    private val stopReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            if (intent?.action == ACTION_STOP_SERVICE) {
                stopForeground(STOP_FOREGROUND_REMOVE)
                stopSelf()
                currentStatus = STATUS_DISCONNECTED
                statusCallback?.invoke(currentStatus)
            }
        }
    }

    override fun onCreate() {
        super.onCreate()
        notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        createNotificationChannel()
        
        // Register receiver for stop action
        val filter = IntentFilter(ACTION_STOP_SERVICE)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            registerReceiver(stopReceiver, filter, Context.RECEIVER_NOT_EXPORTED)
        } else {
            registerReceiver(stopReceiver, filter)
        }
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            "STOP" -> {
                stopForeground(STOP_FOREGROUND_REMOVE)
                stopSelf()
                currentStatus = STATUS_DISCONNECTED
                statusCallback?.invoke(currentStatus)
                return START_NOT_STICKY
            }
            ACTION_UPDATE_STATUS -> {
                val status = intent.getStringExtra(EXTRA_STATUS) ?: STATUS_DISCONNECTED
                currentStatus = status
                currentTitle = intent.getStringExtra(EXTRA_TITLE) ?: getStatusTitle(status)
                currentContent = intent.getStringExtra(EXTRA_CONTENT) ?: getStatusContent(status)
                updateNotification()
                statusCallback?.invoke(status)
            }
            else -> {
                // START or default
                currentTitle = intent?.getStringExtra(EXTRA_TITLE) ?: "ClawChat"
                currentContent = intent?.getStringExtra(EXTRA_CONTENT) ?: "Service running"
                startForeground(NOTIFICATION_ID, createNotification())
            }
        }
        return START_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? = null
    
    override fun onDestroy() {
        super.onDestroy()
        try {
            unregisterReceiver(stopReceiver)
        } catch (e: Exception) {
            // Receiver not registered
        }
        currentStatus = STATUS_DISCONNECTED
        statusCallback?.invoke(currentStatus)
    }
    
    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Connection Status",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Shows WebSocket connection status"
                setShowBadge(false)
                lockscreenVisibility = Notification.VISIBILITY_PUBLIC
            }
            notificationManager.createNotificationChannel(channel)
        }
    }
    
    private fun createNotification(): Notification {
        val stopIntent = Intent(ACTION_STOP_SERVICE).apply {
            setPackage(packageName)
        }
        val stopPendingIntent = PendingIntent.getBroadcast(
            this,
            0,
            stopIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        
        // Get status color for small icon background
        val statusColor = getStatusColor(currentStatus)
        
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle(currentTitle)
            .setContentText(currentContent)
            .setSmallIcon(R.drawable.ic_launcher_foreground)
            .setColor(statusColor)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setCategory(NotificationCompat.CATEGORY_SERVICE)
            .setOngoing(true)
            .setShowWhen(false)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .addAction(
                android.R.drawable.ic_menu_close_clear_cancel,
                "Stop Service",
                stopPendingIntent
            )
            .build()
    }
    
    private fun updateNotification() {
        notificationManager.notify(NOTIFICATION_ID, createNotification())
    }
    
    private fun getStatusTitle(status: String): String {
        return when (status) {
            STATUS_CONNECTED -> "ClawChat - Connected"
            STATUS_RECONNECTING -> "ClawChat - Reconnecting"
            else -> "ClawChat - Disconnected"
        }
    }
    
    private fun getStatusContent(status: String): String {
        return when (status) {
            STATUS_CONNECTED -> "WebSocket connection active"
            STATUS_RECONNECTING -> "Attempting to reconnect..."
            else -> "WebSocket connection lost"
        }
    }
    
    private fun getStatusColor(status: String): Int {
        return when (status) {
            STATUS_CONNECTED -> 0xFF4CAF50.toInt() // Green
            STATUS_RECONNECTING -> 0xFFFFC107.toInt() // Amber
            else -> 0xFF9E9E9E.toInt() // Gray
        }
    }
}