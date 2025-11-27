import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';

import '../Apps/apps_info_screen.dart';
import '../Data/sms_display_screen.dart';
import '../Data/contact_display_screen.dart';
import '../location/location_display_screen.dart';
import '../main.dart';
import '../camera/camera_screen.dart';
import '../Microphone/audio_recording_screen.dart';

class HomeService {
  static const MethodChannel platform = MethodChannel('com.example.alarm_clock/alarm');

  final BuildContext context;
  final Function(String message, {Color color}) showSnackBar;

  HomeService(this.context, this.showSnackBar);

  // ------------------ Permission Requests ------------------
  Future<void> requestInitialPermissions() async {
    await [Permission.notification, Permission.microphone].request();
  }

  // ------------------ Alarm Functions ------------------
  Future<DateTime?> scheduleAlarm({required TimeOfDay? selectedTime, required bool test}) async {
    final now = DateTime.now();
    DateTime nextAlarmTime;

    if (test) {
      nextAlarmTime = now.add(const Duration(seconds: 5));
    } else {
      if (selectedTime == null) {
        showSnackBar('Please select a time first.', color: Colors.orange.shade700);
        return null;
      }
      nextAlarmTime = DateTime(now.year, now.month, now.day, selectedTime.hour, selectedTime.minute);
      if (nextAlarmTime.isBefore(now)) nextAlarmTime = nextAlarmTime.add(const Duration(days: 1));
    }

    try {
      await platform.invokeMethod('setAlarm', {
        'timeInMillis': nextAlarmTime.millisecondsSinceEpoch,
        'title': test ? 'Test Alarm' : 'WAKE UP!',
        'body': test ? 'Alarm in 5 seconds' : 'It is ${selectedTime?.format(context)}',
        'channelId': 'alarm_channel_id',
      });

      final formattedTime = DateFormat('EEE, MMM d, hh:mm a').format(nextAlarmTime.toLocal());
      showSnackBar('Alarm set for $formattedTime.', color: Colors.blue.shade700);
      return nextAlarmTime;
    } on PlatformException catch (e) {
      showSnackBar("Failed to set native alarm: ${e.message}", color: Colors.redAccent);
      return null;
    }
  }

  Future<void> cancelAlarm() async {
    try {
      await platform.invokeMethod('cancelAlarm');
      showSnackBar('Alarm cancelled.', color: Colors.red.shade700);
    } on PlatformException catch (e) {
      showSnackBar('Failed to cancel alarm: ${e.message}', color: Colors.red);
    }
  }

  // ------------------ Camera ------------------
  Future<void> openCameraAndCapture() async {
    if (cameras.isEmpty) {
      showSnackBar('No camera found or initialization failed.', color: Colors.red);
      return;
    }
    final resultPath = await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => CameraScreen(camera: cameras.first)),
    );
    if (resultPath != null) showSnackBar('Image captured successfully.', color: Colors.indigo);
  }

  // ------------------ Microphone ------------------
  Future<String?> openRecordingScreen() async {
    final resultPath = await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AudioRecordingScreen()),
    );
    if (resultPath != null && resultPath is String) {
      showSnackBar('Audio recorded: ${resultPath.split('/').last}', color: Colors.purple.shade600);
      return resultPath;
    } else {
      showSnackBar('Audio recording cancelled.', color: Colors.orange);
      return null;
    }
  }

  // ------------------ Location ------------------
  Future<void> getLocationNative() async {
    if (await Permission.location.request().isGranted) {
      showSnackBar('Fetching location...', color: Colors.indigo.shade600);
      try {
        final Map<dynamic, dynamic>? result = await platform.invokeMethod('getCurrentLocation');
        if (result != null) {
          final lat = result['latitude'] as double;
          final lon = result['longitude'] as double;
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => LocationDisplayScreen(latitude: lat, longitude: lon)),
          );
        } else {
          showSnackBar('Location not available.', color: Colors.orange);
        }
      } on PlatformException catch (e) {
        showSnackBar('Failed to get location: ${e.message}', color: Colors.red);
      }
    } else {
      showSnackBar('Location permission denied.', color: Colors.redAccent);
    }
  }

  // ------------------ SMS ------------------
  Future<void> getSmsListNative() async {
    if (await Permission.sms.request().isGranted) {
      showSnackBar('Fetching SMS list...', color: Colors.blue.shade600);
      try {
        final List<dynamic>? result = await platform.invokeMethod('getSmsList');
        if (result != null && result.isNotEmpty) {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => SmsDisplayScreen(smsList: result)),
          );
        } else {
          showSnackBar('No SMS found.', color: Colors.orange);
        }
      } on PlatformException catch (e) {
        showSnackBar('Failed to get SMS: ${e.message}', color: Colors.red);
      }
    } else {
      showSnackBar('SMS permission denied.', color: Colors.redAccent);
    }
  }

  // ------------------ Contacts ------------------
  Future<void> getContactsListNative() async {
    if (await Permission.contacts.request().isGranted) {
      showSnackBar('Fetching contacts...', color: Colors.purple.shade600);
      try {
        final List<dynamic>? result = await platform.invokeMethod('getContactsList');
        if (result != null && result.isNotEmpty) {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => ContactsDisplayScreen(contactsList: result)),
          );
        } else {
          showSnackBar('No contacts found.', color: Colors.orange);
        }
      } on PlatformException catch (e) {
        showSnackBar('Failed to get contacts: ${e.message}', color: Colors.red);
      }
    } else {
      showSnackBar('Contacts permission denied.', color: Colors.redAccent);
    }
  }

  // ------------------ Installed Apps ------------------
  Future<void> openInstalledAppsScreen() async {
    try {
      showSnackBar('Fetching installed apps...', color: Colors.indigo.shade600);
      final List<dynamic>? appsList = await platform.invokeMethod('getInstalledApps');
      if (appsList != null && appsList.isNotEmpty) {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => AppsInfoScreen(appsList: appsList.cast<String>())),
        );
      } else {
        showSnackBar('No apps found.', color: Colors.orange);
      }
    } on PlatformException catch (e) {
      showSnackBar('Failed to get apps: ${e.message}', color: Colors.red);
    }
  }

  // ------------------ Get App Details ------------------
  Future<Map<String, dynamic>?> getAppDetails(String packageName) async {
    try {
      final Map<dynamic, dynamic>? result =
      await platform.invokeMethod('getAppDetails', {'package': packageName});
      if (result != null) return Map<String, dynamic>.from(result);
      return null;
    } on PlatformException catch (e) {
      showSnackBar('Failed to get app details: ${e.message}', color: Colors.red);
      return null;
    }
  }
}
