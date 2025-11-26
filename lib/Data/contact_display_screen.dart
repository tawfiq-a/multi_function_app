// ContactsDisplayScreen.dart

import 'package:flutter/material.dart';

class ContactsDisplayScreen extends StatelessWidget {
  final List<dynamic> contactsList;

  const ContactsDisplayScreen({super.key, required this.contactsList});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Phone Contacts'),
        backgroundColor: Colors.purple.shade600,
        foregroundColor: Colors.white,
      ),
      body: ListView.builder(
        itemCount: contactsList.length,
        itemBuilder: (context, index) {
          final contact = contactsList[index] as Map<dynamic, dynamic>;

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            elevation: 2,
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.purple,
                child: Icon(Icons.person, color: Colors.white),
              ),
              title: Text(
                contact['name'] as String,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(contact['number'] as String),
              // আপনি চাইলে এই বাটন ব্যবহার করে সরাসরি কল করতে পারেন
              trailing: IconButton(
                icon: const Icon(Icons.call, color: Colors.green),
                onPressed: () {

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Calling ${contact['name']}...')),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}