package com.openclaw.clawchat.platform

import android.content.Context
import android.os.Handler
import android.os.Looper
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

/**
 * Platform Channel plugin for background service control.
 * 
 * Provides:
 * - MethodChannel: startService, stopService, updateNotification
 * - EventChannel: status updates (connected/disconnected/reconnecting)
 */
class BackgroundServicePlugin : FlutterPlugin, EventChannel.StreamHandler {

    companion object {
        const val METHOD_CHANNEL = "com.openclaw.clawchat/background_service"
        const val EVENT_CHANNEL = "com.openclaw.clawchat/background_service_status"
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
                "startService" -> {
                    val title = call.argument<String>("title") ?: "ClawChat"
                    val content = call.argument<String>("content") ?: "Service running"
                    val status = call.argument<String>("status") ?: ForegroundService.STATUS_CONNECTED
                    
                    try {
                        ForegroundService.start(context, title, content)
                        // Set initial status after starting
                        Handler(Looper.getMainLooper()).postDelayed({
                            ForegroundService.updateStatus(context, status, title, content)
                        }, 100)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("SERVICE_ERROR", e.message, null)
                    }
                }
                
                "stopService" -> {
                    try {
                        ForegroundService.stop(context)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("SERVICE_ERROR", e.message, null)
                    }
                }
                
                "updateNotification" -> {
                    val title = call.argument<String>("title")
                    val content = call.argument<String>("content")
                    val status = call.argument<String>("status") ?: ForegroundService.STATUS_CONNECTED
                    
                    try {
                        ForegroundService.updateStatus(context, status, title, content)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("SERVICE_ERROR", e.message, null)
                    }
                }
                
                "getStatus" -> {
                    result.success(ForegroundService.getCurrentStatus())
                }
                
                else -> result.notImplemented()
            }
        }
        
        // Setup event channel for status updates
        val eventChannel = EventChannel(binding.binaryMessenger, EVENT_CHANNEL)
        eventChannel.setStreamHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        eventSink = null
        ForegroundService.setStatusCallback(null)
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
        
        // Set callback to forward status updates to Flutter
        ForegroundService.setStatusCallback { status ->
            mainHandler.post {
                eventSink?.success(status)
            }
        }
        
        // Send current status immediately
        mainHandler.post {
            eventSink?.success(ForegroundService.getCurrentStatus())
        }
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
        ForegroundService.setStatusCallback(null)
    }
}