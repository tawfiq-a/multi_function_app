
package com.example.test_alarm

import android.content.Context
import android.content.pm.PackageManager
import android.database.Cursor
import android.net.Uri
import android.provider.ContactsContract
import androidx.core.app.ActivityCompat
import io.flutter.plugin.common.MethodChannel

class DataHandler(private val context: Context) {

    fun getSmsList(result: MethodChannel.Result) {
        if (ActivityCompat.checkSelfPermission(context, android.Manifest.permission.READ_SMS) != PackageManager.PERMISSION_GRANTED) {
            result.error("PERMISSION_DENIED", "READ_SMS permission not granted.", null)
            return
        }

        val smsList = mutableListOf<Map<String, Any?>>()
        val cursor: Cursor? = context.contentResolver.query(
            Uri.parse("content://sms/inbox"),
            arrayOf("address", "body", "date"),
            null,
            null,
            "date DESC LIMIT 50"
        )

        cursor?.use {
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

        result.success(smsList)
    }

    fun getContactsList(result: MethodChannel.Result) {
        if (ActivityCompat.checkSelfPermission(context, android.Manifest.permission.READ_CONTACTS) != PackageManager.PERMISSION_GRANTED) {
            result.error("PERMISSION_DENIED", "READ_CONTACTS permission not granted.", null)
            return
        }

        val contactsList = mutableListOf<Map<String, Any?>>()
        val cursor: Cursor? = context.contentResolver.query(
            ContactsContract.CommonDataKinds.Phone.CONTENT_URI,
            arrayOf(
                ContactsContract.CommonDataKinds.Phone.DISPLAY_NAME,
                ContactsContract.CommonDataKinds.Phone.NUMBER
            ),
            null,
            null,
            ContactsContract.CommonDataKinds.Phone.DISPLAY_NAME + " ASC"
        )

        cursor?.use {
            if (it.moveToFirst()) {
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