

import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:io';

class AudioRecordingScreen extends StatefulWidget {
  const AudioRecordingScreen({super.key});

  @override
  State<AudioRecordingScreen> createState() => _AudioRecordingScreenState();
}

class _AudioRecordingScreenState extends State<AudioRecordingScreen> {
  final AudioRecorder _audioRecorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isRecording = false;
  bool _isPlaying = false;
  String? _recordedFilePath;

  @override
  void initState() {
    super.initState();
    _audioPlayer.onPlayerComplete.listen((event) {
      setState(() {
        _isPlaying = false;
      });
    });
  }

  @override
  void dispose() {
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _showSnackBar(String message, {Color color = Colors.black}) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: color,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _startRecording() async {
    if (await _audioRecorder.hasPermission()) {
      try {
        final dir = await getApplicationDocumentsDirectory();
        final filePath = '${dir.path}/alarm_note_${DateTime.now().millisecondsSinceEpoch}.m4a';

        await _audioRecorder.start(const RecordConfig(), path: filePath);

        setState(() {
          _isRecording = true;
          _recordedFilePath = null;
          _isPlaying = false;
        });
        _audioPlayer.stop();
        _showSnackBar("Recording started...", color: Colors.green);
      } catch (e) {
        _showSnackBar("Error starting recording: $e", color: Colors.red);
      }
    } else {
      _showSnackBar("Microphone permission denied.", color: Colors.red);
    }
  }

  Future<void> _stopRecording() async {
    final path = await _audioRecorder.stop();

    setState(() {
      _isRecording = false;
      _recordedFilePath = path;
    });

    if (path != null) {
      print('✅ Recorded file path: $path');
      _showSnackBar("Recording stopped. Tap PLAY to listen or SAVE to attach.", color: Colors.blue);
    }
  }


  Future<void> _playPauseAudio() async {
    if (_recordedFilePath == null) return;

    if (_isPlaying) {

      await _audioPlayer.pause();
      setState(() {
        _isPlaying = false;
      });
    } else {

      await _audioPlayer.stop();
      await _audioPlayer.setVolume(1.0);


      await _audioPlayer.play(DeviceFileSource(_recordedFilePath!));

      setState(() {
        _isPlaying = true;
      });
    }
  }


  void _saveAndExit() {
    _audioPlayer.stop();
    if (_recordedFilePath != null && !_isRecording) {
      Navigator.of(context).pop(_recordedFilePath);
    } else if (_isRecording) {
      _showSnackBar("Please stop recording before saving.", color: Colors.orange);
    } else {
      Navigator.of(context).pop(null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Record Alarm Note'),
        backgroundColor: Colors.purple.shade600,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _isRecording ? Icons.mic_external_on : Icons.mic_none,
              size: 100,
              color: _isRecording ? Colors.redAccent : Colors.grey.shade400,
            ),
            const SizedBox(height: 20),
            Text(
              _isRecording ? 'Recording... Tap to Stop' : 'Ready to record alarm audio.',
              style: TextStyle(
                fontSize: 18,
                color: _isRecording ? Colors.black : Colors.grey.shade700,
              ),
            ),
            if (_recordedFilePath != null && !_isRecording)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  'Recorded File: ${File(_recordedFilePath!).path.split('/').last}',
                  style: const TextStyle(fontSize: 14, color: Colors.black54),
                ),
              ),
            const SizedBox(height: 40),


            FloatingActionButton.large(
              onPressed: _isRecording ? _stopRecording : _startRecording,
              backgroundColor: _isRecording ? Colors.redAccent : Colors.purple.shade600,
              foregroundColor: Colors.white,
              child: Icon(_isRecording ? Icons.stop : Icons.mic),
            ),

            const SizedBox(height: 30),


            if (_recordedFilePath != null && !_isRecording)
              SizedBox(
                height: 60,
                child: ElevatedButton.icon(
                  onPressed: _playPauseAudio,
                  icon: Icon(_isPlaying ? Icons.pause_circle : Icons.play_circle, size: 28),
                  label: Text(_isPlaying ? 'PAUSE PLAYBACK' : 'PLAY RECORDING'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isPlaying ? Colors.amber.shade700 : Colors.green.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                    textStyle: const TextStyle(fontSize: 16),
                  ),
                ),
              ),

            if (_recordedFilePath != null && !_isRecording)
              const SizedBox(height: 30),


            ElevatedButton.icon(
              onPressed: _saveAndExit,
              icon: const Icon(Icons.save),
              label: const Text('SAVE AND GO BACK'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                textStyle: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}