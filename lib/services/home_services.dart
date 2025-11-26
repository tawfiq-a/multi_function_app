

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';

import '../Data/sms_display_screen.dart';
import '../Data/contact_display_screen.dart';
import '../location/location_display_screen.dart';
import '../main.dart';
import '../camera/camera_screen.dart';
import '../Microphone/audio_recording_screen.dart';


class HomeService {
  static const MethodChannel platform = MethodChannel(
    'com.example.alarm_clock/alarm',
  );

  final BuildContext context;
  final Function(String message, {Color color}) showSnackBar;

  HomeService(this.context, this.showSnackBar);

  // Permission Request
  Future<void> requestInitialPermissions() async {
    if (await Permission.notification.isDenied) {
      await Permission.notification.request();
    }
    if (await Permission.microphone.isDenied) {
      await Permission.microphone.request();
    }
  }

  // Alarm Function
  Future<DateTime?> scheduleAlarm({
    required TimeOfDay? selectedTime,
    required bool test,
  }) async {
    final now = DateTime.now();
    DateTime nextAlarmTime;

    if (test) {
      nextAlarmTime = now.add(const Duration(seconds: 5));
    } else {
      if (selectedTime == null) {
        showSnackBar('Please select a time first.', color: Colors.orange.shade700);
        return null;
      }
      nextAlarmTime = DateTime(
        now.year,
        now.month,
        now.day,
        selectedTime.hour,
        selectedTime.minute,
      );
      if (nextAlarmTime.isBefore(now)) {
        nextAlarmTime = nextAlarmTime.add(const Duration(days: 1));
      }
    }

    try {
      final int alarmTimeMillis = nextAlarmTime.millisecondsSinceEpoch;

      await platform.invokeMethod('setAlarm', {
        'timeInMillis': alarmTimeMillis,
        'title': test ? 'Test Alarm' : 'WAKE UP!',
        'body': test ? 'Alarm in 5 seconds' : 'It is ${selectedTime?.format(context)}',
        'channelId': 'alarm_channel_id',
      });

      String formattedTime = DateFormat('EEE, MMM d, hh:mm a').format(nextAlarmTime.toLocal());
      showSnackBar('Alarm set for $formattedTime. Check system settings for permissions.', color: Colors.blue.shade700);
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
      debugPrint("Failed to cancel native alarm: ${e.message}");
      showSnackBar('Failed to cancel alarm.', color: Colors.red);
    }
  }

  // Camera Function
  Future<void> openCameraAndCapture() async {
    if (cameras.isEmpty) {
      showSnackBar('Error: No camera found or initialization failed.', color: Colors.red);
      return;
    }

    final resultPath = await Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => CameraScreen(camera: cameras.first)),
    );

    if (resultPath != null) {
      showSnackBar('Image captured and saved temporarily.', color: Colors.indigo);
    }
  }

  // Microphone function
  Future<String?> openRecordingScreen() async {
    final resultPath = await Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const AudioRecordingScreen()),
    );

    if (resultPath != null && resultPath is String) {
      showSnackBar(
        'Audio recorded! Path: ${resultPath.split('/').last}',
        color: Colors.purple.shade600,
      );
      return resultPath;
    } else {
      showSnackBar('Audio recording cancelled.', color: Colors.orange);
      return null;
    }
  }

  // Location Function
  Future<void> getLocationNative() async {
    var status = await Permission.location.request();

    if (status.isGranted) {
      showSnackBar('Getting location via native code...', color: Colors.indigo.shade600);
      try {
        final Map<dynamic, dynamic>? result = await platform.invokeMethod('getCurrentLocation');

        if (result != null) {
          final double lat = result['latitude'];
          final double lon = result['longitude'];

          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => LocationDisplayScreen(latitude: lat, longitude: lon),
            ),
          );
        } else {
          showSnackBar('Location not available or timed out.', color: Colors.orange);
        }
      } on PlatformException catch (e) {
        String message = (e.code == "PERMISSION_DENIED") ? 'Permission Denied by Native Side. Check App Settings.' : "Failed to get location: ${e.message}";
        showSnackBar(message, color: Colors.red);
      }
    } else {
      showSnackBar('Location permission denied by user.', color: Colors.redAccent);
    }
  }

  // Sms Function
  Future<void> getSmsListNative() async {
    var status = await Permission.sms.request();
    if (status.isGranted) {
      showSnackBar('Fetching SMS list via native code...', color: Colors.blue.shade600);
      try {
        final List<dynamic>? result = await platform.invokeMethod('getSmsList');

        if (result != null && result.isNotEmpty) {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => SmsDisplayScreen(smsList: result)),
          );
        } else {
          showSnackBar('No SMS found or failed to fetch.', color: Colors.orange);
        }
      } on PlatformException catch (e) {
        showSnackBar("Failed to get SMS: ${e.message}", color: Colors.red);
      }
    } else {
      showSnackBar('SMS permission denied by user.', color: Colors.redAccent);
    }
  }

  // Contacts Function
  Future<void> getContactsListNative() async {
    var status = await Permission.contacts.request();
    if (status.isGranted) {
      showSnackBar('Fetching contacts via native code...', color: Colors.purple.shade600);
      try {
        final List<dynamic>? result = await platform.invokeMethod('getContactsList');
        if (result != null && result.isNotEmpty) {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => ContactsDisplayScreen(contactsList: result)),
          );
        } else {
          showSnackBar('No contacts found or failed to fetch.', color: Colors.orange);
        }
      } on PlatformException catch (e) {
        showSnackBar("Failed to get contacts: ${e.message}", color: Colors.red);
      }
    } else {
      showSnackBar('Contacts permission denied by user.', color: Colors.redAccent);
    }
  }
}