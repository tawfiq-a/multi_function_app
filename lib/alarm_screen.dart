import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';
import 'package:test_alarm/sms_display_screen.dart';

import 'contact_display_screen.dart';
import 'location_display_screen.dart';
import 'main.dart';
import 'camera_screen.dart';
import 'audio_recording_screen.dart';

class AlarmHomePage extends StatefulWidget {
  const AlarmHomePage({super.key});

  @override
  State<AlarmHomePage> createState() => _AlarmHomePageState();
}

class _AlarmHomePageState extends State<AlarmHomePage> {
  TimeOfDay? selectedTime;
  DateTime? scheduledDate;

  String? _recordedAudioPath;

  static const MethodChannel platform = MethodChannel(
    'com.example.alarm_clock/alarm',
  );

  void _showSnackBar(String message, {Color color = Colors.black}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    if (await Permission.notification.isDenied) {
      await Permission.notification.request();
    }

    if (await Permission.microphone.isDenied) {
      await Permission.microphone.request();
    }
  }

  Future<void> _scheduleAlarm({bool test = false}) async {
    final now = DateTime.now();
    DateTime nextAlarmTime;

    if (test) {
      nextAlarmTime = now.add(const Duration(seconds: 5));
    } else {
      if (selectedTime == null) {
        _showSnackBar(
          'Please select a time first.',
          color: Colors.orange.shade700,
        );
        return;
      }
      nextAlarmTime = DateTime(
        now.year,
        now.month,
        now.day,
        selectedTime!.hour,
        selectedTime!.minute,
      );
      if (nextAlarmTime.isBefore(now)) {
        nextAlarmTime = nextAlarmTime.add(const Duration(days: 1));
      }
    }

    setState(() {
      scheduledDate = nextAlarmTime;
    });

    try {
      final int alarmTimeMillis = nextAlarmTime.millisecondsSinceEpoch;

      await platform.invokeMethod('setAlarm', {
        'timeInMillis': alarmTimeMillis,
        'title': test ? 'Test Alarm' : 'WAKE UP!',
        'body': test
            ? 'Alarm in 5 seconds'
            : 'It is ${selectedTime!.format(context)}',
        'channelId': 'alarm_channel_id',
      });

      String formattedTime = DateFormat(
        'EEE, MMM d, hh:mm a',
      ).format(scheduledDate!.toLocal());
      _showSnackBar(
        'Alarm set for $formattedTime. Check system settings for permissions.',
        color: Colors.blue.shade700,
      );

      setState(() {
        _recordedAudioPath = null;
      });
    } on PlatformException catch (e) {
      _showSnackBar(
        "Failed to set native alarm: ${e.message}",
        color: Colors.redAccent,
      );
    }
  }

  Future<void> _cancelAlarm() async {
    try {
      await platform.invokeMethod('cancelAlarm');
    } on PlatformException catch (e) {
      debugPrint("Failed to cancel native alarm: ${e.message}");
    }

    setState(() {
      selectedTime = null;
      scheduledDate = null;
      _recordedAudioPath = null;
    });
    _showSnackBar('Alarm cancelled.', color: Colors.red.shade700);
  }

