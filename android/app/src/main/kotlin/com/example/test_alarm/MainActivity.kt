package com.example.test_alarm

import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.alarm_clock/alarm"

    private lateinit var alarmHandler: AlarmHandler
    private lateinit var locationHandler: LocationHandler
    private lateinit var dataHandler: DataHandler
    private lateinit var appInfoHandler: AppInfoHandler

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Initialize all handlers
        alarmHandler = AlarmHandler(this)
        locationHandler = LocationHandler(this)
        dataHandler = DataHandler(this)
        appInfoHandler = AppInfoHandler(this)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->

                when (call.method) {

                    // Alarm Handler
                    "setAlarm" -> alarmHandler.setAlarm(call, result)
                    "cancelAlarm" -> alarmHandler.cancelAlarm(result)

                    // Location Handler
                    "getCurrentLocation" -> locationHandler.getCurrentLocation(result)
                    "getAddressFromCoordinates" ->
                        locationHandler.getAddressFromCoordinates(call, result)

                    // Contacts & SMS Handler
                    "getSmsList" -> dataHandler.getSmsList(result)
                    "getContactsList" -> dataHandler.getContactsList(result)

                    // 🔥 NEW — App Info Handler
                    "getInstalledApps" -> appInfoHandler.getInstalledApps(result)
                    "getAppDetails" -> appInfoHandler.getAppDetails(call, result)

                    else -> result.notImplemented()
                }
            }
    }
}
