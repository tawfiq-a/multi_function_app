

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class LocationDisplayScreen extends StatefulWidget {
  final double latitude;
  final double longitude;

  const LocationDisplayScreen({
    super.key,
    required this.latitude,
    required this.longitude,
  });

  @override
  State<LocationDisplayScreen> createState() => _LocationDisplayScreenState();
}

class _LocationDisplayScreenState extends State<LocationDisplayScreen> {

  String _address = 'Fetching address via native...';


  static const MethodChannel platform = MethodChannel('com.example.alarm_clock/alarm');


  final Color primaryBrown = Colors.brown.shade400;

  @override
  void initState() {
    super.initState();

    _getAddressFromCoordinates();
  }


  Future<void> _getAddressFromCoordinates() async {
    try {

      final String? result = await platform.invokeMethod('getAddressFromCoordinates', {
        'latitude': widget.latitude,
        'longitude': widget.longitude,
      });

      setState(() {

        _address = result?.isNotEmpty == true ? result! : 'Address not found or native call failed.';
      });

    } on PlatformException catch (e) {
      setState(() {
        _address = 'Error: Geocoder failed (Check Internet/Native Setup)';
      });
      print('Native Geocoder Error: ${e.message}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Current Location Details'),
        backgroundColor: primaryBrown,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(
              Icons.location_pin,
              size: 80,
              color: Color(0xFF6D4C41),
            ),
            const SizedBox(height: 30),


            Card(
              elevation: 5,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              color: Colors.brown.shade50,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your Current Address :',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.brown.shade800,
                      ),
                    ),
                    const Divider(height: 10, thickness: 1),

                    _address == 'Fetching address ...'
                        ? const Center(child: CircularProgressIndicator(color: Color(0xFF6D4C41)))
                        : Text(
                      _address,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),


            Card(
              elevation: 5,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Location Coordinates (Raw Data)',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.brown.shade800,
                      ),
                    ),
                    const Divider(height: 20, thickness: 1),


                    _buildLocationRow('Latitude :', widget.latitude.toStringAsFixed(6)),
                    const SizedBox(height: 10),


                    _buildLocationRow('Longitude :', widget.longitude.toStringAsFixed(6)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),


            ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Map View feature coming soon!')),
                );
              },
              icon: const Icon(Icons.map),
              label: const Text('View on Map'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBrown,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildLocationRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 16, color: Colors.black54),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
        ),
      ],
    );
  }
}