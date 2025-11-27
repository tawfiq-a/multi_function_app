import 'package:flutter/material.dart';
import '../services/home_services.dart';
import 'app_details_screen.dart';

class AppsInfoScreen extends StatelessWidget {
  final List<String> appsList;
  const AppsInfoScreen({super.key, required this.appsList});

  @override
  Widget build(BuildContext context) {
    // HomeService with nullable color
    final homeService = HomeService(context, (msg, {Color? color}) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: color ?? Colors.black,
          duration: const Duration(seconds: 3),
        ),
      );
    });

    return Scaffold(
      appBar: AppBar(title: const Text("Installed Apps")),
      body: ListView.builder(
        itemCount: appsList.length,
        itemBuilder: (context, index) {
          final package = appsList[index];

          return ListTile(
            title: Text(package),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () async {
              try {
                // Ensure getAppDetails exists in HomeService
                final details = await homeService.getAppDetails(package);
                if (details != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AppDetailsScreen(details: details),
                    ),
                  );
                } else {
                  homeService.showSnackBar('No details found for $package');
                }
              } catch (e) {
                homeService.showSnackBar('Failed to fetch app details: $e', color: Colors.red);
              }
            },
          );
        },
      ),
    );
  }
}
