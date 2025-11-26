package com.example.test_alarm

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.location.Location
import android.os.Build
import android.os.Looper
import android.provider.Settings
import androidx.annotation.NonNull
import androidx.core.app.ActivityCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

import com.google.android.gms.location.FusedLocationProviderClient
import com.google.android.gms.location.LocationServices
import com.google.android.gms.location.LocationRequest
import com.google.android.gms.location.Priority
import com.google.android.gms.location.LocationCallback
import com.google.android.gms.location.LocationResult
import android.location.Geocoder
import java.io.IOException
import java.util.Locale
// --- অনুপস্থিত ইমপোর্টগুলি যোগ করা হলো ---
import android.database.Cursor
import android.net.Uri
import android.provider.ContactsContract
// ----------------------------------------


class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.alarm_clock/alarm"
    private lateinit var fusedLocationClient: FusedLocationProviderClient
    private val ALARM_REQUEST_CODE = 100
    private val LOCATION_PERMISSION_REQUEST_CODE = 101

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        fusedLocationClient = LocationServices.getFusedLocationProviderClient(this)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->

            when (call.method) {
                "setAlarm" -> {
                    val timeInMillis = call.argument<Long>("timeInMillis")
                    val title = call.argument<String>("title")
                    val body = call.argument<String>("body")
                    val channelId = call.argument<String>("channelId")

                    if (timeInMillis != null && title != null && body != null && channelId != null) {
                        setAlarm(timeInMillis, title, body, channelId)
                        result.success(true)
                    } else {
                        result.error("ARGUMENT_ERROR", "Missing alarm details", null)
                    }
                }
                "cancelAlarm" -> {
                    cancelAlarm()
                    result.success(true)
                }
                "getCurrentLocation" -> {
                    getCurrentLocation(result)
                }

                "getAddressFromCoordinates" -> {
                    val latitude = call.argument<Double>("latitude")
                    val longitude = call.argument<Double>("longitude")

                    if (latitude != null && longitude != null) {
                        getAddressFromCoordinates(latitude, longitude, result)
                    } else {
                        result.error("ARGUMENT_ERROR", "Latitude and Longitude are required.", null)
                    }
                }

                "getSmsList" -> {
                    getSmsList(result)
                }
                "getContactsList" -> {
                    getContactsList(result)
                }

                else -> result.notImplemented()

            }
        }
    }

    private fun setAlarm(timeInMillis: Long, title: String, body: String, channelId: String) {
        val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val intent = Intent(this, AlarmReceiver::class.java).apply {
            putExtra("ALARM_TITLE", title)
            putExtra("ALARM_BODY", body)
            putExtra("CHANNEL_ID", channelId)
        }

        val pendingIntent = PendingIntent.getBroadcast(
            this,
            ALARM_REQUEST_CODE,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            if (alarmManager.canScheduleExactAlarms()) {
                alarmManager.setExactAndAllowWhileIdle(
                    AlarmManager.RTC_WAKEUP,
                    timeInMillis,
                    pendingIntent
                )
            } else {
                val settingsIntent = Intent(Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM)
                startActivity(settingsIntent)
            }
        } else {
            alarmManager.setExactAndAllowWhileIdle(
                AlarmManager.RTC_WAKEUP,
                timeInMillis,
                pendingIntent
            )
        }
    }

    private fun cancelAlarm() {
        val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val intent = Intent(this, AlarmReceiver::class.java)
        val pendingIntent = PendingIntent.getBroadcast(
            this,
            ALARM_REQUEST_CODE,
            intent,
            PendingIntent.FLAG_IMMUTABLE
        )
        alarmManager.cancel(pendingIntent)
    }

    private fun getCurrentLocation(result: MethodChannel.Result) {
        if (checkLocationPermission()) {
            fusedLocationClient.lastLocation.addOnSuccessListener { location: Location? ->
                if (location != null) {
                    val locationMap = mapOf(
                        "latitude" to location.latitude,
                        "longitude" to location.longitude
                    )
                    result.success(locationMap)
                } else {
                    requestNewLocationData(result)
                }
            }
        } else {
            result.error("PERMISSION_DENIED", "Location permission not granted.", null)
        }
    }

    private fun requestNewLocationData(result: MethodChannel.Result) {
        val locationRequest = LocationRequest.Builder(
            Priority.PRIORITY_HIGH_ACCURACY, 1000
        ).setMaxUpdates(1).build()

        val locationCallback = object : LocationCallback() {
            override fun onLocationResult(locationResult: LocationResult) {
                val location: Location = locationResult.lastLocation!!
                val locationMap = mapOf(
                    "latitude" to location.latitude,
                    "longitude" to location.longitude
                )
                result.success(locationMap)
                fusedLocationClient.removeLocationUpdates(this)
            }
        }

        if (ActivityCompat.checkSelfPermission(this, android.Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED) {
            fusedLocationClient.requestLocationUpdates(
                locationRequest, locationCallback, Looper.getMainLooper()
            )
        } else {
            result.error("PERMISSION_ERROR", "Location permission check failed.", null)
        }
    }

    private fun checkLocationPermission(): Boolean {
        return ActivityCompat.checkSelfPermission(
            this,
            android.Manifest.permission.ACCESS_FINE_LOCATION
        ) == PackageManager.PERMISSION_GRANTED
    }


    private fun getAddressFromCoordinates(latitude: Double, longitude: Double, result: MethodChannel.Result) {

        val geocoder = Geocoder(this, Locale.getDefault())
        var addressText = "Address not found."

        try {

            val addresses = geocoder.getFromLocation(latitude, longitude, 1)

            if (addresses != null && addresses.isNotEmpty()) {
                val address = addresses[0]


                val sb = StringBuilder()
                sb.append(address.getAddressLine(0))

                addressText = sb.toString()
            }


            result.success(addressText)

        } catch (e: IOException) {

            e.printStackTrace()
            result.error("GEOCODER_ERROR", "Geocoder failed due to network or service issue.", e.message)
        } catch (e: IllegalArgumentException) {
            e.printStackTrace()
            result.error("GEOCODER_ERROR", "Invalid coordinates provided.", e.message)
        }
    }

    private fun getSmsList(result: MethodChannel.Result) {
        // প্রথমে Runtime Permission চেক করা (যদিও Flutter থেকে চাওয়া হবে)
        if (ActivityCompat.checkSelfPermission(this, android.Manifest.permission.READ_SMS) != PackageManager.PERMISSION_GRANTED) {
            result.error("PERMISSION_DENIED", "READ_SMS permission not granted.", null)
            return
        }

        val smsList = mutableListOf<Map<String, Any?>>()
        val cursor: Cursor? = contentResolver.query(
            Uri.parse("content://sms/inbox"), // ইনবক্স মেসেজ
            arrayOf("address", "body", "date"), // যে ডেটাগুলি দরকার
            null,
            null,
            "date DESC LIMIT 50" // সর্বশেষ ৫০টি মেসেজ
        )

        cursor?.use {
            // Index গুলো একবার বের করে নেওয়া
            val indexAddress = it.getColumnIndexOrThrow("address")
            val indexBody = it.getColumnIndexOrThrow("body")
            val indexDate = it.getColumnIndexOrThrow("date")

            if (it.moveToFirst()) {
                do {
                    val address = it.getString(indexAddress)
                    val body = it.getString(indexBody)
                    val date = it.getLong(indexDate)

                    smsList.add(mapOf(
                        "sender" to address,
                        "message" to body,
                        "timestamp" to date
                    ))
                } while (it.moveToNext())
            }
        }

        result.success(smsList) // মেসেজগুলি Flutter এ ফেরত পাঠানো
    }

    private fun getContactsList(result: MethodChannel.Result) {
        // প্রথমে Runtime Permission চেক করা
        if (ActivityCompat.checkSelfPermission(this, android.Manifest.permission.READ_CONTACTS) != PackageManager.PERMISSION_GRANTED) {
            result.error("PERMISSION_DENIED", "READ_CONTACTS permission not granted.", null)
            return
        }

        val contactsList = mutableListOf<Map<String, Any?>>()
        val cursor: Cursor? = contentResolver.query(
            ContactsContract.CommonDataKinds.Phone.CONTENT_URI, // ফোন নম্বর সহ কনট্যাক্ট
            arrayOf(
                ContactsContract.CommonDataKinds.Phone.DISPLAY_NAME, // নাম
                ContactsContract.CommonDataKinds.Phone.NUMBER // ফোন নম্বর
            ),
            null,
            null,
            ContactsContract.CommonDataKinds.Phone.DISPLAY_NAME + " ASC" // নাম অনুযায়ী সাজানো
        )

        cursor?.use {
            if (it.moveToFirst()) {
                // Index গুলো একবার বের করে নেওয়া
                val indexName = it.getColumnIndexOrThrow(ContactsContract.CommonDataKinds.Phone.DISPLAY_NAME)
                val indexNumber = it.getColumnIndexOrThrow(ContactsContract.CommonDataKinds.Phone.NUMBER)

                do {
                    val name = it.getString(indexName)
                    val number = it.getString(indexNumber)

                    if (name != null && number != null) {
                        contactsList.add(mapOf(
                            "name" to name,
                            "number" to number.trim()
                        ))
                    }
                } while (it.moveToNext())
            }
        }

        result.success(contactsList)
    }
}