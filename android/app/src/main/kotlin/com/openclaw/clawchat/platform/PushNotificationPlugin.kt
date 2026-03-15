package com.openclaw.clawchat.platform

import android.content.Context
import android.os.Handler
import android.os.Looper
import com.google.firebase.messaging.FirebaseMessaging
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

/**
 * Platform Channel plugin for push notification control.
 * 
 * Provides:
 * - MethodChannel: initialize, getToken, subscribeToTopic, unsubscribeFromTopic
 * - EventChannel: push events (token refresh, messages in foreground)
 */
class PushNotificationPlugin : FlutterPlugin, EventChannel.StreamHandler {

    companion object {
        const val METHOD_CHANNEL = "com.openclaw.clawchat/push_notification"
        const val EVENT_CHANNEL = "com.openclaw.clawchat/push_notification_event"
    }

    private lateinit var context: Context
    private var eventSink: EventChannel.EventSink? = null
    private val mainHandler = Handler(Looper.getMainLooper())

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        
        // Setup method channel
        val methodChannel = MethodChannel(binding.binaryMessenger, METHOD_CHANNEL)
        methodChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "initialize" -> {
                    // Already initialized via FirebaseService in manifest
                    // Just return success
                    result.success(true)
                }
                
                "getToken" -> {
                    FirebaseMessaging.getInstance().token.addOnCompleteListener { task ->
                        if (task.isSuccessful) {
                            result.success(task.result)
                        } else {
                            result.error("TOKEN_ERROR", "Failed to get FCM token", task.exception?.message)
                        }
                    }
                }
                
                "subscribeToTopic" -> {
                    val topic = call.argument<String>("topic")
                    if (topic.isNullOrEmpty()) {
                        result.error("INVALID_ARG", "topic is required", null)
                        return@setMethodCallHandler
                    }
                    
                    FirebaseMessaging.getInstance().subscribeToTopic(topic)
                        .addOnCompleteListener { task ->
                            if (task.isSuccessful) {
                                result.success(true)
                            } else {
                                result.error("SUBSCRIBE_ERROR", "Failed to subscribe to topic", task.exception?.message)
                            }
                        }
                }
                
                "unsubscribeFromTopic" -> {
                    val topic = call.argument<String>("topic")
                    if (topic.isNullOrEmpty()) {
                        result.error("INVALID_ARG", "topic is required", null)
                        return@setMethodCallHandler
                    }
                    
                    FirebaseMessaging.getInstance().unsubscribeFromTopic(topic)
                        .addOnCompleteListener { task ->
                            if (task.isSuccessful) {
                                result.success(true)
                            } else {
                                result.error("UNSUBSCRIBE_ERROR", "Failed to unsubscribe from topic", task.exception?.message)
                            }
                        }
                }
                
                "setForeground" -> {
                    val foreground = call.argument<Boolean>("foreground") ?: true
                    FirebaseService.setForeground(foreground)
                    result.success(true)
                }
                
                else -> result.notImplemented()
            }
        }
        
        // Setup event channel for push events
        val eventChannel = EventChannel(binding.binaryMessenger, EVENT_CHANNEL)
        eventChannel.setStreamHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        eventSink = null
        FirebaseService.setEventSink(null)
        FirebaseService.setTokenCallback(null)
        FirebaseService.setMessageCallback(null)
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
        FirebaseService.setEventSink(events)
        
        // Set callback for token refresh
        FirebaseService.setTokenCallback { token ->
            mainHandler.post {
                eventSink?.success(mapOf(
                    "type" to "token",
                    "token" to token
                ))
            }
        }
        
        // Set callback for foreground messages
        FirebaseService.setMessageCallback { messageData ->
            mainHandler.post {
                eventSink?.success(mapOf(
                    "type" to "message",
                    "data" to messageData
                ))
            }
        }
        
        // Get initial token
        FirebaseMessaging.getInstance().token.addOnCompleteListener { task ->
            if (task.isSuccessful) {
                mainHandler.post {
                    eventSink?.success(mapOf(
                        "type" to "token",
                        "token" to task.result
                    ))
                }
            }
        }
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
        FirebaseService.setEventSink(null)
        FirebaseService.setTokenCallback(null)
        FirebaseService.setMessageCallback(null)
    }
}