package com.example.test_alarm

import android.content.Context
import android.content.pm.ApplicationInfo
import android.graphics.drawable.BitmapDrawable
import android.graphics.drawable.Drawable
import android.util.Base64
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream

class AppInfoHandler(private val context: Context) {

    // 1️⃣ Get all installed apps
    fun getInstalledApps(result: MethodChannel.Result) {
        try {
            val pm = context.packageManager
            val apps = pm.getInstalledApplications(0)
            val appNames = apps.map { pm.getApplicationLabel(it).toString() }
            result.success(appNames)
        } catch (e: Exception) {
            result.error("ERROR", e.message, null)
        }
    }

    // 2️⃣ Get app details
    fun getAppDetails(call: MethodCall, result: MethodChannel.Result) {
        try {
            val packageName = call.argument<String>("package")!!
            val pm = context.packageManager

            val info = pm.getPackageInfo(packageName, 0)
            val appInfo = pm.getApplicationInfo(packageName, 0)

            val iconDrawable: Drawable = pm.getApplicationIcon(packageName)
            val iconBase64 = drawableToBase64(iconDrawable)

            val details = mapOf(
                "name" to pm.getApplicationLabel(appInfo).toString(),
                "package" to packageName,
                "versionName" to info.versionName,
                "versionCode" to info.longVersionCode.toString(),
                "installed" to info.firstInstallTime.toString(),
                "updated" to info.lastUpdateTime.toString(),
                "isSystem" to ((appInfo.flags and ApplicationInfo.FLAG_SYSTEM) != 0),
                "icon" to iconBase64
            )

            result.success(details)
        } catch (e: Exception) {
            result.error("ERROR", e.message, null)
        }
    }

    // 3️⃣ Helper: Convert Drawable → Base64
    private fun drawableToBase64(drawable: Drawable): String {
        val bitmap = (drawable as BitmapDrawable).bitmap
        val baos = ByteArrayOutputStream()
        bitmap.compress(android.graphics.Bitmap.CompressFormat.PNG, 100, baos)
        return Base64.encodeToString(baos.toByteArray(), Base64.NO_WRAP)
    }
}