  Future<void> _openCameraAndCapture() async {
    if (cameras.isEmpty) {
      _showSnackBar(
        'Error: No camera found or initialization failed.',
        color: Colors.red,
      );
      return;
    }

    final resultPath = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CameraScreen(camera: cameras.first),
      ),
    );

    if (resultPath != null) {
      print('Captured image path: $resultPath');
      _showSnackBar(
        'Image captured and saved temporarily: $resultPath',
        color: Colors.indigo,
      );
    }
  }

  Future<void> _openRecordingScreen() async {
    final resultPath = await Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const AudioRecordingScreen()),
    );

    if (resultPath != null && resultPath is String) {
      setState(() {
        _recordedAudioPath = resultPath;
      });
      _showSnackBar(
        'Audio recorded! Path: ${resultPath.split('/').last}',
        color: Colors.purple.shade600,
      );
      print('Attached audio path: $_recordedAudioPath');
    } else {
      _showSnackBar('Audio recording cancelled.', color: Colors.orange);
    }
  }

  Future<void> _getLocationNative() async {
    var status = await Permission.location.request();

    if (status.isGranted) {
      _showSnackBar(
        'Getting location via native code...',
        color: Colors.indigo.shade600,
      );
      try {
        final Map<dynamic, dynamic>? result = await platform.invokeMethod(
          'getCurrentLocation',
        );

        if (result != null) {
          final double lat = result['latitude'];
          final double lon = result['longitude'];

          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) =>
                  LocationDisplayScreen(latitude: lat, longitude: lon),
            ),
          );
        } else {
          _showSnackBar(
            'Location not available or timed out.',
            color: Colors.orange,
          );
        }
      } on PlatformException catch (e) {
        if (e.code == "PERMISSION_DENIED") {
          _showSnackBar(
            'Permission Denied by Native Side. Check App Settings.',
            color: Colors.red,
          );
        } else {
          _showSnackBar(
            "Failed to get location: ${e.message}",
            color: Colors.red,
          );
        }
      }
    } else {
      _showSnackBar(
        'Location permission denied by user.',
        color: Colors.redAccent,
      );
    }
  }

  Future<void> _getSmsListNative() async {
    // 1. Runtime Permission চাওয়া
    var status = await Permission.sms.request();

    if (status.isGranted) {
      _showSnackBar(
        'Fetching SMS list via native code...',
        color: Colors.blue.shade600,
      );
      try {
        // 2. নেটিভ Method Channel কল করা
        final List<dynamic>? result = await platform.invokeMethod('getSmsList');

        if (result != null && result.isNotEmpty) {
          // SMS গুলি পাওয়ার পর তা দেখানোর জন্য একটি নতুন স্ক্রিনে যেতে পারেন
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => SmsDisplayScreen(smsList: result),
            ),
          );
        } else {
          _showSnackBar(
            'No SMS found or failed to fetch.',
            color: Colors.orange,
          );
        }
      } on PlatformException catch (e) {
        _showSnackBar("Failed to get SMS: ${e.message}", color: Colors.red);
      }
    } else {
      _showSnackBar('SMS permission denied by user.', color: Colors.redAccent);
    }
  }

  Future<void> _getContactsListNative() async {

    var status = await Permission.contacts
        .request();

    if (status.isGranted) {
      _showSnackBar(
        'Fetching contacts via native code...',
        color: Colors.purple.shade600,
      );
      try {

        final List<dynamic>? result = await platform.invokeMethod(
          'getContactsList',
        );

        if (result != null && result.isNotEmpty) {

          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => ContactsDisplayScreen(contactsList: result),
            ),
          );
        } else {
          _showSnackBar(
            'No contacts found or failed to fetch.',
            color: Colors.orange,
          );
        }
      } on PlatformException catch (e) {
        _showSnackBar(
          "Failed to get contacts: ${e.message}",
          color: Colors.red,
        );
      }
    } else {
      _showSnackBar(
        'Contacts permission denied by user.',
        color: Colors.redAccent,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = Color(0xFF0D47A1);

    return Theme(
      data: ThemeData(
        primaryColor: primaryBlue,
        scaffoldBackgroundColor: const Color(0xFFF0F8FF),
        appBarTheme: AppBarTheme(
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(vertical: 15),
            textStyle: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
            elevation: 3,
          ),
        ),
      ),
      child: Scaffold(
        appBar: AppBar(title: const Text('Multi Function App')),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                elevation: 10,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 40.0,
                    horizontal: 20,
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Selected Alarm Time:',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      GestureDetector(
                        onTap: () async {
                          final TimeOfDay? picked = await showTimePicker(
                            context: context,
                            initialTime: selectedTime ?? TimeOfDay.now(),
                          );
                          if (picked != null) {
                            setState(() {
                              selectedTime = picked;
                              scheduledDate = null;
                            });
                          }
                        },
                        child: Text(
                          selectedTime != null
                              ? selectedTime!.format(context)
                              : 'Tap to Select Time',
                          style: TextStyle(
                            fontSize: selectedTime != null ? 72 : 40,
                            color: primaryBlue,
                            fontWeight: FontWeight.w900,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 20),

                      TextButton.icon(
                        onPressed: () async {
                          final TimeOfDay? picked = await showTimePicker(
                            context: context,
                            initialTime: selectedTime ?? TimeOfDay.now(),
                          );
                          if (picked != null) {
                            setState(() {
                              selectedTime = picked;
                              scheduledDate = null;
                            });
                          }
                        },
                        icon: const Icon(Icons.edit, size: 20),
                        label: Text(
                          selectedTime != null ? 'Change Time' : 'Select Time',
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: primaryBlue,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 40),

              Column(
                children: [
                  // SET ALARM
                  SizedBox(
                    height: 60,
                    width: 200,
                    child: ElevatedButton.icon(
                      onPressed: () => _scheduleAlarm(),
                      icon: const Icon(Icons.alarm_add, size: 28),
                      label: const Text('SET ALARM NOW'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryBlue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  SizedBox(
                    height: 60,
                    width: 200,
                    child: ElevatedButton.icon(
                      onPressed: _openCameraAndCapture,
                      icon: const Icon(Icons.photo_camera, size: 28),
                      label: const Text('CAPTURE PHOTO'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo.shade400,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // GET CURRENT LOCATION
                  SizedBox(
                    height: 60,
                    width: 250,
                    child: ElevatedButton.icon(
                      onPressed: _getLocationNative,
                      icon: const Icon(Icons.location_on, size: 28),
                      label: const Text('GET CURRENT LOCATION'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.brown.shade400,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // RECORD AUDIO
                  SizedBox(
                    height: 60,
                    width: 200,
                    child: ElevatedButton.icon(
                      onPressed: _openRecordingScreen,
                      icon: const Icon(Icons.mic, size: 28),
                      label: Text(
                        _recordedAudioPath != null
                            ? 'AUDIO RECORD'
                            : 'RECORD AUDIO ',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _recordedAudioPath != null
                            ? Colors.purple.shade800
                            : Colors.purple.shade600,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // TEST ALARM
                  SizedBox(
                    height: 60,
                    width: 260,
                    child: ElevatedButton.icon(
                      onPressed: () => _scheduleAlarm(test: true),
                      icon: const Icon(Icons.timer_sharp, size: 28),
                      label: const Text('TEST ALARM (5 SECONDS)'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal.shade500,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // CANCEL ALARM
                  SizedBox(
                    height: 50,
                    child: OutlinedButton.icon(
                      onPressed: _cancelAlarm,
                      icon: const Icon(Icons.alarm_off, size: 22),
                      label: const Text('CANCEL CURRENT ALARM'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.redAccent,
                        side: BorderSide(
                          color: Colors.redAccent.shade100,
                          width: 2,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  SizedBox(
                    height: 60,
                    width: 200,
                    child: ElevatedButton.icon(
                      onPressed: _getSmsListNative,
                      icon: const Icon(Icons.message, size: 28),
                      label: const Text('VIEW RECENT SMS '),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade600,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                  SizedBox(
                    height: 60,
                    width: 200,
                    child: ElevatedButton.icon(
                      onPressed: _getContactsListNative,
                      icon: const Icon(Icons.people, size: 28),
                      label: const Text('VIEW CONTACTS '),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple.shade600,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 40),

              // Scheduled Info
              if (scheduledDate != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: primaryBlue.withAlpha(5),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: primaryBlue, width: 1.5),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        color: primaryBlue,
                        size: 30,
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Alarm is Scheduled For:',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14, color: Colors.black54),
                      ),
                      Text(
                        DateFormat(
                          'EEEE, MMM d, hh:mm:ss a',
                        ).format(scheduledDate!.toLocal()),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: primaryBlue,
                        ),
                      ),
                      const SizedBox(height: 5),
                      const Text(
                        'Uses Native Android Alarm Manager',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
