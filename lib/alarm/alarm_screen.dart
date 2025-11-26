import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../services/home_services.dart';

class AlarmScreen extends StatefulWidget {
  const AlarmScreen({super.key});

  @override
  State<AlarmScreen> createState() => _AlarmScreenState();
}

class _AlarmScreenState extends State<AlarmScreen> {
  TimeOfDay? selectedTime;
  DateTime? scheduledDate;
  String? _recordedAudioPath;

  // HomeService instance
  late HomeService _homeService;

  @override
  void initState() {
    super.initState();
    _homeService = HomeService(context, _showSnackBar);
    _homeService.requestInitialPermissions();
  }

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

  // --- Call All Functions ---

  Future<void> _scheduleAlarm({bool test = false}) async {
    final newScheduledDate = await _homeService.scheduleAlarm(
      selectedTime: selectedTime,
      test: test,
    );

    if (newScheduledDate != null) {
      setState(() {
        scheduledDate = newScheduledDate;
        _recordedAudioPath = null;
      });
    }
  }

  Future<void> _cancelAlarm() async {
    await _homeService.cancelAlarm();
    setState(() {
      selectedTime = null;
      scheduledDate = null;
      _recordedAudioPath = null;
    });
  }

  Future<void> _openRecordingScreen() async {
    final path = await _homeService.openRecordingScreen();
    if (path != null) {
      setState(() {
        _recordedAudioPath = path;
      });
    }
  }

  void _openCameraAndCapture() => _homeService.openCameraAndCapture();
  void _getLocationNative() => _homeService.getLocationNative();
  void _getSmsListNative() => _homeService.getSmsListNative();
  void _getContactsListNative() => _homeService.getContactsListNative();

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
                  Row(
                    children: [
                      SizedBox(
                        height: 60,
                        width: 150,
                        child: ElevatedButton.icon(
                          onPressed: () => _scheduleAlarm(),
                          icon: const Icon(Icons.alarm_add, size: 28),
                          label: const Text('SET ALARM'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryBlue,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                      Spacer(),

                      // CANCEL ALARM
                      SizedBox(
                        height: 60,
                        child: OutlinedButton.icon(
                          onPressed: _cancelAlarm,
                          icon: const Icon(Icons.alarm_off, size: 22),
                          label: const Text('CANCEL ALARM'),
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
                    ],
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

                  // GET CURRENT LOCATION
                  SizedBox(
                    height: 60,
                    width: 260,
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

                  Row(
                    children: [
                      // CAPTURE PHOTO
                      SizedBox(
                        height: 60,
                        width: 150,
                        child: ElevatedButton.icon(
                          onPressed: _openCameraAndCapture,
                          icon: const Icon(Icons.photo_camera, size: 28),
                          label: const Text('Camera'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.indigo.shade400,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),

                      Spacer(),

                      // RECORD AUDIO
                      SizedBox(
                        height: 60,
                        width: 150,
                        child: ElevatedButton.icon(
                          onPressed: _openRecordingScreen,
                          icon: const Icon(Icons.mic, size: 28),
                          label: Text(
                            _recordedAudioPath != null
                                ? 'AUDIO RECORDED'
                                : ' Mic ',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _recordedAudioPath != null
                                ? Colors.purple.shade800
                                : Colors.purple.shade600,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  //  SMS
                  Row(
                    children: [
                      SizedBox(
                        height: 60,
                        width: 150,
                        child: ElevatedButton.icon(
                          onPressed: _getSmsListNative,
                          icon: const Icon(Icons.message, size: 28),
                          label: const Text('View SMS '),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade600,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                      Spacer(),

                      // VIEW CONTACTS
                      SizedBox(
                        height: 60,
                        width: 150,
                        child: ElevatedButton.icon(
                          onPressed: _getContactsListNative,
                          icon: const Icon(Icons.people, size: 28),
                          label: const Text('CONTACTS '),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple.shade600,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
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
