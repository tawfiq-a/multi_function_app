import 'package:flutter/material.dart';
import 'dart:convert';

class AppDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> details;
  const AppDetailsScreen({super.key, required this.details});

  @override
  Widget build(BuildContext context) {
    final iconBase64 = details['icon'] as String?;
    final iconBytes =
    iconBase64 != null && iconBase64.isNotEmpty ? base64Decode(iconBase64) : null;

    return Scaffold(
      appBar: AppBar(title: Text(details['name'] ?? "App Details")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: ListView(
          children: [
            if (iconBytes != null)
              Center(
                child: Image.memory(iconBytes, width: 100, height: 100),
              ),
            const SizedBox(height: 20),
            infoRow("Package", details["package"]),
            infoRow("Version Name", details["versionName"]),
            infoRow("Version Code", details["versionCode"]),
            infoRow("Installed", details["installed"]),
            infoRow("Updated", details["updated"]),
            infoRow("System App", details["isSystem"].toString()),
          ],
        ),
      ),
    );
  }

  Widget infoRow(String title, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Text(
        "$title: $value",
        style: const TextStyle(fontSize: 16),
      ),
    );
  }
}
