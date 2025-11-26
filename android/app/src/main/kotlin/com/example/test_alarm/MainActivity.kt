
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

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        //  Initializ all handlers
        alarmHandler = AlarmHandler(this)
        locationHandler = LocationHandler(this)
        dataHandler = DataHandler(this)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->

            when (call.method) {
                // Alarm handle
                "setAlarm" -> alarmHandler.setAlarm(call, result)
                "cancelAlarm" -> alarmHandler.cancelAlarm(result)

                // Location Handle
                "getCurrentLocation" -> locationHandler.getCurrentLocation(result)
                "getAddressFromCoordinates" -> locationHandler.getAddressFromCoordinates(call, result)

                // Sms and contact handle
                "getSmsList" -> dataHandler.getSmsList(result)
                "getContactsList" -> dataHandler.getContactsList(result)

                else -> result.notImplemented()
            }
        }
    }

}