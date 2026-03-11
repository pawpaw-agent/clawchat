package ai.openclaw.android.service

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.os.Binder
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationCompat
import ai.openclaw.android.MainActivity
import ai.openclaw.android.R
import ai.openclaw.android.core.network.ConnectionState
import ai.openclaw.android.core.network.GatewayClient
import android.content.pm.ServiceInfo
import dagger.hilt.android.AndroidEntryPoint
import kotlinx.coroutines.*
import kotlinx.coroutines.flow.collectLatest
import javax.inject.Inject

@AndroidEntryPoint
class GatewayService : Service() {

    @Inject
    lateinit var gatewayClient: GatewayClient

    private val binder = LocalBinder()
    private val serviceScope = CoroutineScope(Dispatchers.Default + SupervisorJob())
    
    private var notificationManager: NotificationManager? = null
    
    companion object {
        const val CHANNEL_ID = "gateway_service_channel"
        const val NOTIFICATION_ID = 1001
        
        const val ACTION_START = "ai.openclaw.android.action.START"
        const val ACTION_STOP = "ai.openclaw.android.action.STOP"
        
        fun start(context: Context) {
            val intent = Intent(context, GatewayService::class.java).apply {
                action = ACTION_START
            }
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(intent)
            } else {
                context.startService(intent)
            }
        }
        
        fun stop(context: Context) {
            val intent = Intent(context, GatewayService::class.java).apply {
                action = ACTION_STOP
            }
            context.startService(intent)
        }
    }

    inner class LocalBinder : Binder() {
        fun getService(): GatewayService = this@GatewayService
    }

    override fun onBind(intent: Intent?): IBinder = binder

    override fun onCreate() {
        super.onCreate()
        notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        createNotificationChannel()
        
        // 监听连接状态
        serviceScope.launch {
            gatewayClient.connectionState.collectLatest { state ->
                updateNotification(state)
            }
        }
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_START -> {
                startForegroundWithNotification()
            }
            ACTION_STOP -> {
                stopForeground(STOP_FOREGROUND_REMOVE)
                stopSelf()
            }
        }
        return START_STICKY
    }

    override fun onDestroy() {
        super.onDestroy()
        serviceScope.cancel()
        gatewayClient.disconnect()
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Gateway Connection",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "OpenClaw Gateway connection status"
                setShowBadge(false)
            }
            notificationManager?.createNotificationChannel(channel)
        }
    }

    private fun startForegroundWithNotification() {
        val notification = createNotification(ConnectionState.Disconnected)
        
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            startForeground(
                NOTIFICATION_ID,
                notification,
                ServiceInfo.FOREGROUND_SERVICE_TYPE_DATA_SYNC
            )
        } else {
            startForeground(NOTIFICATION_ID, notification)
        }
    }

    private fun createNotification(state: ConnectionState): Notification {
        val intent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_SINGLE_TOP
        }
        
        val pendingIntent = PendingIntent.getActivity(
            this, 0, intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        
        val (title, text) = when (state) {
            is ConnectionState.Connected -> "Connected" to "Gateway connection active"
            is ConnectionState.Connecting -> "Connecting..." to "Establishing connection"
            is ConnectionState.ChallengeReceived -> "Authenticating..." to "Verifying device"
            is ConnectionState.Authenticating -> "Authenticating..." to "Verifying credentials"
            is ConnectionState.Error -> "Connection Error" to (state.message)
            is ConnectionState.Disconnected -> "Disconnected" to "Tap to reconnect"
        }
        
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle(title)
            .setContentText(text)
            .setSmallIcon(R.drawable.ic_notification)
            .setContentIntent(pendingIntent)
            .setOngoing(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setCategory(NotificationCompat.CATEGORY_SERVICE)
            .build()
    }

    private fun updateNotification(state: ConnectionState) {
        val notification = createNotification(state)
        notificationManager?.notify(NOTIFICATION_ID, notification)
    }
}