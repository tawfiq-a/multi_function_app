
package com.example.test_alarm

import android.content.Context
import android.content.pm.PackageManager
import android.location.Location
import android.location.Geocoder
import android.os.Looper
import androidx.core.app.ActivityCompat
import io.flutter.plugin.common.MethodChannel
import com.google.android.gms.location.*
import java.io.IOException
import java.util.Locale

class LocationHandler(private val context: Context) {
    private val fusedLocationClient: FusedLocationProviderClient = LocationServices.getFusedLocationProviderClient(context)


    private fun checkLocationPermission(): Boolean {
        return ActivityCompat.checkSelfPermission(
            context,
            android.Manifest.permission.ACCESS_FINE_LOCATION
        ) == PackageManager.PERMISSION_GRANTED
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

        if (checkLocationPermission()) {

            fusedLocationClient.requestLocationUpdates(
                locationRequest, locationCallback, Looper.getMainLooper()
            )
        } else {
            result.error("PERMISSION_ERROR", "Location permission check failed.", null)
        }
    }

    fun getCurrentLocation(result: MethodChannel.Result) {
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

    fun getAddressFromCoordinates(call: io.flutter.plugin.common.MethodCall, result: MethodChannel.Result) {
        val latitude = call.argument<Double>("latitude")
        val longitude = call.argument<Double>("longitude")

        if (latitude == null || longitude == null) {
            result.error("ARGUMENT_ERROR", "Latitude and Longitude are required.", null)
            return
        }

        val geocoder = Geocoder(context, Locale.getDefault())
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
}