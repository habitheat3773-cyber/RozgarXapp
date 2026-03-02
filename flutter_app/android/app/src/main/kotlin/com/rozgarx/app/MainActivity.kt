package com.rozgarx.app

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.os.Bundle
import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build
import android.content.Context

class MainActivity: FlutterActivity() {
    
    private val CHANNEL = "com.rozgarx.app/native"
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        createNotificationChannels()
    }
    
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getDeviceInfo" -> {
                    val deviceInfo = mapOf(
                        "model" to Build.MODEL,
                        "manufacturer" to Build.MANUFACTURER,
                        "androidVersion" to Build.VERSION.RELEASE,
                        "sdkInt" to Build.VERSION.SDK_INT
                    )
                    result.success(deviceInfo)
                }
                "clearAppCache" -> {
                    try {
                        val cacheDir = cacheDir
                        cacheDir.deleteRecursively()
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("CACHE_ERROR", e.message, null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }
    
    private fun createNotificationChannels() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            
            // Main job alerts channel
            val jobAlertsChannel = NotificationChannel(
                "rozgarx_jobs",
                "Job Alerts",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "New government job notifications"
                enableVibration(true)
                enableLights(true)
                lightColor = 0xFF1E3A8A.toInt()
                setShowBadge(true)
            }
            
            // Deadline reminders channel
            val deadlineChannel = NotificationChannel(
                "rozgarx_deadlines",
                "Deadline Reminders",
                NotificationManager.IMPORTANCE_DEFAULT
            ).apply {
                description = "Job application deadline reminders"
                enableVibration(false)
            }
            
            // Exam schedule channel
            val examChannel = NotificationChannel(
                "rozgarx_exams",
                "Exam Schedules",
                NotificationManager.IMPORTANCE_DEFAULT
            ).apply {
                description = "Exam date and admit card notifications"
            }
            
            notificationManager.createNotificationChannels(
                listOf(jobAlertsChannel, deadlineChannel, examChannel)
            )
        }
    }
}
