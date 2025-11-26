// SmsDisplayScreen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // ডেট ফরম্যাট করার জন্য (pubspec.yaml এ intl যোগ করতে হবে)

class SmsDisplayScreen extends StatelessWidget {
  final List<dynamic> smsList;

  const SmsDisplayScreen({super.key, required this.smsList});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recent SMS Messages'),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
      ),
      body: ListView.builder(
        itemCount: smsList.length,
        itemBuilder: (context, index) {
          final sms = smsList[index] as Map<dynamic, dynamic>;
          final timestamp = sms['timestamp'] as int;
          final date = DateTime.fromMillisecondsSinceEpoch(timestamp);

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            elevation: 2,
            child: ListTile(
              leading: const Icon(Icons.message, color: Colors.blue),
              title: Text(
                sms['message'] as String,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text('From: ${sms['sender']}'),
              trailing: Text(
                DateFormat('MMM d, h:mm a').format(date),
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
          );
        },
      ),
    );
  }
}